# GitHub Actions Secrets 配置指南

## 需要配置的 Secrets

在 GitHub 仓库设置中添加以下 Secrets：

### SSH 连接配置（用于部署到本地服务器）

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `SSH_HOST` | `192.168.1.12` | 你的本地IP地址 |
| `SSH_USERNAME` | `你的Windows用户名` | 如：MIHAYOO |
| `SSH_PASSWORD` | `你的Windows密码` | 登录密码 |
| `SSH_PORT` | `22` | SSH端口（默认22） |

### Docker Hub 配置（可选，用于推送镜像）

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `DOCKERHUB_USERNAME` | `你的Docker Hub用户名` | 可选 |
| `DOCKERHUB_PASSWORD` | `你的Docker Hub密码` | 可选 |

## 配置步骤

1. 访问 https://github.com/mihayooo/frontend-backend-learning/settings/secrets/actions
2. 点击 "New repository secret"
3. 依次添加上述 Secrets

## 本地准备工作

在你的 Windows 电脑上需要：

1. **启用 SSH 服务**：
   ```powershell
   # 以管理员身份运行 PowerShell
   Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.0.1
   Start-Service sshd
   Set-Service -Name sshd -StartupType 'Automatic'
   ```

2. **确保 Docker 正在运行**

3. **确保 MySQL 和 Redis 容器正在运行**：
   ```bash
   docker ps
   ```

## 测试 SSH 连接

从其他机器测试是否可以连接：
```bash
ssh 你的用户名@192.168.1.12
```
