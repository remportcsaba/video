param(
  [Parameter(Mandatory=$true)][string]$YtDlp,
  [Parameter(Mandatory=$true)][string]$Url,
  [Parameter(Mandatory=$true)][string]$OutDir,
  [Parameter(Mandatory=$true)][int]$Minutes,
  [string]$ExtraFlags = ""
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $YtDlp)) { Write-Host "[HIBA] Nincs yt-dlp.exe: $YtDlp"; exit 1 }
if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

if ($Minutes -lt 1) { $Minutes = 1 }

Write-Host "[info] LIVE rogzites ELEJETOL idokorlattal"
Write-Host "       Limit: $Minutes perc"
Write-Host "       SPACE = start, CTRL+P = stop"
Write-Host ""

Write-Host -NoNewline "Nyomj SPACE-t az inditashoz..."
while ($true) {
  $k = [Console]::ReadKey($true)
  if ($k.Key -eq [ConsoleKey]::Spacebar) { break }
}
Write-Host " OK`n"

$outTpl  = Join-Path $OutDir ("LIVE_LIMIT_" + $Minutes + "m_%(title)s_%(id)s.%(ext)s")
$logPath = Join-Path $OutDir ("live_limit_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

$argsArr = @("--newline","--no-part","--no-warnings","--live-from-start")

if ($ExtraFlags -and $ExtraFlags.Trim().Length -gt 0) {
  $extra = [System.Management.Automation.PSParser]::Tokenize($ExtraFlags, [ref]$null) |
           Where-Object { $_.Type -in @('CommandArgument','Command') } |
           ForEach-Object { $_.Content }
  if ($extra) { $argsArr += $extra }
}

$argsArr += @("-o", $outTpl, $Url)

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $YtDlp
$psi.WorkingDirectory = Split-Path $YtDlp -Parent
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.Arguments = ($argsArr | ForEach-Object { if ($_ -match '\s') { '"' + ($_ -replace '"','\"') + '"' } else { $_ } }) -join " "

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$null = $proc.Start()

$stdout = New-Object System.IO.StreamWriter($logPath, $true, [System.Text.Encoding]::UTF8)
$stdout.AutoFlush = $true
$proc.BeginOutputReadLine(); $proc.BeginErrorReadLine()
$handler = [System.Diagnostics.DataReceivedEventHandler]{ param($s,$e) if ($e.Data) { $stdout.WriteLine($e.Data) } }
$proc.add_OutputDataReceived($handler); $proc.add_ErrorDataReceived($handler)

$limitMs = $Minutes * 60 * 1000

Write-Host "Felvetel fut... (CTRL+P stop)  Log: $logPath"
Write-Host ""

try {
  while (-not $proc.HasExited) {
    $ts = [TimeSpan]::FromMilliseconds($sw.ElapsedMilliseconds)
    $mm = [Math]::Floor($ts.TotalMinutes); $ss = $ts.Seconds
    $leftMs = [Math]::Max(0, $limitMs - $sw.ElapsedMilliseconds)
    $left = [TimeSpan]::FromMilliseconds($leftMs)
    Write-Host -NoNewline ("`rRogzites: {0:00}:{1:00}  Hatral: {2:00}:{3:00}   CTRL+P=stop      " -f $mm,$ss,$left.Minutes,$left.Seconds)

    if ($sw.ElapsedMilliseconds -ge $limitMs) {
      Write-Host "`n[info] Limit elerve ($Minutes perc). Megallitas..."
      if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
      break
    }

    if ([Console]::KeyAvailable) {
      $k = [Console]::ReadKey($true)
      if ($k.Key -eq [ConsoleKey]::P -and ($k.Modifiers -band [ConsoleModifiers]::Control)) {
        Write-Host "`n[info] Megallitas..."
        if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
        break
      }
    }

    Start-Sleep -Milliseconds 150
  }
} finally {
  $sw.Stop()
  Start-Sleep -Milliseconds 200
  $stdout.Dispose()
}

Write-Host "`nKesz. Mentve: $OutDir"
