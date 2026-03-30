# Lacrosse App

A lacrosse-focused app built with a multi-agent OpenClaw setup.

---

## OpenClaw Agents

Three isolated agents collaborate to build and market this app, each with their own workspace (identity, memory, and tools):

| Agent | ID | Emoji | Role |
|---|---|---|---|
| **BackClaw** | `engineering-backend` | ⚙️ | API, database, server infrastructure |
| **FrontClaw** | `engineering-frontend` | 🎨 | Mobile app, UI, components |
| **PitchClaw** | `marketing` | 📣 | Campaigns, copy, ASO, growth |

`engineering-backend` is the default agent — unrouted messages go there.

---

## Quick Setup

### 1. Install OpenClaw

```bash
npm install -g openclaw@latest
```

Requires Node 22.16+ (Node 24 recommended).

### 2. Clone and wire up agents

```bash
git clone <this-repo> lacrosse-app
cd lacrosse-app
chmod +x setup-openclaw.sh
./setup-openclaw.sh
```

The setup script:
- Writes `LACROSSE_APP_PATH` to `~/.openclaw/.env` so workspace paths resolve
- Symlinks `.openclaw/openclaw.json` to `~/.openclaw/openclaw.json` (or prints the manual option if you have an existing config)

### 3. Set your API key

```bash
export ANTHROPIC_API_KEY=sk-ant-...    # Claude (recommended)
# or
export OPENAI_API_KEY=sk-...           # GPT fallback
```

### 4. Start the gateway

```bash
openclaw gateway
```

### 5. Talk to an agent

```bash
# Default agent (BackClaw)
openclaw agent --message "What's the data model for this app?"

# Target a specific agent
openclaw agent --agent marketing --message "Draft an App Store description"
openclaw agent --agent engineering-frontend --message "What screens need to be built?"
```

---

## Multi-Agent Routing

By default all messages go to `engineering-backend`. To route specific channels (Telegram group, Discord channel, etc.) to different agents, add `bindings` to `.openclaw/openclaw.json`:

```json5
bindings: [
  // Marketing Slack channel → PitchClaw
  { agentId: "marketing", match: { channel: "slack", peer: { kind: "channel", id: "C123MARKETING" } } },
  // Frontend Discord channel → FrontClaw
  { agentId: "engineering-frontend", match: { channel: "discord", peer: { kind: "channel", id: "9876543210" } } },
],
```

Run `openclaw onboard` to configure channels interactively.

---

## Agent Workspaces

Each agent's workspace contains its persistent identity and memory:

```
.openclaw/
  openclaw.json                          ← multi-agent config
  workspace-engineering-backend/
    AGENTS.md    ← BackClaw instructions
    SOUL.md      ← BackClaw identity
    TOOLS.md     ← dev environment notes
    HEARTBEAT.md ← periodic task checklist
    memory/      ← daily notes (auto-created)
    MEMORY.md    ← long-term memory (auto-created)
  workspace-engineering-frontend/
    …            ← FrontClaw workspace (same structure)
  workspace-marketing/
    …            ← PitchClaw workspace (same structure)
```

Update `AGENTS.md` and `TOOLS.md` as the tech stack solidifies. The agents will read these files every session.

---

## Agent-to-Agent Coordination

Agents can message each other using `sessions_send`. Examples:
- FrontClaw asks BackClaw: *"What does the `/teams/:id/roster` endpoint return?"*
- PitchClaw asks BackClaw: *"Is the stat-tracking feature shipped yet?"*
- BackClaw notifies FrontClaw: *"The `/events` endpoint response shape changed — check your types"*

Cross-agent messaging is enabled in the config (`tools.agentToAgent.enabled: true`).

---

## Project Structure

```
lacrosse-app/
  .openclaw/          ← OpenClaw agent configurations
  src/                ← App source code (fill in as you build)
  setup-openclaw.sh   ← OpenClaw wiring script
  README.md
```

---

## Docs & References

- [OpenClaw docs](https://docs.openclaw.ai)
- [Configuration reference](https://docs.openclaw.ai/gateway/configuration-reference)
- [Multi-agent setup](https://docs.openclaw.ai/concepts/multi-agent)
- [Agent workspace & skills](https://docs.openclaw.ai/tools/skills)
