# Exit if any command fails
$ErrorActionPreference = "Stop"

# Variables (Set dynamically or passed as environment variables)
if (-not $env:REPO_URL) {
    Write-Host "Please set the GitLab repository URL as an environment variable."; exit 1
}
if (-not $env:COMMIT_MESSAGE) {
    Write-Host "Please provide a commit message."; exit 1
}
if (-not $env:CSV_DIR) {
    Write-Host "Please set the directory path for test case data."; exit 1
}
if (-not $env:NECTAR_BACKUP_PAT) {
    Write-Host "Please set the GitLab token (NECTAR_BACKUP_PAT) as an environment variable."; exit 1
}

# Default branch if not set
$Branch = $env:BRANCH
if (-not $Branch) { $Branch = "test-case-data-dev" }

# Static project ID
$ProjectID = 1234566

# Navigate to the CSV directory
if (-not (Test-Path -Path $env:CSV_DIR)) {
    Write-Host "Directory $env:CSV_DIR not found! Exiting."; exit 1
}
Set-Location -Path $env:CSV_DIR

# Loop through all .csv files
Get-ChildItem -Path $env:CSV_DIR -Filter *.csv | ForEach-Object {
    $File = $_.Name

    # Check if the file exists in the GitLab repository (via GET request)
    $Response = Invoke-RestMethod -Uri "$env:REPO_URL/api/v4/projects/$ProjectID/repository/files/$File?ref=$Branch" `
                                  -Headers @{ "PRIVATE-TOKEN" = $env:NECTAR_BACKUP_PAT } `
                                  -Method Get -ErrorAction SilentlyContinue

    if ($Response.file_path) {
        # File exists, use PUT to update
        Write-Host "Updating existing file: $File"
        Invoke-RestMethod -Uri "$env:REPO_URL/api/v4/projects/$ProjectID/repository/commits" `
                          -Headers @{ "PRIVATE-TOKEN" = $env:NECTAR_BACKUP_PAT } `
                          -Method Put `
                          -Body @{
                              branch = $Branch
                              commit_message = $env:COMMIT_MESSAGE
                              actions = @(
                                  @{
                                      action = "update"
                                      file_path = $File
                                      content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName))
                                  }
                              )
                          } | ConvertTo-Json -Depth 10 -Compress
    } else {
        # File does not exist, use POST to create
        Write-Host "Creating new file: $File"
        Invoke-RestMethod -Uri "$env:REPO_URL/api/v4/projects/$ProjectID/repository/commits" `
                          -Headers @{ "PRIVATE-TOKEN" = $env:NECTAR_BACKUP_PAT } `
                          -Method Post `
                          -Body @{
                              branch = $Branch
                              commit_message = $env:COMMIT_MESSAGE
                              actions = @(
                                  @{
                                      action = "create"
                                      file_path = $File
                                      content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName))
                                  }
                              )
                          } | ConvertTo-Json -Depth 10 -Compress
    }
}

Write-Host "Backup completed successfully for all CSV files on branch: $Branch"
