# Exit if any command fails
$ErrorActionPreference = "Stop"

# Static Variables
$RepoURL = "http.repo.url" # GitLab repository URL
$CommitMessage = "zebra 2025." # Commit message
$CsvDir = "C/CsvTest" # Directory containing the CSV files
$PrivateToken = "Nectar_backup" # GitLab personal access token
$Branch = "test-case-data-dev" # Default branch name
$ProjectID = 2778 # GitLab project ID

# Navigate to the CSV directory
Set-Location -Path $CsvDir

# Loop through all .csv files
Get-ChildItem -Path . -Filter "*.csv" | ForEach-Object {
    $FilePath = $_.Name

    # Check if the file exists in the GitLab repository (via GET request)
    $Response = Invoke-RestMethod -Headers @{ "PRIVATE-TOKEN" = $PrivateToken } -Uri "$RepoURL/api/v4/projects/$ProjectID/repository/files/$FilePath?ref=$Branch" -Method Get -ErrorAction SilentlyContinue

    if ($Response -and $Response.file_path) {
        # File exists, use PUT to update
        Write-Host "Updating existing file: $FilePath"
        Invoke-RestMethod -Uri "$RepoURL/api/v4/projects/$ProjectID/repository/commits" `
            -Method Put `
            -Headers @{ "PRIVATE-TOKEN" = $PrivateToken } `
            -Form @{ "branch" = $Branch;
                     "commit_message" = $CommitMessage;
                     "actions[0][action]" = "update";
                     "actions[0][file_path]" = $FilePath;
                     "actions[0][content]" = [System.IO.File]::ReadAllText($FilePath) }
    } else {
        # File does not exist, use POST to create
        Write-Host "Creating new file: $FilePath"
        Invoke-RestMethod -Uri "$RepoURL/api/v4/projects/$ProjectID/repository/commits" `
            -Method Post `
            -Headers @{ "PRIVATE-TOKEN" = $PrivateToken } `
            -Form @{ "branch" = $Branch;
                     "commit_message" = $CommitMessage;
                     "actions[0][action]" = "create";
                     "actions[0][file_path]" = $FilePath;
                     "actions[0][content]" = [System.IO.File]::ReadAllText($FilePath) }
    }
}

Write-Host "Backup completed successfully for all CSV files on branch: $Branch"
