#!/bin/bash
# 完整的Jenkins插件依赖修复脚本

PLUGINS_DIR=/var/jenkins_home/plugins
UC_JSON=/var/jenkins_home/updates/default.json

get_url() {
    cat "$UC_JSON" | tr "," "\n" | grep "download/plugins/$1/" | grep '"url"' | head -1 | grep -o '"url":"[^"]*"' | cut -d'"' -f4
}

download_if_missing() {
    local name=$1
    if [ -f "$PLUGINS_DIR/$name.jpi" ] && [ "$(stat -c%s $PLUGINS_DIR/$name.jpi 2>/dev/null)" -gt 5000 ]; then
        echo "已存在: $name"
        return 0
    fi
    
    local url=$(get_url "$name")
    if [ -z "$url" ]; then
        echo "❌ URL未找到: $name"
        return 1
    fi
    
    echo -n "下载 $name... "
    curl -fsSL --max-time 120 --retry 2 "$url" -o "$PLUGINS_DIR/$name.jpi" 2>/dev/null
    local size=$(stat -c%s "$PLUGINS_DIR/$name.jpi" 2>/dev/null || echo 0)
    if [ "$size" -gt 1000 ]; then
        echo "OK (${size}B)"
    else
        echo "FAILED (${size}B)"
        rm -f "$PLUGINS_DIR/$name.jpi"
        return 1
    fi
}

echo "=== 修复Jenkins插件依赖 ==="

# 缺失的插件
download_if_missing "authentication-tokens"
download_if_missing "workflow-durable-task-step"
download_if_missing "cloudbees-folder"
download_if_missing "branch-api"
download_if_missing "pipeline-groovy-lib"
download_if_missing "json-path-api"
download_if_missing "metrics"
download_if_missing "pipeline-rest-api"
download_if_missing "resource-disposer"
download_if_missing "durable-task"

# 需要更新的插件
download_if_missing "bouncycastle-api"
download_if_missing "junit"

# 其他依赖
download_if_missing "scm-api"
download_if_missing "script-security"
download_if_missing "workflow-api"

echo ""
echo "=== 完成 ==="
echo "已安装插件总数: $(ls $PLUGINS_DIR/*.jpi 2>/dev/null | wc -l)"
