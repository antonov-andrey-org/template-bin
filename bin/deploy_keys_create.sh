#!/bin/bash -e

# Get current directory name and current user
CURRENT_DIR=$(basename $(pwd))
CURRENT_USER=$(whoami)

# Function to create SSH key if it doesn't exist
create_ssh_key() {
    local key_name="$1"
    local key_path="$HOME/.ssh/$key_name"

    if [ ! -f "$key_path" ]; then
        ssh-keygen -t ed25519 -C "$key_name" -f "$key_path" -N ""
        echo "Generated new SSH key: $key_name"
    else
        echo "SSH key already exists: $key_name"
    fi
}

# Function to get host name from key name
get_host_from_key() {
    local key_name="$1"
    echo "$key_name" | sed 's/^deploy_//'
}

# Create main project SSH key
KEY_NAME="deploy_${CURRENT_DIR}"
create_ssh_key "$KEY_NAME"

# Create keys for all submodules if they exist
declare -a SUBMODULE_KEYS
if [ -f ".gitmodules" ]; then
    echo -e "\nProcessing submodules..."
    
    # Get list of submodules without using a pipe
    while IFS= read -r submodule; do
        # Create key name: mainproject_submodulepath (replace / with _)
        SUBMODULE_KEY_NAME="deploy_${CURRENT_DIR}_${submodule//\//_}"
        create_ssh_key "$SUBMODULE_KEY_NAME"
        SUBMODULE_KEYS+=("$SUBMODULE_KEY_NAME")
    done < <(git submodule foreach --quiet 'echo $name')
fi

# Create or clear SSH config file for deploy keys
CONFIG_FILE="$HOME/.ssh/config"
echo "# Auto-generated deploy keys config" > "$CONFIG_FILE"

# Function to add config entry
add_config_entry() {
    local key_name="$1"
    local host_name=$(get_host_from_key "$key_name")
    
    echo "" >> "$CONFIG_FILE"
    echo "Host $host_name" >> "$CONFIG_FILE"
    echo "    HostName github.com" >> "$CONFIG_FILE"
    echo "    User $CURRENT_USER" >> "$CONFIG_FILE"
    echo "    IdentityFile $HOME/.ssh/$key_name" >> "$CONFIG_FILE"
    echo "    IdentitiesOnly yes" >> "$CONFIG_FILE"
}

# Add config entries for all deploy keys
for key_file in "$HOME/.ssh/deploy_"*; do
    # Skip if no deploy keys found or if file is .pub
    if [[ ! -f "$key_file" ]] || [[ "$key_file" == *.pub ]]; then
        continue
    fi
    
    key_name=$(basename "$key_file")
    add_config_entry "$key_name"
done

echo "SSH config has been updated at $CONFIG_FILE"

# Display all generated public keys
echo -e "\nPublic keys (for adding to GitHub):"
if [ -f "$HOME/.ssh/${KEY_NAME}.pub" ]; then
    echo -e "\nMain project key (${KEY_NAME}):"
    cat "$HOME/.ssh/${KEY_NAME}.pub"
fi

# Display all submodule keys
for key_name in "${SUBMODULE_KEYS[@]}"; do
    if [ -f "$HOME/.ssh/${key_name}.pub" ]; then
        echo -e "\nSubmodule key (${key_name}):"
        cat "$HOME/.ssh/${key_name}.pub"
    fi
done

# Function to update Git URL
update_git_url() {
    local current_url="$1"
    local host_name="$2"
    echo "$current_url" | sed -E "s#^(https://|git@)[^/:|]+(.*)#\1$host_name\2#"
}

# Update Git remote URLs if in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Update main repository URL
    MAIN_HOST=$(get_host_from_key "$KEY_NAME")
    CURRENT_URL=$(git remote get-url origin)
    NEW_URL=$(update_git_url "$CURRENT_URL" "$MAIN_HOST")
    git remote set-url origin "$NEW_URL"
    echo -e "\nMain repository URL updated to: $NEW_URL"
    
    # Update submodule URLs if they exist
    if [ -f ".gitmodules" ]; then
        echo -e "\nUpdating submodule URLs..."
        
        # Get list of submodules
        while IFS= read -r submodule; do
            # Generate submodule key name and host
            SUBMODULE_KEY_NAME="deploy_${CURRENT_DIR}_${submodule//\//_}"
            SUBMODULE_HOST=$(get_host_from_key "$SUBMODULE_KEY_NAME")
            
            # Get current URL of submodule
            SUBMODULE_URL=$(git config --file .gitmodules --get "submodule.$submodule.url")
            
            # Update submodule URL
            NEW_SUBMODULE_URL=$(update_git_url "$SUBMODULE_URL" "$SUBMODULE_HOST")
            
            # Update URL in .gitmodules file
            git config --file .gitmodules "submodule.$submodule.url" "$NEW_SUBMODULE_URL"
            
            # Update URL in .git/config
            git config "submodule.$submodule.url" "$NEW_SUBMODULE_URL"
            
            echo "Updated submodule $submodule URL to: $NEW_SUBMODULE_URL"
        done < <(git submodule foreach --quiet 'echo $name')
        
        # Sync submodules to ensure changes are properly recorded
        git submodule sync
    fi
else
    echo -e "\nNot a git repository, skipping remote URL updates"
fi
