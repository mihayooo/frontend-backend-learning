# 第27节 Jenkins CI/CD 自动化部署

## 学习目标

- 理解 CI/CD 的价值与工具选型
- 掌握 Jenkins 安装与基础配置
- 实现 Spring Boot 项目自动化构建与部署
- 实现前端 Vue 项目自动化构建与部署
- 掌握 Pipeline 流水线编写
- 学习部署通知与回滚机制

## 1. 工具选型：为什么选择 Jenkins

### 1.1 主流 CI/CD 工具对比

| 工具 | 费用 | 特点 | 适合场景 |
|------|------|------|----------|
| **Jenkins** | 完全免费 | 开源、插件丰富、高度可定制 | 企业私有部署、无费用顾虑 |
| GitHub Actions | 私有仓库每月2000分钟后收费 | 与 GitHub 深度集成 | 开源项目、小团队 |
| GitLab CI | 私有化部署免费 | 与 GitLab 一体化 | GitLab 用户 |
| Travis CI | 私有仓库收费 | 配置简单 | 早期开源项目 |

**选择 Jenkins 的理由：**
- ✅ **完全免费**，无构建分钟限制
- ✅ **私有化部署**，数据不出公司
- ✅ **插件生态丰富**，超过 1800 个插件
- ✅ **企业最广泛使用**，面试加分项
- ✅ **高度可定制**，支持复杂流水线

### 1.2 CI/CD 流程概览

```
┌─────────────────────────────────────────────────────────────────┐
│                        CI/CD 流程                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  开发者                                                          │
│    │                                                            │
│    │  git push                                                  │
│    ▼                                                            │
│  ┌────────┐  Webhook  ┌───────────────────────────────────┐    │
│  │  Git   │──────────▶│              Jenkins               │    │
│  │(Gitea/ │           │  ┌─────────┐  ┌────────────────┐  │    │
│  │GitLab) │           │  │ 1.拉代码 │→│  2.单元测试     │  │    │
│  └────────┘           │  └─────────┘  └────────────────┘  │    │
│                       │       ↓                            │    │
│                       │  ┌─────────┐  ┌────────────────┐  │    │
│                       │  │ 3.构建  │→│  4.构建Docker  │  │    │
│                       │  │  Jar包  │  │     镜像       │  │    │
│                       │  └─────────┘  └────────────────┘  │    │
│                       │                      ↓             │    │
│                       │              ┌────────────────┐    │    │
│                       │              │  5.部署到服务器 │    │    │
│                       │              └────────────────┘    │    │
│                       │                      ↓             │    │
│                       │              ┌────────────────┐    │    │
│                       │              │  6.健康检查&   │    │    │
│                       │              │    通知        │    │    │
│                       │              └────────────────┘    │    │
│                       └───────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 2. Jenkins 安装

### 2.1 方式一：Docker 安装（推荐）

创建 `jenkins/docker-compose.yml`：

```yaml
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts-jdk17
    container_name: jenkins
    restart: always
    privileged: true
    user: root
    ports:
      - "8081:8080"   # Jenkins Web UI
      - "50000:50000" # Agent 通信端口
    volumes:
      - ./jenkins_home:/var/jenkins_home  # 持久化 Jenkins 数据
      - /var/run/docker.sock:/var/run/docker.sock  # 允许 Jenkins 调用 Docker
      - /usr/bin/docker:/usr/bin/docker              # Docker 命令
    environment:
      - TZ=Asia/Shanghai
      - JAVA_OPTS=-Duser.timezone=Asia/Shanghai
```

启动 Jenkins：

```bash
mkdir -p jenkins/jenkins_home
cd jenkins
docker-compose up -d

# 查看启动日志，获取初始密码
docker logs jenkins | grep "Please use the following password"

# 或者从文件读取
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 2.2 方式二：直接安装（CentOS 7）

```bash
# 安装 Java 17
yum install -y java-17-openjdk

# 添加 Jenkins 仓库
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# 安装 Jenkins
yum install -y jenkins

# 启动 Jenkins
systemctl enable jenkins
systemctl start jenkins

# 查看初始密码
cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 2.3 初始化配置

1. 浏览器访问 `http://你的服务器IP:8081`
2. 输入初始密码
3. 选择"安装推荐插件"
4. 创建管理员账号
5. 配置 Jenkins URL

## 3. 必要插件安装

进入 **系统管理 → 插件管理 → 可选插件**，安装以下插件：

| 插件名称 | 用途 |
|----------|------|
| Maven Integration | Maven 项目构建 |
| NodeJS | Node.js 环境 |
| Git | 代码拉取 |
| Pipeline | 流水线支持 |
| Docker Pipeline | Docker 集成 |
| SSH Pipeline Steps | SSH 远程执行 |
| Publish Over SSH | 文件传输 |
| DingTalk | 钉钉通知 |
| Blue Ocean | 可视化流水线 |

## 4. 全局工具配置

进入 **系统管理 → 全局工具配置**：

### 4.1 配置 JDK

```
Name: JDK8
JAVA_HOME: /usr/lib/jvm/java-8-openjdk-amd64  # 根据实际路径填写
```

### 4.2 配置 Maven

```
Name: Maven3
MAVEN_HOME: /usr/share/maven  # 或者选择自动安装
```

### 4.3 配置 Node.js

```
Name: NodeJS18
Version: 18.x  # 选择自动安装
```

## 5. 后端流水线配置

### 5.1 创建 Jenkinsfile（后端）

在 `mall-tiny` 根目录创建 `Jenkinsfile`：

```groovy
pipeline {
    agent any

    // 工具配置（必须先在全局工具配置中定义）
    tools {
        maven 'Maven3'
        jdk 'JDK8'
    }

    // 环境变量
    environment {
        // 应用名称
        APP_NAME = 'mall-tiny'
        // 部署服务器（在 Jenkins 凭据中配置）
        DEPLOY_SERVER = credentials('deploy-server-host')
        // Docker 镜像名称
        IMAGE_NAME = "mall-tiny:${BUILD_NUMBER}"
        // 部署目录
        DEPLOY_DIR = '/opt/mall-tiny'
    }

    // 触发条件
    triggers {
        // 轮询 SCM（每5分钟检查一次代码变更）
        // pollSCM('H/5 * * * *')
        
        // Webhook 触发（推荐，需要 Git 仓库配置 Webhook）
        githubPush()
    }

    stages {
        // 阶段1：拉取代码
        stage('Checkout') {
            steps {
                echo "=== 开始拉取代码 ==="
                git branch: 'main', 
                    url: 'https://github.com/mihayooo/frontend-backend-learning.git'
                echo "=== 代码拉取完成，当前版本：${GIT_COMMIT[0..7]} ==="
            }
        }

        // 阶段2：代码质量检查（可选）
        stage('Code Analysis') {
            when {
                branch 'main'
            }
            steps {
                echo "=== 代码质量检查 ==="
                dir('mall-tiny') {
                    // 运行 Checkstyle 代码风格检查
                    sh 'mvn checkstyle:check --batch-mode -q || true'
                }
            }
        }

        // 阶段3：单元测试
        stage('Test') {
            steps {
                echo "=== 运行单元测试 ==="
                dir('mall-tiny') {
                    sh 'mvn test --batch-mode'
                }
            }
            post {
                always {
                    // 发布测试报告
                    junit allowEmptyResults: true, 
                          testResults: 'mall-tiny/target/surefire-reports/*.xml'
                }
            }
        }

        // 阶段4：构建 Jar 包
        stage('Build') {
            steps {
                echo "=== 开始构建 ==="
                dir('mall-tiny') {
                    sh 'mvn clean package --batch-mode -DskipTests'
                    echo "=== 构建完成：${APP_NAME}-${BUILD_NUMBER}.jar ==="
                }
            }
        }

        // 阶段5：构建 Docker 镜像
        stage('Docker Build') {
            steps {
                echo "=== 构建 Docker 镜像 ==="
                dir('mall-tiny') {
                    sh """
                        docker build -t ${IMAGE_NAME} .
                        docker tag ${IMAGE_NAME} ${APP_NAME}:latest
                    """
                }
            }
        }

        // 阶段6：部署到服务器
        stage('Deploy') {
            steps {
                echo "=== 开始部署到服务器 ==="
                sshagent(credentials: ['deploy-server-ssh-key']) {
                    sh """
                        # 保存当前镜像为备份
                        ssh -o StrictHostKeyChecking=no root@${DEPLOY_SERVER} '
                            cd ${DEPLOY_DIR}
                            docker tag mall-tiny:latest mall-tiny:backup-\$(date +%Y%m%d%H%M%S) 2>/dev/null || true
                        '
                        
                        # 传输新镜像（方式一：推送镜像到私有仓库再拉取）
                        # 方式二：保存镜像文件传输
                        docker save ${IMAGE_NAME} | ssh -o StrictHostKeyChecking=no root@${DEPLOY_SERVER} 'docker load'
                        
                        # 在服务器上重启服务
                        ssh -o StrictHostKeyChecking=no root@${DEPLOY_SERVER} '
                            cd ${DEPLOY_DIR}
                            docker-compose stop app
                            docker-compose rm -f app
                            docker tag ${IMAGE_NAME} mall-tiny:latest
                            docker-compose up -d app
                        '
                    """
                }
            }
        }

        // 阶段7：健康检查
        stage('Health Check') {
            steps {
                echo "=== 执行健康检查 ==="
                sshagent(credentials: ['deploy-server-ssh-key']) {
                    sh """
                        sleep 30
                        for i in \$(seq 1 10); do
                            STATUS=\$(ssh -o StrictHostKeyChecking=no root@${DEPLOY_SERVER} 'curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/admin/actuator/health')
                            if [ "\$STATUS" = "200" ]; then
                                echo "✅ 健康检查通过！"
                                exit 0
                            fi
                            echo "等待服务启动... (\$i/10)"
                            sleep 10
                        done
                        echo "❌ 健康检查失败！"
                        exit 1
                    """
                }
            }
        }
    }

    // 构建后处理
    post {
        success {
            echo "🎉 部署成功！"
            // 钉钉通知
            dingtalk (
                robot: 'dingtalk-robot-id',
                type: 'MARKDOWN',
                title: '✅ 部署成功',
                text: [
                    "### ✅ ${APP_NAME} 部署成功",
                    "**构建号**: #${BUILD_NUMBER}",
                    "**版本**: ${GIT_COMMIT[0..7]}",
                    "**耗时**: ${currentBuild.durationString}",
                    "**提交人**: ${GIT_AUTHOR_NAME}"
                ]
            )
        }
        failure {
            echo "❌ 部署失败，开始回滚..."
            sshagent(credentials: ['deploy-server-ssh-key']) {
                // 自动回滚
                sh """
                    ssh -o StrictHostKeyChecking=no root@${DEPLOY_SERVER} '
                        cd ${DEPLOY_DIR}
                        BACKUP=\$(docker images mall-tiny --format "{{.Tag}}" | grep backup | sort -r | head -1)
                        if [ -n "\$BACKUP" ]; then
                            docker tag mall-tiny:\$BACKUP mall-tiny:latest
                            docker-compose restart app
                            echo "⚠️ 已回滚到版本: \$BACKUP"
                        fi
                    '
                """
            }
            // 失败通知
            dingtalk (
                robot: 'dingtalk-robot-id',
                type: 'MARKDOWN',
                title: '❌ 部署失败',
                text: [
                    "### ❌ ${APP_NAME} 部署失败",
                    "**构建号**: #${BUILD_NUMBER}",
                    "**失败原因**: 请查看 [构建日志](${BUILD_URL})",
                    "> 已自动执行回滚操作"
                ]
            )
        }
        cleanup {
            // 清理旧 Docker 镜像（保留最近3个备份）
            sh "docker images mall-tiny --format '{{.Tag}}' | grep backup | sort -r | tail -n +4 | xargs -I{} docker rmi mall-tiny:{} 2>/dev/null || true"
        }
    }
}
```

## 6. 前端流水线配置

在 `mall-admin-web` 根目录创建 `Jenkinsfile`：

```groovy
pipeline {
    agent any

    tools {
        nodejs 'NodeJS18'
    }

    environment {
        APP_NAME     = 'mall-admin-web'
        DEPLOY_DIR   = '/opt/mall-tiny'
        DEPLOY_SERVER = credentials('deploy-server-host')
    }

    stages {
        stage('Checkout') {
            steps {
                echo "=== 拉取前端代码 ==="
                git branch: 'main',
                    url: 'https://github.com/mihayooo/frontend-backend-learning.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "=== 安装依赖 ==="
                dir('mall-admin-web') {
                    // 使用 ci 保证依赖版本一致
                    sh 'npm ci'
                }
            }
        }

        stage('Lint') {
            steps {
                echo "=== 代码风格检查 ==="
                dir('mall-admin-web') {
                    sh 'npm run lint || true'
                }
            }
        }

        stage('Build') {
            steps {
                echo "=== 生产环境构建 ==="
                dir('mall-admin-web') {
                    sh 'npm run build'
                    echo "=== 前端构建完成，输出目录：dist/ ==="
                }
            }
        }

        stage('Docker Build & Deploy') {
            steps {
                echo "=== 构建前端镜像并部署 ==="
                dir('mall-admin-web') {
                    sh """
                        # 构建镜像
                        docker build -t ${APP_NAME}:${BUILD_NUMBER} .
                        docker tag ${APP_NAME}:${BUILD_NUMBER} ${APP_NAME}:latest
                        
                        # 传输并重启
                        docker save ${APP_NAME}:latest | ssh -o StrictHostKeyChecking=no root@${DEPLOY_SERVER} 'docker load'
                        ssh -o StrictHostKeyChecking=no root@${DEPLOY_SERVER} '
                            cd ${DEPLOY_DIR}
                            docker-compose restart web
                        '
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sshagent(credentials: ['deploy-server-ssh-key']) {
                    sh """
                        sleep 10
                        STATUS=\$(ssh root@${DEPLOY_SERVER} 'curl -s -o /dev/null -w "%{http_code}" http://localhost/')
                        if [ "\$STATUS" != "200" ]; then
                            echo "❌ 前端健康检查失败，状态码: \$STATUS"
                            exit 1
                        fi
                        echo "✅ 前端部署成功，状态码: \$STATUS"
                    """
                }
            }
        }
    }

    post {
        success {
            dingtalk (
                robot: 'dingtalk-robot-id',
                type: 'TEXT',
                text: ["✅ 前端 ${APP_NAME} 部署成功！构建号 #${BUILD_NUMBER}"]
            )
        }
        failure {
            dingtalk (
                robot: 'dingtalk-robot-id',
                type: 'TEXT',
                text: ["❌ 前端 ${APP_NAME} 部署失败！请查看日志: ${BUILD_URL}"]
            )
        }
    }
}
```

## 7. 在 Jenkins 中创建流水线

### 7.1 创建后端流水线 Job

1. **New Item → Pipeline**
2. **填写名称**: `mall-tiny-backend`
3. **配置触发器**：
   - 勾选 "GitHub hook trigger for GITScm polling"
4. **Pipeline 配置**：
   - 选择 "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: `https://github.com/mihayooo/frontend-backend-learning.git`
   - Credentials: 添加 GitHub Token
   - Branch: `*/main`
   - Script Path: `mall-tiny/Jenkinsfile`

### 7.2 配置 Webhook（让 Git Push 自动触发）

**GitHub 仓库设置步骤：**
1. 仓库 → Settings → Webhooks → Add webhook
2. Payload URL: `http://你的Jenkins地址:8081/github-webhook/`
3. Content type: `application/json`
4. 事件: 选择 `Just the push event`

**Gitea（自建 Git）配置：**
1. 仓库 → 设置 → Web 钩子 → 添加 Web 钩子
2. 目标 URL: `http://Jenkins地址:8081/gitea-webhook/post`

## 8. 凭据管理

进入 **系统管理 → 凭据管理** 添加以下凭据：

| ID | 类型 | 说明 |
|----|------|------|
| `deploy-server-host` | 文本 | 部署服务器 IP/域名 |
| `deploy-server-ssh-key` | SSH 私钥 | 服务器 SSH 私钥 |
| `github-token` | Username/Password | GitHub 用户名 + Token |
| `dingtalk-robot-id` | 文本 | 钉钉机器人 ID |
| `docker-hub-credentials` | Username/Password | Docker Hub 账号 |

**生成 SSH 密钥对（在 Jenkins 服务器上执行）：**

```bash
# 生成密钥
ssh-keygen -t rsa -b 4096 -C "jenkins@mall-tiny" -f ~/.ssh/jenkins_deploy

# 将公钥添加到部署服务器
ssh-copy-id -i ~/.ssh/jenkins_deploy.pub root@部署服务器IP

# 私钥内容（填写到 Jenkins 凭据中）
cat ~/.ssh/jenkins_deploy
```

## 9. 完整部署架构

```
┌──────────────┐     push      ┌──────────────┐
│   开发者      │──────────────▶│   Git 仓库   │
│  (本地提交)   │               │  (GitHub/    │
└──────────────┘               │   Gitea)     │
                               └──────┬───────┘
                                      │ Webhook
                                      ▼
┌──────────────────────────────────────────────────┐
│                  Jenkins 服务器                   │
│  ┌───────────┐  ┌───────────┐  ┌──────────────┐  │
│  │  Pipeline │  │  Maven    │  │  Node.js     │  │
│  │  流水线   │  │  构建后端  │  │  构建前端    │  │
│  └─────┬─────┘  └─────┬─────┘  └──────┬───────┘  │
│        └──────────────┴───────────────┘           │
│                      ↓                            │
│  ┌──────────────────────────────────────────────┐ │
│  │          Docker 构建镜像                      │ │
│  └──────────────────────────────────────────────┘ │
└──────────────────────────────┬───────────────────┘
                               │ SSH 推送
                               ▼
                  ┌──────────────────────┐
                  │     生产服务器        │
                  │  ┌────────────────┐  │
                  │  │ Docker Compose │  │
                  │  │  ┌──────────┐  │  │
                  │  │  │ mall-app │  │  │
                  │  │  │ mall-web │  │  │
                  │  │  │  mysql   │  │  │
                  │  │  │  redis   │  │  │
                  │  │  └──────────┘  │  │
                  │  └────────────────┘  │
                  └──────────────────────┘
```

## 10. 常用运维命令

```bash
# 查看构建日志
docker logs jenkins -f

# 进入 Jenkins 容器
docker exec -it jenkins bash

# 备份 Jenkins 配置
tar -czf jenkins_backup_$(date +%Y%m%d).tar.gz jenkins/jenkins_home/

# 重启 Jenkins
docker-compose restart jenkins

# 查看所有 Job 状态（CLI 方式）
java -jar jenkins-cli.jar -s http://localhost:8081 list-jobs
```

## 11. 补充：GitHub Actions（公开仓库免费）

如果你的项目是开源的，GitHub Actions 对**公开仓库完全免费**，可以考虑作为补充：

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '8'
          distribution: 'temurin'
          cache: maven
      - name: Run Tests
        working-directory: ./mall-tiny
        run: mvn test --batch-mode
```

> **结论：** 
> - **私有项目 → 优先使用 Jenkins**（免费、可控、无分钟限制）
> - **开源项目 → 可用 GitHub Actions**（公开仓库完全免费）

## 小结

本节我们学习了：

1. **工具选型** - Jenkins vs GitHub Actions 的对比分析
2. **Jenkins 安装** - Docker 方式安装，简单可靠
3. **Pipeline 配置** - Jenkinsfile 编写后端/前端流水线
4. **Webhook 触发** - 代码提交后自动触发构建
5. **凭据管理** - SSH 密钥、Token 安全管理
6. **自动回滚** - 部署失败自动回滚到上个版本

下一节我们将学习 Docker Compose 生产环境部署的详细配置。
