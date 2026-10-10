param(
    [ValidateRange(1, 65535)]
    [int]$ProxyPort = 7890,
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'CodexSilentProxyLauncher'),
    [string]$ShortcutName = 'Codex Proxy'
)

$ErrorActionPreference = 'Stop'

try {
    if ([IO.Path]::GetFileName($ShortcutName) -ne $ShortcutName -or
        $ShortcutName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or
        [string]::IsNullOrWhiteSpace($ShortcutName)) {
        throw 'ShortcutName must be a filename without directory separators.'
    }

    $package = Get-AppxPackage -Name OpenAI.Codex |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if (-not $package) { throw 'Install Codex Desktop before installing this launcher.' }

    $scriptHost = Join-Path $env:SystemRoot 'System32\wscript.exe'
    if (-not (Test-Path -LiteralPath $scriptHost)) {
        throw 'Windows Script Host is required for silent launch.'
    }

    $InstallDirectory = [IO.Path]::GetFullPath($InstallDirectory)
    $desktop = [Environment]::GetFolderPath('DesktopDirectory')
    $shortcutPath = Join-Path $desktop ($ShortcutName + '.lnk')
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $launcherPath = Join-Path $InstallDirectory 'Start-Codex-With-FlClash.vbs'
    $expectedArguments = '//B //NoLogo "' + $launcherPath + '"'
    if ((Test-Path -LiteralPath $shortcutPath) -and
        ($shortcut.TargetPath -ne $scriptHost -or $shortcut.Arguments -ne $expectedArguments)) {
        throw "An unrelated shortcut already exists: $shortcutPath. Use a different -ShortcutName."
    }

    New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
    $files = @('Start-Codex-With-FlClash.ps1', 'Start-Codex-With-FlClash.vbs',
        'Start-Codex-With-FlClash.cmd', 'Uninstall.ps1', 'Uninstall.cmd', 'README.md', 'LICENSE')
    foreach ($file in $files) {
        $source = Join-Path $PSScriptRoot $file
        $destination = Join-Path $InstallDirectory $file
        if ([IO.Path]::GetFullPath($source) -ne [IO.Path]::GetFullPath($destination)) {
            Copy-Item -LiteralPath $source -Destination $destination -Force
        }
    }

    $iconSource = Join-Path $package.InstallLocation 'app\resources\icon-chatgpt.ico'
    $iconPath = Join-Path $InstallDirectory 'ChatGPT.ico'
    if (Test-Path -LiteralPath $iconSource) {
        Copy-Item -LiteralPath $iconSource -Destination $iconPath -Force
        $shortcut.IconLocation = $iconPath + ',0'
    } else {
        [xml]$manifest = Get-Content -LiteralPath (Join-Path $package.InstallLocation 'AppxManifest.xml') -Raw
        $application = @($manifest.Package.Applications.Application) |
            Where-Object { $_.Id -eq 'App' } | Select-Object -First 1
        $appPath = Join-Path $package.InstallLocation ([string]$application.Executable)
        Add-Type -AssemblyName System.Drawing
        $icon = [Drawing.Icon]::ExtractAssociatedIcon($appPath)
        if (-not $icon) { throw 'Could not extract the application icon.' }
        $iconStream = [IO.File]::Create($iconPath)
        try { $icon.Save($iconStream) } finally { $iconStream.Dispose(); $icon.Dispose() }
        $shortcut.IconLocation = $iconPath + ',0'
    }

    $settings = @{ ProxyPort = $ProxyPort; ShortcutName = $ShortcutName }
    [IO.File]::WriteAllText((Join-Path $InstallDirectory 'settings.json'),
        ($settings | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
    $shortcut.TargetPath = $scriptHost
    $shortcut.Arguments = $expectedArguments
    $shortcut.WorkingDirectory = $InstallDirectory
    $shortcut.WindowStyle = 1
    $shortcut.Description = "Launch Codex silently through the local HTTP proxy on port $ProxyPort."
    $shortcut.Save()

    Write-Host "Installed: $InstallDirectory"
    Write-Host "Desktop shortcut: $shortcutPath"
    Write-Host 'Keep your proxy client running. Fully quit Codex before the first proxy launch.'
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
