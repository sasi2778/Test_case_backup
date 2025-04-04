$ErrorActionPreference = "Stop"

# Static Variables
$api_url = "https://gitlab.com/api/v4/projects/2778/repository/commits"
$CommitMessage = "backup for 2024.2.1 $(Get-Date -Format 'yyyy-MM-dd') [skip ci]"
$CsvDir = "/Users/chandrasekharreddy.sambaiahghari/Desktop/test"
$PrivateToken = ""
$Branch = "test-case-data-dev"

# Navigate to the CSV directory
Set-Location -Path $CsvDir

# Get the list of CSV files in the GitLab repository
$treeUrl = "https://gitlab.com/api/v4/projects/2778/repository/tree?ref=$Branch&path=/"
$repoFiles = Invoke-RestMethod -Uri $treeUrl -Headers @{ "PRIVATE-TOKEN" = $PrivateToken } -Method Get
$repoCsvFiles = $repoFiles | Where-Object { $_.type -eq "blob" -and $_.name -like "*.csv" } | ForEach-Object { $_.name }

# Get the list of local CSV files
$localCsvFiles = Get-ChildItem -Path . -Filter "*.csv" | ForEach-Object { $_.Name }

# Build a list of actions
$actions = @()

# Process each local CSV file to determine "create" or "update" actions
Get-ChildItem -Path . -Filter "*.csv" | ForEach-Object {
    $filePath = $_.Name
    $fileContent = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($_.FullName))
    if ($repoCsvFiles -contains $filePath) {
        $actionType = "update"
        Write-Host "File exists in GitLab. Will update: $filePath"
    } else {
        $actionType = "create"
        Write-Host "File not found in GitLab. Will create: $filePath"
    }
    $actions += @{
        action     = $actionType
        file_path = $filePath
        content    = $fileContent
    }
}

# Identify and add "delete" actions for repo files not present locally
$filesToDelete = $repoCsvFiles | Where-Object { $_ -notin $localCsvFiles }
foreach ($file in $filesToDelete) {
    $actions += @{
        action     = "delete"
        file_path = $file
    }
    Write-Host "File not found locally. Will delete from GitLab: $file"
}

# Build and send the commit request if there are actions
if ($actions.Count -gt 0) {
    $payload = @{
        branch         = $Branch
        commit_message = $CommitMessage
        actions        = $actions
    } | ConvertTo-Json -Depth 10

    $null = Invoke-RestMethod -Uri $api_url `
        -Headers @{ "PRIVATE-TOKEN" = $PrivateToken } `
        -Method Post `
        -Body $payload `
        -ContentType "application/json" `
        -ErrorAction Stop

    Write-Host "Backup completed: files created, updated, or deleted on branch: $Branch"
} else {
    Write-Host "No changes to commit."
}
 
