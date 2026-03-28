#!/bin/sh
# 通过 Script Console 触发构建（最可靠的方式）
CRUMB_JSON=$(curl -s -u admin:admin123 http://localhost:8080/crumbIssuer/api/json)
CRUMB=$(echo "$CRUMB_JSON" | sed 's/.*"crumb":"\([^"]*\)".*/\1/')
echo "Crumb: $CRUMB"

GROOVY='Jenkins.instance.getJob("mall-tiny-pipeline").scheduleBuild2(0)'

HTTP_CODE=$(curl -s -o /tmp/script-result.txt -w '%{http_code}' \
    -u admin:admin123 \
    -H "Jenkins-Crumb: $CRUMB" \
    -X POST \
    --data-urlencode "script=$GROOVY" \
    'http://localhost:8080/scriptText')

echo "Script Console HTTP: $HTTP_CODE"
cat /tmp/script-result.txt
