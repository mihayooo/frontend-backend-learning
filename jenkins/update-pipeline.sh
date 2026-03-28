#!/bin/sh
# 读取 Groovy 脚本并通过 Script Console 执行

COOKIE_JAR=/tmp/jenkins-cookies.txt

# 登录获取 session
curl -s -o /dev/null -c "$COOKIE_JAR" -u admin:admin123 'http://localhost:8080/login'

# 获取 crumb
CRUMB_JSON=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" -u admin:admin123 'http://localhost:8080/crumbIssuer/api/json')
CRUMB=$(echo "$CRUMB_JSON" | sed 's/.*"crumb":"\([^"]*\)".*/\1/')
echo "Crumb: $CRUMB"

# 执行更新 Pipeline 的 Groovy 脚本
HTTP_CODE=$(curl -s -o /tmp/script-output.txt -w '%{http_code}' \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -u admin:admin123 \
    -H "Jenkins-Crumb: $CRUMB" \
    -X POST \
    --data-urlencode "script@/tmp/create-job.groovy" \
    'http://localhost:8080/scriptText')

echo "Script Console HTTP: $HTTP_CODE"
cat /tmp/script-output.txt
