# mall-admin-web 前端 Dockerfile
# Vue 3 + Vite 构建产物，用 Nginx 静态托管 + 反向代理后端 API
FROM nginx:1.25-alpine

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 删除默认配置
RUN rm /etc/nginx/conf.d/default.conf

# 复制自定义 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/mall-admin.conf

# 复制前端构建产物
COPY dist/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
