# 第三阶段：部署运维

> 掌握 CI/CD 自动化部署，实现从代码提交到应用部署的全流程自动化。

---

## 阶段目标

完成本阶段学习后，你将能够：

- ✅ 搭建 Jenkins + Gitea CI/CD 环境
- ✅ 编写 Jenkins Pipeline 流水线
- ✅ 实现自动化构建、打包、部署
- ✅ 排查 CI/CD 过程中的常见问题
- ✅ 验证端到端部署流程

---

## 课程列表

| 节次 | 标题 | 预计时长 | 关键技能 |
|------|------|----------|----------|
| [10](./10-jenkins-setup.md) | Jenkins CI/CD（上）环境搭建 | 30-45 min | Docker Compose、Jenkins配置、Gitea部署 |
| [11](./11-jenkins-pipeline.md) | Jenkins CI/CD（下）Pipeline流水线 | 40-60 min | Pipeline语法、Groovy脚本、自动化部署 |
| [12](./12-jenkins-troubleshooting.md) | Jenkins CI/CD 常见问题 | 20-30 min | 问题排查、调试技巧、解决方案 |
| [13](./13-jenkins-e2e-test.md) | Jenkins CI/CD 端到端验证 | 20-30 min | 全流程测试、自动化验证、故障排查 |

---

## 技术栈

| 组件 | 技术 | 版本/说明 |
|------|------|-----------|
| CI/CD引擎 | Jenkins | LTS + JDK17 |
| Git服务器 | Gitea | latest |
| 构建工具 | Maven | 3.9.9 |
| 容器化 | Docker + Docker Compose | 27.x |
| 流水线 | Jenkins Pipeline | Declarative语法 |

---

## 架构图

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

---

## 前置条件

在开始本阶段之前，请确保：

1. 已完成 [第一阶段：mall-tiny 快速上手](../phase1/README.md)
2. 已安装 Docker Desktop（Windows/Mac）或 Docker Engine（Linux）
3. 了解基本的 Git 操作
4. 系统内存建议 8GB+（同时运行多个容器）

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

### 1. 启动 CI/CD 环境

```bash
cd jenkins
docker compose up -d --build
```

### 2. 初始化 Gitea

1. 访问 http://localhost:3000
2. 创建管理员账号
3. 创建 mall-tiny 仓库
4. 推送代码

### 3. 配置 Jenkins

1. 访问 http://localhost:9090
2. 安装必要插件
3. 创建 Pipeline Job
4. 运行构建

### 4. 验证部署

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

详细解决方案请参考 [第12节：常见问题](./12-jenkins-troubleshooting.md)

---

## 参考资源

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [Jenkins Pipeline 语法](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Gitea 官方文档](https://docs.gitea.io/)
- [Docker Compose 参考](https://docs.docker.com/compose/)

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
