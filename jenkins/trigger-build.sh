#!/bin/sh
# 获取 crumb 并触发 Jenkins 构建
CRUMB_JSON=$(curl -s -u admin:admin123 http://localhost:8080/crumbIssuer/api/json)
echo "Crumb JSON: $CRUMB_JSON"
CRUMB=$(echo "$CRUMB_JSON" | sed 's/.*"crumb":"\([^"]*\)".*/\1/')
echo "Crumb: $CRUMB"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' -u admin:admin123 -H "Jenkins-Crumb: $CRUMB" -X POST 'http://localhost:8080/job/mall-tiny-pipeline/build')
echo "Trigger HTTP code: $HTTP_CODE"
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "Build triggered successfully!"
else
    echo "Failed to trigger build, HTTP: $HTTP_CODE"
fi
