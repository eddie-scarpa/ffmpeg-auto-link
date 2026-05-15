# JunctionWatcher (ffmpeg-auto-link)

**Purpose:** Maintains static Directory Junctions for WinGet portable packages to prevent broken paths during version updates.

## 📋 Prerequisites
* **yt-dlp**, **yt-dlp.FFmpeg**, and **Gyan.FFmpeg** must be installed via **WinGet** (or UniGetUI) for the base paths to exist.
* **PowerShell 7** (installed via Microsoft Store or MSI).

## 📂 Script Placement
Store the script at:
* `C:\scripts\junction-watcher.ps1`

## ⚙️ Setup Environment
Add this static path to your **System PATH**:
* `C:\ffmpeg` 

## 📅 Scheduled Task (Persistence)
To ensure the watcher runs silently at every logon and survives PowerShell version updates, configure the task as follows:

1. **Create Task**: Name it `JunctionWatcher`.
2. **Description**: Copy and paste the following into the Description field:
   > Automated self-healing junction monitor for yt-dlp and FFmpeg. This task runs a persistent background watcher that detects version updates from UniGetUI/WinGet and instantly re-links C:\ffmpeg and C:\yt-dlp-bin to the latest binaries, ensuring zero downtime for media interfaces.
3. **Security Options**: 
   * Select `Run only when user is logged on`.
   * Check `Run with highest privileges`.
   * Check `Hidden`.
4. **Trigger**: `At log on` (for your specific user).
5. **Action**: `Start a program`
   * **Program/script**: `%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe`
   * **Add arguments**: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\scripts\junction-watcher.ps1"`
   * **Start in**: `C:\scripts`
6. **Conditions**: Uncheck `Start only if the computer is on AC power`.
7. **Settings**: 
   * Check `Allow task to be run on demand`.
   * Check `If the running task does not end when requested, force it to stop`.

## ✅ Verification
Verify that the junctions are active and pointing to the latest versioned folders:
```powershell
Get-Item C:\ffmpeg, C:\yt-dlp-bin, C:\ffmpeg-ytdlp | Select-Object Name, LinkTarget