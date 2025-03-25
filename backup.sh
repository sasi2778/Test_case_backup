#!/bin/sh

# Exit if any command fails
set -e

# Variables (Set dynamically or passed as environment variables)
if [ -z "$REPO_URL" ]; then
  echo "Please set the GitLab repository URL as an environment variable."; exit 1
fi
if [ -z "$COMMIT_MESSAGE" ]; then
  echo "Please provide a commit message."; exit 1
fi
if [ -z "$CSV_DIR" ]; then
  echo "Please set the directory path for test case data."; exit 1
fi
if [ -z "$GITLAB_TOKEN" ]; then
  echo "Please set the GitLab token as an environment variable."; exit 1
fi

BRANCH="${BRANCH:-test-case-data-dev}" # Default branch if not set

# Navigate to the CSV directory
cd "$CSV_DIR" || { echo "Directory $CSV_DIR not found! Exiting."; exit 1; }

# Loop through all .csv files and push each one to the repository
for file in *.csv; do
  curl --request POST \
       --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
       --form "branch=$BRANCH" \
       --form "commit_message=$COMMIT_MESSAGE" \
       --form "actions[][action]=create" \
       --form "actions[][file_path]=$file" \
       --form "actions[][content]=$(base64 "$file" | tr -d '\n')" \
       "$REPO_URL/api/v4/projects/<your_project_id>/repository/commits"
done

echo "Backup completed successfully for all CSV files on branch: $BRANCH"
