#!/bin/bash
# Jenkins插件批量下载脚本
# 从 default.json 中提取URL并下载

PLUGINS_DIR=/var/jenkins_home/plugins
UC_JSON=/var/jenkins_home/updates/default.json

get_url() {
    local name=$1
    cat "$UC_JSON" | tr "," "\n" | grep "download/plugins/$name/" | grep "\"url\"" | head -1 | grep -o '"url":"[^"]*"' | cut -d'"' -f4
}

download_plugin() {
    local name=$1
    if [ -f "$PLUGINS_DIR/$name.jpi" ] && [ -s "$PLUGINS_DIR/$name.jpi" ]; then
        size=$(stat -c%s "$PLUGINS_DIR/$name.jpi" 2>/dev/null || echo 0)
        if [ "$size" -gt 1000 ]; then
            echo "已存在(${size}B): $name"
            return 0
        fi
    fi
    
    local url=$(get_url "$name")
    if [ -z "$url" ]; then
        echo "❌ URL未找到: $name"
        return 1
    fi
    
    echo -n "下载 $name ($url)... "
    if curl -fsSL --max-time 120 --retry 3 --retry-delay 5 "$url" -o "$PLUGINS_DIR/$name.jpi" 2>/dev/null; then
        size=$(stat -c%s "$PLUGINS_DIR/$name.jpi" 2>/dev/null || echo 0)
        echo "OK (${size}B)"
    else
        echo "FAILED"
        rm -f "$PLUGINS_DIR/$name.jpi"
        return 1
    fi
}

echo "=== 开始下载 Jenkins 流水线插件 ==="
echo ""

# 基础依赖
download_plugin "credentials"
download_plugin "plain-credentials"
download_plugin "ssh-credentials"
download_plugin "credentials-binding"
download_plugin "git-client"
download_plugin "git"

# 流水线核心
download_plugin "workflow-scm-step"
download_plugin "workflow-cps"
download_plugin "workflow-job"
download_plugin "workflow-basic-steps"
download_plugin "workflow-aggregator"

# 流水线界面
download_plugin "pipeline-stage-step"
download_plugin "pipeline-stage-view"
download_plugin "pipeline-graph-analysis"
download_plugin "pipeline-graph-view"
download_plugin "pipeline-model-api"
download_plugin "pipeline-model-definition"
download_plugin "pipeline-model-extensions"
download_plugin "pipeline-input-step"

# Docker支持
download_plugin "docker-workflow"
download_plugin "docker-commons"

# 实用工具
download_plugin "ansicolor"
download_plugin "timestamper"
download_plugin "generic-webhook-trigger"
download_plugin "ws-cleanup"

echo ""
echo "=== 下载完成 ==="
echo "已安装插件总数: $(ls $PLUGINS_DIR/*.jpi 2>/dev/null | wc -l)"
