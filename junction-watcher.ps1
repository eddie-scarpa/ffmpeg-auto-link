# --- CONFIGURATION ---
# 1. yt-dlp FFmpeg (The lightweight version)
$ffBase   = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\yt-dlp.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"

# 2. yt-dlp Binaries
$ytBase   = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\yt-dlp.yt-dlp_Microsoft.Winget.Source_8wekyb3d8bbwe"

# 3. Gyan FFmpeg (The Full Master Build)
$gyanBase = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"

function Set-Junction ($Path, $Target) {
    if (Test-Path $Path) {
        $item = Get-Item $Path
        # Skip if already linked to the correct target
        if ($item.Attributes -match "ReparsePoint" -and $item.Target -eq $Target) { return }
        Remove-Item $Path -Force -Recurse
    }
    New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
    Write-Host "Linked $Path ---> $Target" -ForegroundColor Green
}

function Sync-All {
    Write-Host "Syncing junctions..." -ForegroundColor Cyan

    # --- 1. Master Global FFmpeg (Gyan) ---
    $gyanVer = Get-ChildItem $gyanBase -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($gyanVer) { 
        $binPath = Join-Path $gyanVer.FullName "bin"
        $target = if (Test-Path $binPath) { $binPath } else { $gyanVer.FullName }
        Set-Junction "C:\ffmpeg" $target 
    }

    # --- 2. Specialized yt-dlp FFmpeg ---
    $ffVer = Get-ChildItem $ffBase -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($ffVer) { 
        $binPath = Join-Path $ffVer.FullName "bin"
        $target = if (Test-Path $binPath) { $binPath } else { $ffVer.FullName }
        Set-Junction "C:\ffmpeg-ytdlp" $target 
    }

    # --- 3. yt-dlp Binaries ---
    $ytVer = Get-ChildItem $ytBase -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($ytVer) { 
        Set-Junction "C:\yt-dlp-bin" $ytVer.FullName 
    } elseif (Test-Path $ytBase) { 
        Set-Junction "C:\yt-dlp-bin" $ytBase 
    }
}

# Initial Sync
Sync-All

# --- WATCHER LOGIC ---
$action = { 
    # 2-second delay ensures WinGet finishes disk operations
    Start-Sleep -Seconds 2
    Sync-All 
}

$watchList = @($ffBase, $ytBase, $gyanBase)
$eventTypes = @("Created", "Changed", "Deleted", "Renamed")

foreach ($folder in $watchList) {
    if (Test-Path $folder) {
        $watcher = New-Object System.IO.FileSystemWatcher $folder
        $watcher.IncludeSubdirectories = $true
        $watcher.EnableRaisingEvents = $true

        foreach ($event in $eventTypes) {
            Register-ObjectEvent -InputObject $watcher -EventName $event -Action $action | Out-Null
        }
    }
}

# Keep the script alive for Task Scheduler
while ($true) { 
    Wait-Event -Timeout 3600 | Out-Null 
}