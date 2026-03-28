# 全栈开发沉浸式学习课程

> 基于 Spring Boot + Vue 的电商系统实战教程

---

## 课程简介

本课程通过拆解 **mall-tiny** 项目，带你从零开始掌握前后端开发技术栈，最终成为一名优秀的全栈工程师。

### 技术栈

| 层级 | 技术 | 版本 |
|-----|------|------|
| 后端 | Spring Boot | 2.7.x |
| 后端 | MyBatis-Plus | 3.5.x |
| 后端 | Spring Security | 5.7.x |
| 后端 | Redis | 7.x |
| 后端 | MySQL | 8.0 |
| 前端 | Vue | 3.x |
| 前端 | Vite | 7.x |
| 前端 | Element Plus | 2.x |
| 前端 | TypeScript | 5.x |

---

## 课程大纲

### 第一阶段：mall-tiny 快速上手（9 节）

| 节次 | 标题 | 内容概述 | 状态 |
|-----|------|---------|------|
| 01 | [开发环境搭建（上）](./phase1/01-env-setup.md) | JDK 与 Maven 安装配置 | ✅ 已验证 |
| 02 | [开发环境搭建（下）](./phase1/02-idea-setup.md) | IDEA 安装与配置 | ✅ 已验证 |
| 03 | [数据库环境搭建](./phase1/03-mysql-setup.md) | MySQL 安装与 mall_tiny 数据库导入 | ✅ 已验证 |
| 04 | [Redis 安装与配置](./phase1/04-redis-setup.md) | Redis 安装与基本使用 | ✅ 已验证 |
| 05 | [后端项目启动](./phase1/05-backend-start.md) | mall-tiny 导入、配置、启动 | ✅ 已验证 |
| 06 | [前端项目部署](./phase1/06-frontend-deploy.md) | mall-admin-web 部署与联调 | ✅ 已验证 |
| 07 | [代码生成器使用](./phase1/07-code-generator.md) | MyBatis-Plus Generator 使用 | ✅ 已验证 |
| 08 | [认证流程解析](./phase1/08-security-flow.md) | Spring Security + JWT 认证机制 | ✅ 已验证 |
| 09 | [Docker 容器化部署](./phase1/09-docker-deploy.md) | Docker + Docker Compose 一键部署（4容器全栈） | ✅ **实际部署验证** |

### 第二阶段：核心功能扩展（规划中）

- 商品模块开发
- 订单模块开发
- 营销模块开发
- 缓存优化
- 搜索功能

### 第三阶段：部署运维（4节）

| 节次 | 标题 | 内容概述 | 状态 |
|-----|------|---------|------|
| 10 | [Jenkins CI/CD（上）环境搭建](./phase3/10-jenkins-setup.md) | Jenkins + Gitea Docker部署、插件安装、网络配置 | ✅ 已验证 |
| 11 | [Jenkins CI/CD（下）Pipeline流水线](./phase3/11-jenkins-pipeline.md) | 5阶段Pipeline：Checkout→Build→Docker Build→Deploy→Health Check | ✅ 已验证 |
| 12 | [Jenkins CI/CD 常见问题](./phase3/12-jenkins-troubleshooting.md) | 构建过程中的坑与解决方案（插件、Java版本、数据库、网络等） | ✅ 已验证 |
| 13 | [Jenkins CI/CD 端到端验证](./phase3/13-jenkins-e2e-test.md) | 完整验证流程、自动化测试脚本、故障排查速查 | ✅ 已验证 |

### 第四阶段：生产优化（规划中）

- 生产环境配置优化
- 监控与日志收集
- 性能调优

---

## 项目源码

- **mall-tiny**: https://github.com/macrozheng/mall-tiny
- **mall-admin-web**: https://github.com/macrozheng/mall-admin-web

---

## 参考资源

- [mall 学习教程](https://www.macrozheng.com)
- [Spring Boot 官方文档](https://spring.io/projects/spring-boot)
- [Vue.js 官方文档](https://vuejs.org/)

---

## 许可证

本课程文档采用 [MIT License](../LICENSE) 开源协议。
