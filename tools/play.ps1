# Play STARWARD in text mode, one command per call.
# Usage:  .\tools\play.ps1 <save.json> <command> [args]
# Example: .\tools\play.ps1 C:\temp\run1.json new navy 42
param([Parameter(Mandatory = $true)][string]$Save, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Command)
$godot = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "Godot_v*_console.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
$project = Split-Path -Parent $PSScriptRoot
& $godot --headless --path $project res://tools/agent_play.tscn -- $Save @Command 2>&1 |
	Where-Object { $_ -notmatch '^(Godot Engine|\s*$)' -and $_ -notmatch '^\[Platform\]' } |
	ForEach-Object { "$_" }
