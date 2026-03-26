# 第三节：数据库环境搭建 - MySQL 安装与配置

> **学习目标**：安装 MySQL 数据库，导入 mall-tiny 数据库脚本，理解表结构设计

---

## 3.1 本节概述

数据库是后端开发的核心组件。本节将带你完成：
- MySQL 8.0 安装与配置
- 数据库创建与用户权限设置
- mall_tiny.sql 脚本导入
- 数据库表结构解析

**预计学习时间**：35 分钟

---

## 3.2 MySQL 安装

### 3.2.1 下载 MySQL

**官方下载地址**：https://dev.mysql.com/downloads/mysql/

推荐下载 **MySQL Installer**（约 300MB），包含服务端和所有工具。

### 3.2.2 安装步骤

1. 双击 `.msi` 安装包
2. 选择 **Server only**（仅安装服务端）
3. 设置 root 密码（建议：`root` 或 `123456`）
4. 完成安装

### 3.2.3 验证安装

```bash
mysql --version
mysql -u root -p
```

---

## 3.3 数据库配置

### 3.3.1 创建数据库

```sql
CREATE DATABASE mall_tiny CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SHOW DATABASES;
```

### 3.3.2 创建专用用户

```sql
CREATE USER 'mall'@'localhost' IDENTIFIED BY 'mall123';
GRANT ALL PRIVILEGES ON mall_tiny.* TO 'mall'@'localhost';
FLUSH PRIVILEGES;
```

---

## 3.4 导入 mall-tiny 数据库脚本

### 3.4.1 命令行导入

```bash
cd mall-tiny/sql
mysql -u root -p mall_tiny < mall_tiny.sql
```

### 3.4.2 验证导入

```sql
USE mall_tiny;
SHOW TABLES;
```

应显示 9 张表：ums_admin、ums_role、ums_menu、ums_permission 等。

---

## 3.5 数据库表结构解析

mall-tiny 采用 **RBAC（基于角色的访问控制）** 模型：

| 表名 | 功能说明 |
|-----|---------|
| ums_admin | 后台用户表 |
| ums_role | 角色表 |
| ums_menu | 菜单表 |
| ums_permission | 权限表 |
| ums_admin_role_relation | 用户-角色关系 |
| ums_role_menu_relation | 角色-菜单关系 |
| ums_role_permission_relation | 角色-权限关系 |

**默认测试用户**：admin/admin、test/test

---

## 3.6 本节小结

✅ 安装并配置了 MySQL 8.0  
✅ 创建了 mall_tiny 数据库  
✅ 成功导入数据库脚本  
✅ 理解了 RBAC 权限模型

---

## 3.7 下节预告

**第四节：Redis 安装与配置**

mall-tiny 使用 Redis 作为缓存，下节将讲解 Redis 的安装和基本使用。

---

## 参考资源

- [MySQL 官方文档](https://dev.mysql.com/doc/)
- [mall-tiny 数据库设计](https://www.macrozheng.com)
