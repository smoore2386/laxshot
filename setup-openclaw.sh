#!/usr/bin/env bash
# setup-openclaw.sh — Wire up OpenClaw agents for the Lacrosse app
# Run from the repo root: ./setup-openclaw.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="${HOME}/.openclaw"
ENV_FILE="${OPENCLAW_DIR}/.env"

echo "🦞 Lacrosse App — OpenClaw Setup"
echo "   Repo root: ${REPO_ROOT}"
echo ""

# ── 1. Ensure ~/.openclaw exists ────────────────────────────────────────────
mkdir -p "${OPENCLAW_DIR}"

# ── 2. Write LACROSSE_APP_PATH to ~/.openclaw/.env ──────────────────────────
# (OpenClaw reads this file; existing values are NOT overridden by it)
touch "${ENV_FILE}"

if grep -q "^LACROSSE_APP_PATH=" "${ENV_FILE}" 2>/dev/null; then
  echo "✓ LACROSSE_APP_PATH already set in ${ENV_FILE}"
  echo "  → $(grep '^LACROSSE_APP_PATH=' "${ENV_FILE}")"
  echo "  Update it manually if the repo has moved."
else
  echo "LACROSSE_APP_PATH=${REPO_ROOT}" >> "${ENV_FILE}"
  echo "✓ Wrote LACROSSE_APP_PATH=${REPO_ROOT} to ${ENV_FILE}"
fi

echo ""

# ── 3. Option A: symlink config ─────────────────────────────────────────────
CONFIG_DEST="${OPENCLAW_DIR}/openclaw.json"
CONFIG_SRC="${REPO_ROOT}/.openclaw/openclaw.json"

if [[ -e "${CONFIG_DEST}" && ! -L "${CONFIG_DEST}" ]]; then
  echo "⚠  ${CONFIG_DEST} already exists and is not a symlink."
  echo "   To use this project's config, either:"
  echo "     a) back up your existing config and re-run this script"
  echo "     b) run the Gateway with OPENCLAW_CONFIG_PATH set:"
  echo "        OPENCLAW_CONFIG_PATH=${CONFIG_SRC} openclaw gateway"
  echo ""
elif [[ -L "${CONFIG_DEST}" ]]; then
  current_target="$(readlink "${CONFIG_DEST}")"
  echo "✓ ${CONFIG_DEST} is already a symlink → ${current_target}"
  echo "  (To target this project's config, re-run after removing the link)"
  echo ""
else
  ln -s "${CONFIG_SRC}" "${CONFIG_DEST}"
  echo "✓ Symlinked ${CONFIG_DEST} → ${CONFIG_SRC}"
  echo ""
fi

# ── 4. Verify openclaw is installed ─────────────────────────────────────────
if command -v openclaw &>/dev/null; then
  echo "✓ openclaw is installed: $(openclaw --version 2>/dev/null || echo '(version flag not available)')"
else
  echo "⚠  openclaw not found in PATH."
  echo "   Install it with:  npm install -g openclaw@latest"
fi

echo ""
echo "── Agents configured ───────────────────────────────────────────────────"
echo "   engineering-backend  (default)  ⚙️  BackClaw"
echo "   engineering-frontend             🎨  FrontClaw"
echo "   hardware                         🔧  LaxForge"
echo "   marketing                        📣  PitchClaw"
echo ""
echo "── Next steps ──────────────────────────────────────────────────────────"
echo "   1. Set your model API key:  export ANTHROPIC_API_KEY=sk-ant-..."
echo "      (or configure auth in ~/.openclaw/openclaw.json)"
echo ""
echo "   2. Start the gateway:  openclaw gateway"
echo "      Or with verbose output:  openclaw gateway --verbose"
echo ""
echo "   3. Talk to an agent:  openclaw agent --message 'Hello, who are you?'"
echo "      Target a specific agent:"
echo "        openclaw agent --agent marketing --message 'Draft an app store description'"
echo "        openclaw agent --agent engineering-backend --message 'What is the data model?'"
echo "        openclaw agent --agent hardware --message 'What is the BLE packet format?'"
echo ""
echo "   4. Configure channels (WhatsApp, Telegram, Slack, Discord, etc.):"
echo "      openclaw onboard"
echo "      Then add bindings in .openclaw/openclaw.json to route channels"
echo "      to specific agents."
echo ""
echo "   Full docs: https://docs.openclaw.ai"
echo "🦞 Setup complete."
