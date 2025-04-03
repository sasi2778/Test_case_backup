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

# Build a list of actions (create or update based on GitLab check)
$actions = @()

Get-ChildItem -Path . -Filter "*.csv" | ForEach-Object {
    $filePath = $_.Name
    $fileContent = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($_.FullName))

    # Check if the file already exists in GitLab
    $checkUrl = "https://gitlab.com/api/v4/projects/68429798/repository/files/$([uri]::EscapeDataString($filePath))?ref=$branch"
    try {
        Invoke-RestMethod -Uri $checkUrl -Headers @{ "PRIVATE-TOKEN" = $privateToken } -Method Get -ErrorAction Stop
        $actionType = "update"
        Write-Host "File exists in GitLab. Will update: $filePath"
    } catch {
        $actionType = "create"
        Write-Host "File not found in GitLab. Will create: $filePath"
    }

    $actions += @{
        action     = $actionType
        file_path = $filePath
        content    = $fileContent
    }
}

# Build final payload
$payload = @{
    branch         = $branch
    commit_message = $commitMessage
    actions        = $actions
} | ConvertTo-Json -Depth 10

# Send the commit request
Invoke-RestMethod -Uri $api_url `
    -Headers @{ "PRIVATE-TOKEN" = $privateToken } `
    -Method Post `
    -Body $payload `
    -ContentType "application/json" `
    -ErrorAction Stop

Write-Host "Backup completed: existing files updated, new files created on branch: $branch"
