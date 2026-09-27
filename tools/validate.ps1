[CmdletBinding()]
param(
    [string]$Python = 'python',
    [switch]$Upstream
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $PSScriptRoot 'run_tests.py'

# No silently skipped syntax checks: the actual Lua 5.1 test runtime is required.
$testArgs = @($runner)
if ($Upstream) { $testArgs += '--upstream' }
& $Python @testArgs
if ($LASTEXITCODE) { throw 'Lua 5.1 validation or regression tests failed.' }

Push-Location $projectRoot
try {
    & git diff --check
    if ($LASTEXITCODE) { throw 'Git whitespace validation failed.' }
} finally {
    Pop-Location
}
Write-Host 'Validation passed: Lua 5.1, behavior tests, MCM/XML, unlocalizer, and Git whitespace.'
