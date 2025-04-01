# Exit if any command fails
$ErrorActionPreference = "Stop"

# Static Variables
$RepoURL = "https://gitlab.com" # GitLab Base URL
$CommitMessage = "Backup for Nectar $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$CsvDir = "C:\CsvTest"
committee $PrivateToken = "Nectar_backup"
$Branch = "test-case-data-dev"
$ProjectID = 2778

# Navigate to the CSV directory
Set-Location -Path $CsvDir

# Authenticate API Header
$Headers = @{ "PRIVATE-TOKEN" = $PrivateToken }

# Loop through all .csv files
Get-ChildItem -Path . -Filter "*.csv" | ForEach-Object {
    $FilePath = $_.FullName
    $FileName = $_.Name

    # URL-encode the file name for the API request
    $EncodedFileName = [System.Web.HttpUtility]::UrlEncode($FileName)

    # Check if the file exists in the GitLab repository (via GET request)
    $CheckUrl = "$RepoURL/api/v4/projects/$ProjectID/repository/files/$EncodedFileName`?ref=$Branch"
    Write-Host "Checking URL: $CheckUrl"
    try {
        $Response = Invoke-RestMethod -Headers $Headers -Uri $CheckUrl -Method Get
    } catch {
        Write-Host "Error checking file existence: $_"
        $Response = $null
    }

    # Rename the file if it already exists in the repository
    $FileName = if ($Response -and $Response.file_path) {
        "new_" + $FileName
    } else {
        $FileName
    }

    # Determine Action
    $Action = if ($Response -and $Response.file_path) { "update" } else { "create" }
    Write-Host "$Action file: $FileName"

    # Commit the file to the repository
    $CommitUrl = "$RepoURL/api/v4/projects/$ProjectID/repository/commits"
    Invoke-RestMethod -Uri $CommitUrl `
        -Method Post `
        -Headers $Headers `
        -Body @{
            "branch" = $Branch
            "commit_message" = $CommitMessage
            "actions[0][action]" = $Action
            "actions[0][file_path]" = $FileName
            "actions[0][content]" = [System.IO.File]::ReadAllText($FilePath)
        }
}

Write-Host "Backup completed successfully for all CSV files on branch: $Branch"