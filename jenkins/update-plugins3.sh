#!/bin/bash
PLUGINS_DIR=/var/jenkins_home/plugins
UC_JSON=/var/jenkins_home/updates/default.json

get_url() {
    cat "$UC_JSON" | tr "," "\n" | grep "download/plugins/$1/" | grep '"url"' | head -1 | grep -o '"url":"[^"]*"' | cut -d'"' -f4
}

for plugin in snakeyaml-engine-api mailer; do
    url=$(get_url "$plugin")
    if [ -z "$url" ]; then echo "NOT FOUND: $plugin"; continue; fi
    echo -n "Processing $plugin... "
    rm -f "$PLUGINS_DIR/$plugin.jpi"
    curl -fsSL --max-time 120 "$url" -o "$PLUGINS_DIR/$plugin.jpi" 2>/dev/null
    size=$(stat -c%s "$PLUGINS_DIR/$plugin.jpi" 2>/dev/null || echo 0)
    echo "OK (${size}B)"
done
echo "Total: $(ls $PLUGINS_DIR/*.jpi | wc -l)"
