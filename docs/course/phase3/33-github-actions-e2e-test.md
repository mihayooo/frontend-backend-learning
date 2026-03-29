# 第33节：GitHub Actions CI/CD 端到端验证

> 目标：从零开始，手把手配置 GitHub Secrets，触发 Workflow，完成从代码提交到本地服务器部署的全流程验证。

---

## 本节概要

| 项目 | 内容 |
|------|------|
| 预计时长 | 20-30 分钟 |
| 前置条件 | 已完成第30-32节，代码已推送到 GitHub |
| 涉及技术 | GitHub Secrets、SSH配置、Workflow触发与验证 |

---

## 1. 准备工作

### 1.1 确认代码已推送

访问你的 GitHub 仓库，确认 `.github/workflows/ci-cd.yml` 文件存在：

```
https://github.com/mihayooo/frontend-backend-learning/blob/master/.github/workflows/ci-cd.yml
```

### 1.2 确认本地 SSH 服务已启动

GitHub Actions 需要通过 SSH 连接你的本地机器进行部署。

**Windows 检查 SSH 服务：**

```powershell
# 管理员 PowerShell
Get-Service sshd

# 如果未启动，执行：
Start-Service sshd

# 设置开机自启
Set-Service -Name sshd -StartupType 'Automatic'
```

**确认 SSH 端口（22）开放：**

```powershell
# 测试本地 SSH
ssh localhost
```

### 1.3 获取本地 IP

```powershell
ipconfig | findstr "IPv4"
# 记录你的 IPv4 地址，例如：192.168.1.12
```

> ⚠️ **注意**：GitHub Actions Runner 是云端服务器，通过公网 SSH 到你本地。  
> 如果你的本地机器在内网（无公网IP），需要配置内网穿透（ngrok/frp），详见 [附录A](#附录a-内网穿透配置)。

---

## 2. 配置 GitHub Secrets

Secrets 是 GitHub 加密存储的敏感配置，Workflow 运行时通过 `${{ secrets.xxx }}` 引用。

### 2.1 进入 Secrets 配置页面

1. 打开仓库页面：`https://github.com/mihayooo/frontend-backend-learning`
2. 点击 **Settings**（设置）标签
3. 左侧菜单选择 **Secrets and variables** → **Actions**
4. 点击 **New repository secret**

### 2.2 添加必需的 5 个 Secrets

按顺序逐一添加：

| Secret 名称 | 值（示例） | 说明 |
|-------------|-----------|------|
| `SSH_HOST` | `192.168.1.12` | 你的本地机器 IP |
| `SSH_USERNAME` | `MIHAYOO` | Windows 用户名（区分大小写） |
| `SSH_PASSWORD` | `你的密码` | Windows 登录密码 |
| `SSH_PORT` | `22` | SSH 端口，默认22 |

**操作步骤（以 SSH_HOST 为例）：**

```
Name: SSH_HOST
Secret: 192.168.1.12
→ 点击 "Add secret"
```

添加完成后，你应该看到 4 个 Secrets：

```
SSH_HOST        ✓ Updated just now
SSH_USERNAME    ✓ Updated just now
SSH_PASSWORD    ✓ Updated just now
SSH_PORT        ✓ Updated just now
```

---

## 3. 确认项目目录

GitHub Actions 部署脚本会 SSH 到你本地，然后在特定目录执行命令。

### 3.1 查看 ci-cd.yml 中的部署路径

打开 `.github/workflows/ci-cd.yml`，找到 `deploy-local` Job：

```yaml
script: |
  echo "=== Starting deployment ==="
  cd d:/Projects/Claude/frontend_and_bankend_learning
  
  # 拉取最新代码
  git pull origin master
  ...
```

### 3.2 确认目录存在且有 Git

```powershell
# 确认目录
ls "d:\Projects\Claude\frontend_and_bankend_learning"

# 确认 Git 状态
cd "d:\Projects\Claude\frontend_and_bankend_learning"
git remote -v
# 应该显示: origin https://github.com/mihayooo/frontend-backend-learning.git
```

---

## 4. 触发第一次 Workflow

### 4.1 通过代码提交触发

```bash
cd "d:\Projects\Claude\frontend_and_bankend_learning"

# 创建一个测试提交
echo "# GitHub Actions 端到端测试" >> docs/course/phase3/TEST.md
git add docs/course/phase3/TEST.md
git commit -m "test: 触发 GitHub Actions 端到端验证"
git push origin master
```

### 4.2 通过 GitHub 界面手动触发

1. 访问：`https://github.com/mihayooo/frontend-backend-learning/actions`
2. 左侧选择 **CI/CD Pipeline**
3. 点击 **Run workflow** → 选择分支 `master` → **Run workflow**

---

## 5. 监控 Workflow 执行过程

### 5.1 查看 Actions 页面

访问：`https://github.com/mihayooo/frontend-backend-learning/actions`

你会看到一个正在运行的 Workflow，点击进入：

```
CI/CD Pipeline  •  test: 触发 GitHub Actions 端到端验证
⏳ In progress  •  master  •  just now
```

### 5.2 查看各 Job 状态

每个 Job 串行执行，依次完成：

```
✅ build (约3-5分钟)
    ├── Checkout code
    ├── Set up JDK 17
    ├── Build mall-tiny        ← Maven 编译（首次较慢）
    ├── Build mall-admin-web   ← npm install + build
    └── Upload artifacts

✅ docker-build (约2-3分钟)
    ├── Checkout code
    ├── Download artifacts
    ├── Set up Docker Buildx
    ├── Build backend Docker image
    └── Build frontend Docker image

✅ deploy-local (约1分钟)
    └── Deploy to local server via SSH
        ├── git pull origin master
        ├── docker build -t mall-tiny:latest
        ├── docker stop/rm old container
        └── docker run new container

✅ health-check (约1-2分钟)
    └── Health check (10次重试，每次10秒)
        └── curl http://localhost:8080/actuator/health
```

### 5.3 查看单个 Step 的日志

点击任意 Job，展开 Step 查看详细日志：

```
▶ Build mall-tiny
[INFO] Scanning for projects...
[INFO] Building mall-tiny 1.0-SNAPSHOT
[INFO] BUILD SUCCESS
[INFO] Total time: 45.678 s
```

---

## 6. 本地验证部署结果

### 6.1 查看容器状态

```bash
docker ps | grep mall-tiny
# 应该看到 mall-tiny-app 容器正在运行
```

### 6.2 健康检查

```bash
curl http://localhost:8080/actuator/health
# 期望结果：{"status":"UP"}
```

### 6.3 登录测试

```bash
curl -X POST http://localhost:8080/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"macro123"}'
# 期望结果：{"code":200,"data":{"token":"eyJ..."}}
```

### 6.4 前端访问

打开浏览器访问：`http://localhost`

---

## 7. 验证结果截图清单

完成验证后，建议截图记录以下关键页面：

| 序号 | 截图内容 | 说明 |
|------|---------|------|
| 1 | GitHub Secrets 配置页面 | 4个Secrets已添加 |
| 2 | Actions 页面 - Workflow 列表 | 显示成功的运行记录 |
| 3 | build Job 日志 - Maven 构建成功 | BUILD SUCCESS |
| 4 | deploy-local Job 日志 - 部署脚本输出 | Deployment completed |
| 5 | health-check Job 日志 - 健康检查通过 | ✅ Health check passed! |
| 6 | 本地 `docker ps` 输出 | 容器运行中 |
| 7 | 健康检查接口响应 | {"status":"UP"} |

---

## 8. 常见验证失败处理

### 8.1 build Job 失败

**Maven 构建超时：**
```yaml
# ci-cd.yml 中添加国内镜像
- name: Configure Maven mirrors
  run: |
    mkdir -p ~/.m2
    cat > ~/.m2/settings.xml << 'EOF'
    <settings>
      <mirrors>
        <mirror>
          <id>aliyunmaven</id>
          <url>https://maven.aliyun.com/repository/public</url>
          <mirrorOf>central</mirrorOf>
        </mirror>
      </mirrors>
    </settings>
    EOF
```

### 8.2 deploy-local 失败（SSH 连接超时）

GitHub Actions Runner 无法连接到你的本地机器（大多数情况是因为内网穿透未配置）。

**临时方案**：使用 `self-hosted` Runner（见 [附录B](#附录b-self-hosted-runner-配置)）

### 8.3 health-check 失败（应用未启动）

```yaml
# 增加等待时间
script: |
  sleep 60  # 从30秒增加到60秒
```

---

## 9. 端到端验证通过标准

全部满足以下条件，视为验证通过 ✅

- [ ] GitHub Actions Workflow 4个Job全部绿色
- [ ] 本地 `docker ps` 显示 mall-tiny-app 容器运行中
- [ ] `curl http://localhost:8080/actuator/health` 返回 `{"status":"UP"}`
- [ ] 浏览器访问 `http://localhost` 可以看到登录页
- [ ] 使用 admin/macro123 登录成功

---

## 10. 本节小结

🎉 恭喜！你已完成 GitHub Actions 端到端验证！

### 整个流程回顾

```
本地写代码
    ↓
git push origin master
    ↓
GitHub Actions 自动触发
    ↓
云端 Runner 构建（Maven + npm）
    ↓
云端 Runner 构建 Docker 镜像
    ↓
SSH 连接本地服务器
    ↓
拉取最新代码 + 重新构建 + 部署
    ↓
健康检查验证
    ↓
✅ 部署完成！
```

### Jenkins vs GitHub Actions 最终对比

| 维度 | Jenkins | GitHub Actions |
|------|---------|----------------|
| 配置复杂度 | ⭐⭐⭐⭐ 较复杂 | ⭐⭐ 简单 |
| 运维成本 | 需要维护 Jenkins 容器 | 零运维（GitHub托管） |
| 触发方式 | Webhook（Gitea→Jenkins） | 代码推送自动触发 |
| 网络要求 | 内网即可 | 需要公网访问本地（或用self-hosted runner）|
| 免费额度 | 完全免费 | 公开仓库无限制 |
| 适合场景 | 企业内网 | 开源/个人项目 |

---

## 附录A：内网穿透配置

如果你的本地机器没有公网 IP，GitHub Actions 无法直接 SSH 连接。解决方案：

### 使用 ngrok

```bash
# 1. 下载并安装 ngrok
# https://ngrok.com/download

# 2. 启动 TCP 隧道（暴露 SSH 22 端口）
ngrok tcp 22

# 3. 获取公网地址，例如：
# tcp://0.tcp.ngrok.io:12345

# 4. 更新 GitHub Secrets
# SSH_HOST = 0.tcp.ngrok.io
# SSH_PORT = 12345
```

> ⚠️ ngrok 免费版每次重启会更换地址，需要更新 Secrets。

### 使用 frp（推荐，稳定）

```bash
# frp 服务端（需要有公网服务器）
./frps -c frps.ini

# frp 客户端（本地机器）
[common]
server_addr = 你的公网服务器IP
server_port = 7000

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 6000
```

---

## 附录B：Self-hosted Runner 配置

Self-hosted Runner 是安装在你本地机器上的 Actions 执行器，可以绕过公网访问限制。

### 安装步骤

1. 进入仓库 **Settings** → **Actions** → **Runners**
2. 点击 **New self-hosted runner**
3. 选择操作系统（Windows）
4. 按照页面指引下载并配置 Runner

### 修改 Workflow 使用本地 Runner

```yaml
jobs:
  deploy-local:
    runs-on: self-hosted  # 改为 self-hosted
    steps:
      - name: Deploy locally
        run: |
          # 直接在本地执行，无需 SSH
          cd d:\Projects\Claude\frontend_and_bankend_learning
          git pull origin master
          cd mall-tiny
          docker build -t mall-tiny:latest .
          docker-compose up -d --build
```

> 优点：无需公网IP，直接在本地执行部署脚本，更安全更稳定。
