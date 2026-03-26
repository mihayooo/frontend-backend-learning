# 第26节 生产环境配置与优化

## 学习目标

- 掌握 Spring Boot 生产环境配置
- 学习数据库连接池优化
- 了解 JVM 参数调优
- 掌握 Nginx 反向代理配置
- 学习静态资源优化策略

## 1. Spring Boot 生产环境配置

### 1.1 application-prod.yml

创建生产环境配置文件 `src/main/resources/application-prod.yml`：

```yaml
# 生产环境配置
server:
  port: 8080
  servlet:
    context-path: /admin
  # 压缩配置
  compression:
    enabled: true
    mime-types: application/json,application/xml,text/html,text/plain
    min-response-size: 1024

spring:
  # 数据源配置
  datasource:
    url: jdbc:mysql://${MYSQL_HOST:localhost}:${MYSQL_PORT:3306}/${MYSQL_DB:mall_tiny}?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=true
    username: ${MYSQL_USERNAME:root}
    password: ${MYSQL_PASSWORD:root}
    driver-class-name: com.mysql.cj.jdbc.Driver
    # HikariCP 连接池配置
    hikari:
      minimum-idle: 10
      maximum-pool-size: 50
      idle-timeout: 600000
      max-lifetime: 1800000
      connection-timeout: 30000
      connection-test-query: SELECT 1

  # Redis 配置
  redis:
    host: ${REDIS_HOST:localhost}
    port: ${REDIS_PORT:6379}
    password: ${REDIS_PASSWORD:}
    database: 0
    timeout: 3000ms
    lettuce:
      pool:
        max-active: 50
        max-idle: 20
        min-idle: 5
        max-wait: 3000ms

  # Jackson 配置
  jackson:
    date-format: yyyy-MM-dd HH:mm:ss
    time-zone: GMT+8
    serialization:
      write-dates-as-timestamps: false
      write-null-map-values: false
    default-property-inclusion: non_null

# MyBatis-Plus 配置
mybatis-plus:
  configuration:
    log-impl: org.apache.ibatis.logging.nologging.NoLoggingImpl  # 生产环境关闭SQL日志
  global-config:
    db-config:
      logic-delete-field: deleted
      logic-delete-value: 1
      logic-not-delete-value: 0

# 日志配置
logging:
  level:
    root: WARN
    com.macro.mall.tiny: INFO
  file:
    name: /var/log/mall-tiny/application.log
    max-size: 100MB
    max-history: 30

# JWT 配置
jwt:
  tokenHeader: Authorization
  secret: ${JWT_SECRET:your-secret-key-here-must-be-at-least-256-bits-long-for-security}
  expiration: 604800  # 7天
  tokenHead: Bearer

# 文件上传配置
file:
  upload:
    path: /var/upload/mall-tiny
    max-size: 10MB
    allowed-types: image/jpeg,image/png,image/gif
```

### 1.2 多环境配置切换

在 `application.yml` 中配置环境切换：

```yaml
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}
```

启动时指定环境：

```bash
# 开发环境
java -jar mall-tiny.jar --spring.profiles.active=dev

# 生产环境
java -jar mall-tiny.jar --spring.profiles.active=prod
```

## 2. 数据库连接池优化

### 2.1 HikariCP 最佳实践

HikariCP 是 Spring Boot 2.x 默认的连接池，性能优异。

**核心参数说明：**

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| minimum-idle | 最小空闲连接数 | 10 |
| maximum-pool-size | 最大连接数 | CPU核数 * 2 + 有效磁盘数 |
| idle-timeout | 空闲连接超时时间 | 600000 (10分钟) |
| max-lifetime | 连接最大生命周期 | 1800000 (30分钟) |
| connection-timeout | 连接超时时间 | 30000 (30秒) |

**计算公式：**
```
maximum-pool-size = (核心数 * 2) + 有效磁盘数

例如：4核CPU + 1块SSD
maximum-pool-size = (4 * 2) + 1 = 9，建议设置为10-20
```

### 2.2 MySQL 优化配置

```sql
-- 查看当前连接数
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Max_used_connections';

-- 查看最大连接数
SHOW VARIABLES LIKE 'max_connections';

-- 修改最大连接数（临时）
SET GLOBAL max_connections = 500;

-- 修改最大连接数（永久，需修改my.cnf）
[mysqld]
max_connections = 500
max_connect_errors = 1000
wait_timeout = 600
interactive_timeout = 600
```

## 3. JVM 参数调优

### 3.1 生产环境 JVM 配置

创建 `start-prod.sh` 启动脚本：

```bash
#!/bin/bash

# JVM 内存配置
JAVA_OPTS="-server \
  -Xms2g \
  -Xmx2g \
  -Xmn768m \
  -XX:MetaspaceSize=256m \
  -XX:MaxMetaspaceSize=512m \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/var/log/mall-tiny/heapdump.hprof \
  -XX:+PrintGCDetails \
  -XX:+PrintGCDateStamps \
  -Xloggc:/var/log/mall-tiny/gc.log \
  -XX:+UseGCLogFileRotation \
  -XX:NumberOfGCLogFiles=10 \
  -XX:GCLogFileSize=100M"

# 应用配置
APP_OPTS="--spring.profiles.active=prod \
  --server.port=8080"

# 启动应用
nohup java $JAVA_OPTS -jar mall-tiny.jar $APP_OPTS > /dev/null 2>&1 &

echo "Application started with PID: $!"
```

### 3.2 JVM 参数说明

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| -Xms | 初始堆内存 | 与-Xmx相同，避免动态调整 |
| -Xmx | 最大堆内存 | 物理内存的 1/4 ~ 1/2 |
| -Xmn | 年轻代大小 | 堆内存的 1/3 ~ 1/4 |
| -XX:+UseG1GC | 使用 G1 垃圾收集器 | JDK 9+ 默认 |
| -XX:MaxGCPauseMillis | 最大 GC 停顿时间 | 200ms |

### 3.3 内存分配示意图

```
┌─────────────────────────────────────────────────────────────┐
│                        2GB 堆内存                            │
├─────────────────────────────────────────────────────────────┤
│  年轻代 (768MB)              │        老年代 (1280MB)        │
│  ┌──────────┬──────────┐    │                               │
│  │  Eden    │ Survivor │    │                               │
│  │  (640MB) │ (128MB)  │    │                               │
│  └──────────┴──────────┘    │                               │
├─────────────────────────────┴───────────────────────────────┤
│              元空间 (256MB ~ 512MB)                          │
└─────────────────────────────────────────────────────────────┘
```

## 4. Nginx 反向代理配置

### 4.1 基础配置

创建 `/etc/nginx/conf.d/mall-tiny.conf`：

```nginx
# 上游服务器配置
upstream mall_tiny_backend {
    least_conn;  # 最少连接负载均衡
    server 127.0.0.1:8080 weight=5 max_fails=3 fail_timeout=30s;
    # 可添加更多实例
    # server 127.0.0.1:8081 weight=5 max_fails=3 fail_timeout=30s;
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL 证书配置
    ssl_certificate /etc/nginx/ssl/your-domain.crt;
    ssl_certificate_key /etc/nginx/ssl/your-domain.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 安全头配置
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # 日志配置
    access_log /var/log/nginx/mall-tiny-access.log;
    error_log /var/log/nginx/mall-tiny-error.log;

    # 前端静态资源
    location / {
        root /var/www/mall-admin-web/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # API 代理
    location /admin/ {
        proxy_pass http://mall_tiny_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时配置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # 缓冲区配置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }

    # Swagger/API 文档（生产环境建议禁用或限制IP）
    location /swagger-ui/ {
        allow 192.168.0.0/24;  # 只允许内网访问
        deny all;
        proxy_pass http://mall_tiny_backend;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        root /var/www/mall-admin-web/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
```

### 4.2 Nginx 性能优化

```nginx
# /etc/nginx/nginx.conf

user nginx;
worker_processes auto;  # 根据CPU核心数自动调整
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

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;

    include /etc/nginx/conf.d/*.conf;
}
```

## 5. 静态资源优化

### 5.1 前端构建优化

修改 `mall-admin-web/vite.config.ts`：

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { visualizer } from 'rollup-plugin-visualizer'

export default defineConfig(({ mode }) => ({
  plugins: [
    vue(),
    // 打包分析（仅生产环境）
    mode === 'production' && visualizer({
      open: true,
      gzipSize: true,
      brotliSize: true,
    })
  ],
  
  build: {
    // 代码分割
    rollupOptions: {
      output: {
        manualChunks: {
          // 将第三方库单独打包
          'element-plus': ['element-plus'],
          'vue-vendor': ['vue', 'vue-router', 'pinia'],
          'utils': ['axios', 'dayjs']
        }
      }
    },
    
    // 压缩配置
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,  // 移除console
        drop_debugger: true  // 移除debugger
      }
    },
    
    // 资源内联阈值
    assetsInlineLimit: 4096,
    
    // 生成source map
    sourcemap: false
  },
  
  // 依赖预构建
  optimizeDeps: {
    include: ['vue', 'vue-router', 'pinia', 'element-plus', 'axios']
  }
}))
```

### 5.2 CDN 加速配置

```html
<!-- index.html -->
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <!-- 使用 CDN 加载第三方库 -->
  <script src="https://cdn.jsdelivr.net/npm/vue@3.3.4/dist/vue.global.prod.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/vue-router@4.2.4/dist/vue-router.global.prod.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/element-plus@2.3.8/dist/index.full.min.js"></script>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/element-plus@2.3.8/dist/index.css">
</head>
<body>
  <div id="app"></div>
  <script type="module" src="/src/main.ts"></script>
</body>
</html>
```

## 6. 安全配置 checklist

### 6.1 Spring Boot 安全

```yaml
# 生产环境安全配置
server:
  servlet:
    session:
      cookie:
        http-only: true
        secure: true  # HTTPS only
        same-site: strict

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics  # 限制暴露的端点
      base-path: /actuator
  endpoint:
    health:
      show-details: when_authorized  # 需要认证才能查看详情
```

### 6.2 生产环境检查清单

- [ ] 关闭开发模式（debug=false）
- [ ] 配置 HTTPS
- [ ] 设置强密码策略
- [ ] 启用 SQL 注入防护
- [ ] 配置 CORS 白名单
- [ ] 禁用 Swagger（或限制访问）
- [ ] 配置日志脱敏
- [ ] 设置请求频率限制

## 小结

本节我们学习了：

1. **Spring Boot 生产配置** - 多环境配置、YAML 配置分离
2. **数据库连接池优化** - HikariCP 参数调优、MySQL 配置
3. **JVM 参数调优** - 内存分配、GC 策略、日志配置
4. **Nginx 反向代理** - 负载均衡、SSL、静态资源缓存
5. **静态资源优化** - 代码分割、Gzip、CDN 加速

下一节我们将学习 GitHub Actions CI/CD 自动化部署。
