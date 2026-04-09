# discord-portal-cli

A Claude Code plugin that automates Discord Developer Portal operations via cmux browser automation.

## What it does

Create Discord bots from your terminal. No more clicking through the Developer Portal UI manually.

```
/create-bot MyAwesomeBot
```

This plugin uses cmux (terminal multiplexer with browser automation) to interact with the Discord Developer Portal, handling:

- Application creation
- Bot token generation
- Permission configuration
- Server invite URL generation

## Why

Discord has no CLI or API for managing Developer Portal resources (applications, bots). Every bot creation requires manual browser navigation. When you need to create multiple bots (e.g., 9 worker bots for a voice recording system), the friction is significant.

This plugin eliminates that friction by automating the browser operations through cmux.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [cmux](https://github.com/anthropics/cmux) installed
- A browser session logged into [Discord Developer Portal](https://discord.com/developers/applications)

## Installation

```bash
# Clone the repository
git clone https://github.com/yourname/discord-portal-cli.git

# Install as a Claude Code plugin
claude plugin install ./discord-portal-cli
```

## Usage

```bash
# Create a new bot
/create-bot MyBotName

# Create a bot with specific server
/create-bot MyBotName --server 123456789
```

## How it works

1. **Semantic layer** (SKILL.md): Natural language description of "what to do"
2. **Script layer** (scripts/): Verified cmux command sequences
3. **Claude bridges them**: Reads the semantic instructions, executes scripts at the right time, verifies results via screenshots, and proceeds to the next step

This approach is more resilient than traditional browser automation (Playwright/Puppeteer) because:
- Uses existing browser sessions (no auth complexity)
- Claude can visually verify each step and recover from unexpected states
- No heavy dependencies (no browser binary downloads)

## Development

```bash
# Set up environment
cp .envrc.example .envrc
# Edit .envrc with your Claude Code OAuth token
direnv allow

# Run Claude Code in this directory
claude
```

## License

MIT
