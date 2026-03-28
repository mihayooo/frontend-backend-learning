#!/bin/sh
# 使用 cookie 会话的方式触发 Jenkins 构建

COOKIE_JAR=/tmp/jenkins-cookies.txt

# 1. 先用 Basic Auth 登录并获取 cookie
LOGIN_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
    -c "$COOKIE_JAR" \
    -u admin:admin123 \
    'http://localhost:8080/login')
echo "Login HTTP: $LOGIN_CODE"

# 2. 获取 crumb（带 cookie）
CRUMB_JSON=$(curl -s \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -u admin:admin123 \
    'http://localhost:8080/crumbIssuer/api/json')
echo "Crumb JSON: $CRUMB_JSON"
CRUMB=$(echo "$CRUMB_JSON" | sed 's/.*"crumb":"\([^"]*\)".*/\1/')
echo "Crumb: $CRUMB"

# 3. 使用 cookie + crumb 触发构建
HTTP_CODE=$(curl -s -o /tmp/build-result.txt -w '%{http_code}' \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -u admin:admin123 \
    -H "Jenkins-Crumb: $CRUMB" \
    -X POST \
    'http://localhost:8080/job/mall-tiny-pipeline/build')
echo "Build trigger HTTP: $HTTP_CODE"
cat /tmp/build-result.txt 2>/dev/null || true
