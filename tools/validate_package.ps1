[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

if (Test-Path -LiteralPath (Join-Path $root '.gitmodules')) {
    $failures.Add('Git submodule configuration is still present.')
}

$gitlinks = @(git -C $root ls-files --stage | Where-Object { $_ -match '^160000 ' })
if ($gitlinks.Count -ne 0) {
    $failures.Add("Gitlink entries remain: $($gitlinks.Count)")
}

$lock = Get-Content -LiteralPath (Join-Path $root 'dependencies.lock.json') -Raw |
    ConvertFrom-Json
if ($lock.package_mode -ne 'temporary_vendored') {
    $failures.Add('Dependency lock is not in temporary_vendored mode.')
}

$presetLines = Get-Content -LiteralPath (Join-Path $root $lock.preset)
$techniqueLine = $presetLines | Where-Object { $_ -match '^Techniques=' } |
    Select-Object -First 1
$techniques = @(($techniqueLine -replace '^Techniques=', '') -split ',' |
    Where-Object { $_ })
$effectNames = @($techniques | ForEach-Object { ($_ -split '@', 2)[1] } |
    Sort-Object -Unique)

if ($techniques.Count -ne 14) {
    $failures.Add("Expected 14 techniques; found $($techniques.Count).")
}
if ($effectNames.Count -ne 13) {
    $failures.Add("Expected 13 unique effect files; found $($effectNames.Count).")
}

$shaderRoot = Join-Path $root 'reshade-shaders\Shaders'
$allShaderFiles = @(Get-ChildItem -LiteralPath $shaderRoot -Recurse -File)
$selected = @{}
foreach ($effectName in $effectNames) {
    $matches = @($allShaderFiles | Where-Object { $_.Name -eq $effectName })
    if ($matches.Count -ne 1) {
        $failures.Add("Effect resolution count $($matches.Count): $effectName")
    }
    else {
        $selected[$effectName] = $matches[0].FullName
    }
}

foreach ($entry in $techniques) {
    $parts = $entry -split '@', 2
    $technique = $parts[0]
    $effectName = $parts[1]
    if ($selected.ContainsKey($effectName)) {
        $source = Get-Content -LiteralPath $selected[$effectName] -Raw
        $pattern = '(?m)^\s*technique\s+' + [regex]::Escape($technique) + '\b'
        if ($source -notmatch $pattern) {
            $failures.Add("Technique $technique is absent from $effectName.")
        }
    }
}

$visited = @{}
$queue = [Collections.Generic.Queue[string]]::new()
foreach ($path in $selected.Values) {
    $queue.Enqueue($path)
}

while ($queue.Count -gt 0) {
    $file = [IO.Path]::GetFullPath($queue.Dequeue())
    if ($visited.ContainsKey($file)) {
        continue
    }
    $visited[$file] = $true
    $directory = Split-Path -Parent $file
    $source = Get-Content -LiteralPath $file -Raw
    foreach ($match in [regex]::Matches($source, '(?m)^\s*#\s*include\s+"([^"]+)"')) {
        $include = $match.Groups[1].Value
        if ($include -eq 'ReShade.fxh') {
            continue
        }
        $candidate = [IO.Path]::GetFullPath(
            (Join-Path $directory ($include -replace '/', '\'))
        )
        if (Test-Path -LiteralPath $candidate) {
            $queue.Enqueue($candidate)
            continue
        }
        $alternates = @($allShaderFiles | Where-Object {
            $_.Name -eq [IO.Path]::GetFileName($include)
        })
        if ($alternates.Count -eq 1) {
            $queue.Enqueue($alternates[0].FullName)
        }
        else {
            $relative = $file.Substring($root.Length + 1)
            $failures.Add("Unresolved include $include from $relative.")
        }
    }
}

if ($visited.Count -ne 108) {
    $failures.Add("Expected a 108-file shader closure; traversed $($visited.Count).")
}

$vendorRoot = Join-Path $shaderRoot 'vendor'
$vendorFiles = @(Get-ChildItem -LiteralPath $vendorRoot -Recurse -File)
$manifestPath = Join-Path $root 'VENDORED_SHA256SUMS.txt'
$manifestLines = @(Get-Content -LiteralPath $manifestPath)
if ($vendorFiles.Count -ne 104 -or $manifestLines.Count -ne 104) {
    $failures.Add(
        "Expected 104 vendored files and manifest entries; found $($vendorFiles.Count) files and $($manifestLines.Count) entries."
    )
}

$manifestPaths = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
foreach ($line in $manifestLines) {
    if ($line -notmatch '^([0-9A-F]{64})  (.+)$') {
        $failures.Add("Malformed vendored manifest line: $line")
        continue
    }
    $expected = $Matches[1]
    $relative = $Matches[2]
    [void]$manifestPaths.Add($relative)
    $path = Join-Path $root ($relative -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing vendored file: $relative")
        continue
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($actual -ne $expected) {
        $failures.Add("Vendored hash mismatch: $relative")
    }
}

foreach ($file in $vendorFiles) {
    $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
    if (-not $manifestPaths.Contains($relative)) {
        $failures.Add("Vendored file absent from manifest: $relative")
    }
}

foreach ($file in $lock.direct_sources) {
    $path = Join-Path $root ($file.path -replace '/', '\')
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($actual -ne $file.sha256) {
        $failures.Add("Direct-source hash mismatch: $($file.path)")
    }
}

if ($failures.Count -ne 0) {
    foreach ($failure in $failures) {
        "FAIL|$failure"
    }
    "SUMMARY|failed=$($failures.Count)"
    exit 1
}

"PASS|package_mode=temporary_vendored"
"PASS|techniques=$($techniques.Count)|effects=$($effectNames.Count)"
"PASS|shader_closure=$($visited.Count)|external=ReShade.fxh"
"PASS|vendored_files=$($vendorFiles.Count)|manifest_entries=$($manifestLines.Count)"
"PASS|git_submodules=0"
"SUMMARY|passed=5|failed=0"
