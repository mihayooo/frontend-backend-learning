# 第30节：GitHub Actions CI/CD 自动化部署（上）环境搭建

> 目标：搭建完整的 GitHub Actions CI/CD 环境，实现代码推送到 GitHub 后自动构建、打包、部署。

---

## 本节概要

| 项目 | 内容 |
|------|------|
| 预计时长 | 30-45 分钟 |
| 前置条件 | 已完成第9节 Docker 部署，有 GitHub 账号 |
| 涉及技术 | GitHub Actions、Workflow、Secrets、Self-hosted Runner |

---

## 1. GitHub Actions vs Jenkins 对比

### 1.1 两种方案的选择

| 特性 | GitHub Actions | Jenkins |
|------|----------------|---------|
| **部署方式** | 云端托管，无需维护服务器 | 需要自建服务器 |
| **费用** | 公有仓库免费，私有仓库有额度限制 | 完全免费 |
| **配置方式** | YAML 文件，版本控制 | Web UI + Groovy 脚本 |
| **生态** | GitHub 原生集成，Marketplace 丰富 | 插件生态成熟 |
| **适用场景** | 开源项目、快速上手 | 企业私有部署、复杂流水线 |

### 1.2 为什么学习 GitHub Actions？

1. **零成本起步**：公有仓库完全免费
2. **与 GitHub 深度集成**：代码提交即触发构建
3. **配置即代码**：Workflow 文件纳入版本控制
4. **Marketplace 丰富**：数千个现成 Action 可用
5. **学习成本低**：YAML 语法简单直观

---

## 2. GitHub Actions 核心概念

### 2.1 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub 仓库                             │
│  ┌──────────────┐         ┌──────────────────────────────┐     │
│  │   代码提交    │ ──────> │  .github/workflows/ci.yml    │     │
│  │   push       │ 触发    │                              │     │
│  └──────────────┘         │  - 定义触发条件               │     │
│                           │  - 定义执行步骤               │     │
│                           │  - 定义运行环境               │     │
│                           └──────────────┬───────────────┘     │
└──────────────────────────────────────────┼─────────────────────┘
                                           │
                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions Runner                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Job: Build & Deploy                                     │  │
│  │  ├─ Step 1: Checkout 代码                               │  │
│  │  ├─ Step 2: Setup JDK 17                                │  │
│  │  ├─ Step 3: Maven Build                                 │  │
│  │  ├─ Step 4: Docker Build & Push                         │  │
│  │  └─ Step 5: Deploy to Server                            │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬──────────────────────────────┘
                                   │ SSH / Docker
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      目标服务器（你的电脑）                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ mall-tiny-app│  │ mysql        │  │ redis        │          │
│  │  (应用)      │  │ (数据库)     │  │ (缓存)       │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 核心术语

| 术语 | 说明 | 类比 Jenkins |
|------|------|-------------|
| **Workflow** | 工作流，由一个或多个 Job 组成 | Pipeline |
| **Job** | 任务，包含多个 Step，可并行或串行 | Stage |
| **Step** | 步骤，执行具体的命令或 Action | Step |
| **Action** | 可复用的动作单元，如 checkout、setup-java | Plugin |
| **Runner** | 执行 Workflow 的虚拟机（Ubuntu/Windows/Mac）| Agent |
| **Event** | 触发 Workflow 的事件（push、pull_request 等）| Trigger |

---

## 3. 环境准备

### 3.1 创建 GitHub 仓库

1. 访问 https://github.com/new
2. 仓库名称：`frontend-backend-learning`（或已有仓库）
3. 选择 Public（免费）或 Private
4. 点击 "Create repository"

### 3.2 本地启用 SSH 服务

GitHub Actions 需要通过 SSH 连接到你的本地电脑进行部署：

**Windows 启用 OpenSSH 服务**：

```powershell
# 以管理员身份运行 PowerShell

# 1. 安装 OpenSSH 服务器
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.0.1

# 2. 启动 SSH 服务
Start-Service sshd

# 3. 设置开机自启
Set-Service -Name sshd -StartupType 'Automatic'

# 4. 确认防火墙规则
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}

# 5. 验证 SSH 服务
Get-Service sshd
```

### 3.3 获取本地 IP 地址

```powershell
ipconfig | findstr "IPv4"
```

记录你的本地 IP 地址（如：`192.168.1.12`）

---

## 4. 配置 GitHub Secrets

### 4.1 需要配置的 Secrets

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `SSH_HOST` | `192.168.1.12` | 你的本地IP地址 |
| `SSH_USERNAME` | `你的Windows用户名` | 如：MIHAYOO |
| `SSH_PASSWORD` | `你的Windows密码` | 登录密码 |
| `SSH_PORT` | `22` | SSH端口（默认22） |

### 4.2 配置步骤

1. 访问 GitHub 仓库 → Settings → Secrets and variables → Actions
2. 点击 "New repository secret"
3. 依次添加以下 Secrets：

**添加 SSH_HOST**：
- Name: `SSH_HOST`
- Value: `192.168.1.12`（你的本地IP）

**添加 SSH_USERNAME**：
- Name: `SSH_USERNAME`
- Value: `你的Windows用户名`

**添加 SSH_PASSWORD**：
- Name: `SSH_PASSWORD`
- Value: `你的Windows登录密码`

**添加 SSH_PORT**：
- Name: `SSH_PORT`
- Value: `22`

### 4.3 验证 Secrets 配置

配置完成后，页面应显示：

```
Repository secrets
- SSH_HOST
- SSH_USERNAME
- SSH_PASSWORD
- SSH_PORT
```

---

## 5. 创建 Workflow 文件

### 5.1 创建工作流目录

```bash
mkdir -p .github/workflows
```

### 5.2 创建 ci-cd.yml

**文件：`.github/workflows/ci-cd.yml`**

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ master, main, develop ]
  pull_request:
    branches: [ master, main ]

env:
  JAVA_VERSION: '17'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    # 1. 检出代码
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        submodules: recursive

    # 2. 设置 JDK
    - name: Set up JDK ${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v4
      with:
        java-version: ${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        cache: maven

    # 3. 构建后端项目
    - name: Build mall-tiny
      run: |
        cd mall-tiny
        mvn clean package -DskipTests -q
        ls -la target/

    # 4. 上传构建产物
    - name: Upload artifact
      uses: actions/upload-artifact@v4
      with:
        name: mall-tiny-jar
        path: mall-tiny/target/*.jar
        retention-days: 7

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Download artifact
      uses: actions/download-artifact@v4
      with:
        name: mall-tiny-jar
        path: mall-tiny/target/

    # 5. 部署到本地服务器
    - name: Deploy to local server
      uses: appleboy/ssh-action@v1.0.0
      with:
        host: ${{ secrets.SSH_HOST }}
        username: ${{ secrets.SSH_USERNAME }}
        password: ${{ secrets.SSH_PASSWORD }}
        port: ${{ secrets.SSH_PORT }}
        script: |
          echo "=== Starting deployment ==="
          cd d:/Projects/Claude/frontend_and_bankend_learning
          
          # 拉取最新代码
          git pull origin master
          
          # 重新构建并部署
          cd mall-tiny
          docker build -t mall-tiny:latest .
          
          # 停止旧容器
          docker stop mall-tiny-app 2>/dev/null || true
          docker rm mall-tiny-app 2>/dev/null || true
          
          # 启动新容器
          docker run -d \
            --name mall-tiny-app \
            --restart unless-stopped \
            -p 8080:8080 \
            --network mall-tiny_default \
            -e SPRING_DATASOURCE_URL="jdbc:mysql://mall-tiny-mysql:3306/mall_tiny?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true" \
            -e SPRING_DATASOURCE_USERNAME=root \
            -e SPRING_DATASOURCE_PASSWORD=root \
            -e SPRING_REDIS_HOST=mall-tiny-redis \
            -e SPRING_REDIS_PORT=6379 \
            mall-tiny:latest
          
          echo "=== Deployment completed ==="

    # 6. 健康检查
    - name: Health check
      uses: appleboy/ssh-action@v1.0.0
      with:
        host: ${{ secrets.SSH_HOST }}
        username: ${{ secrets.SSH_USERNAME }}
        password: ${{ secrets.SSH_PASSWORD }}
        port: ${{ secrets.SSH_PORT }}
        script: |
          echo "=== Health Check ==="
          for i in {1..10}; do
            response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health)
            if [ "$response" = "200" ]; then
              echo "✅ Health check passed!"
              curl -s http://localhost:8080/actuator/health
              exit 0
            fi
            echo "Attempt $i: HTTP $response, retrying in 10s..."
            sleep 10
          done
          echo "❌ Health check failed"
          exit 1
```

---

## 6. 推送代码触发构建

### 6.1 提交 Workflow 文件

```bash
# 添加文件
git add .github/workflows/ci-cd.yml

# 提交
git commit -m "feat: 添加GitHub Actions CI/CD工作流"

# 推送到 GitHub
git push origin master
```

### 6.2 查看构建状态

1. 访问 GitHub 仓库页面
2. 点击 "Actions" 标签
3. 查看正在运行的 Workflow

---

## 7. 本节小结

### 已完成的工作

✅ 了解 GitHub Actions 与 Jenkins 的区别
✅ 学习 GitHub Actions 核心概念
✅ 配置本地 SSH 服务
✅ 配置 GitHub Secrets
✅ 创建 CI/CD Workflow 文件

### 下节预告

下一节将详细介绍 Workflow 配置、常见问题排查以及端到端验证。

---

## 参考资源

- [GitHub Actions 官方文档](https://docs.github.com/cn/actions)
- [Workflow 语法参考](https://docs.github.com/cn/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub Marketplace](https://github.com/marketplace?type=actions)
