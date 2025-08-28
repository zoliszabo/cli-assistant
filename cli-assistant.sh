#!/usr/bin/env bash

# CLI Assistant - A robust wrapper for gemini CLI
# Provides session management, multiple API keys, and friendly configuration

CONFIG_DIR="$HOME/.cli-assistant"
CONFIG_FILE="$CONFIG_DIR/config.json"
LAST_SESSION_FILE="$CONFIG_DIR/last-session"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

cli-assistant() {
    local force_menu=false
    local interactive_mode=false
    local gemini_args=()

    # Parse flags - separate our flags from gemini flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--model)
                force_menu=true
                shift
                ;;
            -i|--prompt-interactive)
                interactive_mode=true
                shift
                ;;
            *)
                # Forward all other arguments to gemini
                gemini_args+=("$1")
                shift
                ;;
        esac
    done

    # Check if config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Configuration file not found at $CONFIG_FILE"
        echo "Please create the config file. See README.md for details."
        return 1
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed."
        echo "Please install jq: sudo apt install jq (Ubuntu/Debian) or brew install jq (macOS)"
        return 1
    fi

    # === Reuse last session unless menu forced ===
    if [[ -f "$LAST_SESSION_FILE" && $force_menu == false ]]; then
        SESSION=$(<"$LAST_SESSION_FILE")
        echo "Using session: $SESSION"
    else
        # Build menu with descriptions + model in ()
        local sessions
        sessions=$(jq -r '.sessions | to_entries[] | "\(.key)::\(.value.description)::\(.value.model)"' "$CONFIG_FILE")

        echo "Choose a session:"
        local i=1
        declare -A session_map
        while IFS="::" read -r key desc model; do
            echo "$i) $key → $desc ($model)"
            session_map[$i]=$key
            ((i++))
        done <<< "$sessions"

        echo "$i) custom"
        session_map[$i]="custom"

        read -rp "Selection: " choice
        SESSION=${session_map[$choice]}

        if [[ -z "$SESSION" ]]; then
            echo "Invalid selection. Exiting."
            return 1
        fi

        if [[ "$SESSION" == "custom" ]]; then
            # === API key menu with descriptions ===
            echo "Choose API key:"
            local keys
            keys=$(jq -r '.api_keys | to_entries[] | "\(.key)::\(.value.description)::\(.value.key)"' "$CONFIG_FILE")

            local j=1
            declare -A key_map
            while IFS="::" read -r key desc fullkey; do
                local preview="${fullkey:0:6}...${fullkey: -4}"
                echo "$j) $key → $desc ($preview)"
                key_map[$j]=$key
                ((j++))
            done <<< "$keys"

            read -rp "Selection: " key_choice
            local keyname=${key_map[$key_choice]}

            if [[ -z "$keyname" ]]; then
                echo "Invalid selection. Exiting."
                return 1
            fi

            API_KEY=$(jq -r ".api_keys[\"$keyname\"].key" "$CONFIG_FILE")

            # === Model menu ===
            echo "Choose model:"
            local models
            models=$(jq -r '.models[]' "$CONFIG_FILE")

            local k=1
            declare -A model_map
            while read -r model; do
                echo "$k) $model"
                model_map[$k]=$model
                ((k++))
            done <<< "$models"

            read -rp "Selection: " model_choice
            MODEL=${model_map[$model_choice]}

            if [[ -z "$MODEL" ]]; then
                echo "Invalid selection. Exiting."
                return 1
            fi
        else
            # Get API key name from session config
            local api_key_name
            api_key_name=$(jq -r ".sessions[\"$SESSION\"].api_key" "$CONFIG_FILE")

            # Get actual API key from api_keys section
            API_KEY=$(jq -r ".api_keys[\"$api_key_name\"].key" "$CONFIG_FILE")
            MODEL=$(jq -r ".sessions[\"$SESSION\"].model" "$CONFIG_FILE")
        fi

        # Save the session choice
        echo "$SESSION" > "$LAST_SESSION_FILE"
    fi

    # Resolve API_KEY and MODEL for non-custom sessions when reusing
    if [[ "$SESSION" != "custom" ]]; then
        local api_key_name
        api_key_name=$(jq -r ".sessions[\"$SESSION\"].api_key" "$CONFIG_FILE")
        API_KEY=$(jq -r ".api_keys[\"$api_key_name\"].key" "$CONFIG_FILE")
        MODEL=$(jq -r ".sessions[\"$SESSION\"].model" "$CONFIG_FILE")
    fi

    # Validate that we have both API key and model
    if [[ -z "$API_KEY" || "$API_KEY" == "null" ]]; then
        echo "Error: Could not determine API key"
        return 1
    fi

    if [[ -z "$MODEL" || "$MODEL" == "null" ]]; then
        echo "Error: Could not determine model"
        return 1
    fi

    # === Run Gemini CLI with chosen options ===
    if [[ "$interactive_mode" == true ]]; then
        echo "Running: GEMINI_API_KEY=*** GEMINI_MODEL=$MODEL gemini --prompt-interactive ${gemini_args[*]}"
        GEMINI_API_KEY="$API_KEY" GEMINI_MODEL="$MODEL" gemini --prompt-interactive "${gemini_args[@]}"
    else
        echo "Running: GEMINI_API_KEY=*** GEMINI_MODEL=$MODEL gemini --prompt ${gemini_args[*]}"
        GEMINI_API_KEY="$API_KEY" GEMINI_MODEL="$MODEL" gemini --prompt "${gemini_args[@]}"
    fi
}

# CLI Assistant command
clia() {
    cli-assistant "$@"
}
