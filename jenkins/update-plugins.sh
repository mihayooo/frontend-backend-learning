#!/bin/bash
PLUGINS_DIR=/var/jenkins_home/plugins
UC_JSON=/var/jenkins_home/updates/default.json

get_url() {
    cat "$UC_JSON" | tr "," "\n" | grep "download/plugins/$1/" | grep '"url"' | head -1 | grep -o '"url":"[^"]*"' | cut -d'"' -f4
}

update_plugin() {
    local name=$1
    local url=$(get_url "$name")
    if [ -z "$url" ]; then
        echo "URL NOT FOUND: $name"
        return 1
    fi
    echo -n "Updating $name... "
    rm -f "$PLUGINS_DIR/$name.jpi"
    curl -fsSL --max-time 120 "$url" -o "$PLUGINS_DIR/$name.jpi" 2>/dev/null
    local size=$(stat -c%s "$PLUGINS_DIR/$name.jpi" 2>/dev/null || echo 0)
    echo "OK (${size}B)"
}

update_plugin "bouncycastle-api"
update_plugin "scm-api"
update_plugin "junit"
update_plugin "variant"

echo "=== Done ==="
ls $PLUGINS_DIR/*.jpi | wc -l
