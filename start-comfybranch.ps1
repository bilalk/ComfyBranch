$ErrorActionPreference = "Continue"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Port = if ($env:COMFYBRANCH_PORT) { $env:COMFYBRANCH_PORT } else { "8788" }
$Python = Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"
$Server = Join-Path $Root "server.py"
$OutLog = Join-Path $Root "comfybranch.out.log"
$ErrLog = Join-Path $Root "comfybranch.err.log"

if (-not (Test-Path -LiteralPath $Python)) { $Python = "python" }

Write-Host "Stopping old COMFYBranch server processes..."
$current = $PID
Get-CimInstance Win32_Process |
  Where-Object { $_.ProcessId -ne $current -and $_.CommandLine -like "*COMFYBranch*" -and $_.CommandLine -like "*server.py*" } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Remove-Item -LiteralPath $OutLog,$ErrLog -Force -ErrorAction SilentlyContinue
$env:COMFYBRANCH_PORT = $Port

$proc = Start-Process -FilePath $Python `
  -ArgumentList @($Server) `
  -WorkingDirectory $Root `
  -RedirectStandardOutput $OutLog `
  -RedirectStandardError $ErrLog `
  -PassThru `
  -WindowStyle Minimized

Start-Sleep -Seconds 2

try {
  Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/health" -TimeoutSec 5 | Out-Null
  Write-Host "COMFYBranch running: http://127.0.0.1:$Port"
  Write-Host "PID: $($proc.Id)"
  Start-Process "http://127.0.0.1:$Port"
}
catch {
  Write-Host "FAILED to start COMFYBranch."
  Write-Host $_.Exception.Message
  if (Test-Path -LiteralPath $OutLog) { Write-Host "--- comfybranch.out.log ---"; Get-Content -LiteralPath $OutLog -Tail 100 }
  if (Test-Path -LiteralPath $ErrLog) { Write-Host "--- comfybranch.err.log ---"; Get-Content -LiteralPath $ErrLog -Tail 100 }
  exit 1
}