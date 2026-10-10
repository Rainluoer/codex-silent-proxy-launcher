$ErrorActionPreference = 'Stop'

try {
    $installRoot = [IO.Path]::GetFullPath($PSScriptRoot)
    $settingsPath = Join-Path $installRoot 'settings.json'
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        throw 'Run Uninstall.cmd from the installed launcher directory.'
    }
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $shortcutName = [string]$settings.ShortcutName
    if ([IO.Path]::GetFileName($shortcutName) -ne $shortcutName -or
        $shortcutName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or
        [string]::IsNullOrWhiteSpace($shortcutName)) {
        throw 'Invalid shortcut name in settings.json.'
    }

    $shortcutPath = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) ($shortcutName + '.lnk')
    if (Test-Path -LiteralPath $shortcutPath) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $scriptHost = Join-Path $env:SystemRoot 'System32\wscript.exe'
        $launcherPath = Join-Path $installRoot 'Start-Codex-With-FlClash.vbs'
        $expectedArguments = '//B //NoLogo "' + $launcherPath + '"'
        if ($shortcut.TargetPath -eq $scriptHost -and $shortcut.Arguments -eq $expectedArguments) {
            Remove-Item -LiteralPath $shortcutPath -Force
        }
    }

    # Delete only owned files; preserve any other files placed in the directory.
    $files = @('Start-Codex-With-FlClash.ps1', 'Start-Codex-With-FlClash.vbs',
        'Start-Codex-With-FlClash.cmd', 'ChatGPT.ico', 'settings.json',
        'README.md', 'LICENSE', 'Uninstall.cmd', 'Uninstall.ps1')
    foreach ($file in $files) {
        $path = [IO.Path]::GetFullPath((Join-Path $installRoot $file))
        if (-not $path.StartsWith($installRoot.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Uninstall path escaped the installation directory.'
        }
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    Write-Host 'Launcher files and its desktop shortcut have been removed.'
    Write-Host 'The original Codex application and your proxy settings are preserved.'
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
