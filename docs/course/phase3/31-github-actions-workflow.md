# 第31节：GitHub Actions CI/CD 自动化部署（下）Workflow 详解

> 目标：深入理解 GitHub Actions Workflow 配置，掌握高级用法和最佳实践。

---

## 本节概要

| 项目 | 内容 |
|------|------|
| 预计时长 | 40-60 分钟 |
| 前置条件 | 已完成第30节环境搭建 |
| 涉及技术 | Workflow YAML、Actions、Secrets |

---

## 1. Workflow 文件结构详解

### 1.1 完整示例

```yaml
# 1. Workflow 名称
name: CI/CD Pipeline

# 2. 触发条件
on:
  push:
    branches: [ master, main ]
  pull_request:
    branches: [ master, main ]
  schedule:
    - cron: '0 2 * * *'  # 每天凌晨2点

# 3. 环境变量
env:
  JAVA_VERSION: '17'
  MAVEN_OPTS: '-Xmx1024m'

# 4. Job 定义
jobs:
  # Job 1: 构建
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: mvn clean package

  # Job 2: 部署（依赖 build 完成）
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: echo "Deploying..."
```

### 1.2 各部分说明

| 部分 | 必需 | 说明 |
|------|------|------|
| `name` | 否 | Workflow 显示名称 |
| `on` | 是 | 触发条件 |
| `env` | 否 | 全局环境变量 |
| `jobs` | 是 | 任务定义 |

---

## 2. 触发条件（on）

### 2.1 常用触发器

```yaml
on:
  # 代码推送
  push:
    branches: [ master, develop ]
    paths:
      - 'src/**'
      - 'pom.xml'
  
  # Pull Request
  pull_request:
    branches: [ master ]
    types: [ opened, synchronize, closed ]
  
  # 定时触发（UTC时间）
  schedule:
    - cron: '0 2 * * 1'  # 每周一凌晨2点
  
  # 手动触发
  workflow_dispatch:
    inputs:
      environment:
        description: '部署环境'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
```

### 2.2 路径过滤

```yaml
on:
  push:
    paths:
      - 'mall-tiny/**'      # 只有后端代码变更时触发
      - '.github/workflows/**'
    paths-ignore:
      - '**.md'             # 忽略文档变更
      - 'docs/**'
```

---

## 3. Job 配置

### 3.1 Job 基础配置

```yaml
jobs:
  build:
    # 运行环境
    runs-on: ubuntu-latest
    
    # 超时时间
    timeout-minutes: 30
    
    # 环境变量（仅本Job有效）
    env:
      DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
    
    # 输出变量（供其他Job使用）
    outputs:
      version: ${{ steps.version.outputs.value }}
    
    steps:
      - name: Get version
        id: version
        run: echo "value=1.0.0" >> $GITHUB_OUTPUT
```

### 3.2 Job 依赖关系

```yaml
jobs:
  # Job 1: 测试
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing..."

  # Job 2: 构建（并行执行）
  build-backend:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building backend..."

  build-frontend:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building frontend..."

  # Job 3: 部署（依赖 test、build-backend、build-frontend）
  deploy:
    needs: [test, build-backend, build-frontend]
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

### 3.3 矩阵构建

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        java: ['11', '17', '21']
        exclude:
          - os: macos-latest
            java: '11'
    steps:
      - uses: actions/setup-java@v4
        with:
          java-version: ${{ matrix.java }}
      - run: mvn test
```

---

## 4. Step 配置

### 4.1 基础 Step

```yaml
steps:
  # 使用 Action
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0

  # 运行命令
  - name: Build
    run: mvn clean package

  # 多行命令
  - name: Multi-line script
    run: |
      echo "Step 1"
      echo "Step 2"
      mvn clean package

  # 条件执行
  - name: Deploy to production
    if: github.ref == 'refs/heads/main'
    run: echo "Deploying..."

  # 使用环境变量
  - name: Use env
    env:
      MY_VAR: "hello"
    run: echo $MY_VAR
```

### 4.2 条件判断

```yaml
steps:
  # 分支判断
  - name: Only on master
    if: github.ref == 'refs/heads/master'
    run: echo "On master branch"

  # 事件类型判断
  - name: Only on PR
    if: github.event_name == 'pull_request'
    run: echo "This is a PR"

  # 文件变更判断
  - name: Only when pom.xml changes
    if: contains(github.event.head_commit.modified, 'pom.xml')
    run: echo "pom.xml changed"

  # 组合条件
  - name: Complex condition
    if: github.ref == 'refs/heads/master' && github.event_name == 'push'
    run: echo "Push to master"
```

---

## 5. 常用 Actions

### 5.1 官方 Actions

| Action | 用途 | 示例 |
|--------|------|------|
| `actions/checkout` | 检出代码 | `uses: actions/checkout@v4` |
| `actions/setup-java` | 设置JDK | `uses: actions/setup-java@v4` |
| `actions/setup-node` | 设置Node.js | `uses: actions/setup-node@v4` |
| `actions/cache` | 缓存依赖 | `uses: actions/cache@v3` |
| `actions/upload-artifact` | 上传构建产物 | `uses: actions/upload-artifact@v4` |
| `actions/download-artifact` | 下载构建产物 | `uses: actions/download-artifact@v4` |

### 5.2 第三方 Actions

| Action | 用途 |
|--------|------|
| `appleboy/ssh-action` | SSH 远程执行 |
| `appleboy/scp-action` | SCP 文件传输 |
| `docker/login-action` | Docker 登录 |
| `docker/build-push-action` | Docker 构建推送 |
| `codecov/codecov-action` | 代码覆盖率上报 |

---

## 6. Secrets 和变量

### 6.1 使用 Secrets

```yaml
steps:
  - name: Use secrets
    env:
      DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
      API_KEY: ${{ secrets.API_KEY }}
    run: |
      echo "Password: $DB_PASSWORD"
      # 不要在日志中打印密码！
```

### 6.2 使用 Variables

```yaml
# 仓库变量（Settings -> Variables）
steps:
  - name: Use variables
    run: |
      echo "Environment: ${{ vars.ENVIRONMENT }}"
      echo "Version: ${{ vars.APP_VERSION }}"
```

### 6.3 GitHub 上下文

```yaml
steps:
  - name: GitHub context
    run: |
      echo "Repository: ${{ github.repository }}"
      echo "Branch: ${{ github.ref_name }}"
      echo "SHA: ${{ github.sha }}"
      echo "Actor: ${{ github.actor }}"
      echo "Event: ${{ github.event_name }}"
      echo "Workflow: ${{ github.workflow }}"
      echo "Run ID: ${{ github.run_id }}"
```

---

## 7. 缓存优化

### 7.1 Maven 缓存

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Cache Maven dependencies
    uses: actions/cache@v3
    with:
      path: ~/.m2
      key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
      restore-keys: ${{ runner.os }}-m2

  - name: Build
    run: mvn clean package
```

### 7.2 Node.js 缓存

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Setup Node.js
    uses: actions/setup-node@v4
    with:
      node-version: '18'
      cache: 'npm'
      cache-dependency-path: '**/package-lock.json'

  - name: Install dependencies
    run: npm ci
```

---

## 8. 完整示例：mall-tiny CI/CD

```yaml
name: mall-tiny CI/CD

on:
  push:
    branches: [ master, main ]
    paths:
      - 'mall-tiny/**'
      - 'mall-admin-web/**'
      - '.github/workflows/**'

env:
  JAVA_VERSION: '17'
  NODE_VERSION: '18'

jobs:
  # Job 1: 构建后端
  build-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: ${{ env.JAVA_VERSION }}
          distribution: 'temurin'
          cache: maven

      - name: Build with Maven
        run: |
          cd mall-tiny
          mvn clean package -DskipTests -q

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: backend-jar
          path: mall-tiny/target/*.jar

  # Job 2: 构建前端
  build-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: mall-admin-web/package-lock.json

      - name: Install dependencies
        run: |
          cd mall-admin-web
          npm ci

      - name: Build
        run: |
          cd mall-admin-web
          npm run build

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: frontend-dist
          path: mall-admin-web/dist/

  # Job 3: 部署
  deploy:
    needs: [build-backend, build-frontend]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download backend artifact
        uses: actions/download-artifact@v4
        with:
          name: backend-jar
          path: mall-tiny/target/

      - name: Download frontend artifact
        uses: actions/download-artifact@v4
        with:
          name: frontend-dist
          path: mall-admin-web/dist/

      - name: Deploy to server
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USERNAME }}
          password: ${{ secrets.SSH_PASSWORD }}
          port: ${{ secrets.SSH_PORT }}
          script: |
            cd d:/Projects/Claude/frontend_and_bankend_learning
            git pull origin master
            docker-compose -f mall-tiny/docker-compose-dev.yml up -d --build

      - name: Health check
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USERNAME }}
          password: ${{ secrets.SSH_PASSWORD }}
          port: ${{ secrets.SSH_PORT }}
          script: |
            for i in {1..10}; do
              if curl -s http://localhost:8080/actuator/health | grep -q "UP"; then
                echo "✅ Health check passed!"
                exit 0
              fi
              sleep 10
            done
            echo "❌ Health check failed"
            exit 1
```

---

## 9. 本节小结

### 核心知识点

✅ Workflow 文件结构和语法
✅ 触发条件配置（push、PR、定时、手动）
✅ Job 依赖和矩阵构建
✅ Step 条件和多行脚本
✅ 常用 Actions 使用
✅ Secrets 和变量管理
✅ 缓存优化策略

### 最佳实践

1. **使用缓存**：加速 Maven/npm 依赖下载
2. **路径过滤**：避免无关文件变更触发构建
3. **Job 拆分**：并行执行提高效率
4. **条件判断**：避免不必要的部署
5. **健康检查**：确保部署成功

---

## 参考资源

- [Workflow 语法文档](https://docs.github.com/cn/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub Actions 上下文](https://docs.github.com/cn/actions/learn-github-actions/contexts)
- [GitHub Marketplace](https://github.com/marketplace?type=actions)
