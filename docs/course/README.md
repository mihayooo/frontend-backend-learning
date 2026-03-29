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

### 第二阶段：核心功能扩展（16 节）

| 节次 | 标题 | 内容概述 | 状态 |
|-----|------|---------|------|
| 10 | [商品模块 - 数据库设计](./phase2/10-database-design.md) | 商品分类、品牌、属性、SKU表设计 | ✅ 已完成 |
| 11 | [商品分类管理](./phase2/11-product-category.md) | 无限级分类、树形结构查询 | ✅ 已完成 |
| 12 | [商品品牌管理](./phase2/12-product-attribute.md) | 品牌CRUD、Logo上传 | ✅ 已完成 |
| 13 | [商品属性管理](./phase2/13-product-publish.md) | 规格参数vs销售属性 | ✅ 已完成 |
| 14 | [商品信息管理（上）](./phase2/14-sku-stock.md) | 商品基本信息、SKU设计 | ✅ 已完成 |
| 15 | [商品信息管理（下）](./phase2/15-product-search.md) | 分页查询、动态筛选 | ✅ 已完成 |
| 16 | [Vue 3 项目结构](./phase2/16-vue-project-structure.md) | 目录结构、路由配置、API封装 | ✅ 已完成 |
| 17 | [Element Plus 组件](./phase2/17-element-plus-components.md) | 常用组件、表单验证 | ✅ 已完成 |
| 18 | [商品分类页面](./phase2/18-product-category-page.md) | 树形表格、拖拽排序 | ✅ 已完成 |
| 19 | [商品列表页面](./phase2/19-product-list-page.md) | 多条件搜索、批量操作 | ✅ 已完成 |
| 20 | [商品发布页面](./phase2/20-product-publish-page.md) | 富文本编辑器、SKU选择器 | ✅ 已完成 |
| 21 | [订单模块概述](./phase2/21-order-module-overview.md) | 订单状态、多条件搜索 | ✅ 已完成 |
| 22 | [订单详情页面](./phase2/22-order-detail-page.md) | Steps步骤条、多对话框 | ✅ 已完成 |
| 23 | [订单发货功能](./phase2/23-order-delivery.md) | Pinia Store、批量发货 | ✅ 已完成 |
| 24 | [退货申请处理](./phase2/24-return-apply.md) | 状态标签、退款计算 | ✅ 已完成 |
| 25 | [订单设置](./phase2/25-order-setting.md) | 表单验证、超时机制 | ✅ 已完成 |

### 第三阶段：部署运维（8节）

#### 方案一：Jenkins（自托管）

| 节次 | 标题 | 内容概述 | 状态 |
|-----|------|---------|------|
| 26 | [Jenkins CI/CD（上）环境搭建](./phase3/26-jenkins-setup.md) | Jenkins + Gitea Docker部署、插件安装、网络配置 | ✅ 已验证 |
| 27 | [Jenkins CI/CD（下）Pipeline流水线](./phase3/27-jenkins-pipeline.md) | 5阶段Pipeline：Checkout→Build→Docker Build→Deploy→Health Check | ✅ 已验证 |
| 28 | [Jenkins CI/CD 常见问题](./phase3/28-jenkins-troubleshooting.md) | 构建过程中的坑与解决方案（插件、Java版本、数据库、网络等） | ✅ 已验证 |
| 29 | [Jenkins CI/CD 端到端验证](./phase3/29-jenkins-e2e-test.md) | 完整验证流程、自动化测试脚本、故障排查速查 | ✅ 已验证 |

#### 方案二：GitHub Actions（云端）

| 节次 | 标题 | 内容概述 | 状态 |
|-----|------|---------|------|
| 30 | [GitHub Actions（上）环境搭建](./phase3/30-github-actions-setup.md) | GitHub Secrets配置、SSH服务、Workflow触发机制 | ✅ 已完成 |
| 31 | [GitHub Actions（下）Workflow配置](./phase3/31-github-actions-workflow.md) | 4个Job设计、缓存优化、Docker构建 | ✅ 已完成 |
| 32 | [GitHub Actions 常见问题](./phase3/32-github-actions-troubleshooting.md) | SSH连接失败、Maven超时、健康检查失败等解决方案 | ✅ 已完成 |
| 33 | [GitHub Actions 端到端验证](./phase3/33-github-actions-e2e-test.md) | 全流程验证：Secrets配置→Push触发→部署→健康检查 | ✅ 已完成 |

### 第四阶段：生产优化（规划中）

- 生产环境配置优化
- 监控与日志收集
- 性能调优

---

## 🚀 学习路径

### 初学者路线
如果你是从零开始的初学者，建议按顺序学习：

```
第一阶段（9节）→ 第二阶段（16节）→ 第三阶段（8节）
```

**第一阶段目标**：跑通项目，理解整体架构
**第二阶段目标**：掌握业务开发，能独立开发新功能
**第三阶段目标**：掌握自动化部署，能搭建CI/CD环境

> 💡 第三阶段提供两种方案：Jenkins（26-29节）适合企业内网，GitHub Actions（30-33节）适合开源项目，按需选择其中一种即可。

### 有经验开发者
如果你已有相关经验，可以按需学习：

| 你的需求 | 推荐章节 |
|---------|---------|
| 快速了解项目 | 第05-06节 |
| 学习Docker部署 | 第09节 |
| 学习商品模块设计 | 第10-15节 |
| 学习前端开发 | 第16-20节 |
| 学习订单模块 | 第21-25节 |
| 学习Jenkins CI/CD | 第26-29节 |
| 学习GitHub Actions CI/CD | 第30-33节 |

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
