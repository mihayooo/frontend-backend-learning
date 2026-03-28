# 第28节：Jenkins CI/CD 常见问题与解决方案

> 目标：整理构建过程中遇到的各种坑，提供快速排查和解决方案。

---

## 本节概要

| 项目 | 内容 |
|------|------|
| 预计时长 | 20-30 分钟 |
| 前置条件 | 已完成第10-11节 Jenkins 配置 |
| 涉及技术 | 问题排查、调试技巧 |

---

## 1. 问题速查表

| 问题现象 | 可能原因 | 解决方案 |
|----------|----------|----------|
| 插件下载失败 | 网络问题/镜像源 | 更换国内镜像源 |
| docker: not found | Docker CLI 未安装 | 安装 Docker CLI |
| UnsupportedClassVersionError | Java 版本不匹配 | 升级 JRE 到 17 |
| Unknown database 'mall' | 数据库名错误 | 修正为 mall_tiny |
| 端口冲突 | 8080 被占用 | 修改端口或停止占用进程 |
| Health check 失败 | 应用启动失败 | 查看容器日志 |
| 无法连接 Gitea | 网络不通 | 检查容器网络配置 |

---

## 2. 环境搭建阶段

### 2.1 问题：Jenkins 插件下载失败

**现象**：
```
Failed to download plugin: workflow-aggregator
java.net.UnknownHostException: updates.jenkins.io
```

**原因**：
- Jenkins 默认从国外服务器下载插件
- 网络不稳定或被墙

**解决方案**：

**方案1：更换插件更新源为清华大学镜像**

1. 访问 Jenkins → Manage Jenkins → Plugins → Advanced settings
2. 找到"Update Site"，将 URL 改为：
   ```
   https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
   ```
3. 点击"提交"，然后点击"立即检查"

**方案2：手动下载插件**

```bash
# 从清华镜像下载插件
curl -L -o workflow-aggregator.hpi \
  https://mirrors.tuna.tsinghua.edu.cn/jenkins/plugins/workflow-aggregator/latest/workflow-aggregator.hpi

# 将插件复制到 Jenkins 插件目录
docker cp workflow-aggregator.hpi jenkins:/var/jenkins_home/plugins/

# 重启 Jenkins
docker restart jenkins
```

### 2.2 问题：插件依赖冲突

**现象**：
```
Failed to install plugin: workflow-aggregator
- Missing dependency: workflow-api v2.40
- Missing dependency: workflow-step-api v2.20
```

**原因**：
- 插件之间有依赖关系
- 依赖插件未安装或版本不匹配

**解决方案**：

**方法1：使用插件管理器自动解决**
1. 进入插件管理 → Available
2. 勾选"安装时重启"
3. Jenkins 会自动安装依赖

**方法2：手动安装依赖**

```bash
# 按顺序安装依赖插件
docker exec jenkins install-plugin workflow-step-api
docker exec jenkins install-plugin workflow-api
docker exec jenkins install-plugin workflow-aggregator
```

**方法3：使用插件列表批量安装**

创建 `jenkins-plugins.txt`：
```
workflow-step-api
workflow-api
workflow-support
workflow-job
workflow-durable-task-step
workflow-basic-steps
workflow-cps
workflow-aggregator
```

执行安装：
```bash
docker exec jenkins bash -c '
  while read plugin; do
    java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar \
      -s http://localhost:8080/ install-plugin $plugin
  done < /var/jenkins_home/plugins.txt
'
```

---

## 3. Pipeline 构建阶段

### 3.1 问题：docker: not found

**现象**：
```
+ docker build -t mall-tiny:1 .
/var/jenkins_home/workspace/mall-tiny-pipeline@tmp/durable-xxx/script.sh: 1: docker: not found
```

**原因**：
- Jenkins 容器内没有安装 Docker CLI
- 或者 Docker socket 未正确挂载

**解决方案**：

**步骤1：在 Dockerfile 中安装 Docker CLI**

```dockerfile
FROM jenkins/jenkins:lts-jdk17

USER root

# 安装 Docker CLI（静态二进制）
RUN curl -fL https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.tgz \
    -o /tmp/docker.tgz \
    && tar -xzf /tmp/docker.tgz -C /tmp/ \
    && cp /tmp/docker/docker /usr/local/bin/docker \
    && chmod +x /usr/local/bin/docker \
    && rm -rf /tmp/docker.tgz /tmp/docker

USER jenkins
```

**步骤2：重新构建镜像**

```bash
cd jenkins
docker compose down
docker compose up -d --build
```

**步骤3：验证安装**

```bash
docker exec -it jenkins docker --version
# 输出：Docker version 27.3.1, build ...
```

### 3.2 问题：Docker socket 权限不足

**现象**：
```
Got permission denied while trying to connect to the Docker daemon socket
```

**原因**：
- Jenkins 用户没有访问 Docker socket 的权限

**解决方案**：

```bash
# 将 jenkins 用户加入 docker 组
docker exec -u root jenkins usermod -aG root jenkins

# 或者修改 socket 权限
docker exec -u root jenkins chmod 666 /var/run/docker.sock

# 重启 Jenkins
docker restart jenkins
```

### 3.3 问题：Java 版本不匹配

**现象**：
```
Exception in thread "main" java.lang.UnsupportedClassVersionError: 
class file version 61.0 (Java 17) not recognized by JRE 8
```

**原因**：
- Jenkins 使用 JDK 17 编译代码
- 但应用运行的容器使用 JRE 8
- Java 版本不兼容

**解决方案**：

**修改 mall-tiny/Dockerfile，使用 JRE 17**：

```dockerfile
# 错误：使用 JRE 8
# FROM eclipse-temurin:8-jre

# 正确：使用 JRE 17，与 Jenkins 的 JDK 17 保持一致
FROM eclipse-temurin:17-jre

# ... 其余配置不变
```

**重新构建并部署**：

```bash
# 重新触发 Pipeline 构建
# Jenkins 会自动使用新的 Dockerfile
```

---

## 4. 部署阶段

### 4.1 问题：Unknown database 'mall'

**现象**：
```
Caused by: java.sql.SQLSyntaxErrorException: Unknown database 'mall'
```

**原因**：
- 数据库连接 URL 中的数据库名错误
- 实际数据库名为 `mall_tiny`，但配置写成了 `mall`

**解决方案**：

**修改 Pipeline 中的数据库连接 URL**：

```groovy
// 错误
-e SPRING_DATASOURCE_URL="jdbc:mysql://${MYSQL_HOST}:3306/mall?..."

// 正确
-e SPRING_DATASOURCE_URL="jdbc:mysql://${MYSQL_HOST}:3306/mall_tiny?..."
```

**完整的环境变量配置**：

```groovy
docker run -d \
    --name mall-tiny-app \
    -e SPRING_DATASOURCE_URL="jdbc:mysql://${MYSQL_HOST}:3306/mall_tiny?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true" \
    -e SPRING_DATASOURCE_USERNAME=root \
    -e SPRING_DATASOURCE_PASSWORD=root \
    -e SPRING_REDIS_HOST=${REDIS_HOST} \
    -e SPRING_REDIS_PORT=6379 \
    ${APP_NAME}:latest
```

### 4.2 问题：端口冲突

**现象**：
```
Bind for 0.0.0.0:8080 failed: port is already allocated
```

**原因**：
- 8080 端口已被其他容器或进程占用
- 可能是之前部署的 mall-tiny 容器还在运行

**解决方案**：

**步骤1：查看端口占用**

```bash
# 查看哪个容器占用了 8080
docker ps --filter publish=8080

# 或查看所有容器
docker ps
```

**步骤2：停止并删除旧容器**

```bash
# 停止并删除
docker stop mall-tiny
docker rm mall-tiny

# 或者在 Pipeline 中自动处理
docker stop mall-tiny 2>/dev/null || true
docker rm mall-tiny 2>/dev/null || true
```

**步骤3：修改 Pipeline 确保清理旧容器**

```groovy
stage('Deploy') {
    steps {
        sh """
            # 停止并删除所有可能的旧容器
            docker stop mall-tiny-app 2>/dev/null || true
            docker rm   mall-tiny-app 2>/dev/null || true
            docker stop mall-tiny 2>/dev/null || true
            docker rm   mall-tiny 2>/dev/null || true
            
            # 启动新容器
            docker run -d --name mall-tiny-app -p 8080:8080 ...
        """
    }
}
```

### 4.3 问题：无法连接 MySQL/Redis

**现象**：
```
Caused by: java.net.UnknownHostException: mall-tiny-mysql
```

**原因**：
- 容器网络配置不正确
- Jenkins 容器和应用容器不在同一网络

**解决方案**：

**步骤1：确保所有容器在同一网络**

```bash
# 将 Jenkins 连接到 mall-tiny_default 网络
docker network connect mall-tiny_default jenkins

# 验证网络连接
docker network inspect mall-tiny_default
```

**步骤2：在 Pipeline 中指定正确的网络**

```groovy
docker run -d \
    --name mall-tiny-app \
    --network mall-tiny_default \
    ...
```

**步骤3：验证容器间通信**

```bash
# 进入 Jenkins 容器
docker exec -it jenkins bash

# 测试网络连通性
ping mall-tiny-mysql
ping mall-tiny-redis
```

---

## 5. 健康检查阶段

### 5.1 问题：Health check 超时

**现象**：
```
Health check 20/20 -> HTTP 000
⚠️ WARNING: health check timeout
```

**原因**：
- 应用启动时间过长
- 应用启动失败
- 健康检查 URL 错误

**解决方案**：

**步骤1：查看应用日志**

```bash
# 查看容器日志
docker logs mall-tiny-app --tail 50

# 或者在 Pipeline 失败时自动输出日志
post {
    failure {
        sh "docker logs mall-tiny-app --tail 30 2>/dev/null || true"
    }
}
```

**步骤2：增加健康检查等待时间**

```groovy
stage('Health Check') {
    steps {
        script {
            def healthy = false
            // 增加重试次数和间隔
            for (int i = 0; i < 30; i++) {      // 30次重试
                sleep(10)                        // 每次等待10秒
                def code = sh(
                    script: "curl -s -o /dev/null -w '%{http_code}' http://host.docker.internal:8080/actuator/health",
                    returnStdout: true
                ).trim()
                echo "Health check ${i+1}/30 -> HTTP ${code}"
                if (code == '200') {
                    healthy = true
                    break
                }
            }
        }
    }
}
```

**步骤3：手动验证健康检查**

```bash
# 在宿主机上测试
curl http://localhost:8080/actuator/health

# 在 Jenkins 容器内测试
docker exec -it jenkins curl http://host.docker.internal:8080/actuator/health
```

### 5.2 问题：Public Key Retrieval is not allowed

**现象**：
```
Caused by: com.mysql.cj.exceptions.UnableToConnectException: 
Public Key Retrieval is not allowed
```

**原因**：
- MySQL 8.0 默认使用 caching_sha2_password 认证插件
- 需要允许公钥检索

**解决方案**：

**在数据库连接 URL 中添加参数**：

```groovy
-e SPRING_DATASOURCE_URL="jdbc:mysql://${MYSQL_HOST}:3306/mall_tiny?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true"
```

**关键参数**：
- `allowPublicKeyRetrieval=true` - 允许公钥检索
- `useSSL=false` - 禁用 SSL（开发环境）

---

## 6. 网络与连接问题

### 6.1 问题：Jenkins 无法访问 Gitea

**现象**：
```
fatal: unable to access 'http://gitea:3000/gitadmin/mall-tiny.git/': 
Could not resolve host: gitea
```

**原因**：
- Jenkins 容器无法解析 `gitea` 主机名
- 两个容器不在同一网络

**解决方案**：

**步骤1：检查网络配置**

```bash
# 查看 Jenkins 容器的网络
docker inspect jenkins --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}'

# 应该输出：jenkins_net mall-tiny_default
```

**步骤2：确保使用正确的 hostname**

在 Jenkins 容器内，Gitea 的访问地址：
- 容器名：`http://gitea:3000`（同一网络内）
- 宿主机：`http://host.docker.internal:3000`

**步骤3：测试连接**

```bash
docker exec -it jenkins bash

# 测试网络连通
ping gitea

# 测试 Git 访问
git ls-remote http://gitea:3000/gitadmin/mall-tiny.git
```

### 6.2 问题：Webhook 无法触发构建

**现象**：
- 推送代码后 Jenkins 没有自动构建

**原因**：
- Webhook URL 配置错误
- Jenkins 安全设置阻止了外部请求

**解决方案**：

**步骤1：检查 Webhook 配置**

Gitea Webhook URL 格式：
```
http://jenkins:8080/gitea-webhook/post
```

**步骤2：在 Jenkins 启用 CSRF 保护例外**

1. Manage Jenkins → Security
2. 找到"CSRF Protection"
3. 勾选"Enable proxy compatibility"

**步骤3：手动测试 Webhook**

```bash
# 模拟 webhook 请求
curl -X POST http://localhost:9090/gitea-webhook/post \
  -H "Content-Type: application/json" \
  -d '{"ref": "refs/heads/master"}'
```

---

## 7. 调试技巧

### 7.1 查看详细日志

```bash
# Jenkins 日志
docker logs -f jenkins

# 应用日志
docker logs -f mall-tiny-app

# MySQL 日志
docker logs -f mall-tiny-mysql
```

### 7.2 进入容器调试

```bash
# 进入 Jenkins 容器
docker exec -it jenkins bash

# 进入应用容器
docker exec -it mall-tiny-app sh

# 查看进程
docker exec mall-tiny-app ps aux

# 查看网络
docker exec mall-tiny-app netstat -tlnp
```

### 7.3 手动执行 Pipeline 步骤

```bash
# 在 Jenkins 容器内手动执行构建步骤
docker exec -it jenkins bash

cd /var/jenkins_home/workspace/mall-tiny-pipeline

# 手动执行 Maven 构建
mvn clean package -DskipTests

# 手动执行 Docker 构建
docker build -t mall-tiny:test .

# 手动启动容器测试
docker run -d --name test-mall-tiny -p 8081:8080 mall-tiny:test
```

### 7.4 使用 Jenkins Script Console

访问 `http://localhost:9090/script`，可以执行 Groovy 脚本进行调试：

```groovy
// 测试网络连接
def url = new URL("http://gitea:3000")
def conn = url.openConnection()
println "Response: ${conn.responseCode}"

// 测试 Docker
def proc = "docker ps".execute()
println proc.text
```

---

## 8. 本节小结

### 核心问题清单

| 阶段 | 常见问题 | 关键解决 |
|------|----------|----------|
| 环境搭建 | 插件下载失败 | 更换国内镜像源 |
| 环境搭建 | Docker CLI 缺失 | 自定义 Dockerfile 安装 |
| 构建阶段 | Java 版本不匹配 | 统一使用 JDK/JRE 17 |
| 部署阶段 | 数据库名错误 | 修正为 mall_tiny |
| 部署阶段 | 端口冲突 | 清理旧容器 |
| 健康检查 | 连接 MySQL 失败 | 添加 allowPublicKeyRetrieval |
| 网络问题 | 容器间不通 | 连接同一网络 |

### 最佳实践

1. **版本统一**：Jenkins JDK、Maven、应用 JRE 版本保持一致
2. **日志记录**：每个阶段都添加详细的日志输出
3. **错误处理**：使用 `|| true` 避免命令失败中断构建
4. **健康检查**：设置合理的重试次数和间隔
5. **网络隔离**：合理规划 Docker 网络，确保必要的服务互通

---

## 参考命令速查

```bash
# 重启所有服务
docker restart jenkins gitea mall-tiny-app

# 查看所有服务状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 清理所有停止的容器
docker container prune -f

# 清理未使用的镜像
docker image prune -f

# 查看网络详情
docker network inspect mall-tiny_default

# 强制删除容器
docker rm -f mall-tiny-app

# 查看容器资源使用
docker stats --no-stream
```
