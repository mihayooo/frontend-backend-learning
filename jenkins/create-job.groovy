import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def jenkins = Jenkins.get()

def oldJob = jenkins.getItem('mall-tiny-pipeline')
if (oldJob) { oldJob.delete(); println "Deleted old job" }

def job = jenkins.createProject(WorkflowJob.class, 'mall-tiny-pipeline')
job.setDescription('mall-tiny CI/CD Pipeline: checkout -> build -> docker -> deploy -> healthcheck')

def pipelineScript = '''
pipeline {
    agent any
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
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
                echo "Code checkout OK"
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests -q -T 4'
                sh 'ls -lh target/*.jar'
                echo "Maven build OK"
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
                echo "Docker image built: ${APP_NAME}:${BUILD_NUMBER}"
            }
        }
        stage('Deploy') {
            steps {
                sh """
                    # 停止并删除旧容器（可能叫 mall-tiny 或 mall-tiny-app）
                    docker stop mall-tiny-app 2>/dev/null || true
                    docker rm   mall-tiny-app 2>/dev/null || true
                    docker stop mall-tiny 2>/dev/null || true
                    docker rm   mall-tiny 2>/dev/null || true
                    # 启动新容器，命名为 mall-tiny-app（与前端 Nginx 配置一致）
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
                echo "Deploy OK: mall-tiny-app started"
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
                            echo "Health: ${body}"
                            break
                        }
                    }
                    if (!healthy) {
                        echo "WARNING: health check timeout"
                        sh "docker logs mall-tiny-app --tail 20 || true"
                    }
                }
            }
        }
    }
    post {
        success {
            echo "BUILD #${BUILD_NUMBER} SUCCESS! Swagger: http://localhost:8080/swagger-ui/ | Login: admin/macro123"
        }
        failure {
            echo "BUILD #${BUILD_NUMBER} FAILED"
            sh "docker logs mall-tiny-app --tail 30 2>/dev/null || true"
        }
    }
}
'''

job.setDefinition(new CpsFlowDefinition(pipelineScript, true))
job.save()
jenkins.save()

println "Pipeline job created: mall-tiny-pipeline"
println "URL: http://localhost:9090/job/mall-tiny-pipeline/"
