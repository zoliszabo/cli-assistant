# CLI Assistant

A robust wrapper for AI CLI tools that provides session management, multiple API key support, and friendly configuration.

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

2. **An AI CLI tool** - One or more actual AI command-line interface tools (such as gemini-cli, openai/codex, claude-code, etc.) must be installed and available in your PATH.

## Installation

### Get the Code

First, clone or download this repository:

```bash
# Clone with git
git clone https://github.com/zoliszabo/cli-assistant.git
cd cli-assistant

# Or download and extract the ZIP file
wget https://github.com/zoliszabo/cli-assistant/archive/main.zip
unzip main.zip
cd cli-assistant-main
```

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

Create `~/.cli-assistant/config.json` with your vendors, API keys and sessions. The tool supports any AI CLI tool - the example below shows configuration for Gemini, but you can configure it for OpenAI, Claude, or any other AI CLI tool by adjusting the vendor settings:

```json
{
  "vendors": {
    "gemini": {
      "command": "gemini",
      "api_keys": {
        "personal": {
          "description": "Personal account",
          "key": "your-personal-api-key-here"
        },
        "work": {
          "description": "Work account",
          "key": "your-work-api-key-here"
        }
      },
      "models": [
        "gemini-2.5-flash",
        "gemini-2.5-pro",
        "gemini-1.5-flash"
      ],
      "env_vars": {
        "api_key": "GEMINI_API_KEY"
      },
      "flags": {
        "model": "-m",
        "prompt": "--prompt",
        "interactive": "--prompt-interactive"
      }
    }
  },
  "sessions": {
    "personal-fast": {
      "vendor": "gemini",
      "api_key": "personal",
      "model": "gemini-2.5-flash",
      "description": "Personal use, quick answers"
    },
    "work-standard": {
      "vendor": "gemini",
      "api_key": "work",
      "model": "gemini-2.5-pro",
      "description": "Work projects, more reliable"
    }
  }
}
```

**Note**: The configuration supports multiple vendors. You can add other AI CLI tools (like OpenAI, Anthropic, etc.) by adding them to the `vendors` section with their respective commands, environment variables, and flags.

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

### Pass additional CLI flags
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
1) personal-fast → Personal use, quick answers (gemini:gemini-2.5-flash)
2) work-standard → Work projects, more reliable (gemini:gemini-2.5-pro)
3) test-mini → Experiments with lower costs (gemini:gemini-1.5-flash)
4) custom
Selection:
```

### Custom selection (when choosing option 4)
```
Choose vendor:
1) gemini
Selection: 1

Choose API key for gemini:
1) personal → Personal account (your-p...here)
2) work → Work account (your-w...here)
Selection: 1

Choose model for gemini:
1) gemini-2.5-flash
2) gemini-2.5-pro
3) gemini-1.5-flash
Selection: 1
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
- Gemini API key(s)

**Note**: The tool supports multiple AI vendors. Additional CLI tools can be configured by extending the `vendors` section in the configuration.
