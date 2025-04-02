# Exit on any error
$ErrorActionPreference = "Stop"

# Static Variables
$api_url = "https://gitlab.com/api/v4/projects/68429798/repository/commits"
$commitMessage = "backup for 2024.2.1 $(Get-Date -Format 'yyyy-MM-dd') [skip ci]"
$csvDir = "C:\TestCSV"
$privateToken = "glpat-GhxVy8e94Wqh4NkGRYvD"
$branch = "Test-case-data-live"

# Navigate to the CSV directory
Set-Location -Path $csvDir

# Build a list of actions (one for each .csv file)
$actions = @()

Get-ChildItem -Path . -Filter "*.csv" | ForEach-Object {
    $filePath = $_.Name
    $fileContent = Get-Content -Raw -Path $_.FullName
    Write-Host "Adding file: $filePath"

    $actions += @{
        action     = "create"
        file_path = $filePath
        content    = $fileContent
    }
}

# Build final payload with all actions
$payload = @{
    branch         = $branch
    commit_message = $commitMessage
    actions        = $actions
} | ConvertTo-Json -Depth 10

# Send single commit request
Invoke-RestMethod -Uri $api_url `
    -Headers @{ "PRIVATE-TOKEN" = $privateToken } `
    -Method Post `
    -Body $payload `
    -ContentType "application/json" `
    -ErrorAction Stop

Write-Host "Backup completed successfully for all CSV files in a single commit on branch: $branch"
