#!/usr/bin/env bash
set -euo pipefail
export PAPERCLIP_HOME="$HOME/.paperclip-loudweb"
export PAPERCLIP_INSTANCE_ID="loudweb"
export PORT="3456"
export SERVE_UI="true"
export BETTER_AUTH_SECRET="loudweb-paperclip-dev-secret"
exec pnpm dev
