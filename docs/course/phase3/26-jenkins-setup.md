# 第26节：Jenkins CI/CD 自动化部署（上）环境搭建

> 目标：搭建完整的 Jenkins + Gitea CI/CD 环境，实现代码提交后自动构建、打包、部署。

---

## 本节概要

| 项目 | 内容 |
|------|------|
| 预计时长 | 30-45 分钟 |
| 前置条件 | 已完成第9节 Docker 部署 |
| 涉及技术 | Jenkins、Gitea、Docker、Pipeline |

---

## 1. 什么是 CI/CD？

**CI（Continuous Integration）持续集成**：开发人员频繁地将代码合并到主干，每次合并都通过自动化构建和测试验证。

**CD（Continuous Deployment）持续部署**：代码通过测试后，自动部署到生产环境。

### 传统部署 vs CI/CD

```
传统方式：
开发者 → 本地打包 → 手动上传 → 登录服务器 → 停止服务 → 替换jar → 启动服务（容易出错）

CI/CD方式：
开发者 → push代码 → Jenkins自动构建 → 自动测试 → 自动部署（一键完成）
```

---

## 2. 架构设计

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         开发环境                                │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │   IDEA       │ ──────> │  Gitea       │                     │
│  │  (编码)      │  push   │  (Git仓库)   │                     │
│  └──────────────┘         └──────┬───────┘                     │
│                                  │                              │
└──────────────────────────────────┼──────────────────────────────┘
                                   │ webhook
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Jenkins (CI/CD引擎)                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Pipeline: Checkout → Build → Docker Build → Deploy      │  │
│  │  ├─ Checkout: 从Gitea拉取代码                             │  │
│  │  ├─ Build: Maven编译打包                                  │  │
│  │  ├─ Docker Build: 构建应用镜像                            │  │
│  │  └─ Deploy: 部署到Docker容器                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬──────────────────────────────┘
                                   │ docker run
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      运行环境（Docker）                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ mall-tiny-app│  │ mysql        │  │ redis        │          │
│  │  (应用)      │  │ (数据库)     │  │ (缓存)       │          │
│  │  port: 8080  │  │ port: 3306   │  │ port: 6379   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 容器清单

| 容器名 | 服务 | 端口 | 说明 |
|--------|------|------|------|
| jenkins | Jenkins CI/CD | 9090 | 避免与mall-tiny的8080冲突 |
| gitea | Git服务器 | 3000/2222 | 替代GitHub的本地Git服务 |
| mall-tiny-app | 后端应用 | 8080 | CI/CD部署目标 |
| mall-tiny-mysql | MySQL | 3307 | 数据库 |
| mall-tiny-redis | Redis | 6380 | 缓存 |

---

## 3. 环境搭建

### 3.1 创建 Jenkins 目录结构

在项目根目录创建 `jenkins/` 文件夹：

```bash
mkdir -p jenkins
cd jenkins
```

### 3.2 编写 Dockerfile（自定义 Jenkins 镜像）

**文件：`jenkins/Dockerfile`**

```dockerfile
FROM jenkins/jenkins:lts-jdk17

USER root

# 安装 Maven 3.9.9
RUN curl -fL https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.9/apache-maven-3.9.9-bin.tar.gz \
    -o /tmp/maven.tgz \
    && tar -xzf /tmp/maven.tgz -C /opt/ \
    && ln -sf /opt/apache-maven-3.9.9/bin/mvn /usr/local/bin/mvn \
    && rm /tmp/maven.tgz

# 安装 Docker CLI（静态二进制，不需要 Docker daemon）
RUN curl -fL https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.tgz \
    -o /tmp/docker.tgz \
    && tar -xzf /tmp/docker.tgz -C /tmp/ \
    && cp /tmp/docker/docker /usr/local/bin/docker \
    && chmod +x /usr/local/bin/docker \
    && rm -rf /tmp/docker.tgz /tmp/docker

# 验证安装
RUN mvn --version && docker --version

USER jenkins
```

**说明**：
- 使用 `jenkins/jenkins:lts-jdk17` 作为基础镜像（JDK 17）
- 安装 Maven 3.9.9 用于编译
- 安装 Docker CLI 用于构建镜像（注意：不需要安装完整的 Docker Engine）

### 3.3 编写 docker-compose.yml

**文件：`jenkins/docker-compose.yml`**

```yaml
version: '3.8'

services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile
    image: jenkins-custom:latest
    container_name: jenkins
    restart: unless-stopped
    privileged: true
    user: root
    ports:
      - "9090:8080"      # Jenkins Web UI (用9090避免与mall-tiny的8080冲突)
      - "50000:50000"    # Jenkins Agent 通信端口
    volumes:
      - jenkins_home:/var/jenkins_home          # Jenkins数据持久化
      - /var/run/docker.sock:/var/run/docker.sock  # Docker socket
      - maven_cache:/root/.m2                   # Maven依赖缓存
      - ./maven-settings.xml:/root/.m2/settings.xml:ro  # Maven阿里云镜像配置
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Xmx1g -Xms512m
      - TZ=Asia/Shanghai
    networks:
      - jenkins_net

  # Gitea - 轻量级本地Git服务器
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    restart: unless-stopped
    ports:
      - "3000:3000"    # Gitea Web UI
      - "2222:22"      # Git SSH
    volumes:
      - gitea_data:/data
    environment:
      - GITEA__database__DB_TYPE=sqlite3
      - GITEA__server__HTTP_PORT=3000
      - GITEA__server__ROOT_URL=http://localhost:3000
      - TZ=Asia/Shanghai
    networks:
      - jenkins_net

volumes:
  jenkins_home:
    name: jenkins_home
  maven_cache:
    name: maven_cache
  gitea_data:
    name: gitea_data

networks:
  jenkins_net:
    name: jenkins_net
```

### 3.4 配置 Maven 阿里云镜像

**文件：`jenkins/maven-settings.xml`**

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <mirrors>
    <mirror>
      <id>aliyunmaven</id>
      <name>阿里云公共仓库</name>
      <url>https://maven.aliyun.com/repository/public</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

### 3.5 启动 Jenkins 和 Gitea

```bash
cd jenkins
docker compose up -d --build
```

等待启动完成（约2-3分钟）：

```bash
# 查看日志
docker logs -f jenkins

# 当看到以下输出表示启动成功
Jenkins is fully up and running
```

### 3.6 验证安装

访问 Jenkins：http://localhost:9090

访问 Gitea：http://localhost:3000

---

## 4. 初始化配置

### 4.1 Gitea 首次配置

1. 访问 http://localhost:3000
2. 点击"安装"进入配置页面
3. 配置管理员账号：
   - 管理员用户名：`gitadmin`
   - 密码：`gitadmin123`
   - 邮箱：`admin@example.com`
4. 点击"安装 Gitea"

### 4.2 在 Gitea 创建仓库

1. 登录 Gitea（http://localhost:3000）
2. 点击右上角 `+` → "新建仓库"
3. 仓库名称：`mall-tiny`
4. 可见性：私有或公开
5. 点击"创建仓库"

### 4.3 推送代码到 Gitea

```bash
# 进入 mall-tiny 项目目录
cd mall-tiny

# 添加 Gitea 远程仓库
git remote add gitea http://localhost:3000/gitadmin/mall-tiny.git

# 推送代码
git push gitea master
```

---

## 5. 安装 Jenkins 插件

### 5.1 必装插件清单

访问 Jenkins → Manage Jenkins → Plugins → Available plugins，搜索并安装：

| 插件名 | 用途 |
|--------|------|
| workflow-aggregator | Pipeline 核心套件 |
| pipeline-stage-view | 流水线阶段可视化 |
| git | Git 集成 |
| gitea | Gitea Webhook 支持 |
| docker-workflow | Pipeline 中使用 Docker |
| blueocean | 现代化 UI（可选但推荐）|
| ansicolor | 控制台彩色输出 |
| timestamper | 日志时间戳 |

### 5.2 插件安装常见问题

**问题1：插件下载失败或超时**
- 原因：Jenkins 默认从国外服务器下载
- 解决：更换插件更新源为清华大学镜像

**问题2：插件依赖冲突**
- 现象：安装插件时报错"依赖不满足"
- 解决：先安装依赖插件，再安装目标插件

---

## 6. 配置 Jenkins 连接 Docker

为了让 Jenkins 容器能够执行 Docker 命令，需要：

1. **挂载 Docker socket**（已在 docker-compose.yml 中配置）
2. **授予权限**：

```bash
# 在宿主机上执行，将 jenkins 用户加入 docker 组
docker exec -u root jenkins usermod -aG root jenkins

# 重启 Jenkins 容器
docker restart jenkins
```

验证 Docker 可用：

```bash
docker exec -it jenkins docker ps
```

---

## 7. 本节小结

### 已完成的工作

✅ 搭建 Jenkins + Gitea Docker 环境
✅ 配置 Maven 阿里云镜像加速
✅ 安装 Jenkins 必要插件
✅ 配置 Jenkins 连接 Docker
✅ 推送代码到 Gitea 仓库

### 下节预告

下一节将创建完整的 Pipeline 流水线，实现：
- 代码自动拉取
- Maven 自动构建
- Docker 镜像自动构建
- 应用自动部署
- 健康检查

---

## 参考配置

### 完整文件结构

```
jenkins/
├── Dockerfile              # 自定义 Jenkins 镜像
├── docker-compose.yml      # 容器编排配置
├── maven-settings.xml      # Maven 镜像配置
└── README.md               # 说明文档
```

### 常用命令

```bash
# 启动
docker compose up -d --build

# 停止
docker compose down

# 查看日志
docker logs -f jenkins

# 进入容器
docker exec -it jenkins bash

# 重启
docker restart jenkins
```
