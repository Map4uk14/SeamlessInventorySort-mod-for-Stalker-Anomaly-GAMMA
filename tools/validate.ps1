[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $projectRoot 'gamedata/scripts/zz_seamless_inventory_sort.script'
$mcmPath = Join-Path $projectRoot 'gamedata/scripts/zz_seamless_inventory_sort_mcm.script'
$xmlPath = Join-Path $projectRoot 'gamedata/configs/text/eng/ui_mcm_seamless_sort.xml'

$main = Get-Content -Raw -LiteralPath $mainPath
$mcm = Get-Content -Raw -LiteralPath $mcmPath
$xmlText = Get-Content -Raw -LiteralPath $xmlPath

# XML must be well formed before the game tries to load the string table.
[void][xml]$xmlText

# Keep runtime defaults and MCM controls in lockstep.
$defBlock = [regex]::Match(
    $main,
    'local DEF = \{(?<body>.*?)\r?\n\}',
    [Text.RegularExpressions.RegexOptions]::Singleline
).Groups['body'].Value

$defIds = @(
    [regex]::Matches(
        $defBlock,
        '^\s*([a-z][a-z0-9_]*)\s*=',
        [Text.RegularExpressions.RegexOptions]::Multiline
    ) | ForEach-Object { $_.Groups[1].Value }
)
$mcmIds = @(
    [regex]::Matches(
        $mcm,
        '\{\s*id\s*=\s*"([a-z][a-z0-9_]*)"\s*,\s*type\s*=\s*"(?:check|track|list)"'
    ) | ForEach-Object { $_.Groups[1].Value }
)
$groupBlock = [regex]::Match(
    $main,
    'local OPT_GROUP = \{(?<body>.*?)\r?\n\}',
    [Text.RegularExpressions.RegexOptions]::Singleline
).Groups['body'].Value
$groupIds = @(
    [regex]::Matches($groupBlock, '([a-z][a-z0-9_]*)\s*=') |
        ForEach-Object { $_.Groups[1].Value }
)

$missingMcm = @($defIds | Where-Object { $_ -notin $mcmIds })
$missingDefault = @($mcmIds | Where-Object { $_ -notin $defIds })
$missingGroup = @($defIds | Where-Object { $_ -notin $groupIds })
$unknownGroup = @($groupIds | Where-Object { $_ -notin $defIds })
if ($missingMcm.Count -or $missingDefault.Count -or $missingGroup.Count -or $unknownGroup.Count) {
    throw "Option mismatch. Missing from MCM: [$($missingMcm -join ', ')]; missing from DEF: [$($missingDefault -join ', ')]; missing from OPT_GROUP: [$($missingGroup -join ', ')]; unknown in OPT_GROUP: [$($unknownGroup -join ', ')]"
}

# Every option needs its visible localization label and description.
$missingStrings = foreach ($id in $mcmIds) {
    $suffix = [regex]::Escape($id)
    $hasLabel = $xmlText -match ('id="ui_mcm_seamless_sort_[^"]*_' + $suffix + '"')
    $hasDescription = $xmlText -match ('id="ui_mcm_seamless_sort_[^"]*_' + $suffix + '_desc"')
    if (-not ($hasLabel -and $hasDescription)) {
        $id
    }
}
if (@($missingStrings).Count) {
    throw "Missing localization labels/descriptions: $(@($missingStrings) -join ', ')"
}

# luaparse defaults to Lua 5.1, matching Anomaly's script runtime. npx caches
# the package after the first run; an internet connection may be needed once.
$npx = Get-Command npx -ErrorAction SilentlyContinue
if ($npx) {
    & $npx.Source --yes luaparse $mainPath | Out-Null
    if ($LASTEXITCODE) { throw 'Main script failed Lua 5.1 parsing.' }
    & $npx.Source --yes luaparse $mcmPath | Out-Null
    if ($LASTEXITCODE) { throw 'MCM script failed Lua 5.1 parsing.' }
} else {
    Write-Warning 'npx not found; skipped Lua syntax parsing.'
}

Push-Location $projectRoot
try {
    & git -c "safe.directory=$($projectRoot.Replace('\', '/'))" diff --check
    if ($LASTEXITCODE) { throw 'Git whitespace validation failed.' }
} finally {
    Pop-Location
}

Write-Host "Validation passed: $($defIds.Count) options, XML, Lua 5.1 syntax, and whitespace."
