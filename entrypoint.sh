#!/bin/sh
set -e

export PATH="/root/.local/bin:$PATH"

# Sync auth tokens from host (like budgie sandbox)
KIRO_DATA_DIR="/root/.local/share/kiro-cli"
AUTH_SOURCE="/auth/data.sqlite3"
TARGET_DB="$KIRO_DATA_DIR/data.sqlite3"

mkdir -p "$KIRO_DATA_DIR"

if [ -f "$AUTH_SOURCE" ]; then
    if [ ! -f "$TARGET_DB" ]; then
        cp "$AUTH_SOURCE" "$TARGET_DB"
    else
        sqlite3 "$TARGET_DB" "ATTACH '$AUTH_SOURCE' AS auth_src; \
            DELETE FROM auth_kv; \
            INSERT INTO auth_kv SELECT * FROM auth_src.auth_kv;" 2>/dev/null || true
    fi
fi

# Git config
git config --global --add safe.directory /workspace
git config --global user.name "${GIT_AUTHOR_NAME:-Ralph}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-ralph@example.com}"
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"

exec "$@"
