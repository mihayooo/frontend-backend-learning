# Jenkins + Gitea 本地 CI/CD 部署手册

## 架构说明

```
┌─────────────────────────────────────────────────────┐
│  本地开发环境 (Windows + Docker Desktop)              │
│                                                     │
│  ┌──────────┐    Webhook    ┌──────────┐            │
│  │  Gitea   │──────────────▶│ Jenkins  │            │
│  │ :3000    │               │ :9090    │            │
│  └──────────┘               └────┬─────┘            │
│                                  │ 构建+部署          │
│                    ┌─────────────┼──────────────┐   │
│                    ▼             ▼              ▼   │
│             ┌──────────┐  ┌──────────┐  ┌────────┐ │
│             │mall-tiny │  │mall-admin│  │ MySQL  │ │
│             │  :8080   │  │ web :80  │  │ :3307  │ │
│             └──────────┘  └──────────┘  └────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## 第一步：启动 Docker Desktop

打开 Docker Desktop，等待左下角状态变为绿色 "Running"。

---

## 第二步：启动 Jenkins + Gitea

```powershell
# 进入jenkins目录
cd d:\Projects\Claude\frontend_and_bankend_learning\jenkins

# 启动服务
docker compose up -d

# 查看启动日志
docker logs jenkins -f
# 等待看到 "Jenkins is fully up and running" 字样后按 Ctrl+C
```

**访问地址：**
- Jenkins：http://localhost:9090
- Gitea：http://localhost:3000

---

## 第三步：获取 Jenkins 初始密码

```powershell
# 方法一：从容器日志获取
docker logs jenkins 2>&1 | Select-String "Please use the following password"

# 方法二：直接读取文件
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 第四步：Jenkins 初始化配置

1. 打开 http://localhost:9090
2. 输入初始密码
3. 选择 **"安装推荐的插件"**（等待5-10分钟）
4. 创建管理员账户（建议：admin / admin123）
5. Jenkins URL 保持 http://localhost:9090/

---

## 第五步：安装额外插件

**进入：** 管理Jenkins → 插件管理 → Available plugins

搜索并安装以下插件：
- `Gitea`（Gitea Webhook支持）
- `Generic Webhook Trigger`（通用触发器）
- `Docker Pipeline`（Pipeline中使用Docker）
- `Blue Ocean`（现代化UI，可选）
- `NodeJS`（前端构建）
- `AnsiColor`（彩色日志）

**安装完成后重启：** http://localhost:9090/restart

---

## 第六步：配置全局工具

**进入：** 管理Jenkins → 全局工具配置

### 配置 Maven
1. 点击 "新增 Maven"
2. 名称：`Maven-3.9`
3. 勾选 "自动安装"，选择版本 `3.9.6`

### 配置 Node.js
1. 点击 "新增 NodeJS"
2. 名称：`NodeJS-18`
3. 勾选 "自动安装"，选择版本 `18.20.0`

---

## 第七步：初始化 Gitea

1. 打开 http://localhost:3000
2. 首次访问进入安装页面，全部保持默认
3. 点击 "安装 Gitea"
4. 注册管理员账户（admin / admin123456）

### 创建仓库

```bash
# 在Gitea中创建两个仓库：
# - admin/mall-tiny
# - admin/mall-admin-web
```

### 推送代码到 Gitea

```powershell
# mall-tiny 推送到 Gitea
cd d:\Projects\Claude\frontend_and_bankend_learning\mall-tiny
git init
git add .
git commit -m "init: mall-tiny项目"
git remote add gitea http://localhost:3000/admin/mall-tiny.git
git push gitea master

# mall-admin-web 推送到 Gitea
cd d:\Projects\Claude\frontend_and_bankend_learning\mall-admin-web
git remote add gitea http://localhost:3000/admin/mall-admin-web.git
git push gitea master
```

---

## 第八步：在 Jenkins 配置凭据

**进入：** 管理Jenkins → 凭据 → System → 全局凭据 → 新增凭据

| 字段 | 值 |
|------|----|
| 类型 | Username with password |
| 用户名 | admin |
| 密码 | admin123456（Gitea密码） |
| ID | `gitea-credentials` |
| 描述 | Gitea访问凭据 |

---

## 第九步：创建 Jenkins 流水线

### 创建后端流水线

1. 点击 "新建任务"
2. 输入名称：`mall-tiny-pipeline`
3. 选择 **"流水线"**，点击确定
4. 在 **"流水线"** 配置中：
   - 定义：选择 "Pipeline script from SCM"
   - SCM：Git
   - 仓库URL：`http://gitea:3000/admin/mall-tiny.git`
   - 凭据：选择 `gitea-credentials`
   - 脚本路径：`Jenkinsfile`
5. 保存

### 创建前端流水线

重复上述步骤，任务名：`mall-admin-web-pipeline`，仓库改为前端仓库

---

## 第十步：配置 Gitea Webhook

**进入 Gitea → 仓库 → 设置 → Webhooks → 添加 Webhook → Gitea**

| 字段 | 值 |
|------|----|
| 目标URL | `http://jenkins:8080/gitea-webhook/post` |
| 内容类型 | application/json |
| 触发事件 | 推送事件 |

> ⚠️ 注意：Webhook URL 中使用 `jenkins:8080`（Docker内部通信），不是 `localhost:9090`

---

## 测试 CI/CD 流程

```powershell
# 修改一行代码并推送
cd d:\Projects\Claude\frontend_and_bankend_learning\mall-tiny
# 随便修改一个文件...
git add .
git commit -m "test: 触发CI/CD测试"
git push gitea master
```

**然后观察：**
1. Gitea 发送 Webhook → Jenkins 自动触发构建
2. Jenkins：http://localhost:9090 查看构建进度
3. 构建成功后访问：http://localhost:8080/swagger-ui/

---

## 常用命令

```powershell
# 查看Jenkins日志
docker logs jenkins -f --tail 50

# 查看Gitea日志
docker logs gitea -f --tail 50

# 重启Jenkins
docker restart jenkins

# 停止所有服务
cd d:\Projects\Claude\frontend_and_bankend_learning\jenkins
docker compose down

# 查看Jenkins工作目录
docker exec jenkins ls /var/jenkins_home/jobs/
```

---

## 故障排查

### Jenkins 无法访问 Docker

```powershell
# 确认docker.sock挂载正确
docker exec jenkins docker ps
# 如果报权限错误，需要给jenkins用户添加docker权限（已通过privileged:true解决）
```

### Webhook 不触发

1. 检查 Gitea → 仓库 → 设置 → Webhooks → 点击测试
2. 确认 Jenkins 防火墙未阻断 3000 端口
3. Webhook URL 检查：Docker 内部 Jenkins 地址是 `http://jenkins:8080`

### Maven 下载依赖慢

```powershell
# 进入容器配置阿里云镜像
docker exec -it jenkins bash
mkdir -p /root/.m2
cat > /root/.m2/settings.xml << 'EOF'
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <mirrorOf>central</mirrorOf>
      <url>https://maven.aliyun.com/repository/central</url>
    </mirror>
  </mirrors>
</settings>
EOF
```

---

## 下一步

完成本地验证后，可以将同样的流程部署到云服务器（ECS/腾讯云），实现真正的生产环境 CI/CD。
