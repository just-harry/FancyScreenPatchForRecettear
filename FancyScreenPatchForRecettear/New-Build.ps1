
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

[CmdletBinding()]
Param (
	[Parameter()]
		[ValidateNotNullOrEmpty()]
			[String] $ScriptPath = (Join-Path $PSScriptRoot Install-FancyScreenPatchForRecettear.ps1),

	[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
			[String] $OutputScriptPath,

	[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
			[String] $OutputBatchFilePath
)


$OutputScript = Copy-Item -LiteralPath $ScriptPath -Destination $OutputScriptPath -PassThru -ErrorAction Stop


$UTF8 = [Text.UTF8Encoding]::new($False, $False)


$BatchHeaderLines = @(
	'@echo off'
	'start "Fancy Screen Patch for Recettear" /D "%~dp0" powershell.exe -ExecutionPolicy Bypass -NoExit -Command "' `
		+ '& ' `
		+ '{' `
			+ '[Console]::WindowHeight = [Console]::LargestWindowHeight * 4 / 5;' `
			+ '$Script = ''Install-FancyScreenPatchForRecettear.v1_0_0.FromBatchFile.ps1'';' `
			+ '$B = [IO.File]::ReadAllBytes(\"%~nx0\");' `
			+ '$O = $B[0xZZZZ .. ($B.Length - 1)];' `
			+ 'try' `
			+ '{' `
				+ '$S = [IO.File]::ReadAllBytes($Script);' `
				+ 'if ($O.Length -ne $S.Length -or -not [Linq.Enumerable]::SequenceEqual($O, $S)) ' `
				+ '{' `
					+ 'if ($Host.UI.PromptForChoice($Null, \"The contents of the file at `\"$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Script))`\" will be overwritten. Would you like to proceed?\", (''&Yes'', ''&No''), 0) -ne 0)' `
					+ '{' `
						+ 'return' `
					+ '}' `
				+ '}' `
			+ '}' `
			+ 'catch {}' `
			+ '[IO.File]::WriteAllBytes($Script, $O);' `
			+ '& (Join-Path . $Script)' `
		+ '}' `
	+ '"'
	'exit /b'
)

$BatchHeader = $BatchHeaderLines -join "`r`n"
$BatchHeader = $BatchHeader -creplace '0xZZZZ', "0x$($UTF8.GetByteCount($BatchHeader).ToString('X04'))"
$BatchHeader += ("`r`n" * $BatchHeaderLines.Count)

[IO.File]::WriteAllBytes(
	$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputBatchFilePath),
	$UTF8.GetBytes($BatchHeader) + [IO.File]::ReadAllBytes($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputScriptPath))
)

