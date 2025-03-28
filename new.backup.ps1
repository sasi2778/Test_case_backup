# Exit if any command fails
$ErrorActionPreference = "Stop"

# Static Variables
$RepoURL = "https://gitlab.com/sasi.uhuk/nectar-backup" # GitLab repository URL (base URL)
$PrivateToken = "Nectar_backup" # GitLab personal access token
$Branch = "test-case-data-dev" # Branch to restore from (can be changed to test-case-data-live if needed)
$ProjectID = 68429798 # GitLab project ID
$RestoreDir = "C:\RestoredCsv" # Directory to restore the CSV files to

# Create the restore directory if it doesn't exist
if (-not (Test-Path -Path $RestoreDir)) {
    New-Item -ItemType Directory -Path $RestoreDir | Out-Null
    Write-Host "Created restore directory: $RestoreDir"
}

# Navigate to the restore directory
Set-Location -Path $RestoreDir

# Get the list of files in the repository for the specified branch
$FilesApiUrl = "$RepoURL/api/v4/projects/$ProjectID/repository/tree?ref=$Branch"
$FilesResponse = Invoke-RestMethod -Headers @{ "PRIVATE-TOKEN" = $PrivateToken } -Uri $FilesApiUrl -Method Get

# Filter for .csv files and download each one
$CsvFiles = $FilesResponse | Where-Object { $_.name -like "*.csv" }

if ($CsvFiles.Count -eq 0) {
    Write-Host "No CSV files found in the branch: $Branch"
    exit
}

foreach ($File in $CsvFiles) {
    $FileName = $File.name
    $FilePath = $File.path
    Write-Host "Downloading file: $FileName"

    # Get the raw content of the file
    $RawFileUrl = "$RepoURL/api/v4/projects/$ProjectID/repository/files/$FilePath/raw?ref=$Branch"
    $FileContent = Invoke-RestMethod -Headers @{ "PRIVATE-TOKEN" = $PrivateToken } -Uri $RawFileUrl -Method Get

    # Save the file to the restore directory
    $OutputPath = Join-Path -Path $RestoreDir -ChildPath $FileName
    $FileContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Restored $FileName to $OutputPath"
}

Write-Host "Restore completed successfully for all CSV files from branch: $Branch"