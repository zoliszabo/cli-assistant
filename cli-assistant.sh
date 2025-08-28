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
        # Check if the file contains JSON (new format) or just a session name (old format)
        if jq -e . "$LAST_SESSION_FILE" >/dev/null 2>&1; then
            # New JSON format - extract configuration and validate
            session=$(jq -r ".session" "$LAST_SESSION_FILE")
            vendor=$(jq -r ".vendor" "$LAST_SESSION_FILE")
            api_key_name=$(jq -r ".api_key" "$LAST_SESSION_FILE")
            model=$(jq -r ".model" "$LAST_SESSION_FILE")

            # Validate that the configuration is still valid
            local config_valid=true

            # Check if vendor still exists
            if ! jq -e ".vendors[\"$vendor\"]" "$CONFIG_FILE" >/dev/null 2>&1; then
                echo "Saved vendor '$vendor' no longer exists in config. Showing menu..."
                config_valid=false
            fi

            # Check if API key still exists (unless it's "none")
            if [[ "$config_valid" == true && "$api_key_name" != "none" ]]; then
                if ! jq -e ".vendors[\"$vendor\"].api_keys[\"$api_key_name\"]" "$CONFIG_FILE" >/dev/null 2>&1; then
                    echo "Saved API key '$api_key_name' no longer exists for vendor '$vendor'. Showing menu..."
                    config_valid=false
                fi
            fi

            # Check if model still exists (unless it's "default")
            if [[ "$config_valid" == true && "$model" != "default" ]]; then
                local model_exists
                model_exists=$(jq -r ".vendors[\"$vendor\"].models[]" "$CONFIG_FILE" | grep -Fx "$model" || true)
                if [[ -z "$model_exists" ]]; then
                    echo "Saved model '$model' no longer exists for vendor '$vendor'. Showing menu..."
                    config_valid=false
                fi
            fi

            # For non-custom sessions, validate that saved config matches current session definition
            if [[ "$config_valid" == true && "$session" != "custom" ]]; then
                local current_vendor current_api_key current_model
                current_vendor=$(jq -r ".sessions[\"$session\"].vendor" "$CONFIG_FILE")
                current_api_key=$(jq -r ".sessions[\"$session\"].api_key" "$CONFIG_FILE")
                current_model=$(jq -r ".sessions[\"$session\"].model" "$CONFIG_FILE")

                if [[ "$vendor" != "$current_vendor" || "$api_key_name" != "$current_api_key" || "$model" != "$current_model" ]]; then
                    echo "Session '$session' configuration has changed in config file. Showing menu..."
                    config_valid=false
                fi
            fi

            if [[ "$config_valid" == true ]]; then
                if [[ "$session" == "custom" ]]; then
                    echo "Using saved custom configuration: $vendor:$model (key: $api_key_name)"
                else
                    echo "Using saved session '$session': $vendor:$model (key: $api_key_name)"
                fi
            else
                force_menu=true
            fi
        else
            # Old format - force menu since we're not converting
            echo "Old or invalid session format detected. Showing menu..."
            force_menu=true
        fi
    fi

    # Show menu if forced or no valid saved session
    if [[ "$force_menu" == true || ! -f "$LAST_SESSION_FILE" ]]; then
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
        session=${session_map[$choice]}

        if [[ -z "$session" ]]; then
            echo "Invalid selection. Exiting."
            return 1
        fi

        if [[ "$session" == "custom" ]]; then
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

            # Add "none" as first option
            echo "$k) none → Use default auth method"
            key_map[$k]="none"
            ((k++))

            # Add all configured API keys (only if keys exist)
            if [[ -n "$keys" ]]; then
                while IFS="|" read -r key label; do
                    echo "$k) $label"
                    key_map[$k]=$key
                    ((k++))
                done <<< "$keys"
            fi

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

            # Add "default" as first option
            echo "$l) default"
            model_map[$l]="default"
            ((l++))

            # Add all configured models (only if models exist)
            if [[ -n "$models" ]]; then
                while read -r model; do
                    echo "$l) $model"
                    model_map[$l]=$model
                    ((l++))
                done <<< "$models"
            fi

            read -rp "Selection: " model_choice
            local selected_model=${model_map[$model_choice]}

            if [[ -z "$selected_model" ]]; then
                echo "Invalid selection. Exiting."
                return 1
            fi

            # Store selections for custom session
            vendor="$selected_vendor"
            api_key_name="$keyname"
            model="$selected_model"
        else
            # Get session configuration
            vendor=$(jq -r ".sessions[\"$session\"].vendor" "$CONFIG_FILE")
            api_key_name=$(jq -r ".sessions[\"$session\"].api_key" "$CONFIG_FILE")
            model=$(jq -r ".sessions[\"$session\"].model" "$CONFIG_FILE")
        fi

        # Save the configuration details for reuse
        echo "{\"session\":\"$session\",\"vendor\":\"$vendor\",\"api_key\":\"$api_key_name\",\"model\":\"$model\"}" > "$LAST_SESSION_FILE"
    fi

    # Get the actual API key from the vendor configuration (unless "none")
    if [[ "$api_key_name" == "none" || -z "$api_key_name" || "$api_key_name" == "null" ]]; then
        api_key="none"
    else
        api_key=$(jq -r ".vendors[\"$vendor\"].api_keys[\"$api_key_name\"].key" "$CONFIG_FILE")
    fi

    # Get vendor-specific configuration
    command=$(jq -r ".vendors[\"$vendor\"].command" "$CONFIG_FILE")
    api_key_env=$(jq -r ".vendors[\"$vendor\"].env_vars.api_key" "$CONFIG_FILE")
    model_flag=$(jq -r ".vendors[\"$vendor\"].flags.model" "$CONFIG_FILE")

    if [[ "$interactive_mode" == true ]]; then
        prompt_flag=$(jq -r ".vendors[\"$vendor\"].flags.interactive" "$CONFIG_FILE")
    else
        prompt_flag=$(jq -r ".vendors[\"$vendor\"].flags.prompt" "$CONFIG_FILE")
    fi

    # Check if API key should use default auth (none, empty, null, or "none" keyword)
    local use_default_auth=false
    if [[ -z "$api_key" || "$api_key" == "null" || "$api_key" == "none" ]]; then
        use_default_auth=true
    fi

    # Check if model should use default (empty, null, or "default" keyword)
    local use_default_model=false
    if [[ -z "$model" || "$model" == "null" || "$model" == "default" ]]; then
        use_default_model=true
    fi

    # === Build command from conditional parts ===
    local env_part=""
    local model_part=""
    local prompt_part=""

    # Build environment variable part
    if [[ "$use_default_auth" == false ]]; then
        env_part="env $api_key_env=$api_key"
    fi

    # Build model flag part
    if [[ "$use_default_model" == false ]]; then
        model_part="$model_flag $model"
    fi

    # Execute command
    if [[ ${#cli_args[@]} -gt 0 ]]; then
        # With prompt arguments (preserve array boundaries)
        ${env_part:+$env_part} $command ${model_part:+$model_part} "$prompt_flag" "${cli_args[@]}"
    else
        # Without prompt arguments
        ${env_part:+$env_part} $command ${model_part:+$model_part}
    fi
}

# CLI Assistant command
clia() {
    cli-assistant "$@"
}
