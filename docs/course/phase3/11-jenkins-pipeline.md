# 第11节：Jenkins CI/CD 自动化部署（下）Pipeline 流水线

> 目标：创建完整的 Jenkins Pipeline，实现从代码提交到应用部署的全自动化。

---

## 本节概要

| 项目 | 内容 |
|------|------|
| 预计时长 | 40-60 分钟 |
| 前置条件 | 已完成第10节 Jenkins 环境搭建 |
| 涉及技术 | Jenkins Pipeline、Groovy、Docker |

---

## 1. Pipeline 简介

### 1.1 什么是 Pipeline？

Jenkins Pipeline 是一套插件，支持将持续交付流水线以代码形式（Jenkinsfile）定义。

**Pipeline 的优势**：
- **代码化**：Pipeline 即代码，可版本控制
- **可视化**：清晰的阶段视图，一眼看出构建进度
- **可复用**：模板化配置，多个项目共用
- **可追溯**：每次构建都有完整日志

### 1.2 Pipeline 语法

Pipeline 支持两种语法：

**声明式（Declarative）**：结构化、易读，推荐新手使用
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
    }
}
```

**脚本式（Scripted）**：灵活、功能强大，适合复杂场景
```groovy
node {
    stage('Build') {
        sh 'mvn clean package'
    }
}
```

本节使用**声明式语法**。

---

## 2. 设计 Pipeline 流程

### 2.1 完整流程图

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Checkout   │ -> │    Build    │ -> │Docker Build │ -> │   Deploy    │ -> │Health Check │
│  拉取代码   │    │ Maven编译   │    │ 构建镜像    │    │ 部署应用    │    │ 健康检查    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
      │                  │                  │                  │                  │
      ▼                  ▼                  ▼                  ▼                  ▼
  git clone        mvn package       docker build     docker run      curl health
```

### 2.2 各阶段说明

| 阶段 | 命令/操作 | 预期输出 |
|------|-----------|----------|
| Checkout | `git clone` | 代码拉取到工作区 |
| Build | `mvn clean package` | `target/*.jar` |
| Docker Build | `docker build -t mall-tiny:latest` | Docker 镜像 |
| Deploy | `docker run` | 运行中的容器 |
| Health Check | `curl /actuator/health` | `{"status":"UP"}` |

---

## 3. 创建 Pipeline Job

### 3.1 使用 Groovy 脚本创建 Job

**文件：`jenkins/create-job.groovy`**

```groovy
import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def jenkins = Jenkins.get()

// 删除旧Job（如果存在）
def oldJob = jenkins.getItem('mall-tiny-pipeline')
if (oldJob) { oldJob.delete(); println "Deleted old job" }

// 创建新Pipeline Job
def job = jenkins.createProject(WorkflowJob.class, 'mall-tiny-pipeline')
job.setDescription('mall-tiny CI/CD Pipeline: checkout -> build -> docker -> deploy -> healthcheck')

def pipelineScript = '''
pipeline {
    agent any
    options {
        timestamps()                          // 添加时间戳
        timeout(time: 30, unit: 'MINUTES')    // 30分钟超时
    }
    environment {
        APP_NAME   = 'mall-tiny'
        MYSQL_HOST = 'mall-tiny-mysql'
        REDIS_HOST = 'mall-tiny-redis'
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'http://gitea:3000/gitadmin/mall-tiny.git'
                sh 'git log --oneline -3'
                echo "✅ Code checkout OK"
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests -q -T 4'
                sh 'ls -lh target/*.jar'
                echo "✅ Maven build OK"
            }
        }
        stage('Docker Build') {
            steps {
                sh """
                    docker build \\
                        -t ${APP_NAME}:${BUILD_NUMBER} \\
                        -t ${APP_NAME}:latest \\
                        .
                    docker images ${APP_NAME}
                """
                echo "✅ Docker image built: ${APP_NAME}:${BUILD_NUMBER}"
            }
        }
        stage('Deploy') {
            steps {
                sh """
                    # 停止并删除旧容器
                    docker stop mall-tiny-app 2>/dev/null || true
                    docker rm   mall-tiny-app 2>/dev/null || true
                    docker stop mall-tiny 2>/dev/null || true
                    docker rm   mall-tiny 2>/dev/null || true
                    
                    # 启动新容器
                    docker run -d \\
                        --name mall-tiny-app \\
                        --restart unless-stopped \\
                        -p 8080:8080 \\
                        --network mall-tiny_default \\
                        -e SPRING_DATASOURCE_URL="jdbc:mysql://${MYSQL_HOST}:3306/mall_tiny?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true" \\
                        -e SPRING_DATASOURCE_USERNAME=root \\
                        -e SPRING_DATASOURCE_PASSWORD=root \\
                        -e SPRING_REDIS_HOST=${REDIS_HOST} \\
                        -e SPRING_REDIS_PORT=6379 \\
                        ${APP_NAME}:latest
                    
                    docker ps --filter name=mall-tiny-app --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                """
                echo "✅ Deploy OK: mall-tiny-app started"
            }
        }
        stage('Health Check') {
            steps {
                script {
                    def healthy = false
                    for (int i = 0; i < 20; i++) {
                        sleep(8)
                        def code = sh(
                            script: "curl -s -o /dev/null -w '%{http_code}' http://host.docker.internal:8080/actuator/health 2>/dev/null || echo 000",
                            returnStdout: true
                        ).trim()
                        echo "Health check ${i+1}/20 -> HTTP ${code}"
                        if (code == '200') {
                            healthy = true
                            def body = sh(script: "curl -s http://host.docker.internal:8080/actuator/health", returnStdout: true).trim()
                            echo "✅ Health: ${body}"
                            break
                        }
                    }
                    if (!healthy) {
                        echo "⚠️ WARNING: health check timeout"
                        sh "docker logs mall-tiny-app --tail 20 || true"
                    }
                }
            }
        }
    }
    post {
        success {
            echo "🎉 BUILD #${BUILD_NUMBER} SUCCESS!"
            echo "Swagger: http://localhost:8080/swagger-ui/"
            echo "Login: admin / macro123"
        }
        failure {
            echo "❌ BUILD #${BUILD_NUMBER} FAILED"
            sh "docker logs mall-tiny-app --tail 30 2>/dev/null || true"
        }
    }
}
'''

job.setDefinition(new CpsFlowDefinition(pipelineScript, true))
job.save()
jenkins.save()

println "✅ Pipeline job created: mall-tiny-pipeline"
println "URL: http://localhost:9090/job/mall-tiny-pipeline/"
```

### 3.2 执行 Groovy 脚本创建 Job

```bash
# 将脚本复制到 Jenkins 容器
docker cp jenkins/create-job.groovy jenkins:/tmp/

# 在 Jenkins 容器中执行
docker exec -it jenkins bash -c "cd /tmp && curl -L http://localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar"

# 或者通过 Jenkins Script Console 执行
# 1. 访问 http://localhost:9090/script
# 2. 将 create-job.groovy 内容粘贴进去
# 3. 点击 Run
```

更简单的方式：直接在 Jenkins Web UI 创建

### 3.3 手动创建 Pipeline Job（备选）

1. 访问 http://localhost:9090
2. 点击"新建 Item"
3. 输入名称：`mall-tiny-pipeline`
4. 选择"Pipeline"类型，点击确定
5. 在 Pipeline 脚本区域粘贴上面的 pipelineScript 内容
6. 点击保存

---

## 4. 配置网络连接

### 4.1 问题背景

Jenkins 容器需要访问：
- **Gitea**：拉取代码（`http://gitea:3000`）
- **MySQL/Redis**：应用部署后需要连接（`mall-tiny-mysql`, `mall-tiny-redis`）

但这些服务运行在不同的 Docker 网络中：
- Jenkins 和 Gitea 在 `jenkins_net`
- mall-tiny 应用在 `mall-tiny_default`

### 4.2 解决方案

**方案1：将 Jenkins 加入 mall-tiny_default 网络**

```bash
# 将 jenkins 容器连接到 mall-tiny_default 网络
docker network connect mall-tiny_default jenkins
```

**方案2：使用 host.docker.internal（推荐用于健康检查）**

在 Pipeline 的健康检查阶段，使用 `host.docker.internal` 访问宿主机的 8080 端口：

```groovy
curl http://host.docker.internal:8080/actuator/health
```

### 4.3 执行网络连接

```bash
# 连接 Jenkins 到 mall-tiny 网络
docker network connect mall-tiny_default jenkins

# 验证
docker network inspect mall-tiny_default
```

---

## 5. 准备应用 Dockerfile

**文件：`mall-tiny/Dockerfile`**

```dockerfile
# 基础镜像：JRE 17 与 Jenkins 编译环境（JDK 17）保持一致
FROM eclipse-temurin:17-jre

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 将jar包复制到容器中
ADD ./target/mall-tiny-1.0.0-SNAPSHOT.jar /mall-tiny-1.0.0-SNAPSHOT.jar

# 声明服务运行在8080端口
EXPOSE 8080

# 启动参数：设置JVM内存，容器友好模式
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "/mall-tiny-1.0.0-SNAPSHOT.jar"]

LABEL maintainer="macrozheng" \
      description="mall-tiny spring boot application"
```

**关键注意点**：
- 使用 `eclipse-temurin:17-jre`（Jenkins 使用 JDK 17 编译，运行时需 JRE 17）
- `ADD ./target/` 指向 Maven 打包输出目录
- 包含 `allowPublicKeyRetrieval=true` 的数据库连接参数

---

## 6. 运行 Pipeline

### 6.1 触发构建

**方式1：手动触发**
1. 访问 http://localhost:9090/job/mall-tiny-pipeline/
2. 点击"立即构建"

**方式2：通过脚本触发**

```bash
# 获取 Jenkins Crumb
crumb=$(curl -s "http://localhost:9090/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

# 触发构建
curl -X POST http://localhost:9090/job/mall-tiny-pipeline/build \
  --user "admin:admin" \
  -H "$crumb"
```

### 6.2 查看构建日志

点击构建编号 → "Console Output"，可以看到完整的构建日志：

```
Started by user admin
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/mall-tiny-pipeline
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Checkout)
[Pipeline] git
...git输出...
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Build)
...Maven编译输出...
[Pipeline] }
...后续阶段...
[Pipeline] End of Pipeline
Finished: SUCCESS
```

### 6.3 预期输出

成功的构建会显示：

```
✅ Code checkout OK
✅ Maven build OK
✅ Docker image built: mall-tiny:1
✅ Deploy OK: mall-tiny-app started
✅ Health: {"status":"UP"}
🎉 BUILD #1 SUCCESS!
Swagger: http://localhost:8080/swagger-ui/
Login: admin / macro123
```

---

## 7. 配置 Webhook 自动触发

### 7.1 在 Jenkins 启用触发器

编辑 Pipeline Job，添加触发器配置：

```groovy
pipeline {
    agent any
    triggers {
        // Gitea webhook 触发
        gitea(pushEvents: true, url: 'http://gitea:3000/gitadmin/mall-tiny')
    }
    // ... 其余配置
}
```

### 7.2 在 Gitea 配置 Webhook

1. 进入 Gitea 仓库 → 设置 → Webhooks
2. 点击"添加 Webhook" → "Gitea"
3. 目标 URL：`http://jenkins:8080/gitea-webhook/post`
4. HTTP 方法：`POST`
5. 触发条件：勾选"推送事件"
6. 点击"添加 Webhook"

### 7.3 测试自动触发

```bash
# 修改代码并推送
echo "# test" >> README.md
git add .
git commit -m "test webhook"
git push gitea master
```

观察 Jenkins 是否自动开始构建。

---

## 8. Pipeline 高级技巧

### 8.1 参数化构建

```groovy
pipeline {
    agent any
    parameters {
        choice(name: 'ENV', choices: ['dev', 'test', 'prod'], description: '部署环境')
        booleanParam(name: 'SKIP_TEST', defaultValue: true, description: '跳过测试')
    }
    stages {
        stage('Build') {
            steps {
                sh "mvn clean package -DskipTests=${params.SKIP_TEST}"
            }
        }
    }
}
```

### 8.2 并行执行

```groovy
stage('Parallel Tasks') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'mvn verify'
            }
        }
    }
}
```

### 8.3 使用凭据

```groovy
stage('Deploy') {
    steps {
        withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh "docker login -u $USER -p $PASS"
            sh "docker push mall-tiny:latest"
        }
    }
}
```

---

## 9. 本节小结

### 已完成的工作

✅ 创建完整的 Jenkins Pipeline
✅ 实现 5 阶段自动化：Checkout → Build → Docker Build → Deploy → Health Check
✅ 配置网络连接，解决跨容器通信问题
✅ 验证端到端流程成功运行

### Pipeline 核心配置回顾

| 配置项 | 值 |
|--------|-----|
| Job 名称 | mall-tiny-pipeline |
| 代码仓库 | http://gitea:3000/gitadmin/mall-tiny.git |
| 构建命令 | mvn clean package -DskipTests |
| 目标容器 | mall-tiny-app |
| 目标端口 | 8080 |
| 健康检查 | /actuator/health |

### 下节预告

下一节将整理构建过程中遇到的各种坑与解决方案，帮助你快速排查问题。

---

## 参考命令

```bash
# 查看构建日志
docker logs -f jenkins

# 查看应用日志
docker logs -f mall-tiny-app

# 手动触发构建
curl -X POST http://localhost:9090/job/mall-tiny-pipeline/build

# 查看所有容器状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 检查网络连接
docker network inspect mall-tiny_default
docker network inspect jenkins_net
```
