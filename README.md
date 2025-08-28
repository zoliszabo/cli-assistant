# CLI Assistant

A robust wrapper for the `gemini` CLI tool that provides session management, multiple API key support, and friendly configuration.

## Features

- **Session-based configuration**: Pre-define combinations of API keys and models
- **Multiple API key support**: Easily switch between different API keys (personal, work, test)
- **Friendly menus**: Clear descriptions for sessions and API keys
- **Automatic session reuse**: Remembers your last choice for quick subsequent runs
- **Custom mode**: Manual API key and model selection when needed
- **Structured configuration**: JSON-based config stored in `~/.cli-assistant/`

## Prerequisites

Before installing, make sure you have the required dependencies:

1. **jq** (command-line JSON processor) - Required for parsing configuration files:
   ```bash
   # Ubuntu/Debian
   sudo apt install jq

   # macOS (with Homebrew)
   brew install jq

   # CentOS/RHEL/Fedora
   sudo yum install jq
   # or for newer versions:
   sudo dnf install jq
   ```

2. **gemini CLI tool** - The actual gemini command-line interface must be installed and available in your PATH.

## Installation

### Option 1: Automated Installation (Recommended)

Run the installation script:
```bash
./install.sh
```

This will:
- Check for required dependencies
- Create the `~/.cli-assistant/` directory
- Copy the script files
- Set up shell configuration
- Create an example config file

### Option 2: Manual Installation

1. Copy the script to your preferred location:
   ```bash
   cp cli-assistant.sh ~/.cli-assistant/
   chmod +x ~/.cli-assistant/cli-assistant.sh
   ```

2. Add to your `.bashrc` or `.zshrc`:
   ```bash
   source ~/.cli-assistant/cli-assistant.sh
   ```

3. Create your configuration file (see Configuration section below).

## Configuration

Create `~/.cli-assistant/config.json` with your API keys and sessions:

```json
{
  "sessions": {
    "personal-fast": {
      "api_key": "personal",
      "model": "gemini-2.5-flash",
      "description": "Personal use, quick answers"
    },
    "work-standard": {
      "api_key": "work",
      "model": "gemini-2.5",
      "description": "Work projects, more reliable"
    },
    "test-mini": {
      "api_key": "test",
      "model": "gemini-1.5-flash",
      "description": "Experiments with lower costs"
    }
  },
  "models": [
    "gemini-2.5-flash",
    "gemini-2.5",
    "gemini-1.5-flash"
  ],
  "api_keys": {
    "personal": {
      "description": "Personal account",
      "key": "your-personal-api-key-here"
    },
    "work": {
      "description": "Work account",
      "key": "your-work-api-key-here"
    },
    "test": {
      "description": "Testing/experimental key",
      "key": "your-test-api-key-here"
    }
  }
}
```

## Usage

### Quick usage (reuses last session)
```bash
clia "git command to list recent branches"
# or
cli-assistant "explain git stash"
```

### Force session selection menu
```bash
clia -m "git command to reset last commit"
# or
cli-assistant --model "explain docker compose"
```

### Interactive mode
```bash
clia -i "explain git concepts"
# or
cli-assistant --prompt-interactive "explain docker concepts"
```

### Pass additional gemini flags
```bash
clia --debug "complex question"
clia --sandbox "run some code"
clia -m --yolo "auto-approve actions"
```

### Combine flags
```bash
clia -m -i "complex development question"
clia --model --prompt-interactive --debug "detailed analysis"
```

### Session menu example
```
Choose a session:
1) personal-fast → Personal use, quick answers (gemini-2.5-flash)
2) work-standard → Work projects, more reliable (gemini-2.5)
3) test-mini → Experiments with lower costs (gemini-1.5-flash)
4) custom
Selection:
```

### Custom selection (when choosing option 4)
```
Choose API key:
1) personal → Personal account (your-p...here)
2) work → Work account (your-w...here)
3) test → Testing/experimental key (your-t...here)
Selection:

Choose model:
1) gemini-2.5-flash
2) gemini-2.5
3) gemini-1.5-flash
Selection:
```

## Files Created

- `~/.cli-assistant/config.json` - Your configuration
- `~/.cli-assistant/last-session` - Remembers last used session
- `~/.cli-assistant/last-key` - Remembers last used API key (for custom mode)
- `~/.cli-assistant/last-model` - Remembers last used model (for custom mode)

## Requirements

- `bash` or `zsh` shell
- `jq` command-line JSON processor
- `gemini` CLI tool installed and in PATH
