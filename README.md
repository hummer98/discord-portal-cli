**[日本語](README.ja.md)** | English

# discord-portal-cli

A Claude Code plugin that automates Discord Developer Portal operations via cmux browser automation.

## Motivation

- Discord has no CLI or API for managing Developer Portal resources
- Creating bots requires manual browser navigation
- When you need multiple bots, the manual process is significant friction
- cmux browser automation eliminates this by driving the real browser session

## What's Included

| Category | Description |
|----------|-------------|
| **Bot creation** | Full lifecycle: application → token → intents → OAuth2 URL |
| **Error handling** | CAPTCHA detection, 2FA escalation, login checks |
| **Token security** | Clipboard-based retrieval, no screenshots during display |
| **Semantic approach** | Claude reads SKILL.md, executes scripts, verifies via screenshots |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [cmux](https://cmux.dev) installed, with Claude Code running inside a cmux session
- A browser session logged into [Discord Developer Portal](https://discord.com/developers/applications)
- macOS (uses `pbpaste` for clipboard access)

## Installation

### Option 1: Plugin (recommended)

```
/plugin marketplace add hummer98/discord-portal-cli
/plugin install discord-portal-cli
```

Skills, commands, and hooks are installed together.

**To update:**

```
/plugin update discord-portal-cli
/reload-plugins
```

### Option 2: Agent Skills (skills only)

```bash
npx skills add hummer98/discord-portal-cli
```

> Note: Commands (`/create-bot`) are not included in Agent Skills distribution.

### Option 3: Manual (legacy)

```bash
git clone https://github.com/hummer98/discord-portal-cli.git
cd discord-portal-cli
bash install.sh
```

Installed files:

| Destination | Contents |
|-------------|----------|
| `~/.claude/skills/create-bot/SKILL.md` | Main skill definition |
| `~/.claude/commands/create-bot.md` | `/create-bot` slash command |

### Verify Installation (manual only)

```bash
bash install.sh --check
```

### Uninstall (manual only)

```bash
bash install.sh --uninstall
```

## Usage

```
/create-bot MyBotName
/create-bot MyBotName --server 123456789
```

Claude will:
1. Open the Discord Developer Portal in a cmux browser pane
2. Create the application and retrieve the bot token
3. Configure privileged gateway intents
4. Generate an OAuth2 invite URL
5. (Optional) Invite the bot to a specified server

**Human intervention required for**: hCaptcha, 2FA password, login, server authorization.

## License

[MIT](LICENSE)
