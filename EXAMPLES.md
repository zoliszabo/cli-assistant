# Example usage scenarios for CLI Assistant

## Scenario 1: First time setup
```bash
# Install the tool
./install.sh

# Edit config with your real API keys
nano ~/.cli-assistant/config.json

# Reload shell
source ~/.bashrc

# First run - will show session menu
clia "explain git rebase"
```

## Scenario 2: Daily usage (automatic session reuse)
```bash
# Quick questions - uses last session automatically
clia "git command to undo last commit"
clia "explain docker compose volumes"
clia "how to debug memory leaks in node.js"
```

## Scenario 3: Switching sessions
```bash
# Force session menu to switch context
clia -m "explain kubernetes deployments"

# Choose different session (e.g., work-standard for complex questions)
# Session gets remembered for next runs
```

## Scenario 4: Custom API key/model selection
```bash
# Use custom mode for one-off combinations
clia -m "write a python script to parse JSON"

# Choose "custom" from session menu
# Pick specific API key and model
# Gets saved for potential reuse
```

## Scenario 5: Different types of queries by session

### Personal-fast session (gemini-2.5-flash)
- Quick coding questions
- Simple explanations
- Fast lookups

### Work-standard session (gemini-2.5)
- Complex architectural decisions
- Detailed code reviews
- Production troubleshooting

### Test-mini session (gemini-1.5-flash)
- Experimenting with prompts
- Testing new approaches
- Cost-conscious usage

## Expected menu outputs

### Session selection menu:
```
Choose a session:
1) personal-fast → Personal use, quick answers (gemini-2.5-flash)
2) work-standard → Work projects, more reliable (gemini-2.5)
3) test-mini → Experiments with lower costs (gemini-1.5-flash)
4) custom
Selection:
```

### Custom API key selection:
```
Choose API key:
1) personal → Personal account (your-p...here)
2) work → Work account (your-w...here)
3) test → Testing/experimental key (your-t...here)
Selection:
```

### Custom model selection:
```
Choose model:
1) gemini-2.5-flash
2) gemini-2.5
3) gemini-1.5-flash
Selection:
```
