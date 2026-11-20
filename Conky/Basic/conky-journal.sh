#!/usr/bin/env bash
# conky-journal.sh — robust colorized journal output for Conky
# Colors by content rather than ANSI codes (more reliable)

LINES=${1:-80}
PRIORITY=${2:-warning}

# Get plain log lines
journalctl -n "$LINES" -p "$PRIORITY" --no-pager -o short-iso 2>/dev/null | \
while IFS= read -r line; do
    # Escape $ so Conky doesn't treat them as variables
    line="${line//\$/\$\$}"

    # Color by keywords (case-insensitive)
    if echo "$line" | grep -qiE 'error|fail|crit|emerg|alert|fatal|panic'; then
        echo "\${color red}${line}\${color}"
    elif echo "$line" | grep -qiE 'warn'; then
        echo "\${color yellow}${line}\${color}"
    elif echo "$line" | grep -qiE 'notice|info'; then
        echo "\${color #2e6b2e}${line}\${color}"
    else
        echo "\${color #2e6b2e}${line}\${color}"
    fi
done

# Fallback if journalctl produced nothing
if [ ${PIPESTATUS[0]} -ne 0 ] || [ -z "$(journalctl -n 1 --no-pager | awk '!seen[$0]++' | tail -n 8 2>/dev/null)" ]; then
    echo "\${color red}Unable to read journal. Check permissions (sudo usermod -aG systemd-journal \$USER).\${color}"
fi
