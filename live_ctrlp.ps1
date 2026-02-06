param(
  [Parameter(Mandatory=$true)][ValidateSet("fromstart","fromstart_limit","m3u8","liveedge","dvr_seek")][string]$Mode,
  [Parameter(Mandatory=$true)][string]$Url,
  [string]$Minutes = "30"
)

# PowerShell 5.1 safe live recorder with hotkeys:
#   SPACE  = start
#   CTRL+P = stop
$ErrorActionPreference = "Stop"

# ASCII-only messages to avoid encoding issues in cmd
function Say([string]$s) { Write-Host $s }

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$ytdlp = Join-Path $root "yt-dlp.exe"
if (!(Test-Path $ytdlp)) {
  Write-Host "ERROR: yt-dlp.exe not found in: $root" -ForegroundColor Red
  exit 1
}

$outDir = Join-Path $root "letoltesek"
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# Detect supported options (older yt-dlp builds may not have newer flags)
$help = ""
try { $help = (& $ytdlp --help 2>$null | Out-String) } catch { $help = "" }

# Build common options (SLOW but stable)
$common = @(
  "--retries","10",
  "--fragment-retries","10",
  "--sleep-interval","2",
  "--retry-sleep","5",
  "--concurrent-fragments","1",
  "--no-part"
)

if ($help -match "--cookies-from-browser") {
  $common += @("--cookies-from-browser","firefox")
}

# Output template
$outTpl = Join-Path $outDir "%(title)s.%(ext)s"

function Wait-ForSpace {
  Say ""
  Write-Host "WAIT... press SPACE to start." -ForegroundColor Green
  while ($true) {
    if ([Console]::KeyAvailable) {
      $k = [Console]::ReadKey($true)
      if ($k.Key -eq "Spacebar") { return }
    }
    Start-Sleep -Milliseconds 50
  }
}

function Quote-Arg([string]$a) {
  if ($a -match '[\s"]') {
    return '"' + ($a -replace '"','\"') + '"'
  }
  return $a
}

function Start-YTDLP([string[]]$ytArgs) {
  $clean = @()
  foreach ($a in $ytArgs) {
    if ($null -ne $a -and $a -ne "") { $clean += $a }
  }
  if ($clean.Count -lt 1) { throw "Internal error: empty argument list" }

  $argLine = ($clean | ForEach-Object { Quote-Arg $_ }) -join " "
  return (Start-Process -FilePath $ytdlp -ArgumentList $argLine -NoNewWindow -PassThru)
}

function Stop-Proc([System.Diagnostics.Process]$p) {
  if ($null -eq $p) { return }
  try {
    if (!$p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
  } catch {}
}

function Wait-ForStopOrTimeout([System.Diagnostics.Process]$p, [int]$maxSeconds) {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  Write-Host ("RECORDING (PID={0}). CTRL+P = STOP" -f $p.Id) -ForegroundColor Cyan

  while ($true) {
    if ($p.HasExited) { break }

    if ([Console]::KeyAvailable) {
      $k = [Console]::ReadKey($true)
      if ($k.Modifiers -band [ConsoleModifiers]::Control -and $k.Key -eq "P") {
        Write-Host "STOP requested (CTRL+P)..." -ForegroundColor Yellow
        Stop-Proc $p
        break
      }
    }

    if ($maxSeconds -gt 0 -and $sw.Elapsed.TotalSeconds -ge $maxSeconds) {
      Write-Host "TIME LIMIT reached. Stopping..." -ForegroundColor Yellow
      Stop-Proc $p
      break
    }

    Start-Sleep -Milliseconds 80
  }
}

# --- MODE HANDLERS ---
switch ($Mode) {
  "liveedge" {
    Write-Host "[9] LIVE record from NOW (live edge)" -ForegroundColor Cyan
    Write-Host "SPACE=start, CTRL+P=stop" -ForegroundColor Cyan
    Write-Host "OUT: $outDir" -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Cyan
    Wait-ForSpace

    $ytArgs = @()
    $ytArgs += $common
    $ytArgs += @("-o", $outTpl, $Url)

    $p = Start-YTDLP $ytArgs
    Wait-ForStopOrTimeout $p 0
  }

  "fromstart" {
    Write-Host "[6] LIVE record from START (DVR)" -ForegroundColor Cyan
    Write-Host "SPACE=start, CTRL+P=stop" -ForegroundColor Cyan
    Write-Host "OUT: $outDir" -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Cyan
    Wait-ForSpace

    $ytArgs = @()
    $ytArgs += $common
    $ytArgs += @("--live-from-start","-o", $outTpl, $Url)

    $p = Start-YTDLP $ytArgs
    Wait-ForStopOrTimeout $p 0
  }

  "fromstart_limit" {
    $sec = 0
    try { $sec = [int]$Minutes * 60 } catch { $sec = 1800 }
    Write-Host "[7] LIVE record from START with LIMIT" -ForegroundColor Cyan
    Write-Host ("SPACE=start, CTRL+P=stop, LIMIT={0} min" -f $Minutes) -ForegroundColor Cyan
    Write-Host "OUT: $outDir" -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Cyan
    Wait-ForSpace

    $ytArgs = @()
    $ytArgs += $common
    $ytArgs += @("--live-from-start","-o", $outTpl, $Url)

    $p = Start-YTDLP $ytArgs
    Wait-ForStopOrTimeout $p $sec
  }

  "m3u8" {
    Write-Host "[8] M3U8 record (live or VOD)" -ForegroundColor Cyan
    Write-Host "SPACE=start, CTRL+P=stop" -ForegroundColor Cyan
    Write-Host "OUT: $outDir" -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Cyan
    Wait-ForSpace

    $ytArgs = @()
    $ytArgs += $common
    $ytArgs += @("--hls-use-mpegts","-o", $outTpl, $Url)

    $p = Start-YTDLP $ytArgs
    Wait-ForStopOrTimeout $p 0
  }

  "dvr_seek" {
    Write-Host "[10] DVR record from t= position (YouTube URL with t=...)" -ForegroundColor Cyan
    Write-Host "SPACE=start, CTRL+P=stop" -ForegroundColor Cyan
    Write-Host "OUT: $outDir" -ForegroundColor Cyan
    Write-Host "URL: $Url" -ForegroundColor Cyan
    Wait-ForSpace

    $ytArgs = @()
    $ytArgs += $common
    $ytArgs += @("--live-from-start","-o", $outTpl, $Url)

    $p = Start-YTDLP $ytArgs
    Wait-ForStopOrTimeout $p 0
  }
}
