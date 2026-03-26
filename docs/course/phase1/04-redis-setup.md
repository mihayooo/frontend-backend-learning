# 第四节：Redis 安装与配置

> **学习目标**：安装 Redis 缓存数据库，理解 mall-tiny 中 Redis 的使用场景

---

## 4.1 本节概述

Redis 是一个高性能的键值对存储系统，常用于：
- 缓存热点数据
- 存储会话信息（Session）
- 实现分布式锁

mall-tiny 使用 Redis 存储用户登录凭证（Token），本节将完成 Redis 的安装和配置。

**预计学习时间**：20 分钟

---

## 4.2 Redis 安装

### 4.2.1 Windows 安装

Redis 官方没有提供 Windows 版本，但微软维护了 Windows 移植版。

**推荐方案：使用 Memurai 或 Redis for Windows**

**方案一：Redis for Windows（GitHub 开源版）**

1. 访问：https://github.com/tporadowski/redis/releases
2. 下载最新版本的 `.msi` 安装包
3. 双击安装，保持默认设置

**方案二：使用 WSL（Windows Subsystem for Linux）**

如果你已安装 WSL，可以直接在 Ubuntu 中安装：
```bash
sudo apt update
sudo apt install redis-server
sudo service redis-server start
```

### 4.2.2 验证安装

```bash
redis-cli ping
```

如果返回 `PONG`，说明 Redis 运行正常。

---

## 4.3 Redis 基本操作

### 4.3.1 连接 Redis

```bash
redis-cli
```

### 4.3.2 常用命令

```bash
# 设置键值
SET key value

# 获取值
GET key

# 删除键
DEL key

# 查看所有键
KEYS *

# 设置过期时间（秒）
EXPIRE key 60

# 退出
EXIT
```

---

## 4.4 mall-tiny 中的 Redis 使用

mall-tiny 主要使用 Redis 存储：
- 用户登录 Token
- 验证码
- 缓存数据

### 4.4.1 配置文件说明

在 `application.yml` 中配置 Redis：

```yaml
spring:
  redis:
    host: localhost
    port: 6379
    database: 0
    timeout: 3000ms
```

---

## 4.5 本节小结

✅ 安装并运行了 Redis  
✅ 掌握了基本 Redis 命令  
✅ 了解了 mall-tiny 中 Redis 的使用场景

---

## 4.6 下节预告

**第五节：mall-tiny 后端项目启动**

我们将导入 mall-tiny 项目到 IDEA，配置并启动后端服务。

---

## 参考资源

- [Redis 官方文档](https://redis.io/documentation)
- [Redis 中文文档](http://www.redis.cn/)
