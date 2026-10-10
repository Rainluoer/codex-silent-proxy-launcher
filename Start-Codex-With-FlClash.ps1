$ErrorActionPreference = 'Stop'

try {
    $package = Get-AppxPackage -Name OpenAI.Codex |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if (-not $package) {
        throw 'Codex Desktop is not installed.'
    }

    $packageRoot = $package.InstallLocation.TrimEnd('\') + '\'
    $existingProcesses = @(Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Path -and $_.Path.StartsWith($packageRoot, [StringComparison]::OrdinalIgnoreCase)
        })
    if ($existingProcesses.Count -gt 0) {
        exit 0
    }

    $proxyPort = 7890
    $settingsPath = Join-Path $PSScriptRoot 'settings.json'
    if (Test-Path -LiteralPath $settingsPath) {
        $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
        $proxyPort = [int]$settings.ProxyPort
        if ($proxyPort -lt 1 -or $proxyPort -gt 65535) {
            throw 'ProxyPort must be between 1 and 65535.'
        }
    }

    $proxyClient = New-Object Net.Sockets.TcpClient
    try {
        $connection = $proxyClient.ConnectAsync('127.0.0.1', $proxyPort)
        if (-not $connection.Wait(2000) -or -not $proxyClient.Connected) {
            throw "Start your proxy client first. The local proxy must listen on port $proxyPort."
        }
    }
    finally {
        $proxyClient.Dispose()
    }

    [xml]$manifest = Get-Content -LiteralPath (Join-Path $package.InstallLocation 'AppxManifest.xml') -Raw
    $application = @($manifest.Package.Applications.Application) |
        Where-Object { $_.Id -eq 'App' } |
        Select-Object -First 1
    $executable = if ($application -and $application.Executable) {
        Join-Path $package.InstallLocation ([string]$application.Executable)
    } else {
        Join-Path $package.InstallLocation 'app\ChatGPT.exe'
    }
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw 'The Codex Desktop executable could not be found.'
    }

    # Only this launcher and its child processes inherit these proxy values.
    $env:HTTP_PROXY = "http://127.0.0.1:$proxyPort"
    $env:HTTPS_PROXY = "http://127.0.0.1:$proxyPort"
    Start-Process -FilePath $executable -WorkingDirectory (Split-Path -Parent $executable)
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
