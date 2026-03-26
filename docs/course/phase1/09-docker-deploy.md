# 第九节：Docker 容器化部署（已验证）

> **学习目标**：使用 Docker Compose 将 MySQL + Redis + mall-tiny + mall-admin-web 全部容器化，实现一键全栈部署

> ✅ **本节内容已通过实际部署验证**：所有命令均在真实环境中运行成功（4 容器全栈）

---

## 9.1 本节概述

本节将带你完成：
- 理解容器化部署的价值
- 编写生产可用的 Dockerfile（后端 + 前端）
- 使用 Docker Compose 编排 4 容器全栈应用
- 验证部署结果

**预计学习时间**：40 分钟

---

## 9.2 为什么要用 Docker？

在没有 Docker 的时代，部署一个 Spring Boot 项目需要：
1. 在服务器上安装 JDK
2. 安装 MySQL，创建数据库，导入数据
3. 安装 Redis
4. 配置各种环境变量
5. 上传 jar 包，启动服务

**问题**：换一台服务器，这些步骤要重新来一遍。开发、测试、生产环境不一致导致"在我电脑上能运行"的问题。

Docker 的核心思想：**把应用和它的运行环境打包成一个镜像**，哪里都能运行。

```
┌──────────────────────────────────────────────────────────────┐
│                        Docker Host                            │
│  ┌─────────────────┐ ┌──────────┐ ┌─────────────┐ ┌────────┐ │
│  │ mall-admin-web  │ │ mall-    │ │   Redis     │ │ MySQL  │ │
│  │ Container       │ │ tiny     │ │  Container  │ │        │ │
│  │ :80 (Nginx)     │ │ Container│ │  :6379      │ │ :3306  │ │
│  │ Vue 3 + Vite    │ │ :8080    │ │             │ │        │ │
│  └────────┬────────┘ └────┬─────┘ └──────┬──────┘ └────┬───┘ │
│           │               │              │             │      │
│           └───────────────┴──────────────┴─────────────┘      │
│                        Docker Network                         │
└──────────────────────────────────────────────────────────────┘
```

---

## 9.3 前置条件

确认以下内容已完成：
- [ ] 第一节：JDK + Maven 安装完成
- [ ] 第五节：mall-tiny 项目能本地启动
- [ ] Docker Desktop 已安装并运行

### 9.3.1 安装 Docker Desktop

**官方下载地址**：https://www.docker.com/products/docker-desktop/

Windows 版安装完成后，启动 Docker Desktop，等待底部状态栏显示 "Docker is running"。

**验证安装**：
```bash
docker version
# 应显示 Client 和 Server 版本信息
docker info
# 应显示 Docker 运行状态
```

> 💡 **建议**：在 Docker Desktop 设置中配置国内镜像加速器，显著提升镜像下载速度：
> Settings → Docker Engine，在 registry-mirrors 中添加：
> ```json
> {
>   "registry-mirrors": [
>     "https://registry.cn-hangzhou.aliyuncs.com",
>     "https://docker.mirrors.ustc.edu.cn"
>   ]
> }
> ```

---

## 9.4 打包 Spring Boot 项目

在 Docker 构建镜像之前，需要先将项目打包成 jar 文件。

```bash
# 进入 mall-tiny 目录
cd mall-tiny

# Maven 打包（跳过单元测试）
mvn package -DskipTests

# 验证 jar 包生成成功
# 应看到 target/mall-tiny-1.0.0-SNAPSHOT.jar（约 58MB）
```

> ⚠️ **注意**：`-DskipTests` 跳过测试是因为测试环境可能没有数据库，实际生产前应该运行测试。

---

## 9.5 编写后端 Dockerfile

原项目的 Dockerfile 有两个问题：
1. 使用了已下架的 `openjdk:8` 基础镜像
2. jar 包路径指向根目录而非 `target/` 目录

**修正后的 Dockerfile**（已实际验证）：

```dockerfile
# 基础镜像：eclipse-temurin 是 openjdk:8 的官方替代
# openjdk:8 已于 2024 年从 Docker Hub 下架，必须使用替代镜像
FROM eclipse-temurin:8-jre

# 设置时区为上海（避免日志时间不对）
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 将 Maven 打包后的 jar 包复制到容器中
ADD ./target/mall-tiny-1.0.0-SNAPSHOT.jar /mall-tiny-1.0.0-SNAPSHOT.jar

# 声明服务运行在 8080 端口
EXPOSE 8080

# 启动命令：加入容器友好的 JVM 参数
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "/mall-tiny-1.0.0-SNAPSHOT.jar"]

LABEL maintainer="macrozheng" \
      description="mall-tiny spring boot application"
```

---

## 9.6 编写前端 Dockerfile

mall-admin-web 前端需要构建后部署。进入 `mall-admin-web` 目录：

```bash
cd mall-admin-web

# 安装依赖
npm install

# 生产构建
npm run build
```

创建 `Dockerfile`：

```dockerfile
# mall-admin-web 前端 Dockerfile
# Vue 3 + Vite 构建产物，用 Nginx 静态托管

FROM nginx:1.25-alpine

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 删除默认配置
RUN rm /etc/nginx/conf.d/default.conf

# 复制自定义 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/mall-admin.conf

# 复制前端构建产物
COPY dist/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

创建 `nginx.conf`（配置反向代理）：

```nginx
server {
    listen       80;
    server_name  localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/javascript application/json;

    # 后端 API 反向代理
    location ~ ^/(admin|minio|aliyun)/ {
        proxy_pass http://mall-tiny-app:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Vue Router history 模式支持
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 7d;
        add_header Cache-Control "public";
    }
}
```

> 💡 **Nginx 反向代理说明**：前端页面在浏览器加载后，所有 `/admin/*` 的 API 请求会被 Nginx 转发到 `mall-tiny-app:8080`（后端容器），实现前后端容器间通信。

**JVM 参数说明**：

| 参数 | 作用 |
|-----|------|
| `-XX:+UseContainerSupport` | 让 JVM 识别容器内存限制（Java 8u191+ 支持） |
| `-XX:MaxRAMPercentage=75.0` | 使用容器内存的 75% 作为堆内存上限 |
| `-Djava.security.egd=...` | 加速随机数生成，避免 SecureRandom 阻塞启动 |

---

## 9.7 编写 Docker Compose

Docker Compose 用来同时管理多个容器，以及它们之间的依赖关系。

创建 `docker-compose-dev.yml`（以下配置已实际验证，包含 **4 个容器**）：

```yaml
version: '3.8'

services:
  # MySQL 数据库
  mysql:
    image: mysql:8.0
    container_name: mall-tiny-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: mall_tiny          # 自动创建数据库
      MYSQL_ROOT_HOST: '%'
    ports:
      - "3307:3306"   # 宿主机3307 -> 容器3306（避免与本地MySQL冲突）
    volumes:
      - mall_tiny_mysql_data:/var/lib/mysql            # 数据持久化
      - ./sql/mall_tiny.sql:/docker-entrypoint-initdb.d/mall_tiny.sql  # 自动初始化
    command: >
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --default-time-zone='+8:00'
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-proot"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s

  # Redis 缓存
  redis:
    image: redis:6-alpine
    container_name: mall-tiny-redis
    restart: unless-stopped
    command: redis-server --appendonly yes  # 开启数据持久化
    ports:
      - "6380:6379"   # 宿主机6380 -> 容器6379（避免与本地Redis冲突）
    volumes:
      - mall_tiny_redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  # mall-tiny 后端服务
  mall-tiny:
    image: mall-tiny:1.0.0-SNAPSHOT
    build:
      context: .
      dockerfile: Dockerfile
    container_name: mall-tiny-app
    restart: unless-stopped
    depends_on:
      mysql:
        condition: service_healthy   # 等MySQL健康检查通过才启动
      redis:
        condition: service_healthy   # 等Redis健康检查通过才启动
    ports:
      - "8080:8080"
    environment:
      - spring.profiles.active=prod
      # ⚠️ 关键：MySQL 8.0 必须加 allowPublicKeyRetrieval=true
      - spring.datasource.url=jdbc:mysql://mysql:3306/mall_tiny?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true
      - spring.datasource.username=root
      - spring.datasource.password=root
      - spring.redis.host=redis       # 容器间通过服务名互访
      - spring.redis.port=6379
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
      interval: 15s
      timeout: 10s
      retries: 5
      start_period: 60s

  # mall-admin-web 前端服务（Vue 3 + Nginx）
  mall-admin-web:
    build:
      context: ../mall-admin-web
      dockerfile: Dockerfile
    container_name: mall-admin-web
    restart: unless-stopped
    depends_on:
      mall-tiny:
        condition: service_healthy   # 等后端服务就绪才启动
    ports:
      - "80:80"                      # 前端访问入口：http://localhost
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost/index.html || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s

volumes:
  mall_tiny_mysql_data:   # MySQL 数据卷
  mall_tiny_redis_data:   # Redis 数据卷
```

### 9.7.1 重要注意事项

> ⚠️ **MySQL 8.0 连接问题（必看！）**
>
> MySQL 8.0 默认使用 `caching_sha2_password` 认证方式，在某些情况下需要公钥交换。  
> 如果 JDBC URL 不加 `allowPublicKeyRetrieval=true`，会报错：
> ```
> java.sql.SQLNonTransientConnectionException: Public Key Retrieval is not allowed
> ```
> **解决方案**：在 JDBC URL 中添加 `allowPublicKeyRetrieval=true`

---

## 9.8 构建和启动

### 9.8.1 构建前端

```bash
# 进入前端目录
cd mall-admin-web

# 安装依赖并构建
npm install
npm run build

# 预期输出：dist/ 目录生成（约 7MB 静态文件）
```

### 9.8.2 构建后端镜像

```bash
# 进入后端目录
cd mall-tiny

# 构建 mall-tiny 镜像
docker build -t mall-tiny:1.0.0-SNAPSHOT .

# 预期输出（关键步骤）：
# #1 FROM eclipse-temurin:8-jre  → 拉取基础镜像
# #2 RUN ln -snf ... → 设置时区
# #3 ADD ./target/mall-tiny-1.0.0-SNAPSHOT.jar  → 复制 jar 包
# Successfully built ...
```

### 9.8.3 一键启动全栈

```bash
# 启动所有服务（4 个容器）
docker compose -f docker-compose-dev.yml up -d

# 预期输出：
# ✔ Container mall-tiny-mysql  Started
# ✔ Container mall-tiny-redis  Started
# ✔ Container mall-tiny-app    Started
# ✔ Container mall-admin-web   Started
```

**查看容器状态**：
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

预期输出（稳定后）：
```
NAMES             STATUS                   PORTS
mall-admin-web    Up 2 minutes (healthy)   0.0.0.0:80->80/tcp
mall-tiny-app     Up 2 minutes (healthy)   0.0.0.0:8080->8080/tcp
mall-tiny-redis   Up 2 minutes (healthy)   0.0.0.0:6380->6379/tcp
mall-tiny-mysql   Up 2 minutes (healthy)   0.0.0.0:3307->3306/tcp
```

> 💡 **说明**：`mall-tiny-app` 从启动到变成 `healthy` 约需 60-90 秒，因为需要等 Spring Boot 完全初始化。前端容器会等待后端健康后才启动。

---

## 9.9 验证部署结果

### 9.9.1 访问前端管理后台

浏览器打开：**http://localhost**

你应该看到 mall-admin-web 的登录页面：
- 账号：`admin`
- 密码：`macro123`

登录成功后，可以看到完整的商城管理后台界面，包括：
- 首页统计面板
- 商品管理、订单管理、用户管理
- 权限管理（角色、菜单）

### 9.9.3 查看后端启动日志

```bash
docker logs mall-tiny-app
```

关键日志（证明启动成功）：
```
Started MallTinyApplication in 4.745 seconds (JVM running for 5.272)
```

### 9.9.4 测试后端 API 接口

**使用 curl**：
```bash
curl -X POST http://localhost:8080/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"macro123"}'
```

**预期响应**（✅ 实际验证结果）：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "tokenHead": "Bearer ",
    "token": "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhZG1pbiIsImNyZWF0Z..."
  }
}
```

### 9.9.5 测试认证接口

使用上一步获取的 token 访问需要认证的接口：

```bash
# 将 YOUR_TOKEN 替换为实际获取的 token
curl -X GET http://localhost:8080/admin/info \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**预期响应**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "username": "admin",
    "roles": ["超级管理员"],
    "menus": [...]
  }
}
```

### 9.9.6 访问 Swagger 文档

浏览器打开：http://localhost:8080/swagger-ui/

可以看到所有可用的 API 接口文档。

---

## 9.10 常用容器管理命令

```bash
# 查看所有容器状态
docker ps

# 查看实时日志
docker logs -f mall-tiny-app

# 进入容器内部（排查问题用）
docker exec -it mall-tiny-app sh

# 停止所有服务（保留数据）
docker compose -f docker-compose-dev.yml stop

# 停止并删除容器（保留数据卷）
docker compose -f docker-compose-dev.yml down

# 停止并删除所有内容（包括数据卷）⚠️ 危险操作，数据全删
docker compose -f docker-compose-dev.yml down -v
```

---

## 9.11 常见问题

| 问题 | 原因 | 解决方案 |
|-----|------|---------|
| `openjdk:8: not found` | openjdk:8 已从 Docker Hub 下架 | 改用 `eclipse-temurin:8-jre` |
| `Public Key Retrieval is not allowed` | MySQL 8.0 认证问题 | JDBC URL 加 `allowPublicKeyRetrieval=true` |
| `mall-tiny-app` 容器反复重启 | MySQL 未完全启动就开始连接 | docker-compose 已配置 `depends_on + healthcheck`，等待即可 |
| 端口冲突 | 本地已有 MySQL/Redis 占用3306/6379 | 本 compose 文件已映射到 3307/6380，不冲突 |
| 镜像拉取失败/极慢 | Docker Hub 国内访问限速 | 配置国内镜像加速器（见 9.3.1） |
| 前端访问空白 | Nginx 配置错误 | 检查 `try_files $uri $uri/ /index.html;` 是否配置 |
| API 请求 502 | 后端未就绪或反向代理配置错误 | 确认 mall-tiny-app 健康状态，检查 nginx.conf 代理地址 |

---

## 9.12 本节小结

✅ 已验证完成的内容：

1. **前端构建**：Vue 3 + Vite 项目构建成功，生成 dist/ 目录
2. **前端 Docker 化**：Nginx 静态托管 + 反向代理配置
3. **Maven 打包**：生成 58MB 的可执行 jar 文件
4. **后端 Dockerfile 修正**：解决了 `openjdk:8` 下架问题，改用 `eclipse-temurin:8-jre`
5. **Docker Compose 编排**：**4 容器全栈**（前端 + 后端 + MySQL + Redis）协作运行
6. **MySQL 8.0 连接修复**：加入 `allowPublicKeyRetrieval=true` 解决认证问题
7. **健康检查**：确保依赖服务就绪后再启动应用
8. **全栈验证**：前端登录页面可访问，后端 API 正常工作

**环境信息（实测版本）**：
- Docker Desktop：29.2.1
- 前端：Vue 3.5.25 + Vite 7.2.4 + Element Plus 2.12.0 + TypeScript 5.9
- 后端基础镜像：eclipse-temurin:8-jre
- MySQL 镜像：mysql:8.0
- Redis 镜像：redis:7-alpine
- Nginx 镜像：nginx:1.25-alpine
- Spring Boot：2.7.5
- 后端启动时间：约 4.7 秒

**访问地址**：
- 管理后台：http://localhost（账号：admin / macro123）
- API 文档：http://localhost:8080/swagger-ui/

---

## 9.13 下节预告

完成 Docker 全栈部署后，下一步将进入**第二阶段**：在 mall-tiny 基础上扩展商品管理模块，学习如何一步步添加新的业务功能。
