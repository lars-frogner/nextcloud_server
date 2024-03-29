#!/bin/bash
set -e

# Add to crontab to automatically run at midnight:
# (sudo crontab -l; echo "0 0 * * * <script dir>/sync_github_repos.sh" ) | sudo crontab -

# Also perform regular file scan to make Nextcloud aware of changes
# (sudo crontab -u www-data -l; echo "0 2 * * * php /var/www/nextcloud/occ files:scan <username> --path=<local repo dir>" ) | sudo crontab -u www-data -

# Directory where repos should be synced to
LOCAL_REPO_DIR=/mnt/hdd1/lars/files/Kode/github_repos_backup

# Directory of this script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)

# Source GITHUB_USERNAME, GITHUB_PUBLIC_KEY and GITHUB_API_TOKEN variables
source $SCRIPT_DIR/github_sync_config.sh

cd $LOCAL_REPO_DIR

# Get list of all GitHub repositories
REPOS=$(curl -s -H "Authorization: token $GITHUB_API_TOKEN" https://api.github.com/search/repositories?q=user:$GITHUB_USERNAME | grep -o 'git@[^"]*')

# Loop over repositories
while IFS= read -r REPO; do

    REPO_NAME="$(basename "$REPO" | sed 's/\.git//')"

    # Clone repo if not present in current directory
    if [[ ! -d "$REPO_NAME" ]]; then
        ssh-agent bash -c "ssh-add $GITHUB_PUBLIC_KEY; git clone $REPO"
    fi
    cd $REPO_NAME
    ssh-agent bash -c "ssh-add $GITHUB_PUBLIC_KEY; git fetch --all"

    # Get list of all remote branches
    BRANCHES=$(git branch --all | grep '^\s*remotes' | sed -n 's/^.*remotes\/\([[:alnum:]_-]*\)\/\([[:alnum:]_-]*\).*$/\1\/\2/p')

    # Loop over remote branches
    while IFS= read -r BRANCH; do
        BRANCH_NAME=${BRANCH##*/}

        if [[ "$BRANCH_NAME" != "HEAD" ]]; then # Skip HEAD
            # Create local tracking branch if not present, and check it out
            git checkout -B "$BRANCH_NAME" --track "$BRANCH"
            # Pull remote branch
            ssh-agent bash -c "ssh-add $GITHUB_PUBLIC_KEY; git pull"
            # Restore modification times after checkout, to avoid triggering unnecessary backups
            git restore-mtime -q
        fi
    done <<< "$BRANCHES"
    cd -
done <<< "$REPOS"

# Perform any custom repo synching
if [[ -f "$SCRIPT_DIR/sync_custom_repos.sh" ]]; then
    source $SCRIPT_DIR/sync_custom_repos.sh
fi
