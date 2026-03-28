#!/bin/bash
PLUGINS_DIR=/var/jenkins_home/plugins
UC_JSON=/var/jenkins_home/updates/default.json

grep_url() {
    local name=$1
    grep -o "\"${name}\":{[^}]*}" "$UC_JSON" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4
}

download_plugin() {
    local name=$1
    local url=$(grep_url "$name")
    if [ -n "$url" ]; then
        echo -n "下载 $name... "
        curl -fsSL --max-time 120 "$url" -o "$PLUGINS_DIR/$name.jpi" 2>/dev/null && echo "OK ($(wc -c < $PLUGINS_DIR/$name.jpi) bytes)" || echo "FAIL"
    else
        echo "跳过 $name (URL未找到)"
    fi
}

download_plugin git-client
download_plugin git
download_plugin credentials
download_plugin plain-credentials
download_plugin ssh-credentials
download_plugin credentials-binding
download_plugin workflow-cps
download_plugin workflow-job
download_plugin workflow-basic-steps
download_plugin workflow-scm-step
download_plugin workflow-aggregator
download_plugin pipeline-stage-step
download_plugin pipeline-stage-view
download_plugin pipeline-model-api
download_plugin pipeline-model-definition
download_plugin pipeline-model-extensions
download_plugin pipeline-input-step
download_plugin pipeline-graph-analysis
download_plugin pipeline-rest-api
download_plugin ansicolor
download_plugin timestamper

echo "=== 全部完成 ==="
ls "$PLUGINS_DIR"/*.jpi | wc -l
echo "失败的(0字节):"
find "$PLUGINS_DIR" -name "*.jpi" -size 0
