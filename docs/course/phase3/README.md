# 第三阶段：部署运维

> 掌握 CI/CD 自动化部署，实现从代码提交到应用部署的全流程自动化。本阶段提供两种方案：Jenkins（自托管）和 GitHub Actions（云端），按需选择。

---

## 阶段目标

完成本阶段学习后，你将能够：

- ✅ 搭建 Jenkins + Gitea CI/CD 环境
- ✅ 编写 Jenkins Pipeline 流水线
- ✅ 配置 GitHub Actions 云端 CI/CD
- ✅ 实现自动化构建、打包、部署
- ✅ 排查 CI/CD 过程中的常见问题
- ✅ 验证端到端部署流程

---

## 课程列表

### 方案一：Jenkins（自托管，适合企业/内网）

| 节次 | 标题 | 预计时长 | 关键技能 |
|------|------|----------|----------|
| [26](./26-jenkins-setup.md) | Jenkins CI/CD（上）环境搭建 | 30-45 min | Docker Compose、Jenkins配置、Gitea部署 |
| [27](./27-jenkins-pipeline.md) | Jenkins CI/CD（下）Pipeline流水线 | 40-60 min | Pipeline语法、Groovy脚本、自动化部署 |
| [28](./28-jenkins-troubleshooting.md) | Jenkins CI/CD 常见问题 | 20-30 min | 问题排查、调试技巧、解决方案 |
| [29](./29-jenkins-e2e-test.md) | Jenkins CI/CD 端到端验证 | 20-30 min | 全流程测试、自动化验证、故障排查 |

### 方案二：GitHub Actions（云端，适合开源/个人项目）

| 节次 | 标题 | 预计时长 | 关键技能 |
|------|------|----------|----------|
| [30](./30-github-actions-setup.md) | GitHub Actions（上）环境搭建 | 20-30 min | GitHub Secrets、SSH配置、Workflow触发 |
| [31](./31-github-actions-workflow.md) | GitHub Actions（下）Workflow配置 | 30-40 min | YAML语法、Job依赖、缓存优化 |
| [32](./32-github-actions-troubleshooting.md) | GitHub Actions 常见问题 | 20-30 min | 问题排查、调试技巧、act本地测试 |
| [33](./33-github-actions-e2e-test.md) | GitHub Actions 端到端验证 | 20-30 min | 全流程验证、Secrets配置、部署确认 |

> 💡 **如何选择？**
> - 有公网服务器 + 开源项目 → 推荐 **GitHub Actions**（零运维成本）
> - 内网部署 + 企业级需求 → 推荐 **Jenkins**（完全自主可控）

---

## 技术栈对比

| 维度 | Jenkins | GitHub Actions |
|------|---------|----------------|
| 部署位置 | 本地/私有服务器 | GitHub 云端 |
| 配置语言 | Groovy (Declarative) | YAML |
| 免费额度 | 完全免费（自托管） | 每月2000分钟（公开仓库无限制） |
| 插件生态 | 1800+ 插件 | 数千 Actions |
| 学习曲线 | 较陡 | 较平缓 |
| 适合场景 | 企业内网、复杂流水线 | 开源项目、快速上手 |

### Jenkins 技术栈

| 组件 | 技术 | 版本/说明 |
|------|------|-----------|
| CI/CD引擎 | Jenkins | LTS + JDK17 |
| Git服务器 | Gitea | latest |
| 构建工具 | Maven | 3.9.9 |
| 容器化 | Docker + Docker Compose | 27.x |
| 流水线 | Jenkins Pipeline | Declarative语法 |

### GitHub Actions 技术栈

| 组件 | 技术 | 版本/说明 |
|------|------|-----------|
| CI/CD平台 | GitHub Actions | 云端Runner |
| 运行环境 | ubuntu-latest | GitHub托管Runner |
| 构建工具 | Maven | 3.9.9（含缓存） |
| 镜像构建 | Docker Buildx | 多平台支持 |
| SSH部署 | appleboy/ssh-action | v1.0.0 |
| 密钥管理 | GitHub Secrets | 加密存储 |

---

## 架构图

### Jenkins 架构

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
│  Pipeline: Checkout → Build → Docker Build → Deploy             │
└──────────────────────────────────┬──────────────────────────────┘
                                   │ docker run
                                   ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ mall-tiny-app│  │    mysql     │  │    redis     │
│  port: 8080  │  │  port: 3306  │  │  port: 6379  │
└──────────────┘  └──────────────┘  └──────────────┘
```

### GitHub Actions 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         本地开发                                │
│  ┌──────────────┐         ┌──────────────────────────────────┐  │
│  │   IDEA       │ push ─> │  GitHub (mihayooo/*)             │  │
│  │  (编码)      │         │  + Secrets (SSH密钥等)           │  │
│  └──────────────┘         └──────────────┬───────────────────┘  │
└──────────────────────────────────────────┼──────────────────────┘
                                           │ 触发 Workflow
                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                  GitHub Actions (云端Runner)                    │
│  Job1: build   → Job2: docker-build                             │
│      ↓                    ↓                                     │
│  Job3: deploy-local ← SSH → Job4: health-check                  │
└──────────────────────────────────────────┬──────────────────────┘
                                           │ SSH 部署
                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     本地服务器 (192.168.1.12)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ mall-tiny-app│  │    mysql     │  │    redis     │          │
│  │  port: 8080  │  │  port: 3306  │  │  port: 6379  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 前置条件

在开始本阶段之前，请确保：

1. 已完成 [第一阶段：mall-tiny 快速上手](../phase1/README.md)
2. 已安装 Docker Desktop（Windows/Mac）或 Docker Engine（Linux）
3. 了解基本的 Git 操作
4. 系统内存建议 8GB+（同时运行多个容器）
5. **GitHub Actions 方案额外需要**：GitHub 账号 + 本地已开启 SSH 服务

---

## 服务端口规划

| 服务 | 容器名 | 端口 | 说明 |
|------|--------|------|------|
| Jenkins | jenkins | 9090 | 避免与mall-tiny的8080冲突 |
| Gitea | gitea | 3000/2222 | Git Web UI / SSH |
| mall-tiny-app | mall-tiny-app | 8080 | 后端应用 |
| MySQL | mall-tiny-mysql | 3307 | 数据库（宿主机映射） |
| Redis | mall-tiny-redis | 6380 | 缓存（宿主机映射） |
| 前端 | mall-admin-web | 80 | Nginx反向代理 |

---

## 快速开始

### 方案一：Jenkins 快速开始

```bash
# 1. 启动 CI/CD 环境
cd jenkins
docker compose up -d --build

# 2. 访问 Jenkins
# http://localhost:9090

# 3. 访问 Gitea
# http://localhost:3000
```

### 方案二：GitHub Actions 快速开始

```bash
# 1. fork 或 clone 本仓库到你的 GitHub
# https://github.com/mihayooo/frontend-backend-learning

# 2. 配置 GitHub Secrets（在仓库 Settings → Secrets）
# SSH_HOST=你的本地IP（如 192.168.1.12）
# SSH_USERNAME=你的用户名
# SSH_PASSWORD=你的密码
# SSH_PORT=22

# 3. push 代码自动触发 Workflow
git push origin master

# 4. 查看运行结果
# https://github.com/mihayooo/frontend-backend-learning/actions
```

### 验证部署

```bash
# 健康检查
curl http://localhost:8080/actuator/health

# 登录测试
curl -X POST http://localhost:8080/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"macro123"}'
```

---

## 常见问题速查

| 问题 | 快速解决 |
|------|----------|
| 插件下载失败 | 更换清华镜像源 |
| docker: not found | 自定义Jenkins镜像安装Docker CLI |
| Java版本不匹配 | 统一使用JDK/JRE 17 |
| 数据库连接失败 | 检查数据库名是否为mall_tiny |
| 端口冲突 | 清理旧容器或修改端口 |
| 网络不通 | 连接容器到同一Docker网络 |
| GitHub Actions SSH失败 | 检查Secrets配置和SSH服务状态 |
| Workflow 未触发 | 检查分支名和YAML文件路径 |

详细解决方案请参考：
- Jenkins 问题：[第28节：Jenkins常见问题](./28-jenkins-troubleshooting.md)
- GitHub Actions 问题：[第32节：GitHub Actions常见问题](./32-github-actions-troubleshooting.md)

---

## 参考资源

**Jenkins**
- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [Jenkins Pipeline 语法](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Gitea 官方文档](https://docs.gitea.io/)

**GitHub Actions**
- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [appleboy/ssh-action](https://github.com/appleboy/ssh-action)
- [act - 本地测试工具](https://github.com/nektos/act)

---

## 下一步

完成本阶段后，你可以继续学习：

- **第四阶段：生产优化**（规划中）
  - 生产环境配置优化
  - 监控与日志收集（ELK/Prometheus）
  - 性能调优

或者返回查看其他阶段：
- [第一阶段：mall-tiny 快速上手](../phase1/README.md)
- [第二阶段：核心功能扩展](../phase2/README.md)
