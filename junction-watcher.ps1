# JunctionWatcher.ps1
# Purpose: Monitors WinGet package folders and maintains static Junction links.

# --- CONFIGURATION ---
$ffBase   = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\yt-dlp.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
$ytBase   = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\yt-dlp.yt-dlp_Microsoft.Winget.Source_8wekyb3d8bbwe"
$gyanBase = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"

# --- CORE FUNCTIONS (Global Scope) ---
function global:Set-Junction ($Path, $Target) {
    if (Test-Path $Path) {
        $item = Get-Item $Path
        # Skip if already linked to the correct target
        if ($item.Attributes -match "ReparsePoint" -and $item.Target -eq $Target) { return }
        Remove-Item $Path -Force -Recurse
    }
    New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Linked $Path ---> $Target" -ForegroundColor Green
}

function global:Sync-All {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Syncing junctions..." -ForegroundColor Cyan

    # 1. Master Global FFmpeg (Gyan)
    if (Test-Path $gyanBase) {
        $gyanVer = Get-ChildItem $gyanBase -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($gyanVer) { 
            $binPath = Join-Path $gyanVer.FullName "bin"
            $target = if (Test-Path $binPath) { $binPath } else { $gyanVer.FullName }
            Set-Junction "C:\ffmpeg" $target 
        }
    }

    # 2. Specialized yt-dlp FFmpeg
    if (Test-Path $ffBase) {
        $ffVer = Get-ChildItem $ffBase -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($ffVer) { 
            $binPath = Join-Path $ffVer.FullName "bin"
            $target = if (Test-Path $binPath) { $binPath } else { $ffVer.FullName }
            Set-Junction "C:\ffmpeg-ytdlp" $target 
        }
    }

    # 3. yt-dlp Binaries
    if (Test-Path $ytBase) {
        $ytVer = Get-ChildItem $ytBase -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($ytVer) { 
            Set-Junction "C:\yt-dlp-bin" $ytVer.FullName 
        } else { 
            Set-Junction "C:\yt-dlp-bin" $ytBase 
        }
    }
}

# --- WATCHER LOGIC ---
$action = { 
    # 5-second delay ensures WinGet finishes disk operations & releases handles
    Start-Sleep -Seconds 5
    Sync-All 
}

$watchList = @($ffBase, $ytBase, $gyanBase)
$eventTypes = @("Created", "Deleted", "Renamed")

try {
    # Initial Sync on Start
    Sync-All 

    foreach ($folder in $watchList) {
        if (Test-Path $folder) {
            $watcher = New-Object System.IO.FileSystemWatcher $folder
            $watcher.IncludeSubdirectories = $false
            $watcher.NotifyFilter = [System.IO.NotifyFilters]::DirectoryName
            $watcher.EnableRaisingEvents = $true

            foreach ($event in $eventTypes) {
                Register-ObjectEvent -InputObject $watcher -EventName $event -Action $action | Out-Null
            }
        }
    }

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Watcher active. Monitoring WinGet packages..." -ForegroundColor Gray
    
    while ($true) { 
        # Keep process alive and visible to Task Scheduler
        Wait-Event -Timeout 3600 | Out-Null 
    }
}
finally {
    # Cleanup on exit
    Get-EventSubscriber | Unregister-Event -ErrorAction SilentlyContinue
    Write-Host "Watcher stopped. Cleanup complete." -ForegroundColor Yellow
}