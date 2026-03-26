# 第27节 GitHub Actions CI/CD 自动化部署

## 学习目标

- 掌握 GitHub Actions 工作流配置
- 学习自动化测试与构建
- 实现 Docker 镜像自动构建与推送
- 掌握自动化部署到服务器
- 了解部署通知与回滚机制

## 1. GitHub Actions 基础

### 1.1 什么是 CI/CD

**CI (Continuous Integration)** - 持续集成：
- 代码提交后自动构建
- 自动运行测试
- 及时发现问题

**CD (Continuous Deployment)** - 持续部署：
- 自动部署到测试环境
- 自动部署到生产环境
- 减少人工操作

### 1.2 GitHub Actions 核心概念

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions 架构                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Workflow（工作流）                                          │
│  └── 触发条件 (on: push, pull_request, schedule)            │
│      └── Job（任务）                                        │
│          └── Runner（运行环境：ubuntu, windows, macos）      │
│              └── Step（步骤）                               │
│                  └── Action（动作：checkout, setup-java）    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 2. 基础工作流配置

### 2.1 项目目录结构

```
.github/
└── workflows/
    ├── ci.yml           # 持续集成
    ├── cd-dev.yml       # 开发环境部署
    └── cd-prod.yml      # 生产环境部署
```

### 2.2 Maven 构建工作流

创建 `.github/workflows/ci.yml`：

```yaml
name: CI - Build and Test

# 触发条件
on:
  push:
    branches: [ main, develop ]
    paths:
      - 'mall-tiny/**'
      - '.github/workflows/ci.yml'
  pull_request:
    branches: [ main, develop ]

# 权限配置
permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      # 1. 检出代码
      - name: Checkout code
        uses: actions/checkout@v4
      
      # 2. 设置 JDK
      - name: Set up JDK 8
        uses: actions/setup-java@v4
        with:
          java-version: '8'
          distribution: 'temurin'
          cache: maven
      
      # 3. 运行测试
      - name: Run tests
        working-directory: ./mall-tiny
        run: mvn test --batch-mode
      
      # 4. 构建项目
      - name: Build with Maven
        working-directory: ./mall-tiny
        run: mvn clean package --batch-mode -DskipTests
      
      # 5. 上传构建产物
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: mall-tiny-jar
          path: mall-tiny/target/*.jar
          retention-days: 7
```

### 2.3 前端构建工作流

创建 `.github/workflows/ci-frontend.yml`：

```yaml
name: CI - Frontend Build

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'mall-admin-web/**'
      - '.github/workflows/ci-frontend.yml'
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      # 设置 Node.js
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: mall-admin-web/package-lock.json
      
      # 安装依赖
      - name: Install dependencies
        working-directory: ./mall-admin-web
        run: npm ci
      
      # 代码检查
      - name: Lint
        working-directory: ./mall-admin-web
        run: npm run lint
      
      # 构建
      - name: Build
        working-directory: ./mall-admin-web
        run: npm run build
      
      # 上传构建产物
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: mall-admin-web-dist
          path: mall-admin-web/dist/
          retention-days: 7
```

## 3. Docker 镜像自动构建

### 3.1 后端 Docker 构建工作流

创建 `.github/workflows/docker-build.yml`：

```yaml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/mall-tiny

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      # 设置 JDK
      - name: Set up JDK 8
        uses: actions/setup-java@v4
        with:
          java-version: '8'
          distribution: 'temurin'
          cache: maven
      
      # Maven 构建
      - name: Build with Maven
        working-directory: ./mall-tiny
        run: mvn clean package --batch-mode -DskipTests
      
      # 设置 Docker Buildx
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      # 登录到 GitHub Container Registry
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      # 提取元数据
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix=,suffix=,format=short
      
      # 构建并推送镜像
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: ./mall-tiny
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
```

### 3.2 优化后的 Dockerfile

创建 `mall-tiny/Dockerfile`：

```dockerfile
# 多阶段构建
# 阶段1：构建
FROM eclipse-temurin:8-jdk-alpine AS builder

WORKDIR /app

# 先复制 pom.xml 下载依赖（利用缓存）
COPY pom.xml .
RUN mvn dependency:go-offline --batch-mode

# 复制源代码并构建
COPY src ./src
RUN mvn clean package --batch-mode -DskipTests

# 阶段2：运行
FROM eclipse-temurin:8-jre-alpine

# 安装必要的工具
RUN apk add --no-cache curl tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

# 创建应用用户
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# 从构建阶段复制 jar 包
COPY --from=builder /app/target/*.jar app.jar

# 更改文件所有者
RUN chown -R appuser:appgroup /app

# 切换到应用用户
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/admin/actuator/health || exit 1

# 暴露端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
```

## 4. 自动化部署到服务器

### 4.1 使用 SSH 部署

创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]
  workflow_dispatch:  # 手动触发

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      # 设置 JDK 并构建
      - name: Build application
        uses: actions/setup-java@v4
        with:
          java-version: '8'
          distribution: 'temurin'
          cache: maven
      
      - name: Maven build
        working-directory: ./mall-tiny
        run: mvn clean package --batch-mode -DskipTests
      
      # 部署到服务器
      - name: Deploy to server
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          source: "mall-tiny/target/*.jar"
          target: "/opt/mall-tiny/"
          strip_components: 2
      
      # 执行远程命令重启服务
      - name: Restart service
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /opt/mall-tiny
            # 备份旧版本
            mv mall-tiny.jar mall-tiny.jar.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
            # 移动新 jar 包
            mv *.jar mall-tiny.jar
            # 重启服务
            sudo systemctl restart mall-tiny
            # 检查服务状态
            sleep 10
            systemctl status mall-tiny --no-pager
            # 健康检查
            curl -f http://localhost:8080/admin/actuator/health && echo "Deployment successful!"
```

### 4.2 使用 Docker Compose 部署

创建 `.github/workflows/deploy-docker.yml`：

```yaml
name: Deploy with Docker Compose

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      # 登录到 Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      # 构建并推送后端镜像
      - name: Build and push backend
        uses: docker/build-push-action@v5
        with:
          context: ./mall-tiny
          push: true
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/mall-tiny:latest
            ${{ secrets.DOCKER_USERNAME }}/mall-tiny:${{ github.sha }}
      
      # 构建并推送前端镜像
      - name: Build and push frontend
        uses: docker/build-push-action@v5
        with:
          context: ./mall-admin-web
          push: true
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/mall-admin-web:latest
            ${{ secrets.DOCKER_USERNAME }}/mall-admin-web:${{ github.sha }}
      
      # 部署到服务器
      - name: Deploy to server
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /opt/mall-tiny
            
            # 拉取最新镜像
            docker-compose pull
            
            # 优雅重启
            docker-compose up -d --no-deps --build app
            
            # 清理旧镜像
            docker image prune -f
            
            # 健康检查
            sleep 30
            docker-compose ps
            curl -f http://localhost:8080/admin/actuator/health && echo "✅ Deployment successful!"
```

## 5. 部署通知与回滚

### 5.1 部署通知

添加钉钉/企业微信通知：

```yaml
      # 部署成功通知
      - name: Notify success
        if: success()
        uses: zcong1993/actions-ding@v3.0.3
        with:
          dingToken: ${{ secrets.DINGTALK_TOKEN }}
          body: |
            {
              "msgtype": "markdown",
              "markdown": {
                "title": "部署成功",
                "text": "### ✅ 部署成功\n\n**项目**: mall-tiny\n**版本**: ${{ github.sha }}\n**时间**: ${{ github.event.head_commit.timestamp }}\n**提交人**: ${{ github.actor }}\n**提交信息**: ${{ github.event.head_commit.message }}"
              }
            }
      
      # 部署失败通知
      - name: Notify failure
        if: failure()
        uses: zcong1993/actions-ding@v3.0.3
        with:
          dingToken: ${{ secrets.DINGTALK_TOKEN }}
          body: |
            {
              "msgtype": "markdown",
              "markdown": {
                "title": "部署失败",
                "text": "### ❌ 部署失败\n\n**项目**: mall-tiny\n**版本**: ${{ github.sha }}\n**提交人**: ${{ github.actor }}\n**查看日志**: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
              }
            }
```

### 5.2 自动回滚

```yaml
      # 健康检查
      - name: Health check
        id: health_check
        run: |
          for i in {1..10}; do
            if curl -f http://${{ secrets.SERVER_HOST }}:8080/admin/actuator/health; then
              echo "health_check=success" >> $GITHUB_OUTPUT
              exit 0
            fi
            sleep 6
          done
          echo "health_check=failed" >> $GITHUB_OUTPUT
          exit 1
      
      # 回滚
      - name: Rollback
        if: steps.health_check.outputs.health_check == 'failed'
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /opt/mall-tiny
            # 恢复备份
            LATEST_BACKUP=$(ls -t mall-tiny.jar.backup.* | head -1)
            cp $LATEST_BACKUP mall-tiny.jar
            sudo systemctl restart mall-tiny
            echo "⚠️ Rollback completed!"
```

## 6. Secrets 配置

在 GitHub 仓库 Settings -> Secrets and variables -> Actions 中添加：

| Secret Name | 说明 |
|-------------|------|
| `SERVER_HOST` | 服务器 IP 或域名 |
| `SERVER_USER` | SSH 用户名 |
| `SERVER_SSH_KEY` | SSH 私钥 |
| `DOCKER_USERNAME` | Docker Hub 用户名 |
| `DOCKER_PASSWORD` | Docker Hub 密码或 Token |
| `DINGTALK_TOKEN` | 钉钉机器人 Token |

## 7. 完整 CI/CD 流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                        CI/CD 流程                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Developer                                                      │
│     │                                                           │
│     ▼                                                           │
│  ┌─────────┐     ┌─────────┐     ┌─────────┐                   │
│  │  Push   │────▶│   CI    │────▶│  Build  │                   │
│  │  Code   │     │  Test   │     │  & Scan │                   │
│  └─────────┘     └─────────┘     └────┬────┘                   │
│                                       │                         │
│                              ┌────────┴────────┐               │
│                              ▼                 ▼               │
│                         ┌─────────┐      ┌─────────┐           │
│                         │  Pass   │      │  Fail   │           │
│                         └────┬────┘      └────┬────┘           │
│                              │                │                 │
│                              ▼                ▼                 │
│                         ┌─────────┐      ┌─────────┐           │
│                         │   CD    │      │ Notify  │           │
│                         │ Deploy  │      │  Fail   │           │
│                         └────┬────┘      └─────────┘           │
│                              │                                  │
│                    ┌─────────┴─────────┐                       │
│                    ▼                   ▼                       │
│               ┌─────────┐        ┌─────────┐                   │
│               │  Health │        │ Rollback│                   │
│               │  Check  │        │         │                   │
│               └────┬────┘        └─────────┘                   │
│                    │                                            │
│           ┌────────┴────────┐                                  │
│           ▼                 ▼                                  │
│      ┌─────────┐      ┌─────────┐                             │
│      │ Success │      │  Fail   │                             │
│      │ Notify  │      │ Notify  │                             │
│      └─────────┘      └─────────┘                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 小结

本节我们学习了：

1. **GitHub Actions 基础** - 工作流、任务、步骤、动作
2. **CI 配置** - 自动测试、构建、代码检查
3. **Docker 自动化** - 镜像构建、多平台支持、缓存优化
4. **CD 配置** - SSH 部署、Docker Compose 部署
5. **通知与回滚** - 钉钉通知、自动回滚机制

下一节我们将学习 Docker Compose 生产环境部署。
