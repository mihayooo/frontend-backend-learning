#!/bin/bash
PLUGINS_DIR=/var/jenkins_home/plugins
UC_JSON=/var/jenkins_home/updates/default.json

get_url() {
    cat "$UC_JSON" | tr "," "\n" | grep "download/plugins/$1/" | grep '"url"' | head -1 | grep -o '"url":"[^"]*"' | cut -d'"' -f4
}

process_plugin() {
    local name=$1
    local url=$(get_url "$name")
    if [ -z "$url" ]; then
        echo "URL NOT FOUND: $name"
        return 1
    fi
    echo -n "Processing $name... "
    rm -f "$PLUGINS_DIR/$name.jpi"
    curl -fsSL --max-time 120 "$url" -o "$PLUGINS_DIR/$name.jpi" 2>/dev/null
    local size=$(stat -c%s "$PLUGINS_DIR/$name.jpi" 2>/dev/null || echo 0)
    echo "OK (${size}B)"
}

process_plugin "script-security"
process_plugin "jackson3-api"
process_plugin "checks-api"
process_plugin "prism-api"
process_plugin "pipeline-build-step"
process_plugin "pipeline-milestone-step"

echo "=== Done: $(ls $PLUGINS_DIR/*.jpi | wc -l) plugins ==="
