# 第六节：前端项目部署

> **学习目标**：部署 mall-admin-web 前端项目，完成前后端联调

---

## 6.1 本节概述

本节将带你完成：
- Node.js 环境安装
- mall-admin-web 项目克隆和部署
- 前后端联调验证

**技术栈说明**：
- 前端框架：**Vue 3**（Composition API）
- 构建工具：**Vite 7**
- UI 组件库：**Element Plus**
- 语言：**TypeScript 5**
- 状态管理：Pinia

> ⚠️ **注意**：mall-admin-web 已升级至 Vue 3 + Vite，不再是 Vue 2 + webpack。

**预计学习时间**：25 分钟

---

## 6.2 Node.js 安装

### 6.2.1 下载 Node.js

**官方下载地址**：https://nodejs.org/

mall-admin-web 基于 Vue 3 + Vite，要求 **Node.js ≥ 20.19.0**。

### 6.2.2 验证安装

```bash
node -v   # 应显示 v20.19.0 或更高
npm -v    # 应显示 10.x 或更高
```

---

## 6.3 部署前端项目

### 6.3.1 克隆项目

```bash
git clone https://github.com/macrozheng/mall-admin-web.git
cd mall-admin-web
```

### 6.3.2 安装依赖

```bash
npm install
```

> 💡 如果下载慢，可以配置淘宝镜像：
> ```bash
> npm config set registry https://registry.npmmirror.com
> ```

### 6.3.3 配置后端接口

修改 `.env.development`：

```bash
# 后端API基础路径
VITE_BASE_SERVER_URL = http://localhost:8080
```

> 默认已经是 `http://localhost:8080`，如果你的后端端口不同，请修改此处。

### 6.3.4 启动开发服务器

```bash
npm run dev
```

启动成功后，访问 http://localhost:8090（Vite 默认端口）

---

## 6.4 生产环境构建

### 6.4.1 构建生产包

```bash
npm run build
```

构建产物输出到 `dist/` 目录。

### 6.4.2 使用 Nginx 部署

创建 `nginx.conf`：

```nginx
server {
    listen       80;
    server_name  localhost;
    root /usr/share/nginx/html;
    index index.html;

    # 后端 API 反向代理
    location ~ ^/(admin|minio|aliyun)/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Vue Router history 模式支持
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

启动 Nginx 容器：

```bash
docker run -d \
  --name mall-admin-web \
  -p 80:80 \
  -v $(pwd)/dist:/usr/share/nginx/html \
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf \
  nginx:1.25-alpine
```

访问 http://localhost 即可。

---

## 6.5 前后端联调验证

### 6.5.1 登录系统

1. 访问 http://localhost（或 http://localhost:8090 开发模式）
2. 输入账号：`admin`
3. 输入密码：`macro123`
4. 点击登录

### 6.5.2 验证功能

- 查看左侧菜单是否正常加载（应有 24 个菜单项）
- 尝试访问"用户管理"、"角色管理"、"商品管理"等页面
- 检查数据是否正常显示

---

## 6.6 本节小结

✅ 安装了 Node.js 环境（≥ 20.19.0）  
✅ 成功部署 mall-admin-web（Vue 3 + Vite）  
✅ 完成了前后端联调

---

## 6.7 第一阶段总结

恭喜你！至此已完成第一阶段的所有内容：

| 节次 | 内容 | 状态 |
|-----|------|------|
| 第1节 | JDK 与 Maven 安装 | ✅ |
| 第2节 | IDEA 安装与配置 | ✅ |
| 第3节 | MySQL 安装与配置 | ✅ |
| 第4节 | Redis 安装与配置 | ✅ |
| 第5节 | mall-tiny 后端启动 | ✅ |
| 第6节 | 前端项目部署 | ✅ |

现在你已经拥有了一个完整运行的 mall-tiny 系统！

---

## 6.8 下节预告

**第七节：代码生成器使用**

学习使用 MyBatis-Plus Generator 自动生成代码，提高开发效率。

---

## 参考资源

- [mall-admin-web 项目](https://github.com/macrozheng/mall-admin-web)
- [Vue 3 官方文档](https://vuejs.org/)
- [Vite 官方文档](https://vitejs.dev/)
- [Element Plus 文档](https://element-plus.org/)
