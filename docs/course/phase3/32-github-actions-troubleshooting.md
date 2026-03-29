# 第32节：GitHub Actions CI/CD 常见问题与解决方案

> 目标：整理 GitHub Actions 构建过程中遇到的常见问题，提供快速排查和解决方案。

---

## 本节概要

| 项目 | 内容 |
|------|------|
| 预计时长 | 20-30 分钟 |
| 前置条件 | 已完成第30-31节 GitHub Actions 配置 |
| 涉及技术 | 问题排查、调试技巧 |

---

## 1. 问题速查表

| 问题现象 | 可能原因 | 解决方案 |
|----------|----------|----------|
| Workflow 未触发 | 分支不匹配/路径过滤 | 检查 `on` 配置 |
| 检出代码失败 | 子模块未初始化 | 添加 `submodules: recursive` |
| Maven 构建失败 | 依赖下载超时 | 配置国内镜像/缓存 |
| SSH 连接失败 | Secrets 配置错误 | 检查 Secrets 和网络 |
| 部署成功但健康检查失败 | 应用启动慢 | 增加等待时间 |
| 权限不足 | Token 权限不够 | 检查仓库权限设置 |

---

## 2. 触发问题

### 2.1 Workflow 未触发

**现象**：
- 推送代码后 Actions 标签没有显示运行

**排查步骤**：

1. **检查分支名称**
   ```yaml
   # 错误
   on:
     push:
       branches: [ main ]  # 但推送到了 master
   
   # 正确
   on:
     push:
       branches: [ master, main ]
   ```

2. **检查路径过滤**
   ```yaml
   # 如果配置了 paths，确保修改了对应文件
   on:
     push:
       paths:
         - 'mall-tiny/**'
   ```

3. **检查 Workflow 文件位置**
   ```
   # 正确路径
   .github/workflows/ci.yml
   
   # 错误路径
   .github/workflow/ci.yml  # 缺少 s
   github/workflows/ci.yml   # 缺少开头的点
   ```

4. **检查 YAML 语法**
   ```bash
   # 使用在线工具验证
   # https://www.yamllint.com/
   ```

### 2.2 手动触发 Workflow

```yaml
on:
  workflow_dispatch:  # 允许手动触发
```

在 GitHub 页面：
1. 进入 Actions 标签
2. 选择 Workflow
3. 点击 "Run workflow" 按钮

---

## 3. 构建问题

### 3.1 检出代码失败

**现象**：
```
Error: fatal: could not read Username for 'https://github.com'
```

**解决方案**：

1. **确保子模块正确配置**
   ```yaml
   - uses: actions/checkout@v4
     with:
       submodules: recursive
       token: ${{ secrets.GITHUB_TOKEN }}
   ```

2. **检查子模块 URL**
   ```bash
   # 在 .gitmodules 中使用 HTTPS 而非 SSH
   [submodule "mall-tiny"]
       path = mall-tiny
       url = https://github.com/macrozheng/mall-tiny.git  # 正确
       # url = git@github.com:macrozheng/mall-tiny.git    # 错误
   ```

### 3.2 Maven 构建失败

**现象**：
```
Error: Could not find artifact xxx
Error: Connection timed out
```

**解决方案**：

1. **配置阿里云镜像**
   ```yaml
   - name: Set up Maven
     run: |
       mkdir -p ~/.m2
       cat > ~/.m2/settings.xml << 'EOF'
       <settings>
         <mirrors>
           <mirror>
             <id>aliyunmaven</id>
             <name>阿里云公共仓库</name>
             <url>https://maven.aliyun.com/repository/public</url>
             <mirrorOf>central</mirrorOf>
           </mirror>
         </mirrors>
       </settings>
       EOF
   ```

2. **使用缓存加速**
   ```yaml
   - name: Cache Maven dependencies
     uses: actions/cache@v3
     with:
       path: ~/.m2
       key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
       restore-keys: ${{ runner.os }}-m2
   ```

### 3.3 Node.js 构建失败

**现象**：
```
npm ERR! code ECONNRESET
npm ERR! network timeout
```

**解决方案**：

```yaml
- name: Set up Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'
    cache: 'npm'
    cache-dependency-path: mall-admin-web/package-lock.json

- name: Install dependencies
  run: |
    cd mall-admin-web
    npm ci --registry=https://registry.npmmirror.com
```

---

## 4. 部署问题

### 4.1 SSH 连接失败

**现象**：
```
ssh: connect to host 192.168.1.12 port 22: Connection timed out
ssh: connect to host 192.168.1.12 port 22: Connection refused
```

**解决方案**：

1. **检查 Secrets 配置**
   ```yaml
   - name: Deploy
     uses: appleboy/ssh-action@v1.0.0
     with:
       host: ${{ secrets.SSH_HOST }}        # 确保正确
       username: ${{ secrets.SSH_USERNAME }} # 确保正确
       password: ${{ secrets.SSH_PASSWORD }} # 确保正确
       port: ${{ secrets.SSH_PORT }}         # 默认 22
   ```

2. **检查本地 SSH 服务**
   ```powershell
   # Windows PowerShell 管理员
   Get-Service sshd
   Start-Service sshd
   ```

3. **检查防火墙**
   ```powershell
   # 确保 22 端口开放
   New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   ```

4. **检查 IP 地址**
   ```powershell
   ipconfig
   # 确保 Secrets 中的 IP 是正确的
   ```

### 4.2 部署成功但应用未启动

**现象**：
- Workflow 显示成功
- 但访问 http://localhost:8080 无响应

**排查步骤**：

1. **检查容器状态**
   ```yaml
   - name: Check container
     uses: appleboy/ssh-action@v1.0.0
     with:
       host: ${{ secrets.SSH_HOST }}
       username: ${{ secrets.SSH_USERNAME }}
       password: ${{ secrets.SSH_PASSWORD }}
       script: |
         docker ps -a | grep mall-tiny
         docker logs mall-tiny-app --tail 50
   ```

2. **增加等待时间**
   ```yaml
   - name: Wait for startup
     run: sleep 60  # 增加等待时间
   ```

3. **检查端口冲突**
   ```bash
   netstat -ano | findstr :8080
   ```

### 4.3 健康检查失败

**现象**：
```
❌ Health check failed after 10 attempts
```

**解决方案**：

1. **增加重试次数和间隔**
   ```yaml
   - name: Health check
     uses: appleboy/ssh-action@v1.0.0
     with:
       script: |
         for i in {1..20}; do  # 增加到20次
           if curl -s http://localhost:8080/actuator/health | grep -q "UP"; then
             echo "✅ Health check passed!"
             exit 0
           fi
           echo "Attempt $i: retrying in 15s..."  # 增加到15秒
           sleep 15
         done
         echo "❌ Health check failed"
         docker logs mall-tiny-app --tail 100
         exit 1
   ```

2. **检查数据库连接**
   ```bash
   # 确保 MySQL 和 Redis 容器正在运行
   docker ps | grep mysql
   docker ps | grep redis
   ```

---

## 5. 权限问题

### 5.1 GITHUB_TOKEN 权限不足

**现象**：
```
Error: Resource not accessible by integration
```

**解决方案**：

1. **检查仓库权限设置**
   - Settings → Actions → General
   - Workflow permissions → 选择 "Read and write permissions"

2. **在 Workflow 中声明权限**
   ```yaml
   permissions:
     contents: write
     packages: write
   ```

### 5.2 Secrets 读取失败

**现象**：
```
Error: Input required and not supplied: host
```

**解决方案**：

1. **检查 Secrets 名称拼写**
   ```yaml
   # 错误
   host: ${{ secrets.SSH-HOST }}  # 不能使用连字符
   
   # 正确
   host: ${{ secrets.SSH_HOST }}  # 使用下划线
   ```

2. **检查 Secrets 是否已设置**
   - Settings → Secrets and variables → Actions
   - 确保 Secrets 已添加

---

## 6. 调试技巧

### 6.1 启用调试日志

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Debug
        run: |
          echo "Event name: ${{ github.event_name }}"
          echo "Ref: ${{ github.ref }}"
          echo "SHA: ${{ github.sha }}"
          echo "Actor: ${{ github.actor }}"
          env | sort
```

### 6.2 使用 tmate 远程调试

```yaml
- name: Setup tmate session
  if: failure()
  uses: mxschmitt/action-tmate@v3
  timeout-minutes: 15
```

当构建失败时，会通过 SSH 提供一个调试会话。

### 6.3 本地测试 Workflow

使用 `act` 工具在本地测试：

```bash
# 安装 act
choco install act-cli

# 运行 Workflow
act push

# 运行特定 Job
act -j build

# 使用本地 Secrets
act --secret-file .secrets
```

### 6.4 查看完整日志

在 GitHub 页面：
1. 进入 Actions 标签
2. 点击失败的 Workflow
3. 点击失败的 Job
4. 点击 "View raw logs" 查看完整日志

---

## 7. 性能优化

### 7.1 减少构建时间

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # 1. 使用缓存
      - uses: actions/cache@v3
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}

      # 2. 并行构建
      - name: Build with Maven
        run: mvn clean package -T 4  # 4线程

      # 3. 跳过测试（在单独 Job 中运行）
      - name: Build
        run: mvn clean package -DskipTests
```

### 7.2 减少传输时间

```yaml
# 只上传必要的文件
- name: Upload artifact
  uses: actions/upload-artifact@v4
  with:
    name: app
    path: |
      target/*.jar
      !target/*-sources.jar
      !target/*-javadoc.jar
```

---

## 8. 本节小结

### 核心问题清单

| 阶段 | 常见问题 | 关键解决 |
|------|----------|----------|
| 触发 | Workflow 未触发 | 检查分支、路径、YAML 语法 |
| 构建 | Maven/Node 失败 | 配置国内镜像、使用缓存 |
| 部署 | SSH 连接失败 | 检查 Secrets、SSH 服务、防火墙 |
| 验证 | 健康检查失败 | 增加等待时间、检查日志 |
| 权限 | Token/Secrets 问题 | 检查权限设置、Secrets 名称 |

### 最佳实践

1. **使用缓存**：加速依赖下载
2. **路径过滤**：避免不必要的构建
3. **并行 Job**：提高效率
4. **详细日志**：方便排查问题
5. **健康检查**：确保部署成功

---

## 参考命令速查

```bash
# 本地测试 Workflow
act push
act -j build
act --secret-file .secrets

# 查看 Docker 日志
docker logs mall-tiny-app --tail 100

# 检查端口
netstat -ano | findstr :8080

# 检查 SSH 服务
Get-Service sshd
Start-Service sshd
```
