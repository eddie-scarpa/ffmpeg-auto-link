# JunctionWatcher (ffmpeg-auto-link)

**Purpose:** Maintains static Directory Junctions for WinGet portable packages to prevent broken paths during version updates.

## 📋 Prerequisites
* **yt-dlp**, **yt-dlp.FFmpeg**, and **Gyan.FFmpeg** must be installed via **WinGet** (or UniGetUI) for the base paths to exist.

## 📂 Script Placement
Store the script at:
* `C:\Scripts\JunctionWatcher.ps1`

## ⚙️ Setup Environment
Add this static path to your **System PATH**:
* `C:\ffmpeg` 

## 📅 Scheduled Task (Persistence)
To run silently at every logon:

1. **Create Task**: Name it `JunctionWatcher`.
2. **Security**: Check `Run with highest privileges` & `Hidden`.
3. **Trigger**: `At log on`.
4. **Action**: `Start a program`
   * **Program**: `powershell.exe`
   * **Arguments**: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Scripts\JunctionWatcher.ps1"`
5. **Conditions**: Uncheck `Start only if on AC power`.

## ✅ Verification
Verify junctions and targets:
```powershell
Get-Item C:\ffmpeg, C:\yt-dlp-bin, C:\ffmpeg-ytdlp | Select-Object Name, LinkTarget