# 第28节 Docker Compose 生产环境部署

## 学习目标

- 掌握生产环境 Docker 配置
- 学习多服务编排与管理
- 实现数据持久化与备份
- 了解环境变量管理
- 掌握 SSL/HTTPS 配置

## 1. 生产环境 Docker Compose 配置

### 1.1 项目目录结构

```
production/
├── docker-compose.yml          # 主编排文件
├── docker-compose.override.yml # 本地覆盖配置
├── .env                        # 环境变量
├── .env.example                # 环境变量示例
├── mysql/
│   ├── conf/
│   │   └── my.cnf             # MySQL 配置
│   └── init/
│       └── 01-init.sql        # 初始化脚本
├── redis/
│   └── redis.conf             # Redis 配置
├── nginx/
│   ├── nginx.conf             # Nginx 主配置
│   └── conf.d/
│       └── default.conf       # 站点配置
├── logs/                      # 日志目录
├── data/                      # 数据目录
└── backup/                    # 备份目录
```

### 1.2 生产环境 docker-compose.yml

创建 `production/docker-compose.yml`：

```yaml
version: '3.8'

services:
  # MySQL 数据库
  mysql:
    image: mysql:8.0
    container_name: mall-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      TZ: Asia/Shanghai
    volumes:
      - ./data/mysql:/var/lib/mysql
      - ./mysql/conf/my.cnf:/etc/mysql/conf.d/my.cnf
      - ./mysql/init:/docker-entrypoint-initdb.d
      - ./backup/mysql:/backup
    ports:
      - "3306:3306"
    networks:
      - mall-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # Redis 缓存
  redis:
    image: redis:7-alpine
    container_name: mall-redis
    restart: always
    command: redis-server /usr/local/etc/redis/redis.conf
    volumes:
      - ./data/redis:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
    ports:
      - "6379:6379"
    networks:
      - mall-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # 后端应用
  app:
    image: ${DOCKER_REGISTRY}/mall-tiny:${APP_VERSION:-latest}
    container_name: mall-app
    restart: always
    environment:
      SPRING_PROFILES_ACTIVE: prod
      MYSQL_HOST: mysql
      MYSQL_PORT: 3306
      MYSQL_DB: ${MYSQL_DATABASE}
      MYSQL_USERNAME: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      JAVA_OPTS: "-Xms1g -Xmx1g -XX:+UseG1GC"
    ports:
      - "8080:8080"
    volumes:
      - ./logs/app:/var/log/mall-tiny
      - ./data/upload:/var/upload/mall-tiny
    networks:
      - mall-network
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/admin/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # 前端应用
  web:
    image: ${DOCKER_REGISTRY}/mall-admin-web:${WEB_VERSION:-latest}
    container_name: mall-web
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./data/ssl:/etc/nginx/ssl
      - ./logs/nginx:/var/log/nginx
    networks:
      - mall-network
    depends_on:
      - app

  # 日志收集 (可选)
  filebeat:
    image: docker.elastic.co/beats/filebeat:8.11.0
    container_name: mall-filebeat
    restart: always
    user: root
    volumes:
      - ./logs:/logs:ro
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml
    networks:
      - mall-network
    depends_on:
      - app
      - web

networks:
  mall-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 1.3 环境变量文件

创建 `production/.env`：

```bash
# Docker 镜像仓库
DOCKER_REGISTRY=ghcr.io/mihayooo

# 应用版本
APP_VERSION=latest
WEB_VERSION=latest

# MySQL 配置
MYSQL_ROOT_PASSWORD=YourStrongRootPassword123!
MYSQL_DATABASE=mall_tiny
MYSQL_USER=mall_user
MYSQL_PASSWORD=YourStrongUserPassword123!

# Redis 配置
REDIS_PASSWORD=YourRedisPassword123!

# JWT 密钥（至少256位）
JWT_SECRET=your-super-secret-jwt-key-must-be-at-least-256-bits-long-for-production

# 服务器配置
SERVER_HOST=your-domain.com
SERVER_IP=123.456.789.0
```

## 2. MySQL 生产配置

### 2.1 MySQL 配置文件

创建 `production/mysql/conf/my.cnf`：

```ini
[mysqld]
# 基础配置
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-storage-engine=InnoDB

# 性能优化
innodb_buffer_pool_size=1G
innodb_log_file_size=256M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT

# 连接配置
max_connections=200
wait_timeout=600
interactive_timeout=600

# 查询缓存（MySQL 8.0 已移除）
# query_cache_type=1
# query_cache_size=64M

# 慢查询日志
slow_query_log=1
slow_query_log_file=/var/lib/mysql/slow.log
long_query_time=2

# 时区
default-time-zone='+08:00'

# 安全配置
local_infile=0
skip-symbolic-links

[mysql]
default-character-set=utf8mb4

[client]
default-character-set=utf8mb4
```

### 2.2 数据库初始化脚本

创建 `production/mysql/init/01-init.sql`：

```sql
-- 创建应用用户（如果需要在初始化时创建）
-- CREATE USER IF NOT EXISTS 'mall_user'@'%' IDENTIFIED BY 'password';
-- GRANT ALL PRIVILEGES ON mall_tiny.* TO 'mall_user'@'%';
-- FLUSH PRIVILEGES;

-- 设置时区
SET GLOBAL time_zone = '+08:00';
SET time_zone = '+08:00';
```

## 3. Redis 生产配置

创建 `production/redis/redis.conf`：

```conf
# 基础配置
bind 0.0.0.0
port 6379
protected-mode yes
requirepass ${REDIS_PASSWORD}

# 持久化配置
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# AOF 持久化
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# 内存配置
maxmemory 512mb
maxmemory-policy allkeys-lru

# 客户端配置
timeout 300
tcp-keepalive 300
maxclients 10000

# 日志配置
loglevel notice

# 慢查询日志
slowlog-log-slower-than 10000
slowlog-max-len 128
```

## 4. Nginx 生产配置

### 4.1 Nginx 主配置

创建 `production/nginx/nginx.conf`：

```nginx
user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    '$request_time $upstream_response_time';

    access_log /var/log/nginx/access.log main;

    # 性能优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json 
               application/javascript application/rss+xml 
               application/atom+xml image/svg+xml;

    # 限流配置
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

    # 包含站点配置
    include /etc/nginx/conf.d/*.conf;
}
```

### 4.2 HTTPS 站点配置

创建 `production/nginx/conf.d/default.conf`：

```nginx
# 上游服务器
upstream backend {
    least_conn;
    server app:8080 weight=5 max_fails=3 fail_timeout=30s;
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    server_name _;

    # SSL 证书
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;

    # 前端静态资源
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # 缓存控制
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
    }

    # API 代理
    location /admin/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时配置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # 缓冲区
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # 限流
        limit_req zone=api_limit burst=20 nodelay;
        limit_conn conn_limit 10;
    }

    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

## 5. 数据备份脚本

### 5.1 MySQL 备份脚本

创建 `production/backup/backup-mysql.sh`：

```bash
#!/bin/bash

# 配置
BACKUP_DIR="/opt/mall-tiny/backup/mysql"
DB_NAME="mall_tiny"
DB_USER="root"
DB_PASS="${MYSQL_ROOT_PASSWORD}"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p ${BACKUP_DIR}

# 执行备份
docker exec mall-mysql mysqldump -u${DB_USER} -p${DB_PASS} \
    --single-transaction \
    --routines \
    --triggers \
    ${DB_NAME} | gzip > ${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz

# 检查备份是否成功
if [ $? -eq 0 ]; then
    echo "✅ Backup completed: ${DB_NAME}_${DATE}.sql.gz"
    
    # 删除旧备份
    find ${BACKUP_DIR} -name "${DB_NAME}_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
    echo "🗑️  Old backups cleaned (>${RETENTION_DAYS} days)"
else
    echo "❌ Backup failed!"
    exit 1
fi
```

### 5.2 定时备份配置

```bash
# 添加 crontab 任务
crontab -e

# 每天凌晨2点备份 MySQL
0 2 * * * /opt/mall-tiny/backup/backup-mysql.sh >> /var/log/mall-tiny/backup.log 2>&1

# 每周日备份整个数据目录
0 3 * * 0 tar -czf /backup/mall-data-$(date +\%Y\%m\%d).tar.gz /opt/mall-tiny/data/
```

## 6. 部署操作指南

### 6.1 首次部署

```bash
# 1. 创建目录
mkdir -p /opt/mall-tiny
cd /opt/mall-tiny

# 2. 复制配置文件
# 将 docker-compose.yml, .env, nginx/, mysql/, redis/ 复制到当前目录

# 3. 修改环境变量
vim .env

# 4. 创建数据目录
mkdir -p data/mysql data/redis data/ssl data/upload
mkdir -p logs/app logs/nginx
mkdir -p backup/mysql

# 5. 放置 SSL 证书
cp your-cert.pem data/ssl/cert.pem
cp your-key.pem data/ssl/key.pem

# 6. 启动服务
docker-compose up -d

# 7. 查看状态
docker-compose ps
docker-compose logs -f
```

### 6.2 日常运维命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f app
docker-compose logs -f --tail=100 web

# 重启服务
docker-compose restart app
docker-compose restart

# 更新镜像
docker-compose pull
docker-compose up -d

# 进入容器
docker-compose exec mysql bash
docker-compose exec app sh

# 备份数据
./backup/backup-mysql.sh

# 查看资源使用
docker stats
```

### 6.3 版本更新流程

```bash
# 1. 拉取新镜像
docker-compose pull

# 2. 备份数据（重要！）
./backup/backup-mysql.sh

# 3. 优雅更新
docker-compose up -d --no-deps --build app

# 4. 健康检查
sleep 30
curl -f http://localhost:8080/admin/actuator/health

# 5. 清理旧镜像
docker image prune -f
```

## 7. 监控检查清单

### 7.1 健康检查端点

| 服务 | 检查命令 | 预期结果 |
|------|----------|----------|
| MySQL | `docker-compose exec mysql mysqladmin ping` | `mysqld is alive` |
| Redis | `docker-compose exec redis redis-cli ping` | `PONG` |
| 后端 | `curl http://localhost:8080/admin/actuator/health` | `{"status":"UP"}` |
| Nginx | `curl http://localhost/health` | `healthy` |

### 7.2 资源监控

```bash
# 查看容器资源使用
docker stats --no-stream

# 查看磁盘使用
df -h

# 查看内存使用
free -h

# 查看日志大小
du -sh logs/*
```

## 小结

本节我们学习了：

1. **Docker Compose 生产配置** - 多服务编排、健康检查
2. **MySQL 生产配置** - 性能优化、持久化、备份
3. **Redis 生产配置** - AOF/RDB、内存管理
4. **Nginx 生产配置** - HTTPS、限流、安全头
5. **数据备份** - 自动化备份、定时任务
6. **运维操作** - 部署、更新、监控

下一节我们将学习日志收集与监控告警。
