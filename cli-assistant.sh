#!/usr/bin/env bash

# CLI Assistant - A robust wrapper for AI CLI tools
# Provides session management, multiple API key support, and friendly configuration

CONFIG_DIR="$HOME/.cli-assistant"
CONFIG_FILE="$CONFIG_DIR/config.json"
LAST_SESSION_FILE="$CONFIG_DIR/last-session"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

cli-assistant() {
    local force_menu=false
    local interactive_mode=false
    local cli_args=()

    # Parse flags - separate our flags from CLI tool flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--model)
                force_menu=true
                shift
                ;;
            -i|--interactive|--prompt-interactive)
                interactive_mode=true
                shift
                ;;
            *)
                # Forward all other arguments to CLI tool
                cli_args+=("$1")
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
        # Build menu with complete labels
        local sessions
        sessions=$(jq -r '.sessions | to_entries[] |
            select(.value.vendor and .value.model and .key) |
            if .value.description and .value.description != "" then
                "\(.key)|\(.key) (\(.value.vendor):\(.value.model)) → \(.value.description)"
            else
                "\(.key)|\(.key) (\(.value.vendor):\(.value.model))"
            end' "$CONFIG_FILE")

        echo "Choose a session:"
        local i=1
        declare -A session_map
        while IFS="|" read -r key label; do
            echo "$i) $label"
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
            # === Vendor selection ===
            echo "Choose vendor:"
            local vendors
            vendors=$(jq -r '.vendors | keys[]' "$CONFIG_FILE")

            local j=1
            declare -A vendor_map
            while read -r vendor; do
                echo "$j) $vendor"
                vendor_map[$j]=$vendor
                ((j++))
            done <<< "$vendors"

            read -rp "Selection: " vendor_choice
            local selected_vendor=${vendor_map[$vendor_choice]}

            if [[ -z "$selected_vendor" ]]; then
                echo "Invalid selection. Exiting."
                return 1
            fi

            # === API key menu for selected vendor ===
            echo "Choose API key for $selected_vendor:"
            local keys
            keys=$(jq -r ".vendors[\"$selected_vendor\"].api_keys | to_entries[] |
                \"\(.key)|\(.key) → \(.value.description) (\(.value.key[:6])...\(.value.key[-4:]))\"" "$CONFIG_FILE")

            local k=1
            declare -A key_map
            while IFS="|" read -r key label; do
                echo "$k) $label"
                key_map[$k]=$key
                ((k++))
            done <<< "$keys"

            read -rp "Selection: " key_choice
            local keyname=${key_map[$key_choice]}

            if [[ -z "$keyname" ]]; then
                echo "Invalid selection. Exiting."
                return 1
            fi

            # === Model menu for selected vendor ===
            echo "Choose model for $selected_vendor:"
            local models
            models=$(jq -r ".vendors[\"$selected_vendor\"].models[]" "$CONFIG_FILE")

            local l=1
            declare -A model_map
            while read -r model; do
                echo "$l) $model"
                model_map[$l]=$model
                ((l++))
            done <<< "$models"

            read -rp "Selection: " model_choice
            local selected_model=${model_map[$model_choice]}

            if [[ -z "$selected_model" ]]; then
                echo "Invalid selection. Exiting."
                return 1
            fi

            # Store selections for custom session
            VENDOR="$selected_vendor"
            API_KEY_NAME="$keyname"
            MODEL="$selected_model"
        else
            # Get session configuration
            VENDOR=$(jq -r ".sessions[\"$SESSION\"].vendor" "$CONFIG_FILE")
            API_KEY_NAME=$(jq -r ".sessions[\"$SESSION\"].api_key" "$CONFIG_FILE")
            MODEL=$(jq -r ".sessions[\"$SESSION\"].model" "$CONFIG_FILE")
        fi

        # Save the session choice
        echo "$SESSION" > "$LAST_SESSION_FILE"
    fi

    # Resolve vendor, API key and model for both new selections and reused sessions
    if [[ "$SESSION" != "custom" ]]; then
        VENDOR=$(jq -r ".sessions[\"$SESSION\"].vendor" "$CONFIG_FILE")
        API_KEY_NAME=$(jq -r ".sessions[\"$SESSION\"].api_key" "$CONFIG_FILE")
        MODEL=$(jq -r ".sessions[\"$SESSION\"].model" "$CONFIG_FILE")
    fi

    # Get the actual API key from the vendor configuration
    API_KEY=$(jq -r ".vendors[\"$VENDOR\"].api_keys[\"$API_KEY_NAME\"].key" "$CONFIG_FILE")

    # Get vendor-specific configuration
    COMMAND=$(jq -r ".vendors[\"$VENDOR\"].command" "$CONFIG_FILE")
    API_KEY_ENV=$(jq -r ".vendors[\"$VENDOR\"].env_vars.api_key" "$CONFIG_FILE")
    MODEL_FLAG=$(jq -r ".vendors[\"$VENDOR\"].flags.model" "$CONFIG_FILE")

    if [[ "$interactive_mode" == true ]]; then
        PROMPT_FLAG=$(jq -r ".vendors[\"$VENDOR\"].flags.interactive" "$CONFIG_FILE")
    else
        PROMPT_FLAG=$(jq -r ".vendors[\"$VENDOR\"].flags.prompt" "$CONFIG_FILE")
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

    # === Run CLI with chosen options ===
    echo "Running: $API_KEY_ENV=*** $COMMAND $MODEL_FLAG $MODEL $PROMPT_FLAG $(printf '%q ' "${cli_args[@]}")"

    # Set environment variables dynamically and run the command
    env "$API_KEY_ENV=$API_KEY" "$COMMAND" "$MODEL_FLAG" "$MODEL" "$PROMPT_FLAG" "${cli_args[@]}"
}

# CLI Assistant command
clia() {
    cli-assistant "$@"
}
