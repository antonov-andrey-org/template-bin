#!/bin/bash -e

# Get current directory name and current user
CURRENT_DIR=$(basename $(pwd))
CURRENT_USER=$(whoami)
KEY_NAME="deploy_${CURRENT_DIR}"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Create SSH key if it doesn't exist
if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -t ed25519 -C "$KEY_NAME" -f "$KEY_PATH" -N ""
    echo "Generated new SSH key: $KEY_NAME"
else
    echo "SSH key already exists: $KEY_NAME"
fi

# Create or clear SSH config file for deploy keys
CONFIG_FILE="$HOME/.ssh/config"
echo "# Auto-generated deploy keys config" > "$CONFIG_FILE"

# Find all deploy keys and generate config entries
for key_file in "$HOME/.ssh/deploy_"*; do
    # Skip if no deploy keys found or if file is .pub
    if [[ ! -f "$key_file" ]] || [[ "$key_file" == *.pub ]]; then
        continue
    fi

    # Extract key name without path and 'deploy_' prefix
    host_name=$(basename "$key_file" | sed 's/^deploy_//')

    # Add config entry
    echo "" >> "$CONFIG_FILE"
    echo "Host $host_name" >> "$CONFIG_FILE"
    echo "    HostName github.com" >> "$CONFIG_FILE"
    echo "    User $CURRENT_USER" >> "$CONFIG_FILE"
    echo "    IdentityFile $key_file" >> "$CONFIG_FILE"
    echo "    IdentitiesOnly yes" >> "$CONFIG_FILE"
done

echo "SSH config has been updated at $CONFIG_FILE"

# Display public key for easy copying
if [ -f "${KEY_PATH}.pub" ]; then
    echo -e "\nNew public key (for adding to GitHub):"
    cat "${KEY_PATH}.pub"
fi

# Function to update Git URL
update_git_url() {
    local current_url="$1"
    echo "$current_url" | sed -E "s#^(https://|git@)[^/:|]+(.*)#\1$CURRENT_DIR\2#"
}

# Update Git remote URLs if in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Update main repository URL
    CURRENT_URL=$(git remote get-url origin)
    NEW_URL=$(update_git_url "$CURRENT_URL")
    git remote set-url origin "$NEW_URL"
    echo -e "\nMain repository URL updated to: $NEW_URL"
    
    # Update submodule URLs if they exist
    if [ -f ".gitmodules" ]; then
        echo -e "\nUpdating submodule URLs..."
        
        # Get list of submodules
        git submodule foreach --quiet 'echo $name' | while read -r submodule; do
            # Get current URL of submodule
            SUBMODULE_URL=$(git config --file .gitmodules --get "submodule.$submodule.url")
            
            # Update submodule URL
            NEW_SUBMODULE_URL=$(update_git_url "$SUBMODULE_URL")
            
            # Update URL in .gitmodules file
            git config --file .gitmodules "submodule.$submodule.url" "$NEW_SUBMODULE_URL"
            
            # Update URL in .git/config
            git config "submodule.$submodule.url" "$NEW_SUBMODULE_URL"
            
            echo "Updated submodule $submodule URL to: $NEW_SUBMODULE_URL"
        done
        
        # Sync submodules to ensure changes are properly recorded
        git submodule sync
    fi
else
    echo -e "\nNot a git repository, skipping remote URL updates"
fi
