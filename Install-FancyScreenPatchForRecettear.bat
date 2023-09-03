@echo off
start "Fancy Screen Patch for Recettear" /D "%~dp0" powershell.exe -ExecutionPolicy Bypass -NoExit -Command "& {[Console]::WindowHeight = [Console]::LargestWindowHeight * 4 / 5;$Script = 'Install-FancyScreenPatchForRecettear.v1_0_0.FromBatchFile.ps1';$B = [IO.File]::ReadAllBytes(\"%~nx0\");$O = $B[0x030E .. ($B.Length - 1)];try{$S = [IO.File]::ReadAllBytes($Script);if ($O.Length -ne $S.Length -or -not [Linq.Enumerable]::SequenceEqual($O, $S)) {if ($Host.UI.PromptForChoice($Null, \"The contents of the file at `\"$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Script))`\" will be overwritten. Would you like to proceed?\", ('&Yes', '&No'), 0) -ne 0){return}}}catch {}[IO.File]::WriteAllBytes($Script, $O);& (Join-Path . $Script)}"
exit /b



<#
	If you meant to run this script file, please right-click the file, and then select "Run with PowerShell".
#>

<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>


<#
	.Synopsis
	Used to apply the Fancy Screen Patch for Recettear to an installation of Recettear.

	.Description
	Fancy Screen Patch for Recettear is a patch for the video-game Recettear.
	The patch adds supports to Recettear for:
		* Arbitrary resolutions of aspect-ratios at-least as wide as 4:3.
		* Raising the frame-rate limit above 60-FPS, whilst retaining the game's original frame-rate of 60-FPS for game-logic.
		* Configurability for the texture-filtering algorithm used to up-scale a given category of textures.
		* Restricting the up-scaling of 2D art to integral scaling multipliers.
		* Restricting the width of the HUD to a subset of the game's width.
		* Hiding some persistent control reminders from the HUD.

	This script is used to apply the patch to an installation of Recettear.

	This script has two main modes of operation: interactive, and non-interactive. Interactive is the default mode, and non-interactive mode can be enabled via the `NonInteractive` switch.
	The interactive and non-interactive modes generally behave in the same way when given the same arguments, with two exceptions: when a value is not provided for the `SaveSettingsToConfiguration` parameter or the `DoNotInstallThirdPartyToolsByDefaultNextTime` parameter, they default to `$True` in interactive mode, and `$False` in non-interactive mode.

	When no value is provided for the `Configuration` parameter, it will be initialised from an `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder, if present.
	This is true in both interactive and non-interactive mode.
	If you want to ignore the configuration file, you can supply an empty hash-table for the `Configuration` parameter.
	See the help entry for the `Configuration` parameter for more detail.

	The `ReturnInformation` switch is useful for interacting with the more complex parameters programmatically.

	For consistency between the parameters of this script and the values set via the configuration file, every parameter that can be set via the configuration file is optional, and untyped.
	Additionally, for such parameters, explicitly supplying a value of `$Null` is treated in the same way as not specifying the parameter at all.
	The general philosophy for those parameters is that if a parameter is `$Null` or unspecified then a reasonable default is used for its value.

	.Example
	PS> Install-FancyScreenPatchForRecettear.ps1
	# Applies the patch interactively with the default settings, including the settings saved in an `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder, if present.

	.Example
	PS> Install-FancyScreenPatchForRecettear.ps1 -NonInteractive
	# Applies the patch non-interactively with the default settings, including the settings saved in an `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder, if present.

	.Example
	PS> Install-FancyScreenPatchForRecettear.ps1 -NonInteractive -Configuration @{}
	# Applies the patch non-interactively with the default settings, ignoring the settings saved in an `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder.

	.Example
	PS> Install-FancyScreenPatchForRecettear.ps1 -NonInteractive -Configuration @{} -ResolutionWidth 3840 -ResolutionHeight 2160 -FramerateLimit 160
	# Applies the patch non-interactively such that the game will use a resolution of 3840x2160, at 160 FPS, with otherwise default settings, ignoring the settings saved in an `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder.

	.Outputs
	System.Management.Automation.PSCustomObject.

	When the `ReturnInformation` parameter is `$False`, this script's returned value will contain the following entries:
		TimeTaken: [System.TimeSpan]; How long it took the script to patch the game (excluding time spent waiting for user-input in interactive mode, and time spent downloading files from the Internet).

	When the game is patched, this script's returned value will contain the following entries:
		BackupOfPatchedExecutable: [System.IO.FileInfo]; The backup made of the game's executable before it was patched.
		PatchedExecutable: [System.IO.FileInfo]; The game's patched executable.

	When post-patch operations are performed, this script's returned value will contain the following entries:
		ConfigurationChanges: [System.Management.Automation.PSCustomObject]; Details about the changes made to the game's configuration.

		The ConfigurationChanges member is structured as follows:
			ByFile: [System.Collections.Specialized.OrderedDictionary]; A hash-table keyed by the name of a configuration file that was changed, with the values being a `PSCustomObject` with two entries:
				Reset: [System.Management.Automation.PSCustomObject]; If the configuration file was not reset, this will be `$Null`, otherwise it will have two entries:
					Before: [System.Management.Automation.PSCustomObject]; The state of the configuration file before it was reset:
						Lines: [String[]]; An array of the lines of the configuration file.
					After: [System.Management.Automation.PSCustomObject]; The state of the configuration file after it was reset:
						Lines: [String[]]; An array of the lines of the configuration file.
				Changes: [System.Collections.Specialized.OrderedDictionary]; A hash-table keyed by the name of a section of the configuration file that was changed, with the values being an `OrderedDictionary` wherein each entry is keyed by the name of a setting in the configuration and the value is what that setting was changed to.
			DgVoodoo2EnabledStatusChange: [System.Boolean]; To switch between DirectX 12/11 and DirectX 9/8.1, dgVoodoo2 may be enabled or disabled, when this happens, this will be a boolean representing whether or not dgVoodoo2 is enabled or disabled. If dgVoodoo2 does not need to be enabled or disabled this will be `$Null`.
			FileNameChanges: [System.Collections.Generic.List[System.ValueTuple[System.String, System.String]]]; This is a list of two-item tuples detailing any files that were renamed. The first item of each tuple is the full path of a file before it was renamed, and the second item is the new name of the renamed file.

		When the `CheckDxWrapperConfiguration`, `CheckDgVoodoo2Configuration`, or `CheckSpecialKConfiguration` parameters are `$True`, this script's returned value will contain `DxWrapperConfiguration`, `DgVoodoo2Configuration`, or `SpecialKConfiguration` entries respectively, the values of these entries are:
			[System.Collections.Specialized.OrderedDictionary]; A hash-table keyed by the name of a section of the configuration file that was changed, with the values being an `OrderedDictionary` wherein each entry is keyed by the name of a setting in the configuration and the value is a `PSCustomObject` with two entries:
				ActualValue: [System.String]; The actual value of the configuration setting.
				ExpectedValue: [System.String]; The value of the configuration setting expected by the patch.

		When the `GetGameWindowMode` parameter is `$True`, this script's returned value will have a `GameWindowMode` member, wherein the value is a string representing the mode that the game's window is configured to use.

		When the `GetDirectXVersionToUse` parameter is `$True`, this script's returned value will have a `DirectXVersionToUse` member, wherein the value is an integer representing the version of DirectX that the game is configured to use.

		When the `GetVerticalSyncEnabled` parameter is `$True`, this script's returned value will have a `VerticalSyncEnabled` member, wherein the value is a boolean representing whether the game is configured to use vertical-sync or not.

	When the `ReturnInformation` parameter is `$True`, this script's returned value will contain the following entries:
		DetectedInstallations: An array of `PSCustomObject`s wherein each object represents an automatically detected installation of Recettear, with each object having these three entries:
			Source: A string representing the source of the installation, using the same values recognised by the `DetectedInstallationPreference` parameter.
			UIChoice: A string containing the label used for the installation source in interactive mode.
			Path: The full-path to the installation's `recettear.exe` file.
		UsingIntegral2DScaling: A boolean representing whether integral 2D scaling is being used or not.
		DrawDistanceMultiplier: A double representing the value by which the game's vanilla draw-distance for mobs and whatnot is being multiplied by.
		PartiallyResolvedEffectiveConfiguration: An `OrderedDictionary` containing the configuration that would be saved to the `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder when the `SaveSettingsToConfiguration` parameter is `$True`.
		FullyResolvedEffectiveConfiguration: An `OrderedDictionary` containing the configuration that would be used for patching the game if the `ReturnInformation` parameter were `$False`.
		RecettearExecutablePath: The full path of the `recettear.exe` file that would be patched if the `ReturnInformation` parameter were `$False`.
		BackupPath: If the `BackupPath` parameter has been supplied, its values will be mirrored here.
		ClobberedByRestoredBackupBackupPath: If the `ClobberedByRestoredBackupBackupPath` parameter has been supplied, its values will be mirrored here.
		Configuration: The configuration object that the script loaded. Either from the `Configuration` parameter or the `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder.
		ReturnInformation: `$True`.
		ConfigurableInterpolatedFloats: A collection of `PSCustomObject`s representing the interpolated floats that can be configured, each object having the following entries:
			Names: An array of strings representing the names that the interpolated float is recognised by. The first name in this array is always the canonical name for the interpolated float.
			Recommendation: The value recommended by this patch for the interpolated float.
			Synopsis: A string describing the interpolated float.
		ConfigurableTextureFilterings: A collection of `PSCustomObject`s representing the classes of textures for which the texture-filtering can be configured, each object having the following entries:
			Names: An array of strings representing the names that the class of textures is recognised by. The first name in this array is always the canonical name for the class of textures.
			Recommendation: The value recommended by this patch for the class of textures.
			Synopsis: A string describing the class of textures.

	.Parameter NonInteractive
	Controls whether the script is operating in non-interactive or interactive mode.

	.Parameter RecettearExecutablePath
	Specifies which installation of Recettear is patched, via the path of a `recettear.exe` file.

	If this is not provided, an automatically detected installation of Recettear is patched; see the help entry for the `DetectedInstallationPreference` parameter for more detail on how that operates.

	.Parameter DetectedInstallationPreference
	Specifies the precedence of automatically detected installations of Recettear over one another.

	This script can automatically detect installations of Recettear from four locations:
		`ScriptRoot`: The same folder as the script is in.
		`CurrentDirectory`: The current working directory.
		`Steam`: An installation of the game in a Steam library folder.
		`GOG.com`: An installation of the game from GOG.com.

	The precedence of those locations can be specified as an array ordered from most preferred to least preferred.
	The order those locations were documented in above is the default order.

	When the `RecettearExecutablePath` parameter is not supplied:
		In interactive mode, this is used for the order of the locations when prompting the user to select one of them.
		In non-interactive mode, the first of these installations that can be found is the installation that gets patched.

	.Parameter BackupPath
	Specifies the path to save a backup of the `recettear.exe` file to be patched to. Existing files at this path will be overwritten.

	This patch saves a backup of the `recettear.exe` file before it makes any changes to it.

	If this parameter is not provided the backup path defaults to `<game installation folder>/recettear.<game language code>.SansFancyScreenPatch.<current time in UTC as the number of hecto-nanoseconds elapsed since 0001-01-01 00:00>.exe`.

	.Parameter ClobberedByRestoredBackupBackupPath
	Specifies the path to save a backup of the `recettear.exe` file being overwritten, when restoring a backup, to. Existing files at this path will be overwritten.

	This patch can automatically restore a previously-made backup of the `recettear.exe` file, before it does this it creates a backup for the `recettear.exe` file.

	If this parameter is not provided the backup path defaults to `<game installation folder>/recettear.<game language code>.ClobberedByRestoredBackupBackupPath.<current time in UTC as the number of hecto-nanoseconds elapsed since 0001-01-01 00:00>.exe`.

	.Parameter FramerateLimit
	The controls the frame-rate that the game should run at.

	If you intend to use vertical-sync, this ideally should be one less than your screen's refresh-rate (e.g 119-FPS for a 120-Hz screen), if possible, to avoid excess latency. Otherwise, this should be the frame-rate you intend to run the game at.

	The frame-rate limit must be at-least sixty. Values greater-than one-thousand for the frame-rate limit can be used, but any adverse effects resulting from values greater-than one-thousand are unsupported.

	Whilst this patch does allow the use of frame-rates greater-than the game's native frame-rate of sixty FPS, it does not completely decouple the frame-rate from the rendering logic. The frame-rate limit set here influences how the game is interpolated to higher frame-rates, so setting this value higher than your screen's refresh-rate may have an adverse effect on the appearance of the game's motion.

	If this parameter is not provided the frame-rate limit defaults to 60 FPS.

	.Parameter ResolutionWidth
	This controls the width, in pixels, of the game's window.

	If no value is provided for the width, it defaults to 640.

	.Parameter ResolutionHeight
	This controls the height, in pixels, of the game's window.

	If no value is provided for the height, it defaults to 480.

	.Parameter HUDWidth
	This controls the width, in pixels, that the game's HUD is bounded to.

	If no value is provided for the HUD's width, it defaults to being no wider-than a 16:9 resolution of the same height as the game window's height.

	.Parameter UseIntegral2DScaling
	This controls whether or not integral scaling is used for 2D graphics.

	When integral scaling is enabled 2D graphics will be upscaled by the largest integer multiplier that will fit the height of the screen. As an example, given a 1080p resolution: upscaling 480 to 1080 requires a scaling-factor of 2.25, which is not an integer, so when integral scaling is enabled 480 would be upscaled by a scaling-factor of 2, resulting in a height of 960.

	Most full-screen 2D graphics will be letter-boxed if the graphic cannot fill the height of the screen due to the integral scaling. An exception to this is when Recet is manning the till, wherein the interface is rearranged slightly to make use of the additional space.

	.Parameter MobDrawDistancePatchVariant
	This controls how the draw-distance for mobs in dungeons is patched when the aspect-ratio is wider than 4:3.

	When a mob in a dungeon goes off-screen (roughly speaking), the vanilla game stops simulating that mob entirely: it will not move, nor attack—it won't even animate.
	There are three options for how the patch handles the draw-distance of mobs:
		`OnlyVisual`: Will cause mobs to always be displayed after they have been first revealed, but the mobs will not be simulated outside of the game's vanilla draw-distance, as described earlier.
		`Real`: Will cause mobs to always be displayed and simulated after they have been first revealed—this will make the game more difficult as mobs will chase the player-character from further away–this option is not intended to provide balanced gameplay.
		`None`: Will cause mobs to simply disappear when they are out of the game's vanilla draw-distance.

	.Parameter CameraSmoothingVariant
	This controls how the game's camera smoothing is adapted to support frame-rates higher than 60 FPS.

	There are two options for the camera smoothing variant:
		`Interpolatedv2`: Aims to replicate the game's vanilla camera smoothing, but at a higher frame-rate.
		`None`: Makes no changes to the game's camera smoothing, which generally results in choppy-looking motion.

	.Parameter FloatInterpolation
	This can be used to individually specify which floats should be interpolated for display at a frame-rate higher than 60 FPS.

	Recettear's game logic is fixed at 60 FPS, so merely raising the frame-rate limit is not enough to achieve high frame-rate motion. To give the appearance of high frame-rate motion, this patch can interpolate specific floating-point values during the frames that get presented between each frame of game logic. (This is done in a way that has only a visual effect, the game logic is exactly the same as it is in the vanilla game.)

	This parameter is used by supplying a HashTable-like object which is keyed by the name of an interpolated float, wherein the values are: `$True` to interpolate the float; `$False` to not interpolate the float; `'Recommended'` to use the patch's recommendation for the interpolated float.

	If this parameter is not provided, the patch defaults to using the recommended value for each interpolated float.

	The interpolated floats which can be configured can be found in the `ConfigurableInterpolatedFloats` member of this script's output when the `ReturnInformation` switch is present.

	.Parameter TextureFiltering
	This can be used to individually specify which texture-filtering algorithm is used to upscale a class of textures.

	Much of Recettear's 2D art was designed for a resolution of 640x480, which is then, usually, upscaled using bilinear interpolation: causing the art to looking extremely blurry at high resolutions. To remedy this this patch allows the texture-filtering algorithms used for upscaling different classes of textures to be configured separately.

	This parameter is used by supplying a HashTable-like object which is keyed by the name of a class of textures, wherein the values are: `$False` to make no change to the texture-filtering algorithm used for a class of textures; `'Recommended'` to use the patch's recommendation for the texture-filtering algorithm used for a class of textures; one of the following texture-filtering algorithm identifiers:
		`NearestNeighbour`
		`Bilinear`
		`Anisotropic`
		`FlatCubic`
		`GaussianCubic`.

	If this parameter is not provided, the patch defaults to using the recommended value for each texture-filtering algorithm used for a class of textures.

	The classes of textures which can be configured can be found in the `ConfigurableTextureFilterings` member of this script's output when the `ReturnInformation` switch is present.

	As it is not known which textures some of the classes of textures affect, they are named "Unknown" with a hexadecimal suffix.
	In the future, these may be renamed to reflect the textures that they affect – if this happens, the original UnknownFF-style names will still be recognised for backwards-compatibility.

	.Parameter HideChangeCameraControlReminder
	This controls whether or not the "Change camera" button reminder is displayed in the bottom-right corner of the screen when in the shop.

	.Parameter HideSkipEventControlReminder
	This controls whether or not the "Skip event" button reminder is displayed in the bottom-right corner of the screen during an event or a cutscene.

	.Parameter HideItemDetailsControlReminderWhenHaggling
	This controls whether or not the "Item details" button reminder is displayed in the bottom-right corner of the screen when haggling with a customer.

	.Parameter HideItemDetailsControlReminderInItemMenus
	This controls whether or not the "Item details" button reminder is displayed in the bottom-right corner of the screen when browsing through an item menu.

	.Parameter GameLanguageOverride
	This is used to override the language that this script considers the version of Recettear being patched to be.

	The Japanese version and English version of Recettear differ enough that this patch needs to handle them differently.
	This patch will automatically detect the language of a Recettear installation via the hash of certain files, or through the game executable's version-info, or through the contents of the game's manual.
	Usually this should determine the language of the game correctly, but if it does not, this parameter can be used to override it.

	Use a value of `eng` for English, and `jpn` for Japanese.

	.Parameter RestoreBackupAutomatically
	This controls whether or not a previously-made backup of Recettear is automatically restored if the patching of the game fails, in non-interactive mode.

	.Parameter ApplySupportedPatchAutomatically
	This controls whether or not the game's official patch is downloaded and applied when the Steam version of the game is to be patched, or when the patching of the game fails, in non-interactive mode.

	.Parameter Configuration
	This is used to supply a base configuration for the parameters that control how the game is patched.

	If no value is provided for this parameter it will be initialised from an `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder, if present.

	The values in the configuration object are used as-is for the parameters of this script.
	Any parameters supplied when invoking this script will take precedence over the values in the configuration object.

	The parameters that get used from the configuration object are: FramerateLimit; ResolutionWidth; ResolutionHeight; HUDWidth; UseIntegral2DScaling; MobDrawDistancePatchVariant; CameraSmoothingVariant; FloatInterpolation; TextureFiltering; HideChangeCameraControlReminder; HideSkipEventControlReminder; HideItemDetailsControlReminderWhenHaggling; HideItemDetailsControlReminderInItemMenus; SkipPatching; SkipPostPatchOperations; GetGameWindowMode; SetGameWindowMode; InstallDxWrapper; ConfigureDxWrapper; ResetDxWrapperConfiguration; CheckDxWrapperConfiguration; InstallDgVoodoo2; ConfigureDgVoodoo2; ResetDgVoodoo2Configuration; CheckDgVoodoo2Configuration; InstallSpecialK; ResetSpecialKConfiguration; ConfigureSpecialK; SetDirectXVersionToUse; GetDirectXVersionToUse; SetVerticalSyncEnabled; GetVerticalSyncEnabled; CheckSpecialKConfiguration; SaveSettingsToConfiguration; DoNotInstallThirdPartyToolsByDefaultNextTime.

	.Parameter ReturnInformation
	When this switch is present, this script will return an object with some information, and the game will not be patched, nor will any post-patch operations be carried out (the `SkipPatching` and `SkipPostPatchOperations` parameters will be treated as though they are `$True`).

	Refer to the Outputs section of this documentation for information about how this parameter affects this script's output.

	.Parameter SkipConfigurator
	When this switch is present, the configurator that usually runs, in interactive mode, will be skipped.

	.Parameter ConfiguratorPort
	Specifies a port number that the configurator, in interactive mode, should listen on.

	If this parameter is not provided, the configurator will listen on the first port that it can successfully listen on starting from port 49600.
	If this parameter is provided, and the configuration cannot listen on it, the script will throw an exception.

	.Parameter SkipPatching
	This controls whether or not this script actually patches the game.

	This can be used to perform only post-patch operations, for configuring the game/patch without patching it again.

	.Parameter SkipPostPatchOperations
	This controls whether or not this script performs post-patch operations.

	This can be used to only patch the game, without affecting the game's configuration, or the state of any third-party tools.

	The post-patch operations are controlled via the parameters documented after this parameter, until the `SaveSettingsToConfiguration` parameter.

	.Parameter GetGameWindowMode
	When this is `$True`, this script's output will detail the mode that the game's window is configured to use.

	This is a post-patch operation.

	.Parameter SetGameWindowMode
	Specifies which mode the game's window should be configured to use.

	There are four options for this:
		`NoChange`: The game's window mode is not changed.
		`FullScreen`: The game's window mode is changed to full-screen.
		`Windowed`: The game's window mode is changed to windowed.
		`BorderlessWindowed`: The game's window mode is changed to borderless-windowed.

	This is a post-patch operation.

	.Parameter InstallDxWrapper
	Controls whether or not DxWrapper is installed. (https://github.com/elishacloud/dxwrapper).

	If DxWrapper cannot be found in the game's installation folder, as `dxwrapper.zip`, it will be downloaded from the Internet (the file's SHA256 hash will be verified to ensure the file is safe to install). If DxWrapper is already installed it will be reinstalled, overwriting any existing files (a backup of the existing files will be made, however).

	This is a post-patch operation.

	.Parameter ConfigureDxWrapper
	Controls whether or not DxWrapper will be configured to use the settings recommended by this patch.

	If the `InstallDxWrapper` parameter or the `ResetDxWrapperConfiguration` parameter is `$True`, DxWrapper will be configured regardless of whether this parameter is `$True` or not.

	This is a post-patch operation.

	.Parameter ResetDxWrapperConfiguration
	Controls whether or not DxWrapper's configuration is entirely reset – this is achieved by clearing the configuration file entirely.

	This is a post-patch operation.

	.Parameter CheckDxWrapperConfiguration
	When this is `$True`, this script's output will detail the difference between the recommended settings and the configured settings for DxWrapper's configuration.

	This is a post-patch operation.

	.Parameter InstallDgVoodoo2
	Controls whether or not dgVoodoo2 is installed. (http://dege.freeweb.hu/dgVoodoo2/).

	If dgVoodoo2 cannot be found in the game's installation folder, as `dgVoodoo2.zip`, it will be downloaded from the Internet (the file's SHA256 hash will be verified to ensure the file is safe to install). If dgVoodoo2 is already installed it will be reinstalled, overwriting any existing files (a backup of the existing files will be made, however).

	This is a post-patch operation.

	.Parameter ConfigureDgVoodoo2
	Controls whether or not dgVoodoo2 will be configured to use the settings recommended by this patch.

	If the `InstallDgVoodoo2` parameter or the `ResetDgVoodoo2Configuration` parameter is `$True`, dgVoodoo2 will be configured regardless of whether this parameter is `$True` or not.

	This is a post-patch operation.

	.Parameter ResetDgVoodoo2Configuration
	Controls whether or not dgVoodoo2's configuration is entirely reset – this is achieved by clearing the configuration file entirely.

	This is a post-patch operation.

	.Parameter CheckDgVoodoo2Configuration
	When this is `$True`, this script's output will detail the difference between the recommended settings and the configured settings for dgVoodoo2's configuration.

	This is a post-patch operation.

	.Parameter InstallSpecialK
	Controls whether or not Special K is installed. (https://special-k.info/).

	If Special K cannot be found in the game's installation folder, as `SpecialK.zip`, it will be downloaded from the Internet (the file's SHA256 hash will be verified to ensure the file is safe to install). If Special K is already installed it will be reinstalled, overwriting any existing files (a backup of the existing files will be made, however).

	This is a post-patch operation.

	.Parameter ConfigureSpecialK
	Controls whether or not Special K will be configured to use the settings recommended by this patch.

	If the `InstallSpecialK` parameter or the `ResetSpecialKConfiguration` parameter is `$True`, Special K will be configured regardless of whether this parameter is `$True` or not.

	This is a post-patch operation.

	.Parameter ResetSpecialKConfiguration
	Controls whether or not Special K's configuration is entirely reset – this is achieved by clearing the configuration file entirely.

	This is a post-patch operation.

	.Parameter CheckSpecialKConfiguration
	When this is `$True`, this script's output will detail the difference between the recommended settings and the configured settings for Special K's configuration.

	This is a post-patch operation.

	.Parameter SetDirectXVersionToUse
	This is used to change which version of DirectX is used by the game. Each DirectX version performs differently with regards to frame-pacing (especially when vertical-sync is enabled) and in their support for windowed/fullscreen mode.

	DirectX 12 generally has the best results for frame-pacing, however it does not support fullscreen mode so borderless-windowed mode must be used instead.
	If the game's resolution is configured to be the same as the monitor's resolution then DirectX 12 should be the first choice on machines that support DirectX 12, as it works well regardless of the vertical-sync setting, and has low-latency in borderless-windowed mode meaning the fast alt-tabbing of borderless-windowed mode can be availed of without the traditional drawbacks of borderless-windowed mode.
	To be able to use DirectX 12, DxWrapper and dgVoodoo2 must be installed.

	DirectX 9 has the next best results for frame-pacing, and it supports fullscreen mode, however it incurs additional latency when borderless-windowed mode is used.
	If the game's resolution is configured to be smaller than the monitor's resolution and fullscreen is desired then DirectX 9 should be the first choice.
	To be able to use DirectX 9, DxWrapper must be installed.

	DirectX 11 is very sensitive when it comes to frame-pacing, especially when vertical-sync is enabled, but it does support fullscreen mode, and does not incur additional latency when borderless-windowed mode is used.
	If vertical-sync is disabled, DirectX 11 may be worth a try if DirectX 9 does not satisfy, or for usage of borderless-windowed mode on machines that do not support DirectX 12.
	To be able to use DirectX 11, DxWrapper and dgVoodoo2 must be installed.

	DirectX 8.1 is the version of DirectX used by the vanilla game. It has little advantage over the other versions of DirectX 8.1 except for compatibility with very old hardware. Though, its usage does not require any third-party tools, so it can be useful for trouble-shooting.

	When DirectX 9 or later is used, DxWrapper is used to convert the game's usage of DirextX 8.1 to DirectX 9 (DxWrapper in turn uses "d3d8to9" for the conversion).
	When DirectX 11 or later is used, DxWrapper is still used, and dgVoodoo2 is used to convert the game's usage of DirectX 9 to DirectX 11 or 12.
	When DirectX 8.1 is used, neither DxWrapper nor dgVoodoo2 are used.

	There are five options for this:
		`'NoChange'`: The DirectX version to use is not changed.
		`12`: The DirectX version to use is changed to DirectX 12.
		`9`: The DirectX version to use is changed to DirectX 9.
		`11`: The DirectX version to use is changed to DirectX 11.
		`8`: The DirectX version to use is changed to DirectX 8.1.

	This is a post-patch operation.

	.Parameter GetDirectXVersionToUse
	When this is `$True`, this script's output will detail the version of DirectX that the game is configured to use.

	This is a post-patch operation.

	.Parameter SetVerticalSyncEnabled
	This is used to change whether vertical-sync ("v-sync") is enabled or disabled.

	There are three options for this:
		`'NoChange'`: The vertical-sync setting is not changed.
		`$False`: Vertical-sync is configured to be disabled.
		`$True`: Vertical-sync is configured to be enabled.

	This is a post-patch operation.

	.Parameter GetVerticalSyncEnabled
	When this is `$True`, this script's output will detail whether vertical-sync is configured to be enabled or disabled.

	This is a post-patch operation.

	.Parameter SaveSettingsToConfiguration
	When this is `$True`, the configuration that the game is to be patched with is saved to an `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder.

	In interactive mode, this defaults to `$True`. In non-interactive mode, this defaults to `$False`.

	.Parameter DoNotInstallThirdPartyToolsByDefaultNextTime
	When this is `$True`, the `InstallDxWrapper`, `InstallDgVoodoo2`, and `InstallSpecialK` parameters are treated as though they are `$False` when the configuration that the game is to be patched with is saved to the `Install-FancyScreenPatchForRecettear.config.json` file in the game's installation folder.

	In interactive mode, this defaults to `$True`. In non-interactive mode, this defaults to `$False`.

	.Parameter CheatEngineTablePath
	Specifies a path to save a cheat-table for Cheat Engine to. Any existing files at this path will be overwritten.

	The generated cheat-table is used mainly for debugging, but it does include one cheat (forcing Nagi to spawn regardless of the RNG roll for her spawning).

	.Parameter InterpolatedFloatsToIncludeInCheatTable
	Specifies a HashSet of strings of interpolated float names, the interpolated floats specified by this set are the interpolated floats that will be present in the cheat-table that is generated when the `CheatEngineTablePath` parameter is used.
#>


[CmdletBinding()]
Param (
	[Parameter()]
			[Switch] $NonInteractive,

	[Parameter()]
			$RecettearExecutablePath,

	[Parameter()]
			$DetectedInstallationPreference = ('ScriptRoot', 'CurrentDirectory', 'Steam', 'GOG'),

	[Parameter()]
			$BackupPath,

	[Parameter()]
			$ClobberedByRestoredBackupBackupPath,

	[Parameter()]
			$FramerateLimit,

	[Parameter()]
			$ResolutionWidth,

	[Parameter()]
			$ResolutionHeight,

	[Parameter()]
			$HUDWidth,

	[Parameter()]
			$UseIntegral2DScaling,

	[Parameter()]
		[ArgumentCompleter({'OnlyVisual', 'None', 'Real' | ForEach-Object {$_}})]
			$MobDrawDistancePatchVariant,

	[Parameter()]
		[ArgumentCompleter({'InterpolatedV2', 'None' | ForEach-Object {$_}})]
			$CameraSmoothingVariant,

	[Parameter()]
			$FloatInterpolation,

	[Parameter()]
			$TextureFiltering,

	[Parameter()]
			$HideChangeCameraControlReminder,

	[Parameter()]
			$HideSkipEventControlReminder,

	[Parameter()]
			$HideItemDetailsControlReminderWhenHaggling,

	[Parameter()]
			$HideItemDetailsControlReminderInItemMenus,

	[Parameter()]
		[ValidateSet('eng', 'jpn')]
		[ArgumentCompleter({'eng', 'jpn' | ForEach-Object {$_}})]
			$GameLanguageOverride,

	[Parameter()]
			[Switch] $RestoreBackupAutomatically = $True,

	[Parameter()]
			[Switch] $ApplySupportedPatchAutomatically = $True,

	[Parameter()]
		$Configuration,

	[Parameter()]
			[Switch] $ReturnInformation,

	[Parameter()]
			[Switch] $SkipConfigurator,

	[Parameter()]
			[UInt16] $ConfiguratorPort,

	[Parameter()]
			$SkipPatching,

	[Parameter()]
			$SkipPostPatchOperations,

	[Parameter()]
			$GetGameWindowMode,

	[Parameter()]
		[ArgumentCompleter({'NoChange', 'FullScreen', 'Windowed', 'BorderlessWindowed' | ForEach-Object {$_}})]
			$SetGameWindowMode,

	[Parameter()]
			$InstallDxWrapper,

	[Parameter()]
			$ConfigureDxWrapper,

	[Parameter()]
			$ResetDxWrapperConfiguration,

	[Parameter()]
			$CheckDxWrapperConfiguration,

	[Parameter()]
			$InstallDgVoodoo2,

	[Parameter()]
			$ResetDgVoodoo2Configuration,

	[Parameter()]
			$ConfigureDgVoodoo2,

	[Parameter()]
			$CheckDgVoodoo2Configuration,

	[Parameter()]
			$InstallSpecialK,

	[Parameter()]
			$ResetSpecialKConfiguration,

	[Parameter()]
			$ConfigureSpecialK,

	[Parameter()]
			$CheckSpecialKConfiguration,

	[Parameter()]
		[ArgumentCompleter({12, 9, 11, 8, 'NoChange' | ForEach-Object {$_}})]
			$SetDirectXVersionToUse,

	[Parameter()]
			$GetDirectXVersionToUse,

	[Parameter()]
		[ArgumentCompleter({'NoChange', $False, $True | ForEach-Object {$_}})]
			$SetVerticalSyncEnabled,

	[Parameter()]
			$GetVerticalSyncEnabled,

	[Parameter()]
			$SaveSettingsToConfiguration,

	[Parameter()]
			$DoNotInstallThirdPartyToolsByDefaultNextTime,

	[Parameter()]
			$CheatEngineTablePath,

	[Parameter()]
		[ValidateNotNull()]
		[AllowEmptyCollection()]
			[Collections.Generic.HashSet[String]] $InterpolatedFloatsToIncludeInCheatTable = (
				'PlayerCharacterPosition',
				'RecetWhenInDungeonPosition',
				'TearPosition',
				'ShopperPosition',
				'WindowShopperPosition',
				'MobPosition',
				'HUDSlideIn'
			)
)


$StopWatch = [Diagnostics.Stopwatch]::StartNew()


if ($Null -eq $PSVersionTable -or ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)))
{
	Write-Error 'This script requires at-least version 5.1, or later, of PowerShell.'

	exit 2
}

if ($Null -eq ([Management.Automation.PSTypeName] 'System.ValueTuple').Type)
{
	Write-Error 'This script requires at-least version 4.7, or later, of .NET to be installed.'

	exit 3
}


$ExtendedDebug = $False
$Verbose = $Null -ne (Write-Verbose ([String]::Empty) 4>&1)
$Debug = $Null -ne (Write-Debug ([String]::Empty) 5>&1)


if ($PSVersionTable.PSVersion.Major -le 5)
{
	$IsWindows = $True
	$ANSIEncoding = 'Default'
	$Script:MaximumVariableCount = 32767
}
elseif ($PSVersionTable.PSVersion.Major -gt 7 -or ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -ge 4))
{
	$ANSIEncoding = 'ANSI'
}
else
{
	$ANSIEncoding = 'OEM'
}


$ScriptArgumentDepth = 3


$Variables = $ExecutionContext.SessionState.PSVariable


class FancyScreenPatchForRecettearException : Exception
{
	[PSCustomObject] $Data

	FancyScreenPatchForRecettearException ([String] $Message, [PSCustomObject] $Data) : base($Message)
	{
		$This.Data = $Data
	}
}

class FancyScreenPatchForRecettearConfigurationException : FancyScreenPatchForRecettearException {FancyScreenPatchForRecettearConfigurationException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class FancyScreenPatchForRecettearOptionAlreadyConfiguredAsException : FancyScreenPatchForRecettearConfigurationException {FancyScreenPatchForRecettearOptionAlreadyConfiguredAsException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class FancyScreenPatchForRecettearNoInstallationFoundException : FancyScreenPatchForRecettearConfigurationException {FancyScreenPatchForRecettearNoInstallationFoundException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}

class FancyScreenPatchForRecettearConfiguratorException : FancyScreenPatchForRecettearException {FancyScreenPatchForRecettearConfiguratorException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class FancyScreenPatchForRecettearUnableToUseConfiguratorPortException : FancyScreenPatchForRecettearConfiguratorException {FancyScreenPatchForRecettearUnableToUseConfiguratorPortException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}

class FancyScreenPatchForRecettearPatchingException : FancyScreenPatchForRecettearException {FancyScreenPatchForRecettearPatchingException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class FancyScreenPatchForRecettearNoRecettearExecutableException : FancyScreenPatchForRecettearPatchingException {FancyScreenPatchForRecettearNoRecettearExecutableException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class FancyScreenPatchForRecettearTooFewUnusedExecutableSectionSlotsException : FancyScreenPatchForRecettearPatchingException {FancyScreenPatchForRecettearTooFewUnusedExecutableSectionSlotsException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class FancyScreenPatchForRecettearFailedToFindSectionException : FancyScreenPatchForRecettearPatchingException {FancyScreenPatchForRecettearFailedToFindSectionException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class FancyScreenPatchForRecettearFailedToFindCodeException : FancyScreenPatchForRecettearPatchingException {FancyScreenPatchForRecettearFailedToFindCodeException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class FancyScreenPatchForRecettearFailedToDetectLanguageException : FancyScreenPatchForRecettearPatchingException {FancyScreenPatchForRecettearFailedToDetectLanguageException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}

class FancyScreenPatchForRecettearBugException : FancyScreenPatchForRecettearException {FancyScreenPatchForRecettearBugException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}

class FancyScreenPatchForRecettearFailedToDownloadFileException : FancyScreenPatchForRecettearException {FancyScreenPatchForRecettearFailedToDownloadFileException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}


function Coerce-Parameter ($Identifier, $Type, $TypeDescription)
{
	$Value = $Variables.GetValue("Script:$Identifier")

	if ($Null -ne $Value)
	{
		if (-not ($Value -as $Type -is $Type))
		{
			Write-Warning "The value for the `"$Identifier`" parameter is expected to be $TypeDescription. And thus, it is being ignored.",

			$Variables.Set("Script:$Identifier", $Null)
		}
		else
		{
			$Variables.Set("Script:$Identifier", $Value -as $Type)
		}
	}
}


function Assert-MinimumValue ($Identifier, $Minimum)
{
	$Value = $Variables.GetValue("Script:$Identifier")

	if ($Null -ne $Value -and $Value -lt $Minimum)
	{
		Write-Warning "The value for the `"$Identifier`" parameter is expected to be at-least $Minimum. And thus, it is being ignored."

		$Variables.Set("Script:$Identifier", $Null)
	}
}


$RecognisedInstallationPreferences = ('ScriptRoot', 'CurrentDirectory', 'Steam', 'GOG')
$RecognisedMobDrawDistancePatchVariants = ('OnlyVisual', 'None', 'Real')
$RecognisedCameraSmoothingVariants = ('InterpolatedV2', 'None')
$RecognisedDirectXVersions = ('NoChange', 8, 9, 11, 12)
$RecognisedGameWindowModes = ('NoChange', 'BorderlessWindowed', 'FullScreen', 'Windowed')
$RecognisedVerticalSyncSettings = ('NoChange', $False, $True)


$GameFramerate = [UInt32] 60


$DefaultResolutionWidth = 640
$DefaultResolutionHeight = 480


$GameBaseWidth = 640.0
$GameBaseHeight = 480.0


$ConfigurableInterpolatedFloats = @(
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('PlayerCharacterPosition'); Recommendation = $Null; Synopsis = 'The position of the current player-character.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('RecetWhenInDungeonPosition'); Recommendation = $Null; Synopsis = 'The position of Recet, when dungeon crawling.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('TearPosition'); Recommendation = $Null; Synopsis = 'The position of Tear.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('ShopperPosition'); Recommendation = $Null; Synopsis = 'The positions of the NPCs that walk past the shop''s window.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('WindowShopperPosition'); Recommendation = $Null; Synopsis = 'The positions of NPCs that are walking around in the shop.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('MobPosition'); Recommendation = $Null; Synopsis = 'The positions of mobs when dungeon crawling.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('MirrorImageReflectionPosition'); Recommendation = $Null; Synopsis = 'The positions of the reflections that follow the player-character when the Mirror Image skill is used.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('AttackProjectilePosition'); Recommendation = $Null; Synopsis = 'The positions of projectiles originating from attacks.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('XPGemPosition'); Recommendation = $Null; Synopsis = 'The positions of XP-gems acquired from felling mobs.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('MovementParticlePosition'); Recommendation = $Null; Synopsis = 'The positions of particles that originate from the movement of characters.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('HUDSlideIn'); Recommendation = $Null; Synopsis = 'The sliding-around of various HUD elements during transitions.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('ShopTillEntryTransitionFloatMirror'); Recommendation = $Null; Synopsis = 'The sliding-around of various HUD elements when a customer comes to or leaves the till.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('ShopTillCustomerPositionFloatMirror'); Recommendation = $Null; Synopsis = 'The position of a customer as they enter or exit the screen when talking to Recet, in the shop.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('TearMenuTransitionCounterFloatMirror'); Recommendation = $Null; Synopsis = 'The sliding-around of the menus displayed when interacting with Tear, in the shop.'}}
	[PSCustomObject] @{Metadata = [PSCustomObject] @{Names = [String[]] @('TearLectureButtonTransitionCounterFloatMirror'); Recommendation = $Null; Synopsis = 'The sliding-around of the menu buttons used for replaying Tear''s lectures, in the shop.'}}
)


$D3DTEXF_POINT = 1
$D3DTEXF_LINEAR = 2
$D3DTEXF_ANISOTROPIC = 3
$D3DTEXF_FLATCUBIC = 4
$D3DTEXF_GAUSSIANCUBIC = 5


$TextureFilteringAlgorithmLookup = @{
	NearestNeighbour = $D3DTEXF_POINT
	Bilinear = $D3DTEXF_LINEAR
	Anisotropic = $D3DTEXF_ANISOTROPIC
	FlatCubic = $D3DTEXF_FLATCUBIC
	GaussianCubic = $D3DTEXF_GAUSSIANCUBIC
}

$TextureFilteringAlgorithmFriendlyNameMapping = [Ordered] @{
	'Nearest Neighbour' = 'NearestNeighbour'
	'Bilinear' = 'Bilinear'
	'Anisotropic' = 'Anisotropic'
	'Flat Cubic' = 'FlatCubic'
	'Gaussian Cubic' = 'GaussianCubic'
}


$CameraSmoothingVariantFriendlyNameMapping = [Ordered] @{
	'Interpolated v2' = 'InterpolatedV2'
	'None' = 'None'
}


$ConfigurableTextureFilterings = @(
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[0]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('ShopItems'); Recommendation = $Null; Synopsis = 'Items in the shop.'}}
	[PSCustomObject] @{PatchVariant = 'ShopShadows'; Metadata = [PSCustomObject] @{Names = [String[]] @('ShopShadows'); Recommendation = $Null; Synopsis = 'Shadows in the shop.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[1]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('HUDClock'); Recommendation = $Null; Synopsis = 'HUD clock.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[2]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('FPSOSD'); Recommendation = $Null; Synopsis = 'FPS OSD.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[3]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('SaveAndItemSlots'); Recommendation = $Null; Synopsis = 'Save slots and item icons.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[4]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Flora'); Recommendation = $Null; Synopsis = 'Flora?'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[5]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('MeshTextures'); Recommendation = $Null; Synopsis = 'Mesh textures.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[6]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('ChestTextures'); Recommendation = $Null; Synopsis = 'Chest textures?'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[7]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Other2DArt'); Recommendation = $Null; Synopsis = 'All other 2D art not covered by other options.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[8]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown00'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[9]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown01'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[10]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown02'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[11]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown03'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[12]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown04'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[13]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown05'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[14]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown06'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[15]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown07'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[16]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown08'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[17]'; PatchVariant = 'PushedImmediate'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown09'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[18]'; PatchVariant = 'WrapperCall'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown0A'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[19]'; PatchVariant = 'WrapperCall'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown0B'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[20]'; PatchVariant = 'WrapperCall'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown0C'); Recommendation = $Null; Synopsis = 'Unknown.'}}
	[PSCustomObject] @{VirtualAddress = $Null; VirtualAddressSource = 'TextureFiltering[21]'; PatchVariant = 'WrapperCall'; Metadata = [PSCustomObject] @{Names = [String[]] @('Unknown0D'); Recommendation = $Null; Synopsis = 'Unknown.'}}
)


function Resolve-KeyedOptionConfiguration ($Parameter, $Object, $ConfigurableOptions, $ConfigurableOptionKey, $ValueKey, $RecognisedValues, [Switch] $IgnoreFalseValues, [Switch] $Final)
{
	$ResolvedConfiguration = [Collections.Generic.Dictionary[String, HashTable]]::new()

	if ($Null -ne $Object)
	{
		for ($Index = $ConfigurableOptions.Length; ($Index--) -gt 0;)
		{
			$ConfigurableOption = $ConfigurableOptions[$Index]
			$AlreadyConfiguredAs = $Null

			foreach ($Name in $ConfigurableOption.Metadata.Names)
			{
				$ConfigurationValue = $Object.$Name

				if ($Null -eq $ConfigurationValue)
				{
					continue
				}

				if ($Null -ne $AlreadyConfiguredAs)
				{
					throw [FancyScreenPatchForRecettearOptionAlreadyConfiguredAsException]::new("The `"$Name`" option of `"$Parameter`" was already configured as `"$AlreadyConfiguredAs`".", [PSCustomObject] @{ProvidedName = $Name; AlreadyConfiguredAs = $AlreadyConfiguredAs})
				}

				$AlreadyConfiguredAs = $Name

				if ($IgnoreFalseValues -and $ConfigurationValue -eq $False)
				{
					continue
				}

				if ('Recommended' -eq $ConfigurationValue)
				{
					if ($Final)
					{
						$ConfigurationValue = $ConfigurableOption.Metadata.Recommendation
					}
				}
				elseif (-not $RecognisedValues.Contains($ConfigurationValue))
				{
					Write-Warning "An unrecognised value of `"$ConfigurationValue`" was supplied for `"$Name`" for `"$Parameter`". The recognised values are: $(($RecognisedValues | Sort-Object) -join '; ')."

					continue
				}

				$ResolvedConfiguration[$ConfigurableOption.Metadata.Names[0]] = @{
					$ValueKey = $ConfigurationValue
					$ConfigurableOptionKey = $ConfigurableOption
				}
			}
		}
	}
	else
	{
		for ($Index = $ConfigurableOptions.Length; ($Index--) -gt 0;)
		{
			$Filtering = $ConfigurableOptions[$Index]

			$ResolvedConfiguration[$Filtering.Metadata.Names[0]] = @{
				$ValueKey = $(if ($Final) {$Filtering.Metadata.Recommendation})
				$ConfigurableOptionKey = $Filtering
			}
		}
	}

	$ResolvedConfiguration
}


function Resolve-InterpolatedFloatConfiguration ([Switch] $Final)
{
	Resolve-KeyedOptionConfiguration FloatInterpolation $Script:FloatInterpolation $ConfigurableInterpolatedFloats ConfigurableInterpolatedFloat Enabled ([Collections.Generic.HashSet[Bool]] ($True, $False)) -Final:$Final
}


function Resolve-TextureFilteringConfiguration ([Switch] $Final)
{
	Resolve-KeyedOptionConfiguration TextureFiltering $Script:TextureFiltering $ConfigurableTextureFilterings ConfigurableTextureFiltering Algorithm ([Collections.Generic.HashSet[String]] ($TextureFilteringAlgorithmLookup.Keys | % {$_})) -IgnoreFalseValues -Final:$Final
}


function Resolve-Configuration
{
	[CmdletBinding()]
	Param (
		[Parameter()]
				[Switch] $Final
	)

	$DefaultDirectXVersionToUse = 12

	if ($Null -eq $Script:SetDirectXVersionToUse)
	{
		$Script:SetDirectXVersionToUse = $DefaultDirectXVersionToUse
	}
	elseif ($Null -eq $RecognisedDirectXVersions.Where({$_ -eq $Script:SetDirectXVersionToUse}, 'First')[0])
	{
		Write-Warning "DirectX version $Script:SetDirectXVersionToUse, specified by `"SetDirectXVersionToUse`", is unrecognised, and thus the default version of $DefaultDirectXVersionToUse is being used. The recognised DirectX versions are: $(($RecognisedDirectXVersions | Sort-Object) -join '; ')."

		$Script:SetDirectXVersionToUse = $DefaultDirectXVersionToUse
	}

	$DefaultSetGameWindowMode = 'NoChange'

	if ($Null -eq $Script:SetGameWindowMode)
	{
		$Script:SetGameWindowMode = $DefaultSetGameWindowMode
	}
	elseif ($Null -eq $RecognisedGameWindowModes.Where({$_ -eq $Script:SetGameWindowMode}, 'First')[0])
	{
		Write-Warning "The window-mode of `"$Script:SetGameWindowMode`" specified by `"SetGameWindowMode`" is unrecognised. Thus, the game's window-mode will not be changed. The recognised window-modes are: $(($RecognisedGameWindowModes | Sort-Object) -join '; ')."

		$Script:SetGameWindowMode = $DefaultSetGameWindowMode
	}

	$DefaultSetVerticalSyncEnabled = 'NoChange'

	if ($Null -eq $Script:SetVerticalSyncEnabled)
	{
		$Script:SetVerticalSyncEnabled = $DefaultSetVerticalSyncEnabled
	}
	if ($Null -eq $RecognisedVerticalSyncSettings.Where({$_ -eq $Script:SetVerticalSyncEnabled}, 'First')[0])
	{
		Write-Warning "The setting of `"$Script:SetVerticalSyncEnabled`" specified by `"SetVerticalSyncEnabled`" is unrecognised. Thus, the game's vertical-sync setting will not be changed. The recognised vertical-sync settings are: $(($RecognisedVerticalSyncSettings | Sort-Object) -join '; ')."

		$Script:SetVerticalSyncEnabled = $DefaultSetVerticalSyncEnabled
	}

	if ($Final)
	{
		Coerce-Parameter RecettearExecutablePath ([String]) 'a string of text'
		Coerce-Parameter BackupPath ([String]) 'a string of text'
		Coerce-Parameter ClobberedByRestoredBackupBackupPath ([String]) 'a string of text'
		Coerce-Parameter FramerateLimit ([UInt32]) 'a 32-bit unsigned integer'
		Coerce-Parameter ResolutionWidth ([UInt32]) 'a 32-bit unsigned integer'
		Coerce-Parameter ResolutionHeight ([UInt32]) 'a 32-bit unsigned integer'
		Coerce-Parameter HUDWidth ([UInt32]) 'a 32-bit unsigned integer'
		Coerce-Parameter UseIntegral2DScaling ([Bool]) 'true or false'
		Coerce-Parameter MobDrawDistancePatchVariant ([String]) 'a string of text'
		Coerce-Parameter CheatEngineTablePath ([String]) 'a string of text'
		Coerce-Parameter HideChangeCameraControlReminder ([Bool]) 'true or false'
		Coerce-Parameter HideSkipEventControlReminder ([Bool]) 'true or false'
		Coerce-Parameter HideItemDetailsControlReminderWhenHaggling ([Bool]) 'true or false'
		Coerce-Parameter HideItemDetailsControlReminderInItemMenus ([Bool]) 'true or false'
		Coerce-Parameter SkipPatching ([Bool]) 'true or false'
		Coerce-Parameter SkipPostPatchOperations ([Bool]) 'true or false'
		Coerce-Parameter GetGameWindowMode ([Bool]) 'true or false'
		Coerce-Parameter SetGameWindowMode ([String]) 'a string of text'
		Coerce-Parameter InstallDxWrapper ([Bool]) 'true or false'
		Coerce-Parameter ConfigureDxWrapper ([Bool]) 'true or false'
		Coerce-Parameter ResetDxWrapperConfiguration ([Bool]) 'true or false'
		Coerce-Parameter CheckDxWrapperConfiguration ([Bool]) 'true or false'
		Coerce-Parameter InstallDgVoodoo2 ([Bool]) 'true or false'
		Coerce-Parameter ResetDgVoodoo2Configuration ([Bool]) 'true or false'
		Coerce-Parameter ConfigureDgVoodoo2 ([Bool]) 'true or false'
		Coerce-Parameter CheckDgVoodoo2Configuration ([Bool]) 'true or false'
		Coerce-Parameter InstallSpecialK ([Bool]) 'true or false'
		Coerce-Parameter ResetSpecialKConfiguration ([Bool]) 'true or false'
		Coerce-Parameter ConfigureSpecialK ([Bool]) 'true or false'
		Coerce-Parameter CheckSpecialKConfiguration ([Bool]) 'true or false'
		Coerce-Parameter GetDirectXVersionToUse ([Bool]) 'true or false'
		Coerce-Parameter GetVerticalSyncEnabled ([Bool]) 'true or false'
		Coerce-Parameter SaveSettingsToConfiguration ([Bool]) 'true or false'
		Coerce-Parameter DoNotInstallThirdPartyToolsByDefaultNextTime ([Bool]) 'true or false'

		Assert-MinimumValue FramerateLimit ([UInt32] 60)
		Assert-MinimumValue ResolutionWidth ([UInt32] 1)
		Assert-MinimumValue ResolutionHeight ([UInt32] 1)
		Assert-MinimumValue HUDWidth ([UInt32] 1)

		if ($Null -ne $Script:ResolutionWidth)
		{
			if ($Null -eq $Script:ResolutionHeight)
			{
				Write-Warning 'A value must be provided for "ResolutionHeight" when a value for "ResolutionWidth" has been provided. And thus, "ResolutionWidth" is being ignored.'

				$Script:ResolutionWidth = $Null
			}
		}
		elseif ($Null -ne $Script:ResolutionHeight)
		{
			if ($Null -eq $Script:ResolutionWidth)
			{
				Write-Warning 'A value must be provided for "ResolutionWidth" when a value for "ResolutionHeight" has been provided. And thus, "ResolutionHeight" is being ignored.'

				$Script:ResolutionHeight = $Null
			}
		}

		if ($Null -eq $Script:ResolutionWidth)
		{
			Write-Warning "A value has not been provided for `"ResolutionWidth`". And thus, the default value of $DefaultResolutionWidth is being used."

			$Script:ResolutionWidth = $DefaultResolutionWidth
		}

		if ($Null -eq $Script:ResolutionHeight)
		{
			Write-Warning "A value has not been provided for `"ResolutionHeight`". And thus, the default value of $DefaultResolutionHeight is being used."

			$Script:ResolutionHeight = $DefaultResolutionHeight
		}

		if ($Script:FramerateLimit -gt 1000)
		{
			Write-Warning 'Any adverse effects resulting from framerate-limits greater-than one-thousand are unsupported.'
		}

		if ($Null -ne $Script:ResolutionWidth)
		{
			if ($Script:ResolutionWidth / $Script:ResolutionHeight -lt 4 / 3)
			{
				Write-Warning 'Any adverse effects resulting from resolutions with an aspect-ratio narrower than 4:3 are unsupported.'
			}
		}

		if ($Null -ne $Script:HUDWidth)
		{
			if ($Script:HUDWidth / $Script:ResolutionHeight -lt 4 / 3)
			{
				Write-Warning 'Any adverse effects resulting from HUD-widths with an aspect-ratio narrower than 4:3 are unsupported.'
			}

			if ($Script:HUDWidth -gt $Script:ResolutionWidth)
			{
				Write-Warning 'Any adverse effects resulting from HUD-widths wider than the game''s resolution are unsupported.'
			}
		}

		if ($Null -eq $Script:UseIntegral2DScaling)
		{
			$Script:UseIntegral2DScaling = $True
		}

		$Script:DetectedInstallationPreference = $Script:DetectedInstallationPreference | ? `
		{
			$Preference = $_

			if ($Null -ne $RecognisedInstallationPreferences.Where({$_ -eq $Preference}, 'First')[0])
			{
				$True
			}
			else
			{
				Write-Warning "The `"$_`" installation-preference is unrecognised, and is thus being ignored. The recognised installation-preferences are: $(($RecognisedInstallationPreferences | Sort-Object) -join '; ')."
				$False
			}
		}

		$DefaultMobDrawDistancePatchVariant = 'OnlyVisual'

		if ($Null -eq $Script:MobDrawDistancePatchVariant)
		{
			$Script:MobDrawDistancePatchVariant = $DefaultMobDrawDistancePatchVariant
		}
		elseif ($Null -eq $RecognisedMobDrawDistancePatchVariants.Where({$_ -eq $Script:MobDrawDistancePatchVariant}, 'First')[0])
		{
			Write-Warning "The `"$Script:MobDrawDistancePatchVariant`" mob draw-distance patch-variant is unrecognised, and thus the default patch-variant of `"$DefaultMobDrawDistancePatchVariant`" is being used. The recognised mob draw-distance patch-variants are: $(($RecognisedMobDrawDistancePatchVariants | Sort-Object) -join '; ')."

			$Script:MobDrawDistancePatchVariant = $DefaultMobDrawDistancePatchVariant
		}

		$DefaultCameraSmoothingVariant = if ($Script:FramerateLimit -ne $GameFramerate) {'InterpolatedV2'} else {'None'}

		if ($Null -eq $Script:CameraSmoothingVariant)
		{
			$Script:CameraSmoothingVariant = $DefaultCameraSmoothingVariant
		}
		elseif ($Null -eq $RecognisedCameraSmoothingVariants.Where({$_ -eq $Script:CameraSmoothingVariant}, 'First')[0])
		{
			Write-Warning "The `"$Script:CameraSmoothingVariant`" camera-smoothing variant is unrecognised, and thus the default variant of `"$DefaultCameraSmoothingVariant`" is being used. The recognised camera-smoothing variants are: $(($RecognisedCameraSmoothingVariants | Sort-Object) -join '; ')."

			$Script:CameraSmoothingVariant = $DefaultCameraSmoothingVariant
		}
	}

	if ($Null -eq $Script:HideChangeCameraControlReminder)
	{
		$Script:HideChangeCameraControlReminder = $False
	}

	if ($Null -eq $Script:HideSkipEventControlReminder)
	{
		$Script:HideSkipEventControlReminder = $False
	}

	if ($Null -eq $Script:HideItemDetailsControlReminderWhenHaggling)
	{
		$Script:HideItemDetailsControlReminderWhenHaggling = $False
	}

	if ($Null -eq $Script:HideItemDetailsControlReminderInItemMenus)
	{
		$Script:HideItemDetailsControlReminderInItemMenus = $False
	}

	$Script:UsingIntegral2DScaling = $Script:UseIntegral2DScaling -eq $True

	$DefaultInterpolatedFloatRecommendation = $Script:FramerateLimit -ne $GameFramerate

	foreach ($ConfigurableInterpolatedFloat in $ConfigurableInterpolatedFloats)
	{
		$ConfigurableInterpolatedFloat.Metadata.Recommendation = $DefaultInterpolatedFloatRecommendation
	}

	$DefaultTextureFilteringRecommendation = if ($Script:UsingIntegral2DScaling -or ($Null -ne $Script:ResolutionHeight -and $Script:ResolutionHeight % $GameBaseHeight -eq 0)) {'NearestNeighbour'} else {'Bilinear'}

	foreach ($ConfigurableTextureFiltering in $ConfigurableTextureFilterings)
	{
		$ConfigurableTextureFiltering.Metadata.Recommendation = if ($ConfigurableTextureFiltering.Metadata.Names[0] -ceq 'ShopShadows') {'Bilinear'} else {$DefaultTextureFilteringRecommendation}
	}

	$Script:InterpolatedFloatConfiguration = Resolve-InterpolatedFloatConfiguration -Final:$Final
	$Script:TextureFilteringConfiguration = Resolve-TextureFilteringConfiguration -Final:$Final

	if ($Null -eq $Script:ConfigureDxWrapper)
	{
		$Script:ConfigureDxWrapper = $True
	}

	if ($Null -eq $Script:ConfigureDgVoodoo2)
	{
		$Script:ConfigureDgVoodoo2 = $True
	}

	if ($Null -eq $Script:ConfigureSpecialK)
	{
		$Script:ConfigureSpecialK = $True
	}

	if ($Null -eq $Script:SaveSettingsToConfiguration)
	{
		$Script:SaveSettingsToConfiguration = -not $Script:NonInteractive
	}

	if ($Null -eq $Script:DoNotInstallThirdPartyToolsByDefaultNextTime)
	{
		$Script:DoNotInstallThirdPartyToolsByDefaultNextTime = -not $Script:NonInteractive
	}
}


$RecettearExeName = 'recettear.exe'


function Use-Disposable ($InputObject, [ScriptBlock] $Use)
{
	try
	{
		& $Use $InputObject
	}
	catch
	{
		throw
	}
	finally
	{
		if ($Null -ne $InputObject)
		{
			$InputObject.Dispose()
		}
	}
}


function Select-ChosenOne
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
				$InputObject,

		[Parameter(Mandatory, Position = 0)]
				[ScriptBlock] $Choose,

		[Parameter(Position = 1)]
				[ScriptBlock] $Map = {Param ($A) $A}
	)

	Begin
	{
		$ChosenOne = $Null
		$ProcessedFirst = $False
	}

	Process
	{
		if ($ProcessedFirst)
		{
			$ChosenOne = @($ChosenOne, $InputObject)[(& $Choose (& $Map $ChosenOne) (& $Map $InputObject))]
		}
		else
		{
			$ProcessedFirst = $True
			$ChosenOne = $InputObject
		}
	}

	End
	{
		$ChosenOne
	}
}


$SelectGreater = {Param ($A, $B) [Int32] ($B -gt $A)}


<# See some scant documentation, here: https://developer.valvesoftware.com/wiki/KeyValues #>
function ConvertFrom-VDF
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline, Position = 0)]
				[String] $VDF
	)

	Process
	{
		$ParentObjectKey = [Object]::new()
		$Object = [Ordered] @{}
		$Index = 0
		$Length = $VDF.Length

		$CR = [Char] "`r"
		$LF = [Char] "`n"
		$Tab = [Char] "`t"
		$Space = [Char] ' '
		$Quote = [Char] '"'
		$Backslash = [Char] '\'
		$ForwardSlash = [Char] '/'
		$n = [Char] 'n'
		$t = [Char] 't'
		$LeftCurlyBracket = [Char] '{'
		$RightCurlyBracket = [Char] '}'
		$LeftSquareBracket = [Char] '['
		$RightSquareBracket = [Char] ']'
		$LeastDigit = [Char] '0'
		$MostDigit = [Char] '9'
		$Dot = [Char] '.'
		$Minus = [Char] '-'
		$Plus = [Char] '+'

		$KeyOrValue = 0
		$KeyValuePair = @($Null, $Null)

		while ($Index -lt $Length)
		{
			$C = [Char] $VDF[$Index]

			if ($C -ceq $Tab -or $C -ceq $Space -or $C -ceq $LF -or $C -ceq $CR)
			{
				++$Index
				continue
			}

			if ($C -ceq $Quote)
			{
				++$Index

				$Sequence = for (;;)
				{
					if ($Index -ge $Length)
					{
						Write-Error "A string was left unterminated at UTF-16 code-unit $Index."

						break
					}

					$C = [Char] $VDF[$Index]

					if ($C -ceq $Quote)
					{
						++$Index

						break
					}

					if ($C -ceq $Backslash)
					{
						++$Index

						if ($Index -ge $Length)
						{
							Write-Error "An escape-sequence was left unterminated at UTF-16 code-unit $Index."

							break
						}

						$C = [Char] $VDF[$Index]

						if ($C -ceq $Backslash)
						{
							$Backslash
						}
						elseif ($C -ceq $Quote)
						{
							$Quote
						}
						elseif ($C -ceq $n)
						{
							$LF
						}
						elseif ($C -ceq $t)
						{
							$Tab
						}
						else
						{
							Write-Error "The escape sequence ``\$C`` at UTF-16 code-unit $Index is invalid."
						}

						++$Index
					}
					else
					{
						++$Index

						$C
					}
				}

				$KeyValuePair[($KeyOrValue++)] = if ($Null -ne $Sequence) {[String]::new($Sequence)} else {[String]::Empty}

				if ($KeyOrValue -eq 2)
				{
					$KeyOrValue = 0
					$Object[[Object] $KeyValuePair[0]] = $KeyValuePair[1]
				}
			}
			elseif ($C -ceq $LeftCurlyBracket)
			{
				$SubObject = [Ordered] @{}

				if ($KeyOrValue -eq 1)
				{
					$Object[[Object] $KeyValuePair[0]] = $SubObject
					$KeyOrValue = 0
				}
				else
				{
					Write-Error "An object opened at UTF-16 code-unit $Index was not preceded by a key."
				}

				$SubObject[$ParentObjectKey] = $Object
				$Object = $SubObject

				++$Index
			}
			elseif ($C -ceq $RightCurlyBracket)
			{
				$ParentObject = $Object[$ParentObjectKey]

				if ($Null -ne $ParentObject)
				{
					if ($KeyOrValue -gt 0)
					{
						Write-Error "A key was left without a value in the object ending at UTF-16 code-unit $Index."

						$KeyOrValue = 0
					}
				}
				else
				{
					Write-Error "A ``}`` at UTF-16 code-unit $Index was not preceded by a ``{``."

					++$Index

					break
				}

				$Object.Remove($ParentObjectKey)
				$Object = $ParentObject

				++$Index
			}
			elseif ($C -ceq $ForwardSlash -and $Index + 1 -lt $Length -and [Char] $VDF[$Index + 1] -ceq $ForwardSlash)
			{
				$Index += 2

				for (;;)
				{
					if ($Index -ge $Length)
					{
						break
					}

					$C = [Char] $VDF[$Index]

					++$Index

					if ($C -ceq $LF -or $C -ceq $CR)
					{
						break
					}
				}
			}
			else
			{
				$NonNumeric = $False
				$DotCount = 0
				$PlusAndMinusCount = 0

				$Primitive = [String]::new(
					$(
						for (;;)
						{
							if ($C -ge $LeastDigit -and $C -le $MostDigit)
							{
								$C
							}
							elseif ($C -ceq $Dot)
							{
								++$DotCount

								$C
							}
							elseif ($C -ceq $Minus -or $C -ceq $Plus)
							{
								++$PlusAndMinusCount

								$C
							}
							else
							{
								$NonNumeric = $True

								$C
							}

							++$Index

							if ($Index -ge $Length)
							{
								break
							}

							$C = [Char] $VDF[$Index]

							if ($C -ceq $Tab -or $C -ceq $Space -or $C -ceq $LF -or $C -ceq $CR -or $C -ceq $Quote -or $C -ceq $LeftCurlyBracket -or $C -ceq $RightCurlyBracket)
							{
								break
							}
						}
					)
				)

				if (
					    $Primitive.Length -le 1 `
					-or [Char] $Primitive[0] -cne $LeftSquareBracket `
					-or [Char] $Primitive[$Primitive.Length - 1] -cne $RightSquareBracket
				)
				{
					$KeyValuePair[($KeyOrValue++)] = if (
						    $NonNumeric `
						-or $DotCount -ge 2 `
						-or $PlusAndMinusCount -ge 2 `
						-or ($PlusAndMinusCount -eq 1 -and [Char] $Primitive[0] -cne $Minus -and [Char] $Primitive[0] -cne $Plus))
					{
						$Primitive
					}
					elseif ($DotCount -eq 1)
					{
						[Float]::Parse($Primitive)
					}
					else
					{
						$Integer = $Null

						if (
							    [Int32]::TryParse($Primitive, [Ref] $Integer) `
							-or [UInt32]::TryParse($Primitive, [Ref] $Integer) `
							-or [Int64]::TryParse($Primitive, [Ref] $Integer) `
							-or [UInt64]::TryParse($Primitive, [Ref] $Integer)
						)
						{
							$Integer
						}
						else
						{
							$Primitive
						}
					}

					if ($KeyOrValue -eq 2)
					{
						$KeyOrValue = 0
						$Object[[Object] $KeyValuePair[0]] = $KeyValuePair[1]
					}
				}
			}
		}

		while ($Null -ne ($ParentObject = $Object[$ParentObjectKey]))
		{
			Write-Error 'An object was left unclosed.'

			$Object.Remove($ParentObjectKey)
			$Object = $ParentObject
		}

		if ($KeyOrValue -gt 0)
		{
			Write-Error "The last key of the root object of the VDF was left without a value."
		}

		$Object
	}
}


$INILineRegex = [RegEx]::new('^(?:(?<Section>\s*\[(?<SectionName>[^\];]*)\]\s*)|(?<Entry>)\s*(?<EntryKey>[^=;]+?)\s*=\s*(?<EntryValue>[^;]*?)\s*|\s*)?(?<Comment>;(?<CommentText>.*))?$', [Text.RegularExpressions.RegexOptions]::Compiled)


function Set-ValuesInINI ($INILines, $ReplacementsBySection)
{
	$NoReplacements = @{}
	$Lines = $INILines.GetEnumerator()

	$Replacements = $ReplacementsBySection[[String]::Empty]
	$ReplacementsBySection.Remove([String]::Empty)

	if ($Null -eq $Replacements)
	{
		$Replacements = $NoReplacements
	}

	while ($Lines.MoveNext())
	{
		$Match = $INILineRegex.Match($Lines.Current)

		if ($Match.Success)
		{
			if (($Group = $Match.Groups['SectionName']).Success)
			{
				foreach ($Replacement in $Replacements.GetEnumerator())
				{
					"$($Replacement.Key)=$($Replacement.Value)"
				}

				$Replacements = $ReplacementsBySection[$Group.Value]
				$ReplacementsBySection.Remove($Group.Value)

				if ($Null -eq $Replacements)
				{
					$Replacements = $NoReplacements
				}

				$Lines.Current
			}
			elseif (($Group = $Match.Groups['EntryKey']).Success)
			{
				if ($Null -ne ($Replacement = $Replacements[$Group.Value]))
				{
					$Replacements.Remove($Group.Value)

					$Group = $Match.Groups['EntryValue']

					"$($Lines.Current.Substring(0, $Group.Index))$Replacement$($Lines.Current.Substring($Group.Index + $Group.Length))"
				}
				else
				{
					$Lines.Current
				}
			}
			else
			{
				$Lines.Current
			}
		}
		else
		{
			$Lines.Current
		}
	}

	foreach ($Replacements in $ReplacementsBySection.GetEnumerator())
	{
		[String]::Empty
		"[$($Replacements.Key)]"

		foreach ($Replacement in $Replacements.Value.GetEnumerator())
		{
			"$($Replacement.Key)=$($Replacement.Value)"
		}
	}
}


function Get-ValuesFromINI ($INILines)
{
	$Sections = [Ordered] @{[String]::Empty = ($Section = [Ordered] @{})}

	$Lines = $INILines.GetEnumerator()

	while ($Lines.MoveNext())
	{
		$Match = $INILineRegex.Match($Lines.Current)

		if ($Match.Success)
		{
			if (($Group = $Match.Groups['SectionName']).Success)
			{
				$Section = $Sections[$Group.Value]

				if ($Null -eq $Section)
				{
					$Sections[$Group.Value] = ($Section = [Ordered] @{})
				}
			}
			elseif (($Group = $Match.Groups['EntryKey']).Success)
			{
				$Key = $Group.Value

				if (-not $Section.Contains($Key))
				{
					$Group = $Match.Groups['EntryValue']

					$Section[$Key] = $Group.Value
				}
			}
		}
	}

	$Sections
}


function Get-DataFromRegistry
{
	Use-Disposable ([Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)) `
	{
		Param ($Registry)

		[PSCustomObject] @{
			SteamPath = $(if (($Key = $Registry.OpenSubKey('SOFTWARE\Valve\Steam'))) {$Key.GetValue('InstallPath')})
			GOGInstallationPath = $(if (($Key = $Registry.OpenSubKey('SOFTWARE\GOG.com\Games\1441875624'))) {$Key.GetValue('PATH')})
		}
	}
}


function Get-RecettearInstallations
{
	[CmdletBinding()]
	Param ()

	$RegistryData = Get-DataFromRegistry
	$SteamPath = $RegistryData.SteamPath
	$GOGPath = $RegistryData.GOGInstallationPath

	if ($($Path = Join-Path $PSScriptRoot $RecettearExeName; Test-Path -LiteralPath $Path -PathType Leaf))
	{
		[PSCustomObject] @{Source = 'ScriptRoot'; UIChoice = 'Script-&root'; Path = $Path}
	}

	if ($($Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RecettearExeName); Test-Path -LiteralPath $Path -PathType Leaf))
	{
		[PSCustomObject] @{Source = 'CurrentDirectory'; UIChoice = '&Current-directory'; Path = $Path}
	}

	if (
		     $Null -ne $SteamPath `
		-and $Null -ne ($LibraryFoldersVDF = Get-Content -Raw -LiteralPath (Join-Path $SteamPath steamapps/libraryfolders.vdf) -ErrorAction Ignore) `
		-and $Null -ne ($LibraryFolders = try {$LibraryFoldersVDF | ConvertFrom-VDF -ErrorAction Stop} catch {})
	)
	{
		$LibraryFolders.libraryfolders.Values | ? {$_.apps.Contains('70400')} | % `
		{
			if (
				     $Null -ne ($ManifestVDF = Get-Content -Raw -LiteralPath (Join-Path $_.path steamapps/appmanifest_70400.acf) -ErrorAction Ignore) `
				-and $Null -ne ($Manifest = try {$ManifestVDF | ConvertFrom-VDF -ErrorAction Stop} catch {}) `
				-and $(
					$AppState = $Manifest.AppState
					$StateFlags = [UInt64] $AppState.StateFlags

					     $StateFlags -ne 0 -and ($StateFlags -band (1 -bor 2048)) -eq 0 `
					-and $(
						$Path = Join-Path $_.path "steamapps/common/$($AppState.installdir)/$RecettearExeName"
						Test-Path -LiteralPath $Path -PathType Leaf
					)
				)
			)
			{
				[PSCustomObject] @{Source = 'Steam'; UIChoice = '&Steam'; Path = $Path; Time = [UInt64] $AppState.LastUpdated}
			}
		} `
		| Select-ChosenOne $SelectGreater {Param ($A) $A.Time}
	}

	if ($Null -ne $GOGPath -and $($Path = Join-Path $GOGPath $RecettearExeName; (Test-Path -LiteralPath $Path -PathType Leaf)))
	{
		[PSCustomObject] @{Source = 'GOG'; UIChoice = '&GOG.com'; Path = $Path}
	}
}


$RecettearExecutable = if ($Null -eq $Script:RecettearExecutablePath)
{
	$DetectedInstallations = Get-RecettearInstallations

	if ($Script:NonInteractive)
	{
		$MostPreferredInstallation = foreach ($Source in $Script:DetectedInstallationPreference)
		{
			$FoundInstallation = $DetectedInstallations.Where({$_.Source -eq $Source}, 'First')[0]

			if ($Null -ne $FoundInstallation)
			{
				$FoundInstallation

				break
			}
		}

		if ($Null -ne $MostPreferredInstallation)
		{
			Get-Item -LiteralPath $MostPreferredInstallation.Path -ErrorAction Stop
		}
		else
		{
			throw [FancyScreenPatchForRecettearNoInstallationFoundException]::new(
				'No preferred installation could be found',
				[PSCustomObject] @{DetectedInstallationPreference = $Script:DetectedInstallationPreference; DetectedInstallations = $DetectedInstallations}
			)
		}
	}
	else
	{
		function Get-PathOfRecettearExecutableFileDialog
		{
			[CmdletBinding()] Param ()

			Add-Type -AssemblyName 'System.Windows.Forms' -ErrorAction Stop

			Use-Disposable ([Windows.Forms.OpenFileDialog]::new()) `
			{
				Param ($Dialog)

				$Dialog.InitialDirectory = $PSScriptRoot
				$Dialog.FileName = $RecettearExeName
				$Dialog.Filter = "$RecettearExeName|*.exe"
				$Dialog.Title = "Please select the `"$RecettearExeName`" to be patched."

				if ($Dialog.ShowDialog() -eq 'OK')
				{
					$Dialog.FileName
				}
			}
		}


		function Get-PathOfRecettearExecutableFromHost
		{
			[CmdletBinding()] Param ()
			Read-Host -Prompt "Please supply the path of the `"$RecettearExeName`" executable to be patched"
		}


		function Get-RecettearExecutableFromUserInput
		{
			[CmdletBinding()] Param ()

			$StopWatch.Stop()
			if (($Item = Get-Item -LiteralPath (Get-PathOfRecettearExecutableFileDialog -ErrorAction Ignore) -ErrorAction Ignore)) {return $Item}
			if (($Item = Get-Item -LiteralPath (Get-PathOfRecettearExecutableFromHost -ErrorAction Ignore) -ErrorAction Stop)) {return $Item}
		}

		if ($DetectedInstallations.Count -eq 0)
		{
			Get-RecettearExecutableFromUserInput
			$StopWatch.Start()
		}
		else
		{
			$StopWatch.Stop()
			$Choice = $Host.UI.PromptForChoice('The following installations of Recettear were detected.', 'Please select which installation you would like to patch (if any):', @(($DetectedInstallations.ForEach{"$($_.UIChoice): $($_.Path)"}, 'A &different installation: <Select your own path>').ForEach{$_}), 0)
			$StopWatch.Start()

			Write-Host

			if ($Choice -eq $DetectedInstallations.Count)
			{
				Get-RecettearExecutableFromUserInput
				$StopWatch.Start()
			}
			else
			{
				Get-Item -LiteralPath $DetectedInstallations[$Choice].Path -ErrorAction Stop
			}
		}

	}
}
else
{
	Get-Item -LiteralPath $Script:RecettearExecutablePath -ErrorAction Stop
}


if ($Null -eq $RecettearExecutable)
{
	throw [FancyScreenPatchForRecettearNoRecettearExecutableException]::new("No `"$RecettearExeName`" executable could be found to be patched.", [PSCustomObject] @{})
}


$RecettearExecutableVersionInfo = $RecettearExecutable.VersionInfo


$ConfigurationFilePath = if ($Null -ne $RecettearExecutable)
{
	Join-Path $RecettearExecutable.DirectoryName Install-FancyScreenPatchForRecettear.config.json
}


function Write-Configuration
{
	[CmdletBinding()]
	Param ($ConfigurationObject)

	if ($Script:DoNotInstallThirdPartyToolsByDefaultNextTime)
	{
		$ConfigurationObject.InstallDxWrapper = $False
		$ConfigurationObject.InstallDgVoodoo2 = $False
		$ConfigurationObject.InstallSpecialK = $False
	}

	New-Item $ConfigurationFilePath -Force -Value ($ConfigurationObject | ConvertTo-JSON -Depth $ScriptArgumentDepth | Out-String) -ErrorAction Stop > $Null
}


if (
	     $Null -eq $Script:Configuration `
	-and $Null -ne $ConfigurationFilePath `
	-and (Test-Path -LiteralPath $ConfigurationFilePath -PathType Leaf) `
	-and $Null -ne ($JSON = Get-Content -Raw -LiteralPath $ConfigurationFilePath -ErrorAction Continue)
)
{
	$Script:Configuration = $JSON | ConvertFrom-Json -ErrorAction Continue
}


if ($Null -ne $Script:Configuration)
{
	if ($Null -eq $Script:FramerateLimit -and $Null -ne $Script:Configuration.FramerateLimit) {$Script:FramerateLimit = [UInt32] $Script:Configuration.FramerateLimit}
	if ($Null -eq $Script:ResolutionWidth -and $Null -ne $Script:Configuration.ResolutionWidth) {$Script:ResolutionWidth = [UInt32] $Script:Configuration.ResolutionWidth}
	if ($Null -eq $Script:ResolutionHeight -and $Null -ne $Script:Configuration.ResolutionHeight) {$Script:ResolutionHeight = [UInt32] $Script:Configuration.ResolutionHeight}
	if ($Null -eq $Script:HUDWidth -and $Null -ne $Script:Configuration.HUDWidth) {$Script:HUDWidth = [UInt32] $Script:Configuration.HUDWidth}
	if ($Null -eq $Script:UseIntegral2DScaling -and $Null -ne $Script:Configuration.UseIntegral2DScaling) {$Script:UseIntegral2DScaling = [Bool] $Script:Configuration.UseIntegral2DScaling}
	if ($Null -eq $Script:MobDrawDistancePatchVariant -and $Null -ne $Script:Configuration.MobDrawDistancePatchVariant) {$Script:MobDrawDistancePatchVariant = [String] $Script:Configuration.MobDrawDistancePatchVariant}
	if ($Null -eq $Script:CameraSmoothingVariant -and $Null -ne $Script:Configuration.CameraSmoothingVariant) {$Script:CameraSmoothingVariant = [String] $Script:Configuration.CameraSmoothingVariant}
	if ($Null -eq $Script:FloatInterpolation -and $Null -ne $Script:Configuration.FloatInterpolation) {$Script:FloatInterpolation = $Script:Configuration.FloatInterpolation}
	if ($Null -eq $Script:TextureFiltering -and $Null -ne $Script:Configuration.TextureFiltering) {$Script:TextureFiltering = $Script:Configuration.TextureFiltering}
	if ($Null -eq $Script:HideChangeCameraControlReminder -and $Null -ne $Script:Configuration.HideChangeCameraControlReminder) {$Script:HideChangeCameraControlReminder = [Bool] $Script:Configuration.HideChangeCameraControlReminder}
	if ($Null -eq $Script:HideSkipEventControlReminder -and $Null -ne $Script:Configuration.HideSkipEventControlReminder) {$Script:HideSkipEventControlReminder = [Bool] $Script:Configuration.HideSkipEventControlReminder}
	if ($Null -eq $Script:HideItemDetailsControlReminderWhenHaggling -and $Null -ne $Script:Configuration.HideItemDetailsControlReminderWhenHaggling) {$Script:HideItemDetailsControlReminderWhenHaggling = [Bool] $Script:Configuration.HideItemDetailsControlReminderWhenHaggling}
	if ($Null -eq $Script:HideItemDetailsControlReminderInItemMenus -and $Null -ne $Script:Configuration.HideItemDetailsControlReminderInItemMenus) {$Script:HideItemDetailsControlReminderInItemMenus = [Bool] $Script:Configuration.HideItemDetailsControlReminderInItemMenus}
	if ($Null -eq $Script:SkipPatching -and $Null -ne $Script:Configuration.SkipPatching) {$Script:SkipPatching = [Bool] $Script:Configuration.SkipPatching}
	if ($Null -eq $Script:SkipPostPatchOperations -and $Null -ne $Script:Configuration.SkipPostPatchOperations) {$Script:SkipPostPatchOperations = [Bool] $Script:Configuration.SkipPostPatchOperations}
	if ($Null -eq $Script:GetGameWindowMode -and $Null -ne $Script:Configuration.GetGameWindowMode) {$Script:GetGameWindowMode = [Bool] $Script:Configuration.GetGameWindowMode}
	if ($Null -eq $Script:SetGameWindowMode -and $Null -ne $Script:Configuration.SetGameWindowMode) {$Script:SetGameWindowMode = $Script:Configuration.SetGameWindowMode}
	if ($Null -eq $Script:InstallDxWrapper -and $Null -ne $Script:Configuration.InstallDxWrapper) {$Script:InstallDxWrapper = [Bool] $Script:Configuration.InstallDxWrapper}
	if ($Null -eq $Script:ConfigureDxWrapper -and $Null -ne $Script:Configuration.ConfigureDxWrapper) {$Script:ConfigureDxWrapper = [Bool] $Script:Configuration.ConfigureDxWrapper}
	if ($Null -eq $Script:ResetDxWrapperConfiguration -and $Null -ne $Script:Configuration.ResetDxWrapperConfiguration) {$Script:ResetDxWrapperConfiguration = [Bool] $Script:Configuration.ResetDxWrapperConfiguration}
	if ($Null -eq $Script:CheckDxWrapperConfiguration -and $Null -ne $Script:Configuration.CheckDxWrapperConfiguration) {$Script:CheckDxWrapperConfiguration = [Bool] $Script:Configuration.CheckDxWrapperConfiguration}
	if ($Null -eq $Script:InstallDgVoodoo2 -and $Null -ne $Script:Configuration.InstallDgVoodoo2) {$Script:InstallDgVoodoo2 = [Bool] $Script:Configuration.InstallDgVoodoo2}
	if ($Null -eq $Script:ResetDgVoodoo2Configuration -and $Null -ne $Script:Configuration.ResetDgVoodoo2Configuration) {$Script:ResetDgVoodoo2Configuration = [Bool] $Script:Configuration.ResetDgVoodoo2Configuration}
	if ($Null -eq $Script:ConfigureDgVoodoo2 -and $Null -ne $Script:Configuration.ConfigureDgVoodoo2) {$Script:ConfigureDgVoodoo2 = [Bool] $Script:Configuration.ConfigureDgVoodoo2}
	if ($Null -eq $Script:CheckDgVoodoo2Configuration -and $Null -ne $Script:Configuration.CheckDgVoodoo2Configuration) {$Script:CheckDgVoodoo2Configuration = [Bool] $Script:Configuration.CheckDgVoodoo2Configuration}
	if ($Null -eq $Script:InstallSpecialK -and $Null -ne $Script:Configuration.InstallSpecialK) {$Script:InstallSpecialK = [Bool] $Script:Configuration.InstallSpecialK}
	if ($Null -eq $Script:ResetSpecialKConfiguration -and $Null -ne $Script:Configuration.ResetSpecialKConfiguration) {$Script:ResetSpecialKConfiguration = [Bool] $Script:Configuration.ResetSpecialKConfiguration}
	if ($Null -eq $Script:ConfigureSpecialK -and $Null -ne $Script:Configuration.ConfigureSpecialK) {$Script:ConfigureSpecialK = [Bool] $Script:Configuration.ConfigureSpecialK}
	if ($Null -eq $Script:CheckSpecialKConfiguration -and $Null -ne $Script:Configuration.CheckSpecialKConfiguration) {$Script:CheckSpecialKConfiguration = [Bool] $Script:Configuration.CheckSpecialKConfiguration}
	if ($Null -eq $Script:SetDirectXVersionToUse -and $Null -ne $Script:Configuration.SetDirectXVersionToUse) {$Script:SetDirectXVersionToUse = $Script:Configuration.SetDirectXVersionToUse}
	if ($Null -eq $Script:GetDirectXVersionToUse -and $Null -ne $Script:Configuration.GetDirectXVersionToUse) {$Script:GetDirectXVersionToUse = [Bool] $Script:Configuration.GetDirectXVersionToUse}
	if ($Null -eq $Script:SetVerticalSyncEnabled -and $Null -ne $Script:Configuration.SetVerticalSyncEnabled) {$Script:SetVerticalSyncEnabled = $Script:Configuration.SetVerticalSyncEnabled}
	if ($Null -eq $Script:GetVerticalSyncEnabled -and $Null -ne $Script:Configuration.GetVerticalSyncEnabled) {$Script:GetVerticalSyncEnabled = [Bool] $Script:Configuration.GetVerticalSyncEnabled}
	if ($Null -eq $Script:SaveSettingsToConfiguration -and $Null -ne $Script:Configuration.SaveSettingsToConfiguration) {$Script:SaveSettingsToConfiguration = [Bool] $Script:Configuration.SaveSettingsToConfiguration}
	if ($Null -eq $Script:DoNotInstallThirdPartyToolsByDefaultNextTime -and $Null -ne $Script:Configuration.DoNotInstallThirdPartyToolsByDefaultNextTime) {$Script:DoNotInstallThirdPartyToolsByDefaultNextTime = [Bool] $Script:Configuration.DoNotInstallThirdPartyToolsByDefaultNextTime}
}


Resolve-Configuration


$DxWrapperDLL = 'winmm.dll'
$DxWrapperActualDLL = 'dxwrapper.dll'
$DgVoodoo2EnabledDLL = 'd3d9.dll'
$DgVoodoo2DisabledDLL = "$DgVoodoo2EnabledDLL.disabled"
$DgVoodoo2DLL = $DgVoodoo2EnabledDLL
$SpecialKWrapperName = 'dinput8'
$SpecialKDLL = "$SpecialKWrapperName.dll"


$DxWrapperIsProbablyInstalled = (Test-Path -LiteralPath (Join-Path $RecettearExecutable.DirectoryName $DxWrapperDLL) -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $RecettearExecutable.DirectoryName $DxWrapperActualDLL) -PathType Leaf)

if (-not $DxWrapperIsProbablyInstalled -and $Null -eq $Script:InstallDxWrapper)
{
	Write-Host "Either a `"$DxWrapperDLL`" file or a `"$DxWrapperActualDLL`" file was not found in the game's installation folder, and thus `"DXWrapper`" is being installed by default."

	$Script:InstallDxWrapper = $True
}


$DgVoodoo2IsProbablyInstalled = Test-Path -LiteralPath (Join-Path $RecettearExecutable.DirectoryName $DgVoodoo2DLL) -PathType Leaf

if (-not $DgVoodoo2IsProbablyInstalled -and ($DgVoodoo2IsProbablyInstalled = Test-Path -LiteralPath (Join-Path $RecettearExecutable.DirectoryName $DgVoodoo2DisabledDLL) -PathType Leaf))
{
	$DgVoodoo2DLL = $DgVoodoo2DisabledDLL
}

if (-not $DgVoodoo2IsProbablyInstalled -and ($Script:SetDirectXVersionToUse -eq 12 -or $Script:SetDirectXVersionToUse -eq 11) -and $Null -eq $Script:InstallDgVoodoo2)
{
	Write-Host "A `"$DgVoodoo2DLL`" file was not found in the game's installation folder, and as DirectX $Script:SetDirectXVersionToUse is to be used `"dgVoodoo2`" is being installed by default."

	$Script:InstallDgVoodoo2 = $True
}


$SpecialKIsProbablyInstalled = Test-Path -LiteralPath (Join-Path $RecettearExecutable.DirectoryName $SpecialKDLL) -PathType Leaf

if (-not $SpecialKIsProbablyInstalled -and $Null -eq $Script:InstallSpecialK)
{
	Write-Host "A `"$SpecialKDLL`" file was not found in the game's installation folder, and thus `"Special K`" is being installed by default."

	$Script:InstallSpecialK = $True
}


function Read-YesOrNo ($Prompt)
{
	$Host.UI.PromptForChoice($Null, $Prompt, ('&Yes', '&No'), 0) -eq 0
}


function New-ConfigurationHashTable ($TapBefore)
{
	$Object = [Ordered] @{}

	if ($Null -ne $TapBefore)
	{
		& $TapBefore $Object
	}

	$Object.FramerateLimit = $Script:FramerateLimit
	$Object.ResolutionWidth = $Script:ResolutionWidth
	$Object.ResolutionHeight = $Script:ResolutionHeight
	$Object.HUDWidth = $Script:HUDWidth
	$Object.UseIntegral2DScaling = $Script:UseIntegral2DScaling
	$Object.MobDrawDistancePatchVariant = $Script:MobDrawDistancePatchVariant
	$Object.CameraSmoothingVariant = $Script:CameraSmoothingVariant
	$Object.FloatInterpolation = $Script:FloatInterpolation
	$Object.TextureFiltering = $Script:TextureFiltering
	$Object.HideChangeCameraControlReminder = $Script:HideChangeCameraControlReminder
	$Object.HideSkipEventControlReminder = $Script:HideSkipEventControlReminder
	$Object.HideItemDetailsControlReminderWhenHaggling = $Script:HideItemDetailsControlReminderWhenHaggling
	$Object.HideItemDetailsControlReminderInItemMenus = $Script:HideItemDetailsControlReminderInItemMenus
	$Object.SkipPatching = $Script:SkipPatching
	$Object.SkipPostPatchOperations = $Script:SkipPostPatchOperations
	$Object.GetGameWindowMode = $Script:GetGameWindowMode
	$Object.SetGameWindowMode = $Script:SetGameWindowMode
	$Object.InstallDxWrapper = $Script:InstallDxWrapper
	$Object.ConfigureDxWrapper = $Script:ConfigureDxWrapper
	$Object.ResetDxWrapperConfiguration = $Script:ResetDxWrapperConfiguration
	$Object.CheckDxWrapperConfiguration = $Script:CheckDxWrapperConfiguration
	$Object.InstallDgVoodoo2 = $Script:InstallDgVoodoo2
	$Object.ConfigureDgVoodoo2 = $Script:ConfigureDgVoodoo2
	$Object.ResetDgVoodoo2Configuration = $Script:ResetDgVoodoo2Configuration
	$Object.CheckDgVoodoo2Configuration = $Script:CheckDgVoodoo2Configuration
	$Object.InstallSpecialK = $Script:InstallSpecialK
	$Object.ResetSpecialKConfiguration = $Script:ResetSpecialKConfiguration
	$Object.ConfigureSpecialK = $Script:ConfigureSpecialK
	$Object.SetDirectXVersionToUse = $Script:SetDirectXVersionToUse
	$Object.GetDirectXVersionToUse = $Script:GetDirectXVersionToUse
	$Object.SetVerticalSyncEnabled = $Script:SetVerticalSyncEnabled
	$Object.GetVerticalSyncEnabled = $Script:GetVerticalSyncEnabled
	$Object.CheckSpecialKConfiguration = $Script:CheckSpecialKConfiguration
	$Object.SaveSettingsToConfiguration = $Script:SaveSettingsToConfiguration
	$Object.DoNotInstallThirdPartyToolsByDefaultNextTime = $Script:DoNotInstallThirdPartyToolsByDefaultNextTime

	$Object
}


function New-FloatInterpolationConfigurationHashTable
{
	$Object = @{}
	$Script:InterpolatedFloatConfiguration.GetEnumerator() | % {$Object[$_.Key] = $_.Value.Enabled}
	$Object
}


function New-TextureFilteringConfigurationHashTable
{
	$Object = @{}
	$Script:TextureFilteringConfiguration.GetEnumerator() | % {$Object[$_.Key] = $_.Value.Algorithm}
	$Object
}


Use-Disposable $(
	if ($Null -ne $RecettearExecutable)
	{
		try
		{
			$RecettearExecutable.Open([IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::Read)
		}
		catch [UnauthorizedAccessException]
		{
			if (
				     -not $Script:NonInteractive `
				-and $IsWindows `
				-and -not [Security.Principal.WindowsPrincipal]::new(
					     [Security.Principal.WindowsIdentity]::GetCurrent()
				     ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) `
				-and (Read-YesOrNo "`"$($RecettearExecutable.FullName)`" could not be accessed. Would you like to try again as an administrator?")
			)
			{
				$ScriptArguments = New-ConfigurationHashTable
				$ScriptArguments.RecettearExecutablePath = $RecettearExecutable.FullName
				$ScriptArguments.BackupPath = $Script:BackupPath
				$ScriptArguments.ClobberedByRestoredBackupBackupPath = $Script:ClobberedByRestoredBackupBackupPath
				$ScriptArguments.Configuration = $Script:Configuration

				if ($Null -ne $Script:PSBoundParameters.GameLanguageOverride) {$ScriptArguments.GameLanguageOverride = $Script:GameLanguageOverride}
				if ($Null -ne $Script:PSBoundParameters.RestoreBackupAutomatically) {$ScriptArguments.RestoreBackupAutomatically = $Script:RestoreBackupAutomatically}
				if ($Null -ne $Script:PSBoundParameters.ApplySupportedPatchAutomatically) {$ScriptArguments.ApplySupportedPatchAutomatically = $Script:ApplySupportedPatchAutomatically}
				if ($Null -ne $Script:PSBoundParameters.ReturnInformation) {$ScriptArguments.ReturnInformation = $Script:ReturnInformation}
				if ($Null -ne $Script:PSBoundParameters.SkipConfigurator) {$ScriptArguments.SkipConfigurator = $Script:SkipConfigurator}
				if ($Null -ne $Script:PSBoundParameters.ConfiguratorPort) {$ScriptArguments.ConfiguratorPort = $Script:ConfiguratorPort}
				if ($Null -ne $Script:PSBoundParameters.InterpolatedFloatsToIncludeInCheatTable) {$ScriptArguments.InterpolatedFloatsToIncludeInCheatTable = $Script:InterpolatedFloatsToIncludeInCheatTable}

				$ScriptArgumentsFile = New-TemporaryFile
				$ScriptArguments | Export-Clixml -Depth $ScriptArgumentDepth -LiteralPath $ScriptArgumentsFile.FullName -Encoding Unicode -ErrorAction Stop

				Start-Process ([Diagnostics.Process]::GetCurrentProcess().Path) -Verb RunAs @(
					  "-ExecutionPolicy Bypass -NoExit -Command `"" `
					+ "`$Data = Import-Clixml -LiteralPath \`"$($ScriptArgumentsFile.FullName)\`" -ErrorAction Stop; " `
					+ "Remove-Item -LiteralPath \`"$($ScriptArgumentsFile.FullName)\`" -ErrorAction Continue; " `
					+ "& \`"$PSCommandPath\`" @Data " `
					+ "`""
				)

				exit
			}
			else
			{
				throw
			}
		}
	}
) `
{
	Param ($RecettearFile)


	$ScriptResult = [Ordered] @{}


	function Get-InstallationRootPathFromExecutablePath ($ExecutablePath)
	{
		Split-Path -LiteralPath $ExecutablePath
	}


	function Test-FingerprintForFile ($Fingerprint, $File)
	{
		     $File.Length -eq $Fingerprint.FileSize `
		-and $Fingerprint.SHA256Hash -ceq (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
	}


	function Find-FileFromInstallations ($FileDescription)
	{
		if ($Null -eq $DetectedInstallations)
		{
			$Script:DetectedInstallations = Get-RecettearInstallations
		}

		foreach ($DetectedInstallation in $DetectedInstallations)
		{
			$RootPath = Get-InstallationRootPathFromExecutablePath $DetectedInstallation.Path

			if (
				     $Null -ne ($FoundFile = Get-Item -LiteralPath (Join-Path $RootPath $FileDescription.FileName) -ErrorAction Ignore) `
				-and (Test-FingerprintForFile $FileDescription.Fingerprint $FoundFile)
			)
			{
				$FoundFile

				break
			}
		}
	}


	function Use-FileWhatIsDownloadedIfNecessary ($FoundFile, $FileDescription, $UseFile)
	{
		try
		{
			if ($Null -eq $FoundFile)
			{
				$DestinationPath = Join-Path (Get-InstallationRootPathFromExecutablePath $RecettearExecutable.FullName) $FileDescription.FileName
				$PatchFileIsTemporary = $False

				if (Test-Path -LiteralPath $DestinationPath -PathType Leaf)
				{
					$DestinationPath = (New-TemporaryFile).FullName
					$PatchFileIsTemporary = $True
				}

				foreach ($URL in $FileDescription.URLs)
				{
					Write-Host "$([Environment]::NewLine)Downloading $($FileDescription.FileName) from $URL, please stand-by as it downloads."

					$StopWatch.Stop()

					Invoke-WebRequest -UseBasicParsing -Uri $URL -OutFile $DestinationPath -ErrorAction Continue

					$StopWatch.Start()

					if ($?)
					{
						$DownloadedFile = Get-Item -LiteralPath $DestinationPath -ErrorAction Stop
						$Fingerprint = $FileDescription.Fingerprint

						if (Test-FingerprintForFile $Fingerprint $DownloadedFile)
						{
							Write-Host "$([Environment]::NewLine)$($FileDescription.FileName) was downloaded successfully from $URL."

							$FoundFile = $DownloadedFile

							break
						}
						else
						{
							Write-Warning "$([Environment]::NewLine)`"$($DownloadedFile.FullName)`" downloaded from $URL either: did not match the expected file-size of $($Fingerprint.FileSize)-bytes, or did not match the expected SHA-256 hash of $($Fingerprint.SHA256Hash). The file may have been corrupted, or tampered with."
						}
					}
				}

				if ($Null -eq $FoundFile)
				{
					$ErrorMessage = "$($FileDescription.FileName) could not be downloaded from any of these URLs: $($FileDescription.URLs -join '; ')."

					if ($Script:NonInteractive)
					{
						throw [FancyScreenPatchForRecettearFailedToDownloadFileException]::new($ErrorMessage, [PSCustomObject] @{FileName = $FileDescription.FileName; DestinationPath = $DestinationPath; URLsTried = $FileDescription.URLs})
					}
					else
					{
						Write-Warning "$([Environment]::NewLine)$ErrorMessage. As such, it was not installed."

						return
					}
				}
			}

			& $UseFile $FoundFile $FileDescription
		}
		finally
		{
			if ($PatchFileIsTemporary -and $Null -ne $DestinationPath)
			{
				Remove-Item -LiteralPath $DestinationPath -ErrorAction Ignore
			}
		}
	}



	function Install-FromZipArchive ($ArchiveFile, $FileDescription, $ExtractionMapping)
	{
		if ($Null -eq ([Management.Automation.PSTypeName] 'System.IO.Compression.ZipFile').Type)
		{
			Add-Type -Assembly 'System.IO.Compression.FileSystem'
		}

		$RootPath = Get-InstallationRootPathFromExecutablePath $RecettearExecutable.FullName
		$RecettearFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath((Join-Path $RootPath 'recettear.exe'))

		Use-Disposable ([IO.Compression.ZipFile]::OpenRead($ArchiveFile.FullName)) `
		{
			Param ($PatchArchive)

			$AnyBackupEntries = Use-Disposable $(
				for (;;)
				{
					try
					{
						[IO.Compression.ZipFile]::Open(
							($BackupArchivePath = Join-Path $RootPath "Before_$($FileDescription.FileName)_Backup.$([DateTime]::UtcNow.Ticks).zip"),
							[IO.Compression.ZipArchiveMode]::Create
						)
					}
					catch [IO.IOException]
					{
						if ($_.Exception.HResult -eq 0x80070050)
						{
							continue
						}

						throw
					}

					break
				}
			) `
			{
				Param ($BackupArchive)

				$AnyBackupEntries = $False

				foreach ($PatchEntry in $PatchArchive.Entries)
				{
					if ($PatchEntry.Name.Length -eq 0 -and $PatchEntry.FullName.EndsWith([Char] '/'))
					{
						continue
					}

					$PatchEntryPath = $PatchEntry.FullName -replace $FileDescription.RootPath

					$DestinationPath = if ($Null -eq $ExtractionMapping)
					{
						$PatchEntryPath
					}
					elseif ($Null -ne ($Destination = $ExtractionMapping[$PatchEntryPath]))
					{
						$Destination
					}
					else
					{
						continue
					}

					$FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
						(Join-Path $RootPath $DestinationPath)
					)

					$FileParentPath = Split-Path -LiteralPath $FilePath

					if (-not (Test-Path -LiteralPath $FileParentPath))
					{
						New-Item -ItemType Directory -Force -Path $FilePath > $Null
					}

					$BackupEntry = $BackupArchive.CreateEntry($DestinationPath, [IO.Compression.CompressionLevel]::Fastest)
					$AnyBackupEntries = $True

					$PatchTheFile =
					{
						Param ($File)

						Use-Disposable $BackupEntry.Open() `
						{
							Param ($BackupEntryStream)

							$File.Position = 0
							$File.CopyTo($BackupEntryStream)
						}

						Use-Disposable $PatchEntry.Open() `
						{
							Param ($PatchEntryStream)

							$File.SetLength(0)
							$PatchEntryStream.CopyTo($File)
							$File.Flush()
							$File.Position = 0
						}
					}

					if ($FilePath -eq $RecettearFilePath)
					{
						& $PatchTheFile $RecettearFile
					}
					else
					{
						Use-Disposable ([IO.File]::Open($FilePath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::Read)) $PatchTheFile
					}
				}

				$AnyBackupEntries
			}

			if (-not $AnyBackupEntries)
			{
				Remove-Item -LiteralPath $BackupArchivePath
			}
		}
	}


			function Slice ($Array, $From, $To)
			{
				if ($From -eq $To)
				{
					return @() -as $Array.GetType()
				}

				return $Array[$From .. ($To - 1)]
			}


			function Hex ([String] $Hex)
			{
				$Hex.Trim() -split '\s+' | % {[Convert]::ToUInt64($_ -replace '_', 16)}
			}


			function LittleEndian ($Value, $Offset, $Length)
			{
				if ($Value -is [Byte])
				{
					return $Value
				}

				if ($Value -is [SByte])
				{
					return [Byte] ($Value -band 0xFF)
				}

				$Bytes = if ($Value -is [Byte[]]) {$Value} else {[BitConverter]::GetBytes($Value)}

				$Offset = if ($Null -ne $Offset) {$Offset} else {0}
				$Length = if ($Null -ne $Length) {$Length} else {$Bytes.Length - $Offset}

				if ([BitConverter]::IsLittleEndian)
				{
					$Slice = [Byte[]]::new($Length)
					[Byte[]]::Copy($Bytes, $Offset, $Slice, 0, $Length)
					$Slice
				}
				else
				{
					for ($Index = $Offset + $Bytes.Length; $Index--;) {$Bytes[$Index]}
				}
			}

			New-Alias -Name LE -Value LittleEndian


			function Get-MultipleOfPowerOfTwoAwayFromZero ($From, $MultipleOf)
			{
				$Mask = $MultipleOf - 1
				$From + (($MultipleOf - ($From -band $Mask)) -band $Mask)
			}


			function Divide ($Numerator, $Denominator)
			{
				$Remainder = $Null
				$Quotient = [Math]::DivRem($Numerator, $Denominator, [Ref] $Remainder)
				$Quotient
				$Remainder
			}


			$IntTypes = [Type[]] @($Null, [SByte], [Int16], $Null, [Int32], $Null, $Null, $Null, [Int64])
			$UIntTypes = [Type[]] @($Null, [Byte], [UInt16], $Null, [UInt32], $Null, $Null, $Null, [UInt64])


			if ($Null -eq $Script:FramerateLimit)
			{
				$Script:FramerateLimit = [UInt32] $GameFramerate
			}

			if ($Null -eq $Script:MobDrawDistancePatchVariant)
			{
				$Script:MobDrawDistancePatchVariant = 'OnlyVisual'
			}


	$UTF8 = [Text.UTF8Encoding]::new($False, $False)
	$Latin1 = [Text.Encoding]::GetEncoding('Latin1')


	$SecondAsMicroseconds = 1000000


	$PatchingFPSDisplay = $True


	function Update-ConfigurationDependentValues
	{
		#$Script:PresentationFrameTime = [UInt32] $($Q, $R = Divide $SecondAsMicroseconds $Script:FramerateLimit; $Q + ($R -ne 0))
		$Script:PresentationFrameTime = [UInt32] (Divide $SecondAsMicroseconds $Script:FramerateLimit)[0]
		#$Script:GameFrameTime = [UInt32] $($Q, $R = Divide $SecondAsMicroseconds $GameFramerate; $Q + ($R -ne 0))
		$Script:GameFrameTime = [UInt32] (Divide $SecondAsMicroseconds $GameFramerate)[0]

		$Script:PresentationFrameScale = $GameFramerate / $Script:FramerateLimit

		$Script:PatchingResolution = $Null -ne $Script:ResolutionWidth -and $Null -ne $Script:ResolutionHeight

		if ($PatchingResolution)
		{
			$Script:GameAspectRatioNumerator = [UInt32] 4
			$Script:GameAspectRatioDenominator = [UInt32] 3

			$Script:PatchedResolutionGCF = [UInt32] [BigInt]::GreatestCommonDivisor($Script:ResolutionWidth, $Script:ResolutionHeight)

			$Script:PatchedAspectRatioNumerator = [UInt32] ($Script:ResolutionWidth / $PatchedResolutionGCF)
			$Script:PatchedAspectRatioDenominator = [UInt32] ($Script:ResolutionHeight / $PatchedResolutionGCF)

			$Script:CommonAspectRatioDenominatorGCF = [UInt32] [BigInt]::GreatestCommonDivisor($GameAspectRatioDenominator, $PatchedAspectRatioDenominator)
			$Script:CommonAspectRatioDenominatorLCM = [UInt32] ($GameAspectRatioDenominator * ($PatchedAspectRatioDenominator / $CommonAspectRatioDenominatorGCF))

			$Script:GameToCommonAspectRatioScale = $CommonAspectRatioDenominatorLCM / $GameAspectRatioDenominator
			$Script:PatchedToCommonAspectRatioScale = $CommonAspectRatioDenominatorLCM / $PatchedAspectRatioDenominator

			$Script:GameAsCommonAspectRatioNumerator = [UInt32] ($GameAspectRatioNumerator * $GameToCommonAspectRatioScale)
			$Script:GameAsCommonAspectRatioDenominator = [UInt32] ($GameAspectRatioDenominator * $GameToCommonAspectRatioScale)

			$Script:PatchedAsCommonAspectRatioNumerator = [UInt32] ($PatchedAspectRatioNumerator * $PatchedToCommonAspectRatioScale)
			$Script:PatchedAsCommonAspectRatioDenominator = [UInt32] ($PatchedAspectRatioDenominator * $PatchedToCommonAspectRatioScale)

			if ($Null -eq $Script:HUDWidth)
			{
				$Script:HUDWidth = if ($PatchedAspectRatioNumerator / $PatchedAspectRatioDenominator -gt 16 / 9)
				{
					[UInt32] ((Divide ($Script:ResolutionHeight -shl 4) 9)[0] -band -2)
				}
				else
				{
					$Script:ResolutionWidth
				}
			}

			if ($Script:UsingIntegral2DScaling)
			{
				$Script:2DIntegralScale = [UInt32] (Divide $Script:ResolutionHeight ([UInt32] $GameBaseHeight))[0]
				$Script:2DResolutionHeight = [UInt32] ($GameBaseHeight * $2DIntegralScale)
				$Script:2DResolutionWidth = $GameBaseHeight * $2DIntegralScale * $PatchedAspectRatioNumerator / $PatchedAspectRatioDenominator
			}
			else
			{
				$Script:2DResolutionHeight = $Script:ResolutionHeight
				$Script:2DResolutionWidth = $Script:ResolutionWidth
			}

			$Script:2DResolutionDiffersFrom3DResolution = $2DResolutionHeight -ne $Script:ResolutionHeight

			$Script:PatchingAspectRatio = (
				    $Script:UsingIntegral2DScaling `
				-or (
					    $GameAsCommonAspectRatioNumerator -ne $PatchedAsCommonAspectRatioNumerator `
					-or $GameAsCommonAspectRatioDenominator -ne $PatchedAsCommonAspectRatioDenominator
				)
			)

			$Script:PatchedAspectRatio = $PatchedAspectRatioNumerator / $PatchedAspectRatioDenominator

			$Script:XScale = $PatchedAsCommonAspectRatioNumerator / $GameAsCommonAspectRatioNumerator
			$Script:YScale = $PatchedAsCommonAspectRatioDenominator / $GameAsCommonAspectRatioDenominator
			$Script:HUDXScale = $Script:ResolutionWidth / $Script:HUDWidth

			$Script:2DTo3DScale = $Script:ResolutionHeight / $2DResolutionHeight

			$Script:3DScaledBaseWidth = $GameBaseWidth * $XScale
			$Script:2DScaledBaseWidth = $GameBaseWidth * $2DTo3DScale * $XScale
			$Script:HUDScaledBaseWidth = ([UInt32] ($GameBaseWidth * $2DTo3DScale * $XScale / $HUDXScale) -band -2)
			$Script:2DScaledBaseHeight = $GameBaseHeight * $2DTo3DScale

			$Script:ScaledBaseWidth = $3DScaledBaseWidth

			$Script:3DTotalPillarboxWidth = $ScaledBaseWidth - $GameBaseWidth
			$Script:3DPillarboxWidth = $3DTotalPillarboxWidth / 2

			$Script:2DTotalPillarboxWidth = $2DScaledBaseWidth - $GameBaseWidth
			$Script:2DPillarboxWidth = $2DTotalPillarboxWidth / 2
			$Script:2DPillarboxWidthNegative = -$2DPillarboxWidth

			$Script:UIPillarboxWidth = $2DPillarboxWidth
			$Script:UIPillarboxWidthNegative = -$UIPillarboxWidth

			if ($Script:ResolutionWidth -ne $Script:HUDWidth)
			{
				$Script:HUDTotalPillarboxWidth = $HUDScaledBaseWidth - $GameBaseWidth
				$Script:HUDPillarboxWidth = $HUDTotalPillarboxWidth / 2
				$Script:HUDPillarboxWidthNegative = -$HUDPillarboxWidth
			}
			else
			{
				$Script:HUDPillarboxWidth = $UIPillarboxWidth
				$Script:HUDPillarboxWidthNegative = $UIPillarboxWidthNegative
			}

			$Script:2DTotalLetterboxHeight = ($GameBaseHeight * $2DTo3DScale) - $GameBaseHeight
			$Script:2DLetterboxHeight = $2DTotalLetterboxHeight / 2
			$Script:2DLetterboxHeightNegative = -$2DLetterboxHeight

			$Script:TotalPillarboxWidth = $3DTotalPillarboxWidth
			$Script:PillarboxWidth = $3DPillarboxWidth

			$Script:FullWidth = $3DScaledBaseWidth + $TotalPillarboxWidth
			$Script:2DFullWidth = $2DScaledBaseWidth

			$Script:HUDClockHandX = 41.6 - $HUDPillarboxWidth
			$Script:HUDClockHandY = 57.6 - $2DLetterboxHeight

			$Script:HUDClockDayOneDigitX = 89.6 - $HUDPillarboxWidth
			$Script:HUDClockDayTwoDigitX = 92.8 - $HUDPillarboxWidth
			$Script:HUDClockDayThreeDigitX = 96 - $HUDPillarboxWidth
			$Script:HUDClockDayFourDigitX = 104 - $HUDPillarboxWidth
			$Script:HUDClockDayY = 60.8 - $2DLetterboxHeight

			$Script:HUDClockPixX = 244.8 - $HUDPillarboxWidth
			$Script:HUDClockPixY = 22.4 - $2DLetterboxHeight

			$Script:HUDMerchantLevelYOffset = 424 + $2DLetterboxHeight

			$Script:HUDChangeCameraX = 440 + $HUDPillarboxWidth
			$Script:HUDChangeCameraY = 440 + $2DLetterboxHeight

			$Script:HUDFPSOSDX = 594 + $HUDPillarboxWidth
			$Script:HUDFPSOSDY = 468 + $2DLetterboxHeight
			$Script:HUDFPSCounterX = 616 + $HUDPillarboxWidth
			$Script:HUDFPSCounterXIncrement = 8
			$Script:HUDFPSCounterY = 462 + $2DLetterboxHeight

			$Script:HUDEnemyHealthBarXOffset416 = 416 + $HUDPillarboxWidth
			$Script:HUDEnemyHealthBarXOffset360 = 360 + $HUDPillarboxWidth
			$Script:HUDEnemyHealthBarXOffset364 = 364 + $HUDPillarboxWidth
			$Script:HUDEnemyHealthBarXOffset404 = 404 + $HUDPillarboxWidth
			$Script:HUDEnemyHealthBarXOffset418 = 418 + $HUDPillarboxWidth
			$Script:HUDEnemyHealthBarXOffset456 = 456 + $HUDPillarboxWidth
			$Script:HUDEnemyHealthBarXOffset488 = 488 + $HUDPillarboxWidth

			$Script:HUDCombatChainXOffset16 = 16 - $HUDPillarboxWidth
			$Script:HUDCombatChainXOffset96 = 96 - $HUDPillarboxWidth
			$Script:HUDCombatChainY = 160 - $2DLetterboxHeight

			$Script:HUDLevelNameXOffset460 = 460 + $HUDPillarboxWidth
			$Script:HUDLevelNameXOffset468 = 468 + $HUDPillarboxWidth
			$Script:HUDLevelNameXOffset560 = 560 + $HUDPillarboxWidth
			$Script:HUDLevelNameXOffset600 = 600 + $HUDPillarboxWidth
			$Script:HUDLevelNameYOffset = 436 + $2DLetterboxHeight

			$Script:HUDLootedLootXOffset = 160 + $HUDPillarboxWidth
			$Script:HUDLootedLootXOffsetMaximum = 496 + $HUDPillarboxWidth
			$Script:HUDLootedLootYOffset104 = 104 - $2DLetterboxHeight
			$Script:HUDLootedLootYOffset98 = 98 - $2DLetterboxHeight

			$Script:HUDHealthBarXOffset = 80 - $HUDPillarboxWidth
			$Script:HUDHealthBarYOffset = 10.400001 + $2DLetterboxHeight
			$Script:HUDSPBarYOffset = 53.600002 + $2DLetterboxHeight

			$Script:HUDAdventurerPanelYOffset = 376 + $2DLetterboxHeight

			$Script:HUDCombatNewsXOffset = 960 + $HUDPillarboxWidth
			$Script:HUDCombatNewsXOffsetMaximum = 632 + $HUDPillarboxWidth
			$Script:HUDCombatNewsYOffset = 420 + $2DLetterboxHeight

			$Script:HUDJapaneseCombatNewsXOffset = 640 + $HUDPillarboxWidth
			$Script:HUDCombatNewsHorizontalPositionOriginalMultiplier = 16
			$Script:HUDCombatNewsHorizontalPositionMultiplier = $HUDCombatNewsHorizontalPositionOriginalMultiplier * $2DTo3DScale * $XScale

			$Script:HUDMinimapXOffset = 620 + $HUDPillarboxWidth
			$Script:HUDMinimapYOffset = 432 + $2DLetterboxHeight

			$Script:HUDArrowPowerArrowXOffset = 16 - $HUDPillarboxWidth
			$Script:HUDArrowPowerArrowYOffset = 360 + $2DLetterboxHeight
			$Script:HUDArrowPowerPOWERXOffset = 100 - $HUDPillarboxWidth
			$Script:HUDArrowPowerPOWERYOffset = 362 + $2DLetterboxHeight

			$Script:HUDAmmoNotchXOffset = 16 - $HUDPillarboxWidth
			$Script:HUDAmmoNotchYOffset = 360 + $2DLetterboxHeight
			$Script:HUDAmmoReloadXOffset = 16 - $HUDPillarboxWidth
			$Script:HUDAmmoReloadYOffset = 346 + $2DLetterboxHeight

			$Script:ShopTillCustomerPositionOffset = 640 + $2DPillarboxWidth
			$Script:ShopTillCustomerPositionCounterOriginalMultiplier = 12
			$Script:ShopTillCustomerPositionCounterOriginalLimit = 32
			$Script:ShopTillCustomerPositionCounterLinearConvergence = 16
			$Script:ShopTillCustomerPositionCounterLinearConvergenceLimit = $ShopTillCustomerPositionCounterOriginalLimit + $ShopTillCustomerPositionCounterLinearConvergence
			$Script:ShopTillCustomerPositionCounterLinearConvergenceDivisor = $ShopTillCustomerPositionCounterOriginalLimit * $ShopTillCustomerPositionCounterLinearConvergence

			$Script:ShopTillRecetPositionOffset = 524 + $2DPillarboxWidth
			$Script:ShopTillRecetPositionMinimum = -128 - $2DPillarboxWidth

			$Script:ShopTillCustomerPositionCounterMultiplierMultiplier = 1 + $2DPillarboxWidth / ($ShopTillCustomerPositionCounterOriginalLimit * $ShopTillCustomerPositionCounterOriginalMultiplier)
			$Script:ShopTillCustomerPositionCounterMultiplier = $ShopTillCustomerPositionCounterOriginalMultiplier * $ShopTillCustomerPositionCounterMultiplierMultiplier

			$Script:ShopSpeechBubbleYOffset = 376 + $2DLetterboxHeight

			$Script:ShopSpeechBubbleButtonYOffset186 = 186 + $2DLetterboxHeight
			$Script:ShopSpeechBubbleButtonYOffset362 = 362 + $2DLetterboxHeight

			$Script:ShopEquipmentStatDiffYOffset24 = 24 + $2DLetterboxHeight
			$Script:ShopEquipmentStatDiffYOffset36 = 36 + $2DLetterboxHeight
			$Script:ShopEquipmentStatDiffYOffset44 = 44 + $2DLetterboxHeight

			$Script:ShowCaseItemSparklesYOffset = 128 + $2DLetterboxHeight

			$Script:GameBaseWidthPlusUIPillarbox = $GameBaseWidth + $UIPillarboxWidth
			$Script:GameBaseHeightPlus2DLetterbox = $GameBaseHeight + $2DLetterboxHeight

			$Script:NewsTickerXOffset208 = 208 - $2DPillarboxWidth
			$Script:NewsTickerTextXOffset = 640 - $2DPillarboxWidth

			$Script:SelectionHandOriginalYOffset = 20
			$Script:SelectionHandYOffset = 20 - $2DLetterboxHeight

			$Script:TearMenuTransitionCounterOriginalMultiplier = 64
			$Script:TearMenuTransitionCounterOriginalLimit = 10
			$Script:TearMenuTransitionCounterMultiplierMultiplier = 1 + $2DPillarboxWidth / ($TearMenuTransitionCounterOriginalLimit * $TearMenuTransitionCounterOriginalMultiplier)
			$Script:TearMenuTransitionCounterMultiplier = $TearMenuTransitionCounterOriginalMultiplier * $TearMenuTransitionCounterMultiplierMultiplier

			$Script:TearLectureButtonTransitionCounterOriginalMultiplier = 60
			$Script:TearLectureButtonTransitionCounterOriginalLimit = 12
			$Script:TearLectureButtonTransitionCounterMultiplierMultiplier = 1 + $2DPillarboxWidth / ($TearLectureButtonTransitionCounterOriginalLimit * $TearLectureButtonTransitionCounterOriginalMultiplier)
			$Script:TearLectureButtonTransitionCounterMultiplier = $TearLectureButtonTransitionCounterOriginalMultiplier * $TearLectureButtonTransitionCounterMultiplierMultiplier

			$Script:SelectionHandRestingX = 0.0
			$Script:SelectionHandRestingY = -64.0

			$Script:NowLoadingTextX = 512 + $HUDPillarboxWidth
			$Script:NowLoadingTextY = 400 + $2DLetterboxHeight
			$Script:NowLoadingDiscX = 496 + $HUDPillarboxWidth
			$Script:NowLoadingDiscY = 440 + $2DLetterboxHeight

			$Script:EncyclopediaItemLeftCutoff = 0 - 64
			$Script:EncyclopediaItemRightCutoff = $GameBaseWidth + 64

			$Script:Scaled16f = 16.0 * $XScale

			$Script:LoadingDiscSpinRate = 0.3 * $PresentationFrameScale

			#$DrawDistanceMultiplier = [Math]::Max($XScale, $YScale)
			$Script:DrawDistanceMultiplier = [Math]::Sqrt(
				  ([Math]::Pow($PatchedAsCommonAspectRatioNumerator, 2) + [Math]::Pow($PatchedAsCommonAspectRatioDenominator, 2)) `
				/ ([Math]::Pow($GameAsCommonAspectRatioNumerator, 2) + [Math]::Pow($GameAsCommonAspectRatioDenominator, 2))
			)

			$Script:WorldDrawDistanceShort = 60 * $DrawDistanceMultiplier
			$Script:WorldDrawDistanceLong = 120 * $DrawDistanceMultiplier
			$Script:MobDrawDistanceShort = 12 * $DrawDistanceMultiplier
			$Script:MobDrawDistanceLong = 24 * $DrawDistanceMultiplier
			$Script:FloraDrawDistance = 50 * $DrawDistanceMultiplier
			$Script:ShadowDrawDistance = 50 * $DrawDistanceMultiplier
		}
	}


	if (-not $Script:NonInteractive -and -not $Script:SkipConfigurator)
	{
		function Use-ConfigurationObject ($ConfigurationObject)
		{
			$Script:ResolutionWidth = if ($Null -ne $ConfigurationObject.ResolutionWidth) {[UInt32] $ConfigurationObject.ResolutionWidth}
			$Script:ResolutionHeight = if ($Null -ne $ConfigurationObject.ResolutionHeight) {[UInt32] $ConfigurationObject.ResolutionHeight}
			$Script:HUDWidth = if ($Null -ne $ConfigurationObject.HUDWidth) {[UInt32] $ConfigurationObject.HUDWidth}
			$Script:UseIntegral2DScaling = if ($Null -ne $ConfigurationObject.UseIntegral2DScaling) {[Bool] $ConfigurationObject.UseIntegral2DScaling}
			$Script:FramerateLimit = if ($Null -ne $ConfigurationObject.FramerateLimit) {[UInt32] $ConfigurationObject.FramerateLimit}
			$Script:CameraSmoothingVariant = if ($Null -ne $ConfigurationObject.CameraSmoothingVariant) {[String] $ConfigurationObject.CameraSmoothingVariant}
			$Script:FloatInterpolation = if ($Null -ne $ConfigurationObject.FloatInterpolation) {$ConfigurationObject.FloatInterpolation}
			$Script:TextureFiltering = if ($Null -ne $ConfigurationObject.TextureFiltering) {$ConfigurationObject.TextureFiltering}
			$Script:HideChangeCameraControlReminder = if ($Null -ne $ConfigurationObject.HideChangeCameraControlReminder) {[Bool] $ConfigurationObject.HideChangeCameraControlReminder}
			$Script:HideSkipEventControlReminder = if ($Null -ne $ConfigurationObject.HideSkipEventControlReminder) {[Bool] $ConfigurationObject.HideSkipEventControlReminder}
			$Script:HideItemDetailsControlReminderWhenHaggling = if ($Null -ne $ConfigurationObject.HideItemDetailsControlReminderWhenHaggling) {[Bool] $ConfigurationObject.HideItemDetailsControlReminderWhenHaggling}
			$Script:HideItemDetailsControlReminderInItemMenus = if ($Null -ne $ConfigurationObject.HideItemDetailsControlReminderInItemMenus) {[Bool] $ConfigurationObject.HideItemDetailsControlReminderInItemMenus}
			$Script:MobDrawDistancePatchVariant = if ($Null -ne $ConfigurationObject.MobDrawDistancePatchVariant) {[String] $ConfigurationObject.MobDrawDistancePatchVariant}
			$Script:SkipPatching = if ($Null -ne $ConfigurationObject.SkipPatching) {[Bool] $ConfigurationObject.SkipPatching}
			$Script:SkipPostPatchOperations = if ($Null -ne $ConfigurationObject.SkipPostPatchOperations) {[Bool] $ConfigurationObject.SkipPostPatchOperations}
			$Script:GetGameWindowMode = if ($Null -ne $ConfigurationObject.GetGameWindowMode) {[Bool] $ConfigurationObject.GetGameWindowMode}
			$Script:SetGameWindowMode = if ($Null -ne $ConfigurationObject.SetGameWindowMode) {$ConfigurationObject.SetGameWindowMode}
			$Script:InstallDxWrapper = if ($Null -ne $ConfigurationObject.InstallDxWrapper) {[Bool] $ConfigurationObject.InstallDxWrapper}
			$Script:ConfigureDxWrapper = if ($Null -ne $ConfigurationObject.ConfigureDxWrapper) {[Bool] $ConfigurationObject.ConfigureDxWrapper}
			$Script:ResetDxWrapperConfiguration = if ($Null -ne $ConfigurationObject.ResetDxWrapperConfiguration) {[Bool] $ConfigurationObject.ResetDxWrapperConfiguration}
			$Script:CheckDxWrapperConfiguration = if ($Null -ne $ConfigurationObject.CheckDxWrapperConfiguration) {[Bool] $ConfigurationObject.CheckDxWrapperConfiguration}
			$Script:InstallSpecialK = if ($Null -ne $ConfigurationObject.InstallSpecialK) {[Bool] $ConfigurationObject.InstallSpecialK}
			$Script:ResetSpecialKConfiguration = if ($Null -ne $ConfigurationObject.ResetSpecialKConfiguration) {[Bool] $ConfigurationObject.ResetSpecialKConfiguration}
			$Script:ConfigureSpecialK = if ($Null -ne $ConfigurationObject.ConfigureSpecialK) {[Bool] $ConfigurationObject.ConfigureSpecialK}
			$Script:CheckSpecialKConfiguration = if ($Null -ne $ConfigurationObject.CheckSpecialKConfiguration) {[Bool] $ConfigurationObject.CheckSpecialKConfiguration}
			$Script:InstallDgVoodoo2 = if ($Null -ne $ConfigurationObject.InstallDgVoodoo2) {[Bool] $ConfigurationObject.InstallDgVoodoo2}
			$Script:ResetDgVoodoo2Configuration = if ($Null -ne $ConfigurationObject.ResetDgVoodoo2Configuration) {[Bool] $ConfigurationObject.ResetDgVoodoo2Configuration}
			$Script:ConfigureDgVoodoo2 = if ($Null -ne $ConfigurationObject.ConfigureDgVoodoo2) {[Bool] $ConfigurationObject.ConfigureDgVoodoo2}
			$Script:CheckSpecialKConfiguration = if ($Null -ne $ConfigurationObject.CheckSpecialKConfiguration) {[Bool] $ConfigurationObject.CheckSpecialKConfiguration}
			$Script:SetDirectXVersionToUse = if ($Null -ne $ConfigurationObject.SetDirectXVersionToUse) {$ConfigurationObject.SetDirectXVersionToUse}
			$Script:GetDirectXVersionToUse = if ($Null -ne $ConfigurationObject.GetDirectXVersionToUse) {[Bool] $ConfigurationObject.GetDirectXVersionToUse}
			$Script:SetVerticalSyncEnabled = if ($Null -ne $ConfigurationObject.SetVerticalSyncEnabled) {$ConfigurationObject.SetVerticalSyncEnabled}
			$Script:GetVerticalSyncEnabled = if ($Null -ne $ConfigurationObject.GetVerticalSyncEnabled) {[Bool] $ConfigurationObject.GetVerticalSyncEnabled}
			$Script:SaveSettingsToConfiguration = if ($Null -ne $ConfigurationObject.SaveSettingsToConfiguration) {[Bool] $ConfigurationObject.SaveSettingsToConfiguration}
			$Script:DoNotInstallThirdPartyToolsByDefaultNextTime = if ($Null -ne $ConfigurationObject.DoNotInstallThirdPartyToolsByDefaultNextTime) {[Bool] $ConfigurationObject.DoNotInstallThirdPartyToolsByDefaultNextTime}
		}

		$CurrentConfiguratorPort = if ($Null -eq $Script:PSBoundParameters.ConfiguratorPort) {49600} else {$Script:ConfiguratorPort}

		for (;;)
		{
			try
			{
				$Listener = [Net.HttpListener]::new()
				$CurrentConfiguratorPrefix = "http://127.0.0.1:$CurrentConfiguratorPort/"
				$Listener.Prefixes.Add($CurrentConfiguratorPrefix)

				$OriginalTreatControlCAsInput = [Console]::TreatControlCAsInput
				[Console]::TreatControlCAsInput = $True

				$Listener.Start()
			}
			catch [Net.HttpListenerException]
			{
				[Console]::TreatControlCAsInput = $OriginalTreatControlCAsInput

				if ($_.Exception.ErrorCode -ne 0x000000B7)
				{
					throw
				}

				if ($Null -ne $Script:ConfiguratorPort)
				{
					throw [FancyScreenPatchForRecettearUnableToUseConfiguratorPortException]::new("Port $Script:ConfiguratorPort could not be used. Perhaps, it is already in use?", [PSCustomObject] @{StartingPort = $Script:ConfiguratorPort; PortsTriedCount = 1})
				}

				$LastPort = $CurrentConfiguratorPort

				if (($CurrentConfiguratorPort++) -eq 65535)
				{
					throw [FancyScreenPatchForRecettearUnableToUseConfiguratorPortException]::new('Ports 49600-through-to-65535 could not be used. Are they all in use?', [PSCustomObject] @{StartingPort = 49600; PortsTriedCount = 15936})
				}

				Write-Verbose "Port $LastPort was in use, so we're trying port $CurrentConfiguratorPort."

				continue
			}

			break
		}

		try
		{
			function Write-ConfiguratorMessage
			{
				$Script:ConfiguratorMessageLeft = [Console]::CursorLeft
				$Script:ConfiguratorMessageTop = [Console]::CursorTop

				[Console]::Write("The configurator is available at the URL: $CurrentConfiguratorPrefix`nYou can:`n`tPress [Enter], or [O] to open the URL in the default web-browser.`n`tOr, open the URL manually.`n`tOr, close the configurator by pressing [Q], [Ctrl+C], or [Ctrl+Z].`n`tOr, cancel the patching altogether by pressing [Ctrl+D].`n`n")
			}

			function Remove-ConfiguratorMessage
			{
				[Console]::SetCursorPosition($ConfiguratorMessageLeft, $ConfiguratorMessageTop)
				[Console]::Write("                                          $(' ' * $CurrentConfiguratorPrefix.Length)`n        `n`t                                                                 `n`t                          `n`t                                                                  `n`t                                                        `n`n")
				[Console]::SetCursorPosition($ConfiguratorMessageLeft, $ConfiguratorMessageTop)
			}

			Write-ConfiguratorMessage

			$StopWatch.Stop()

			for (;;)
			{
				$ShouldProceed = $False
				$ShouldStop = $False
				$ContextTask = $Listener.GetContextAsync()

				:PollForCompletionOrCancellation for (;;)
				{
					while ([Console]::KeyAvailable)
					{
						$Key = [Console]::ReadKey($True)

						if ($Key.Modifiers -eq 0)
						{
							if ($Key.Key -eq [ConsoleKey]::Q)
							{
								$ShouldStop = $True
								break PollForCompletionOrCancellation
							}
							elseif ($Key.Key -eq [ConsoleKey]::Enter -or $Key.Key -eq [ConsoleKey]::O)
							{
								try
								{
									Start-Process -FilePath $CurrentConfiguratorPrefix -ErrorAction Continue
								}
								catch
								{
									Remove-ConfiguratorMessage
									Write-Error $_ -ErrorAction Continue
									Write-ConfiguratorMessage
								}
							}
						}
						elseif ($Key.Modifiers -eq [ConsoleModifiers]::Control)
						{
							if ($Key.Key -eq [ConsoleKey]::C -or $Key.Key -eq [ConsoleKey]::Z)
							{
								$ShouldStop = $True
								break PollForCompletionOrCancellation
							}
							elseif ($Key.Key -eq [ConsoleKey]::D)
							{
								$Script:ShouldExitAfterConfigurator = $True
								$ShouldStop = $True
								break PollForCompletionOrCancellation
							}
						}
					}

					if ($ContextTask.IsCompleted)
					{
						if ($ContextTask.IsFaulted)
						{
							Remove-ConfiguratorMessage
							Write-Error $ContextTask.Exception -ErrorAction Continue
							Write-ConfiguratorMessage
						}
						else
						{
							$Context = $ContextTask.Result
							$ShouldProceed = $True
						}

						break PollForCompletionOrCancellation
					}

					$ContextTask.Wait(1) > $Null
				}

				if ($ShouldStop)
				{
					$Listener.Abort()

					break
				}

				if (-not $ShouldProceed)
				{
					continue
				}

				function Start-HTMLResponse ([String] $HTML)
				{
					$Context.Response.ContentEncoding = $UTF8
					$Context.Response.ContentType = 'text/html; charset=utf8'

					$Context.Response.Headers.Add('Content-Security-Policy', "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src 'self'; font-src 'none'; connect-src 'self'; media-src 'self'; object-src 'none'; child-src 'self'; frame-src 'self'; worker-src 'none'; frame-ancestors 'self'; form-action 'self'; base-uri 'self'")
					$Context.Response.Headers.Add('X-Content-Type-Options', 'nosniff')
					$Context.Response.Headers.Add('X-Frame-Options', 'SAMEORIGIN')
					$Context.Response.Headers.Add('X-XSS-Protection', '1; mode=block')
					$Context.Response.Headers.Add('Referrer-Policy', 'same-origin')
					$Context.Response.Headers.Add('Feature-Policy', "accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'none'; camera 'none'; document-domain 'none'; document-write 'none'; encrypted-media 'none'; fullscreen 'none'; geolocation 'none'; gyroscope 'none'; legacy-image-formats 'none'; magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture 'none'; speaker 'none'; usb 'none'; vr 'none'")

					$ResponseBody = $UTF8.GetBytes($HTML)
					$Context.Response.ContentLength64 = $ResponseBody.Length
					$Context.Response.OutputStream.Write($ResponseBody, 0, $ResponseBody.Length)
				}

				function Send-Response
				{
					$Context.Response.Close()
				}

				function Read-RequestBody
				{
					try
					{
						$BodyStream = [IO.StreamReader]::new($Context.Request.InputStream, $Context.Request.ContentEncoding)
						$BodyStream.ReadToEnd()
					}
					finally
					{
						$BodyStream.Close()
					}
				}

				try
				{
					if ($Context.Request.Url.AbsolutePath -eq '/')
					{
						Resolve-Configuration

						Start-HTMLResponse `
@"
<!DOCTYPE html>
<html class="no-margin fill-container" lang="en-IE">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=240, initial-scale=1">
		<title>Fancy Screen Patch for Recettear | Configurator</title>

		<style>
			figure, h1, h2, h3, h4, h5
			{
				margin: 0px;
			}

			fieldset
			{
				border-width: 0px;
				padding: 0;
				margin: 0;
			}

			fieldset, dl.same-line-definitions, .adorned-labelled-input
			{
				grid-template-columns: fit-content(30ch) min-content max-content;
				column-gap: 1.4ch;
			}

			fieldset, dl.same-line-definitions
			{
				row-gap: 1ch;

				display: grid;

				grid-auto-rows: max-content;

				min-width: max-content;
				height: max-content;
			}

			fieldset.horizontal
			{
				display: flex;
			}

			fieldset > legend
			{
				float: left;
			}

			fieldset > label:not(.one-column)
			{
				display: contents;
			}

			fieldset > :not(label), fieldset > label.one-column
			{
				grid-column-start: 1;
				grid-column-end: 4;
			}

			fieldset > *:not(legend):not(label), fieldset > label > :not(details)
			{
				margin-left: 2ch;
			}

			dl.same-line-definitions > dd
			{
				display: flex;
				align-items: center;
			}

			figcaption
			{
				max-width: max-content;
			}

			label > *:first-child, label.checkbox > :first-child > *:nth-child(2), label.radio-button > *:nth-child(2), .unlabelled
			{
				font-weight: 600;
			}

			label.checkbox:not(.adorned) > :nth-child(1)
			{
				grid-column-start: 1;
				grid-column-end: 3;
			}

			label.checkbox > :nth-child(1), label.checkbox > :nth-child(1) > :nth-child(2)
			{
				width: max-content;
			}

			label.radio-button
			{
				display: flex;
				align-items: center;
				column-gap: 0.16ch;
				max-width: 14vw;
			}

			.same-line-recommendation
			{
				display: inline-block;
				min-width: max-content;
			}

			a:not(.link)
			{
				text-decoration: none;
				color: inherit;
			}

			a.link
			{
				color: #5a3c28;
				font-weight: bold;
			}

			menu
			{
				list-style: none;
				padding: 0px;
				margin: 0px;
			}

			dl
			{
				margin: 0px;
			}

			label > *
			{
				height: max-content;
			}

			figure
			{
				display: flex;
				column-gap: 1.4ch;
				align-items: start;
			}

			figure > *
			{
				flex-grow: 1;
			}

			dd
			{
				margin-left: 2ch;
			}

			dl.same-line-definitions
			{

			}

			dl.same-line-definitions > dd
			{
				margin-left: 0px;
			}

			th
			{
				vertical-align: baseline;
			}

			p
			{
				margin: 0;

				max-width: 72ch;
			}

			p:not(:first-child):not(.austere)
			{
				margin-top: 1ch;
			}

			hr
			{
				border-style: solid;
				border-color: #5a3c28;
			}

			input, select, button
			{
				background-color: #5a3c28;
				color: #e5e0db;
				border-color: transparent;
				accent-color: #5a3c28;
				color-scheme: dark;

				padding: 0.2em 0.4em;
			}

			input:hover, input:focus, select:hover, button:hover
			{
				background-color: #f4c94b;
				color: #5a3c28;
				accent-color: #f4c94b;
			}

			button:active
			{
				font-size: 80%;
			}

			input[type = "checkbox"]:not(:checked):not(:indeterminate), input[type = "radio"]:not(:checked)
			{
				filter: invert() hue-rotate(330deg) saturate(1800%) brightness(40%);
			}

			input[type = "checkbox"]:hover:not(:checked):not(:indeterminate), input[type = "checkbox"]:focus:not(:checked):not(:indeterminate), input[type = "radio"]:hover:not(:checked), input[type = "radio"]:focus:not(:checked)
			{
				filter: invert() hue-rotate(344deg) saturate(1800%) brightness(110%);
			}

			.no-margin
			{
				margin: 0px;
			}

			.fill-container
			{
				height: 100%;
				min-height: 100%;
				width: 100%;
				min-width: 100%;
			}

			.centre-aligned-text
			{
				text-align: center;
			}

			.end-aligned-text
			{
				text-align: end;
			}

			.document
			{
				font-family: system-ui, sans-serif;
				background-color: #3B210F;
			}

			.viewable-body
			{
				display: flex;
			}

			.main-panel
			{
				/*background-color: #F0F0F0;*/

				border-radius: 1.4ch;
				border-width: 4px;
				border-color: #f4c94b;
				border-style: solid;

				margin: auto;
				height: 98vh;
				width: 96vw;

				display: flex;

				background-image: linear-gradient(#6c4222, #b98537 14%, #6c4222 150%);
			}

			.main-panel > *
			{
				height: 100%;
				overflow: auto;
			}

			.main-panel > *:first-child
			{
				border-radius: inherit;
				border-top-right-radius: unset;
				border-bottom-right-radius: unset;
			}

			.main-panel > *:last-child
			{
				border-radius: inherit;
				border-top-left-radius: unset;
				border-bottom-left-radius: unset;
			}

			.main-panel > nav
			{
				resize: horizontal;
				width: 26%;
				max-width: 50vw;

				/*background-color: #b98537;*/
			}

			.main-panel > nav menu > li
			{
				padding: 0;
			}

			.main-panel > nav menu > li > a
			{
				display: block;

				padding-left: 1.4ch;
				padding-right: 1.4ch;
				padding-top: 0.7ch;
				padding-bottom: 0.7ch;
			}

			.main-panel > nav menu > li:first-of-type > a
			{
				padding-top: 1.4ch;
			}

			.main-panel > nav menu > li:last-of-type > a
			{
				padding-bottom: 1.4ch;
			}

			.pane
			{
				background-color: #FFF8CA;
				color: #924016;
				border: 2px #6C5A47 solid;
				padding-left: 1.6ch;
				padding-right: 1.6ch;
				padding-top: 0.6ch;
				padding-bottom: 1ch;
			}

			.as-button
			{
				background-color: unset;
				background-image: linear-gradient(#FFF5B2, #FFFAD9);
				box-shadow: -0.4ch -0.3ch 0;
			}

			.as-button:hover, .as-button:focus, a:focus-within > .as-button
			{
				background-image: linear-gradient(#FFF8BF, #FFFCE6 40%);
				box-shadow: -0.2ch -0.1ch 0;
			}

			.as-button:active, a:active > .as-button
			{
				background-image: linear-gradient(#FFF8C7, #FFFDED 10%);
				box-shadow: unset;
			}

			.main-panel > nav menu > li > a > dl > dt
			{
				font-weight: bold;
				text-decoration: underline;
			}

			.configurator
			{
				width: 100%;
				display: flex;
				flex-direction: column;
			}

			.configurator > *
			{
				width: 100%;
				padding-left: 2ch;
				padding-right: 2ch;
				box-sizing: border-box;
			}

			.configurator > header, .configurator > footer
			{
				border-color: #f4c94b;

				display: flex;
				align-items: center;

				padding: 1.8ch;
				column-gap: 1.8ch;

				max-height: 14vh;
			}

			.configurator > header
			{
				padding-bottom: 0.7ch;

				border-bottom-width: 2px;
				border-bottom-style: solid;

				/*background-image: linear-gradient(#6c4222, #b98537);*/
			}

			.configurator > footer
			{
				border-top-width: 2px;
				border-top-style: solid;

				/*background-image: linear-gradient(#b98537, #6c4222);*/

				justify-content: flex-end;
				flex-wrap: wrap;
			}

			.configurator > .settings
			{
				overflow: auto;
				flex-grow: 1;

				padding-top: 1ch;
				padding-bottom: 1ch;

				/*background-color: #b98537;*/

				border-left: 2px solid #f4c94b;

				display: flex;
				flex-wrap: wrap;

				column-gap: 4ch;
			}

			.configurator > .settings section > header
			{
				width: max-content;
			}

			.configurator > .settings section
			{
				padding-top: 1ch;
				padding-bottom: 1ch;
				margin-bottom: 2ch;
				flex-grow: 1;

				display: flex;
			}

			.configurator > .settings section > .pane
			{
				flex-grow: 1;
			}

			.configurator > .settings section > *
			{
				max-width: 100%;
			}

			.configurator > .settings section > * > *
			{
				max-width: max-content;
			}

			.configurator > footer strong
			{
				font-size: 180%;
			}

			.configurator > footer > div.pane
			{
				margin-left: auto;
				margin-right: auto;
			}

			.adorned-labelled-input
			{
				display: grid;
				grid-template-rows: auto auto;
			}

			.adorned-labelled-input > label:nth-child(1)
			{
				display: contents;
			}

			fieldset > label:not(.checkbox) > :nth-child(1)
			{
				grid-column: 1;
				min-width: max-content;
			}

			fieldset > label > :nth-child(2)
			{
				grid-column: 2;
			}

			fieldset details[open]
			{
				display: contents;
			}

			fieldset details:not([open])
			{
				grid-column-start: 3;
				grid-column-end: 4;
			}

			fieldset label details:not([open])
			{
				height: 100%;
			}

			fieldset details
			{
				cursor: initial;
			}

			fieldset details > summary::before
			{
				content: "?";
				font-weight: bold;
			}

			fieldset details.with-label > summary::before
			{
				margin-left: 0.1em;
				margin-right: 0.4em;
			}

			fieldset details.with-label[open] > summary:not(:hover)::before
			{
				color: #f4c94b;
			}

			fieldset details > summary
			{
				display: flex;

				height: 100%;
				max-height: 3ch;
				aspect-ratio: 1 / 1;

				justify-content: center;
				align-items: center;

				cursor: pointer;

				background-color: #5a3c28;
				color: #e5e0db;
				border-radius: 50%;

				max-width: max-content;

				margin-left: 0.4ch;
				margin-right: 2ch;

				box-sizing: border-box;
			}

			fieldset details.with-label > summary
			{
				aspect-ratio: unset;
				border-radius: unset;
				border-style: none;
				padding: 0.2em 0.4em;
				margin-bottom: 1ex;
			}

			fieldset details > summary:hover
			{
				background-color: #f4c94b;
				color: #5a3c28;
			}

			fieldset details:not(.with-label)[open] > summary
			{
				border-style: dashed;
				border-color: #f4c94b;
				border-width: 0.2em;

				animation: full-revolution 4s linear infinite;
			}

			fieldset details[open] > summary::before
			{
				content: "i";
				font-style: italic;

				animation: full-revolution 4s linear infinite reverse;
			}

			fieldset details.with-label[open] > summary::before
			{
				animation: full-revolution 2.8s ease-in-out infinite;
			}

			fieldset details > :not(summary)
			{
				grid-column-start: 1;
				grid-column-end: 4;

				margin-left: 4ch;
				padding: 1ch;

				background-color: #5a3c28;
				color: #e5e0db;
				border: 6px solid #f4c94b;
				border-radius: 2.4ch;

				max-width: max-content;
			}

			fieldset details.with-label > :not(summary)
			{
				margin-bottom: 1ex;
			}

			fieldset details strong
			{
				color: #f4c94b;
			}

			fieldset details hr
			{
				border-color: #f4c94b;
			}

			.adorned-labelled-input > label:nth-child(1) > *:nth-child(1)
			{
				grid-column: 1;
			}

			.adorned-labelled-input > label:nth-child(1) > *:nth-child(2)
			{
				grid-column-start: 2;
				grid-column-end: 4;
			}

			.adorned-labelled-input > label:nth-child(1) + *
			{
				grid-row: 2;
				grid-column-start: 2;
				grid-column-end: 4;
			}

			.with-units
			{
				display: flex;
				column-gap: 0.6ch;
			}

			menu.resolution-presets, menu.frame-rate-presets
			{
				display: grid;
				grid-template-columns: repeat(4, 1fr);
				column-gap: 0.8ch;
			}

			#frame-rate-settings > .pane
			{
				min-width: 92ch;
			}

			.patch-title
			{
				width: 100%;
			}

			.patch-title-svg
			{
				font-size: 3rem;
				font-weight: bold;

				width: 100%;
				max-width: 100%;

				max-height: 7vh;
			}

			.patch-title-text
			{
				font-family: "Bodoni MT", fantasy;

				stroke: #e5e0db;
				stroke-width: 1.6px;
				stroke-linejoin: round;
				paint-order: stroke;
			}

			.patch-title-text.outer-stroke
			{
				stroke: #5a3c28;
				stroke-width: 8px;
			}

			.as-block
			{
				display: block;
			}

			@keyframes full-revolution
			{
				from
				{
					transform: rotate(0deg);
				}

				to
				{
					transform: rotate(360deg);
				}
			}
		</style>

		<script>
			const gameFramerate = $GameFramerate;
			const gameBaseHeight = $GameBaseHeight;

			const textureFilteringAlgorithmFriendlyNameMapping = {
				$(
					foreach ($Entry in $TextureFilteringAlgorithmFriendlyNameMapping.GetEnumerator())
					{
@"
				$($Entry.Value): '$($Entry.Key)',
"@
					}
				)
			};

			const cameraSmoothingVariantFriendlyNameMapping = {
				$(
					foreach ($Entry in $CameraSmoothingVariantFriendlyNameMapping.GetEnumerator())
					{
@"
				$($Entry.Value): '$($Entry.Key)',
"@
					}
				)
			};


			function parseAsInteger (value, radix = 10)
			{
				const parsed = parseInt(value);
				return isNaN(parsed) ? null : parsed;
			}


			function numberThatSatisfy (sequence, predicate)
			{
				let count = 0;

				for (const entry of sequence)
				{
					if (predicate(entry))
					{
						++count;
					}
				}

				return count;
			}


			function allTheSame (sequence, transform)
			{
				const iterator = sequence[Symbol.iterator]();
				let {value: firstValue, done: empty} = iterator.next();

				if (empty)
				{
					return [false, undefined];
				}

				firstValue = transform(firstValue);

				for (;;)
				{
					const {value, done} = iterator.next();

					if (done)
					{
						break;
					}

					if (transform(value) !== firstValue)
					{
						return [false, undefined];
					}
				}

				return [true, firstValue];
			}


			function indexBy (sequence, summarise)
			{
				const map = new Map();

				for (const entry of sequence)
				{
					map.set(summarise(entry), entry);
				}

				return map;
			}


			function transformValuesOf (map, transformValue)
			{
				const transformed = new Map();

				for (const [key, value] of map)
				{
					transformed.set(key, transformValue(value));
				}

				return transformed;
			}


			function initialiseAsIndeterminate (within = document)
			{
				for (const element of within.querySelectorAll('[data-initialise-as-indeterminate]'))
				{
					element.indeterminate = true;

					delete element.dataset.initialiseAsIndeterminate;
				}
			}


			function initialiseDropdownColumn (headerDropdown, cellDropdowns)
			{
				headerDropdown.addEventListener(
					'input',
					() =>
					{
						for (const cellDropdown of cellDropdowns)
						{
							cellDropdown.selectedIndex = headerDropdown.selectedIndex;
						}
					}
				);

				const onChangeOfCellDropdown = () =>
				{
					const [allTheSameSelected, value] = allTheSame(cellDropdowns, c => c.selectedIndex);

					headerDropdown.selectedIndex = allTheSameSelected ? value : -1;
				};

				for (const cellDropdown of cellDropdowns)
				{
					cellDropdown.addEventListener('input', onChangeOfCellDropdown);
				}

				onChangeOfCellDropdown();
			}


			function initialiseCheckboxColumn (headerCheckbox, cellCheckboxes)
			{
				headerCheckbox.addEventListener(
					'change',
					() =>
					{
						for (const cellCheckbox of cellCheckboxes)
						{
							cellCheckbox.indeterminate = false;
							cellCheckbox.checked = headerCheckbox.checked;
						}
					}
				);

				const onChangeOfCellCheckbox = () =>
				{
					if (Array.prototype.every.call(cellCheckboxes, c => c.indeterminate))
					{
						headerCheckbox.indeterminate = true;
					}
					else
					{
						const [allTheSameSelected, value] = allTheSame(cellCheckboxes, c => c.checked);

						if (allTheSameSelected)
						{
							headerCheckbox.indeterminate = false;
							headerCheckbox.checked = value;
						}
						else
						{
							headerCheckbox.indeterminate = true;
						}
					}
				};

				for (const cellCheckbox of cellCheckboxes)
				{
					cellCheckbox.addEventListener('change', onChangeOfCellCheckbox);
				}

				onChangeOfCellCheckbox();
			}


			function initialiseDocument ()
			{
				let useIntegral2DScalingRecommendation;
				let cameraSmoothingVariantRecommendation;
				let interpolatedFloatRecommendation;
				let textureFilteringRecommendation;

				let framerateLimitInformationChangedByScript = false;
				let framerateLimitInformationUsedByUser = false;

				initialiseAsIndeterminate();

				const configurator = document.getElementById('configurator');

				const viewportWidth = configurator.querySelector('[data-viewport-width]');
				const viewportHeight = configurator.querySelector('[data-viewport-height]');
				const hudWidth = configurator.querySelector('[data-hud-width]');
				const resolutionVisualisation = configurator.querySelector('[data-resolution-settings-visualisation]');
				const useIntegral2DScaling = configurator.querySelector('[data-use-integral-2d-scaling]');
				const framerateLimit = configurator.querySelector('[data-frame-rate-limit]');
				const cameraSmoothingVariant = configurator.querySelector('[data-camera-smoothing-variant]');
				const interpolatedFloats = indexBy(configurator.querySelectorAll('[data-interpolated-float]'), f => f.dataset.interpolatedFloat);
				const textureFilteringAlgorithms = indexBy(configurator.querySelectorAll('[data-texture-filtering]'), f => f.dataset.textureFiltering);
				const hideChangeCameraControlReminder = configurator.querySelector('[data-hide-change-camera-control-reminder]');
				const hideSkipEventControlReminder = configurator.querySelector('[data-hide-skip-event-control-reminder]');
				const hideItemDetailsControlReminderWhenHaggling = configurator.querySelector('[data-hide-item-details-control-reminder-when-haggling]');
				const hideItemDetailsControlReminderInItemMenus = configurator.querySelector('[data-hide-item-details-control-reminder-in-item-menus]');
				const mobDrawDistancePatchVariant = configurator.querySelector('[data-mob-draw-distance-patch-variant]');
				const skipPatching = configurator.querySelector('[data-skip-patching]');
				const skipPostPatchOperations = configurator.querySelector('[data-skip-post-patch-operations]');
				const getGameWindowMode = configurator.querySelector('[data-get-game-window-mode]');
				const setGameWindowMode = configurator.querySelector('[data-set-game-window-mode]');
				const installDxWrapper = configurator.querySelector('[data-install-dx-wrapper]');
				const configureDxWrapper = configurator.querySelector('[data-configure-dx-wrapper]');
				const resetDxWrapperConfiguration = configurator.querySelector('[data-reset-dx-wrapper-configuration]');
				const checkDxWrapperConfiguration = configurator.querySelector('[data-check-dx-wrapper-configuration]');
				const installDgVoodoo2 = configurator.querySelector('[data-install-dgvoodoo2]');
				const configureDgVoodoo2 = configurator.querySelector('[data-configure-dgvoodoo2]');
				const resetDgVoodoo2Configuration = configurator.querySelector('[data-reset-dgvoodoo2-configuration]');
				const checkDgVoodoo2Configuration = configurator.querySelector('[data-check-dgvoodoo2-configuration]');
				const installSpecialK = configurator.querySelector('[data-install-special-k]');
				const configureSpecialK = configurator.querySelector('[data-configure-special-k]');
				const resetSpecialKConfiguration = configurator.querySelector('[data-reset-special-k-configuration]');
				const getVerticalSyncEnabled = configurator.querySelector('[data-get-vertical-sync-enabled]');
				const setVerticalSyncEnabled = configurator.querySelector('[data-set-vertical-sync-enabled]');
				const setDirectXVersionToUse = configurator.querySelector('[data-set-directx-version-to-use]');
				const getDirectXVersionToUse = configurator.querySelector('[data-get-directx-version-to-use]');
				const checkSpecialKConfiguration = configurator.querySelector('[data-check-special-k-configuration]');

				const toggleFloatInterpolationForAll = configurator.querySelector('[data-toggle-float-interpolation-for-all]');
				const selectTextureFilteringForAll = configurator.querySelector('[data-select-texture-filtering-for-all]');

				const useIntegral2DScalingRecommendationOutput = configurator.querySelector('[data-use-integral-2d-scaling-recommendation]');
				const cameraSmoothingVariantRecommendationOutput = configurator.querySelector('[data-camera-smoothing-variant-recommendation]');

				const useUseIntegral2DScalingRecommendationButton = configurator.querySelector('[data-use-use-integral-2d-scaling-recommendation]');
				const useInterpolatedFloatRecommendationsButton = configurator.querySelector('[data-use-interpolated-float-recommendations]');
				const useTextureFilteringRecommendationsButton = configurator.querySelector('[data-use-texture-filtering-recommendations]');

				const resolutionPresetsParent = configurator.querySelector('[data-resolution-presets]');
				const resolutionPresets = indexBy(resolutionPresetsParent.querySelectorAll('[data-resolution-preset]'), p => parseAsInteger(p.dataset.resolutionPreset));
				const aspectRatioPresetsParent = configurator.querySelector('[data-aspect-ratio-presets]');
				const aspectRatioPresets = indexBy(aspectRatioPresetsParent.querySelectorAll('[data-aspect-ratio-preset]'), p => parseAsInteger(p.dataset.aspectRatioPreset));

				const frameRatePresetsParent = configurator.querySelector('[data-frame-rate-presets]');
				const frameRatePresets = indexBy(frameRatePresetsParent.querySelectorAll('[data-frame-rate-preset]'), p => parseAsInteger(p.dataset.frameRatePreset));
				const verticalSyncPresetsParent = configurator.querySelector('[data-vertical-sync-presets]');
				const verticalSyncPresets = indexBy(verticalSyncPresetsParent.querySelectorAll('[data-vertical-sync-preset]'), p => parseAsInteger(p.dataset.verticalSyncPreset));

				const saveSettingsAsDefault = configurator.querySelector('[data-save-settings-as-default]');
				const doNotInstallThirdPartyToolsByDefaultNextTime = configurator.querySelector('[data-do-not-install-third-party-tools-by-default-next-time]');
				const patchGameWithTheseSettingsButton = configurator.querySelector('[data-patch-game-with-these-settings-button]');
				const discardChangesAndPatchGameButton = configurator.querySelector('[data-discard-changes-and-patch-game-button]');
				const saveCurrentSettingsAsDefaultButton = configurator.querySelector('[data-save-current-settings-as-default-button]');
				const patchingFooter = configurator.querySelector('[data-patching-footer]');

				const framerateLimitInformation = configurator.querySelector('[data-frame-rate-limit-information]');

				function recommendInterpolatedFloat ()
				{
					const fps = parseAsInteger(framerateLimit.value);

					interpolatedFloatRecommendation = fps != null && fps !== gameFramerate;

					const recommendationText = interpolatedFloatRecommendation ? 'Enabled' : 'Disabled';

					for (const [key, interpolatedFloat] of interpolatedFloats)
					{
						interpolatedFloat.querySelector('[data-recommendation]').innerText = recommendationText;
					}
				}

				recommendInterpolatedFloat();

				function useInterpolatedFloatRecommendations ()
				{
					for (const [key, interpolatedFloat] of interpolatedFloats)
					{
						interpolatedFloat.querySelector('[data-toggle-float-interpolation-for-one]').indeterminate = true;
					}

					toggleFloatInterpolationForAll.indeterminate = true;
				}

				useInterpolatedFloatRecommendationsButton.addEventListener('click', useInterpolatedFloatRecommendations);

				function interpolatedFloatValueFor (element)
				{
					const checkbox = element.querySelector('[data-toggle-float-interpolation-for-one]');

					return checkbox.indeterminate ? 'Recommended' : checkbox.checked;
				}

				function recommendTextureFilteringForTextureFiltering (name)
				{
					return name === 'ShopShadows' ? 'Bilinear' : textureFilteringRecommendation;
				}


				function recommendTextureFiltering ()
				{
					const height = parseAsInteger(viewportHeight.value);

					textureFilteringRecommendation = (
						     useIntegral2DScalingValueFor(useIntegral2DScaling, {final: true})
						  || (height != null && height % gameBaseHeight === 0)
						? 'NearestNeighbour'
						: 'Bilinear'
					);

					for (const [key, textureFiltering] of textureFilteringAlgorithms)
					{
						textureFiltering.querySelector('[data-recommendation]').innerText = textureFilteringAlgorithmFriendlyNameMapping[
							recommendTextureFilteringForTextureFiltering(textureFiltering.dataset.textureFiltering)
						];
					}
				}

				function onChangeOfViewportHeight ()
				{
					recommendTextureFiltering();
				}

				viewportHeight.addEventListener('input', onChangeOfViewportHeight);
				useIntegral2DScaling.addEventListener('change', recommendTextureFiltering);

				recommendTextureFiltering();

				function useTextureFilteringRecommendations ()
				{
					for (const [key, textureFilteringAlgorithm] of textureFilteringAlgorithms)
					{
						const select = textureFilteringAlgorithm.querySelector('[data-select-texture-filtering-for-one]');
						select.selectedIndex = 0;
					}

					selectTextureFilteringForAll.selectedIndex = 0;
				}

				useTextureFilteringRecommendationsButton.addEventListener('click', useTextureFilteringRecommendations);

				function textureFilteringValueFor (element)
				{
					const select = element.querySelector('[data-select-texture-filtering-for-one]');

					return (
						  select.selectedIndex === 0
						? 'Recommended'
						: select.options[select.selectedIndex].value
					);
				}

				function recommendUseIntegral2DScaling ()
				{
					useIntegral2DScalingRecommendation = true;

					useIntegral2DScalingRecommendationOutput.innerText = useIntegral2DScalingRecommendation ? 'Enabled' : 'Disabled';

					recommendTextureFiltering();
				}

				recommendUseIntegral2DScaling();

				function useRecommendedUseIntegral2DScaling ()
				{
					useIntegral2DScaling.indeterminate = true;

					recommendTextureFiltering();
				}

				useUseIntegral2DScalingRecommendationButton.addEventListener('click', useRecommendedUseIntegral2DScaling);

				function useIntegral2DScalingValueFor (element, {final} = {})
				{
					return element.indeterminate ? (final ? useIntegral2DScalingRecommendation : null) : element.checked;
				}

				function recommendCameraSmoothingVariant ()
				{
					const fps = parseAsInteger(framerateLimit.value);

					cameraSmoothingVariantRecommendation = fps != null && fps !== gameFramerate ? 'InterpolatedV2' : 'None';

					cameraSmoothingVariantRecommendationOutput.innerText = cameraSmoothingVariantFriendlyNameMapping[
						cameraSmoothingVariantRecommendation
					];
				}

				function onChangeOfFramerateLimit ()
				{
					recommendInterpolatedFloat();
					recommendCameraSmoothingVariant();
				}

				framerateLimit.addEventListener('input', onChangeOfFramerateLimit);

				recommendCameraSmoothingVariant();

				function cameraSmoothingVariantValueFor (element)
				{
					return element.selectedIndex === 0 ? null : element.options[element.selectedIndex].value;
				}

				initialiseCheckboxColumn(
					toggleFloatInterpolationForAll,
					configurator.querySelectorAll('[data-toggle-float-interpolation-for-one]')
				);

				initialiseDropdownColumn(
					selectTextureFilteringForAll,
					configurator.querySelectorAll('[data-select-texture-filtering-for-one]')
				);

				framerateLimitInformation.addEventListener(
					'toggle',
					event =>
					{
						if (framerateLimitInformationChangedByScript)
						{
							framerateLimitInformationChangedByScript = false;
						}
						else
						{
							framerateLimitInformationUsedByUser = true;
						}
					}
				);

				framerateLimit.addEventListener(
					'focus',
					event =>
					{
						if (!framerateLimitInformationUsedByUser)
						{
							if (!framerateLimitInformation.open)
							{
								framerateLimitInformationChangedByScript = true;
								framerateLimitInformation.open = true;
							}
						}
					}
				);

				framerateLimit.addEventListener(
					'blur',
					event =>
					{
						if (!framerateLimitInformationUsedByUser && framerateLimitInformation.open)
						{
							framerateLimitInformationChangedByScript = true;
							framerateLimitInformation.open = false;
						}
					}
				);

				function applyResolutionPreset (resolutionPreset, aspectRatioPreset)
				{
					let aspectRatio = parseAsInteger(aspectRatioPreset.dataset.aspectRatioPreset);
					const denominator = aspectRatio & 0xFFFF;
					aspectRatio >>>= 16;
					const numerator = aspectRatio & 0xFFFF;

					const height = parseAsInteger(resolutionPreset.dataset.resolutionPreset);
					const width = Math.ceil(height * numerator / denominator);

					viewportWidth.value = width;
					viewportHeight.value = height;
					hudWidth.value = '';

					onChangeOfViewportHeight();
				}

				for (const [height, resolutionPreset] of resolutionPresets)
				{
					resolutionPreset.addEventListener(
						'change',
						event =>
						{
							const aspectRatioPreset = aspectRatioPresetsParent.querySelector('[data-aspect-ratio-preset]:checked');

							if (aspectRatioPreset != null)
							{
								applyResolutionPreset(resolutionPreset, aspectRatioPreset);
							}
						}
					);
				}

				for (const [aspectRatio, aspectRatioPreset] of aspectRatioPresets)
				{
					aspectRatioPreset.addEventListener(
						'change',
						event =>
						{
							const resolutionPreset = resolutionPresetsParent.querySelector('[data-resolution-preset]:checked');

							if (resolutionPreset != null)
							{
								applyResolutionPreset(resolutionPreset, aspectRatioPreset);
							}
						}
					);
				}

				function clearResolutionPreset ()
				{
					let e;

					if ((e = resolutionPresetsParent.querySelector('[data-resolution-preset]:checked'))) {e.checked = false};
					if ((e = aspectRatioPresetsParent.querySelector('[data-aspect-ratio-preset]:checked'))) {e.checked = false};
				}

				viewportWidth.addEventListener('input', clearResolutionPreset);
				viewportHeight.addEventListener('input', clearResolutionPreset);
				hudWidth.addEventListener('input', clearResolutionPreset);

				function applyFrameRatePreset (frameRatePreset, verticalSyncPreset)
				{
					const frameRate = parseAsInteger(frameRatePreset.dataset.frameRatePreset);
					const verticalSync = parseAsInteger(verticalSyncPreset.dataset.verticalSyncPreset);
					const adjustedFrameRate = frameRate === gameFramerate ? frameRate : frameRate - (verticalSync !== 0);

					framerateLimit.value = adjustedFrameRate;

					setVerticalSyncEnabled.selectedIndex = Array.prototype.findIndex.call(
						setVerticalSyncEnabled.options,
						o => parseAsInteger(o.value) === verticalSync
					);

					onChangeOfFramerateLimit();
				}

				for (const [frameRate, frameRatePreset] of frameRatePresets)
				{
					frameRatePreset.addEventListener(
						'change',
						event =>
						{
							const verticalSyncPreset = verticalSyncPresetsParent.querySelector('[data-vertical-sync-preset]:checked');

							if (verticalSyncPreset != null)
							{
								applyFrameRatePreset(frameRatePreset, verticalSyncPreset);
							}
						}
					);
				}

				for (const [verticalSync, verticalSyncPreset] of verticalSyncPresets)
				{
					verticalSyncPreset.addEventListener(
						'change',
						event =>
						{
							const frameRatePreset = frameRatePresetsParent.querySelector('[data-frame-rate-preset]:checked');

							if (frameRatePreset != null)
							{
								applyFrameRatePreset(frameRatePreset, verticalSyncPreset);
							}
						}
					);
				}

				function clearFrameRatePreset ()
				{
					let e;

					if ((e = frameRatePresetsParent.querySelector('[data-frame-rate-preset]:checked'))) {e.checked = false};
					if ((e = verticalSyncPresetsParent.querySelector('[data-vertical-sync-preset]:checked'))) {e.checked = false};
				}

				framerateLimit.addEventListener('input', clearFrameRatePreset);
				setVerticalSyncEnabled.addEventListener('change', clearFrameRatePreset);

				function prepareConfigurationObject ()
				{
					let verticalSyncSetting = setVerticalSyncEnabled.options[setVerticalSyncEnabled.selectedIndex].value;
					verticalSyncSetting = verticalSyncSetting === '0' ? false : (verticalSyncSetting === '1' ? true : 'NoChange');

					let setDirectXVersionToUseSetting = setDirectXVersionToUse.options[setDirectXVersionToUse.selectedIndex].value;
					setDirectXVersionToUseSetting = parseAsInteger(setDirectXVersionToUseSetting) ?? setDirectXVersionToUseSetting;

					return {
						SchemaVersion: 1,
						SaveSettingsToConfiguration: saveSettingsAsDefault.checked,
						DoNotInstallThirdPartyToolsByDefaultNextTime: doNotInstallThirdPartyToolsByDefaultNextTime.checked,
						ResolutionWidth: parseAsInteger(viewportWidth.value),
						ResolutionHeight: parseAsInteger(viewportHeight.value),
						HUDWidth: parseAsInteger(hudWidth.value),
						UseIntegral2DScaling: useIntegral2DScalingValueFor(useIntegral2DScaling),
						FramerateLimit: parseAsInteger(framerateLimit.value),
						FloatInterpolation: Object.fromEntries(transformValuesOf(interpolatedFloats, interpolatedFloatValueFor)),
						TextureFiltering: Object.fromEntries(transformValuesOf(textureFilteringAlgorithms, textureFilteringValueFor)),
						HideChangeCameraControlReminder: hideChangeCameraControlReminder.checked,
						HideSkipEventControlReminder: hideSkipEventControlReminder.checked,
						HideItemDetailsControlReminderWhenHaggling: hideItemDetailsControlReminderWhenHaggling.checked,
						HideItemDetailsControlReminderInItemMenus: hideItemDetailsControlReminderInItemMenus.checked,
						MobDrawDistancePatchVariant: mobDrawDistancePatchVariant.options[mobDrawDistancePatchVariant.selectedIndex].value,
						CameraSmoothingVariant: cameraSmoothingVariantValueFor(cameraSmoothingVariant),
						SkipPatching: skipPatching.checked,
						SkipPostPatchOperations: skipPostPatchOperations.checked,
						GetGameWindowMode: getGameWindowMode.checked,
						SetGameWindowMode: setGameWindowMode.options[setGameWindowMode.selectedIndex].value,
						InstallDxWrapper: installDxWrapper.checked,
						ConfigureDxWrapper: configureDxWrapper.checked,
						ResetDxWrapperConfiguration: resetDxWrapperConfiguration.checked,
						CheckDxWrapperConfiguration: checkDxWrapperConfiguration.checked,
						InstallDgVoodoo2: installDgVoodoo2.checked,
						ConfigureDgVoodoo2: configureDgVoodoo2.checked,
						ResetDgVoodoo2Configuration: resetDgVoodoo2Configuration.checked,
						CheckDgVoodoo2Configuration: checkDgVoodoo2Configuration.checked,
						InstallSpecialK: installSpecialK.checked,
						ResetSpecialKConfiguration: resetSpecialKConfiguration.checked,
						ConfigureSpecialK: configureSpecialK.checked,
						CheckSpecialKConfiguration: checkSpecialKConfiguration.checked,
						GetVerticalSyncEnabled: getVerticalSyncEnabled.checked,
						SetVerticalSyncEnabled: verticalSyncSetting,
						GetDirectXVersionToUse: getDirectXVersionToUse.checked,
						SetDirectXVersionToUse: setDirectXVersionToUseSetting
					};
				}

				function preparePatchRequestBody (configuration)
				{
					return {
						Configuration: configuration
					};
				}

				function sendRequest (path, body, onResponse = response => {})
				{
					return fetch(
						path,
						{
							method: 'POST',
							headers: {'Content-Type': 'application/json'},
							body: JSON.stringify(body)
						}
					).then(
						response =>
						{
							if (response.status !== 204)
							{
								window.alert('The PowerShell script responded, but an error occurred. Please refer back to the script\'s output for more information.');

								return;
							}

							return onResponse(response);
						}
					).catch(
						error => window.alert(``The PowerShell script failed to respond.\n\n`${error}``)
					);
				}

				function patchGame (patchRequestBody)
				{
					return sendRequest(
						'/patch-game',
						patchRequestBody,
						response =>
						{
							const pane = Object.assign(document.createElement('div'), {className: 'pane'});

							Object.assign(
								pane.appendChild(document.createElement('strong')),
								{role: 'alert', innerText: 'Recettear is now being patched. Please return to the PowerShell script.'}
							)

							patchingFooter.replaceChildren(pane);
						}
					);
				}

				patchGameWithTheseSettingsButton.addEventListener('click', () => patchGame(preparePatchRequestBody(prepareConfigurationObject())));
				discardChangesAndPatchGameButton.addEventListener('click', () => patchGame(preparePatchRequestBody()));
				saveCurrentSettingsAsDefaultButton.addEventListener('click', () => sendRequest('/save-settings-as-default', prepareConfigurationObject()));
			}

			if (document.readyState === 'loading')
			{
				document.addEventListener('DOMContentLoaded', initialiseDocument);
			}
			else
			{
				initialiseDocument();
			}
		</script>
	</head>
	<body class="document no-margin fill-container">
		<div id="viewable_body" class="viewable-body no-margin fill-container">
			<div id="main-panel" class="main-panel">
				<nav>
					<menu>
						<li>
							<a href="#operational-settings">
								<dl class="pane as-button">
									<dt>Operational settings</dt>
									<dd>Used to configure how the patch is applied.</dd>
								</dl>
							</a>
						</li>
						<li>
							<a href="#resolution-settings">
								<dl class="pane as-button">
									<dt>Resolution settings</dt>
									<dd>Used to configure the game's display-resolution.</dd>
								</dl>
							</a>
						</li>
						<li>
							<a href="#frame-rate-settings">
								<dl class="pane as-button">
									<dt>Frame-rate settings</dt>
									<dd>Used to configure the game's frame-rate limit.</dd>
								</dl>
							</a>
						</li>
						<li>
							<a href="#user-interface-settings">
								<dl class="pane as-button">
									<dt>User-interface settings</dt>
									<dd>Used to configure the game's user-interface (UI).</dd>
								</dl>
							</a>
						</li>
						<li>
							<a href="#gameplay-affecting-settings">
								<dl class="pane as-button">
									<dt>Gameplay-affecting settings</dt>
									<dd>Used to configure settings that affect the gameplay of the game.</dd>
								</dl>
							</a>
						</li>
						<li>
							<a href="#post-patch-operation-settings">
								<dl class="pane as-button">
									<dt>Post-patch operations</dt>
									<dd>Used to control which ancillary tasks take effect after the game is patched.</dd>
								</dl>
							</a>
						</li>
						<li>
							<a href="#float-interpolation-settings">
								<dl class="pane as-button">
									<dt>Float interpolation settings</dt>
									<dd>Used to configure how the game's 60-FPS game-logic is interpolated to higher frame-rates.</dd>
								</dl>
							</a>
						</li>
						<li>
							<a href="#texture-filtering-settings">
								<dl class="pane as-button">
									<dt>Texture filtering settings</dt>
									<dd>Used to configure how the game's textures and 2D-artwork are up-scaled to resolutions larger than 640x480.</dd>
								</dl>
							</a>
						</li>
					</menu>
				</nav>
				<main id="configurator" class="configurator">
					<header>
						<h1 class="patch-title">
							<svg aria-label="Fancy Screen Patch for Recettear" viewBox="0 0 900 50" class="patch-title-svg" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
								<defs>
									<linearGradient id="titleGradient" gradientTransform="rotate(90)">
										<stop offset="45%" stop-color="#f8f100" />
										<stop offset="95%" stop-color="#fe7700" />
									</linearGradient>
								</defs>

								<text x="4" y="40" class="patch-title-text outer-stroke">FANCY SCREEN PATCH FOR RECETTEAR</text>
								<text x="4" y="40" fill="url(#titleGradient)" class="patch-title-text">FANCY SCREEN PATCH FOR RECETTEAR</text>
							</svg>
						</h1>
					</header>

					<section id="settings" class="settings" tabindex="-1">
						<section id="operational-settings">
							<fieldset class="pane">
								<legend>
									<header><a href="#operational-settings" tabindex="-1"><h2>Operational Settings</h2></a></header>
								</legend>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:SkipPatching) {'checked'}) data-skip-patching>
										<span>Skip patching?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Skip patching?&quot; setting." title="Information about the &quot;Skip patching?&quot; setting."></summary>
										<div>
											<p>This option can be used to skip the patching of the game. When patching is skipped, no changes will be made to the game's executable.</p>
											<p>This can be used to perform only post-patch operations, for configuring the game/patch without patching it again.</p>
										</div>
									</details>
								</label>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:SkipPostPatchOperations) {'checked'}) data-skip-post-patch-operations>
										<span>Skip post-patch operations?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Skip post-patch operations?&quot; setting." title="Information about the &quot;Skip post-patch operations?&quot; setting."></summary>
										<div>
											<p>This option can be used to skip post-patch operations. When post-patch operations are skipped, no changes will be made to the game's configuration, nor to the configuration of any third-party tools.</p>
											<p>This can be used to only patch the game, without affecting the game's configuration, or the state of any third-party tools.</p>
										</div>
									</details>
								</label>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:SaveSettingsToConfiguration) {'checked'}) data-save-settings-as-default>
										<span>Save these settings as the default settings for next time?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Save these settings as the default settings for next time?&quot; setting." title="Information about the &quot;Save these settings as the default settings for next time?&quot; setting."></summary>
										<div>
											<p>If this option is enabled: when the "Patch the game with these settings" button is pressed, the settings that have been configured will be saved to a configuration file, and those saved settings will be used by default the next time this patch is used.</p>
										</div>
									</details>
								</label>
							</fieldset>
						</section>

						<section id="resolution-settings">
							<fieldset class="pane">
								<legend>
									<header><a href="#resolution-settings" tabindex="-1"><h2>Resolution Settings</h2></a></header>
								</legend>
								<div class="pane">
									<header><a href="#resolution-settings-presets" tabindex="-1"><h3>Presets</h3></a></header>
									<menu class="resolution-presets" data-resolution-presets>
										<li>
											<label class="radio-button">
												<input type="radio" name="resolution-preset" data-resolution-preset="480">
												<span>480p</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="resolution-preset" data-resolution-preset="720">
												<span>720p</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="resolution-preset" data-resolution-preset="768">
												<span>768p</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="resolution-preset" data-resolution-preset="1080">
												<span>1080p</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="resolution-preset" data-resolution-preset="1200">
												<span>1200p</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="resolution-preset" data-resolution-preset="1440">
												<span>1440p</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="resolution-preset" data-resolution-preset="2160">
												<span>4K</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="resolution-preset" data-resolution-preset="2880">
												<span>5K</span>
											</label>
										</li>
									</menu>
									<hr>
									<menu class="resolution-presets" data-aspect-ratio-presets>
										<li>
											<label class="radio-button">
												<input type="radio" name="aspect-ratio-preset" data-aspect-ratio-preset="$((4 -shl 16) -bor 3)">
												<span>4:3</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="aspect-ratio-preset" data-aspect-ratio-preset="$((3 -shl 16) -bor 2)">
												<span>3:2</span>
											</label>
										<li>
											<label class="radio-button">
												<input type="radio" name="aspect-ratio-preset" data-aspect-ratio-preset="$((16 -shl 16) -bor 9)">
												<span>16:9</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="aspect-ratio-preset" data-aspect-ratio-preset="$((16 -shl 16) -bor 10)">
												<span>16:10</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="aspect-ratio-preset" data-aspect-ratio-preset="$((21 -shl 16) -bor 9)">
												<span>21:9</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="aspect-ratio-preset" data-aspect-ratio-preset="$((32 -shl 16) -bor 9)">
												<span>32:9</span>
											</label>
										</li>
									</menu>
								</div>
								<label>
									<span>Resolution width</span>
									<span class="with-units">
										<input id="viewport-width" type="number" min="1" name="viewport-width" value="$Script:ResolutionWidth" data-viewport-width>
										<span><abbr title="pixels">px</abbr></span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Resolution width&quot; setting." title="information about the &quot;Resolution width&quot; setting."></summary>
										<div>
											<p>This controls the width, in pixels, of the game's window.</p>
											<p>If no value is provided for the width, it defaults to $GameBaseWidth.</p>
										</div>
									</details>
								</label>
								<label>
									<span>Resolution height</span>
									<span class="with-units">
										<input id="viewport-height" type="number" min="1" name="viewport-height" value="$Script:ResolutionHeight" data-viewport-height>
										<span><abbr title="pixels">px</abbr></span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Resolution height&quot; setting." title="information about the &quot;Resolution height&quot; setting."></summary>
										<div>
											<p>This controls the height, in pixels, of the game's window.</p>
											<p>If no value is provided for the height, it defaults to $GameBaseHeight.</p>
										</div>
									</details>
								</label>
								<label>
									<span>HUD width</span>
									<span class="with-units">
										<input id="hud-width" type="number" min="1" name="hud-width" value="$Script:HUDWidth" data-hud-width>
										<span><abbr title="pixels">px</abbr></span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;HUD width&quot; setting." title="information about the &quot;HUD width&quot; setting."></summary>
										<div>
											<p>This controls the width, in pixels, that the game's HUD is bounded to.</p>
											<p>If no value is provided for the HUD's width, it defaults to being no wider-than a 16:9 resolution of the same height as the game window's height.</p>
										</div>
									</details>
								</label>
								<label class="adorned checkbox">
									<span>
										<input type="checkbox" $(if ($Script:UseIntegral2DScaling) {'checked'}) $(if ($Null -eq $Script:UseIntegral2DScaling) {'data-initialise-as-indeterminate'}) data-use-integral-2d-scaling>
										<span>Use integral scaling for 2D graphics?</span>
									</span>
									<span>
										<span class="same-line-recommendation">
											<span>Recommended value: </span>
											<span data-use-integral-2d-scaling-recommendation></span>
										</span>
										<button type="button" data-use-use-integral-2d-scaling-recommendation class="as-block">Use recommended value</button>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Use integral scaling for 2D graphics?&quot; setting." title="Information about the &quot;Use integral scaling for 2D graphics?&quot; setting."></summary>
										<div>
											<p>This controls whether or not integral scaling is used for 2D graphics.</p>
											<p>When integral scaling is enabled 2D graphics will be upscaled by the largest integer multiplier that will fit the height of the screen. As an example, given a 1080p resolution: upscaling 480 to 1080 requires a scaling-factor of 2.25, which is not an integer, so when integral scaling is enabled 480 would be upscaled by a scaling-factor of 2, resulting in a height of 960.</p>
											<p>Most full-screen 2D graphics will be letter-boxed if the graphic cannot fill the height of the screen due to the integral scaling. An exception to this is when Recet is manning the till, wherein the interface is rearranged slightly to make use of the additional space.</p>
										</div>
									</details>
								</label>
							</fieldset>
						</section>

						<section id="frame-rate-settings">
							<fieldset class="pane">
								<legend>
									<header><a href="#frame-rate-settings" tabindex="-1"><h2>Frame-rate Settings</h2></a></header>
								</legend>
								<div class="pane">
									<header><a href="#frame-rate-settings-presets" tabindex="-1"><h3>Presets</h3></a></header>
									<menu class="frame-rate-presets" data-frame-rate-presets>
										<li>
											<label class="radio-button">
												<input type="radio" name="frame-rate-preset" data-frame-rate-preset="60">
												<span>60 Hz</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="frame-rate-preset" data-frame-rate-preset="75">
												<span>75 Hz</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="frame-rate-preset" data-frame-rate-preset="120">
												<span>120 Hz</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="frame-rate-preset" data-frame-rate-preset="144">
												<span>144 Hz</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="frame-rate-preset" data-frame-rate-preset="160">
												<span>160 Hz</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="frame-rate-preset" data-frame-rate-preset="165">
												<span>165 Hz</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="frame-rate-preset" data-frame-rate-preset="240">
												<span>240 Hz</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="frame-rate-preset" data-frame-rate-preset="360">
												<span>360 Hz</span>
											</label>
										</li>
									</menu>
									<hr>
									<menu class="frame-rate-presets" data-vertical-sync-presets>
										<li>
											<label class="radio-button">
												<input type="radio" name="vertical-sync-preset" data-vertical-sync-preset="0">
												<span>Vertical-sync disabled</span>
											</label>
										</li>
										<li>
											<label class="radio-button">
												<input type="radio" name="vertical-sync-preset" data-vertical-sync-preset="1">
												<span>Vertical-sync enabled</span>
											</label>
										</li>
									</menu>
								</div>
								<label>
									<span>Frame-rate limit</span>
									<span class="with-units">
										<input id="frame-rate-limit" type="number" min="60" max="1000" value="$Script:FramerateLimit" data-frame-rate-limit>
										<span><abbr title="Frames-per-second">FPS</abbr></span>
									</span>
									<details data-frame-rate-limit-information>
										<summary aria-label="Information about the &quot;Frame-rate limit&quot; setting." title="information about the &quot;Frame-rate limit&quot; setting."></summary>
										<div>
											<p><strong>If you intend to use vertical-sync, this ideally should be one less than your screen's refresh-rate (e.g 119-FPS for a 120-Hz screen)</strong>, if possible, to avoid excess latency. Otherwise, this should be the frame-rate you intend to run the game at.</p>
											<hr>
											<p>The frame-rate limit must be at-least sixty. Values greater-than one-thousand for the frame-rate limit can be used, but any adverse effects resulting from values greater-than one-thousand are unsupported.</p>
											<p>Whilst this patch does allow the use of frame-rates greater-than the game's native frame-rate of sixty FPS, it does not completely decouple the frame-rate from the rendering logic. The frame-rate limit set here influences how the game is interpolated to higher frame-rates, so setting this value higher than your screen's refresh-rate may have an adverse effect on the appearance of the game's motion.</p>
										</div>
									</details>
								</label>
							</fieldset>
						</section>

						<section id="user-interface-settings">
							<fieldset class="pane">
								<legend>
									<header><a href="#user-interface-settings" tabindex="-1"><h2>User-interface Settings</h2></a></header>
								</legend>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:HideChangeCameraControlReminder) {'checked'}) data-hide-change-camera-control-reminder>
										<span>Hide the "Change camera" control-reminder?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Hide the &quot;Change camera&quot; control-reminder?&quot; setting." title="Information about the &quot;Hide the &quot;Change camera&quot; control-reminder?&quot; setting."></summary>
										<div>
											<p>This controls whether or not the "Change camera" button reminder is displayed in the bottom-right corner of the screen when in the shop.</p>
										</div>
									</details>
								</label>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:HideSkipEventControlReminder) {'checked'}) data-hide-skip-event-control-reminder>
										<span>Hide the "Skip event" control-reminder?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Hide the &quot;Skip event&quot; control-reminder?&quot; setting." title="Information about the &quot;Hide the &quot;Skip event&quot; control-reminder?&quot; setting."></summary>
										<div>
											<p>This controls whether or not the "Skip event" button reminder is displayed in the bottom-right corner of the screen during an event or a cutscene.</p>
										</div>
									</details>
								</label>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:HideItemDetailsControlReminderWhenHaggling) {'checked'}) data-hide-item-details-control-reminder-when-haggling>
										<span>Hide the "Item details" control-reminder when haggling?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Hide the &quot;Item details&quot; control-reminder when haggling?&quot; setting." title="Information about the &quot;Hide the &quot;Item details&quot; control-reminder when haggling?&quot; setting."></summary>
										<div>
											<p>This controls whether or not the "Item details" button reminder is displayed in the bottom-right corner of the screen when haggling with a customer.</p>
										</div>
									</details>
								</label>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:HideItemDetailsControlReminderInItemMenus) {'checked'}) data-hide-item-details-control-reminder-in-item-menus>
										<span>Hide the "Item details" control-reminder in item menus?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Hide the &quot;Item details&quot; control-reminder in item menus?&quot; setting." title="Information about the &quot;Hide the &quot;Item details&quot; control-reminder in item menus?&quot; setting."></summary>
										<div>
											<p>This controls whether or not the "Item details" button reminder is displayed in the bottom-right corner of the screen when browsing through an item menu.</p>
										</div>
									</details>
								</label>
							</fieldset>
						</section>

						<section id="gameplay-affecting-settings">
							<fieldset class="pane">
								<legend>
									<header><a href="#gameplay-affecting-settings" tabindex="-1"><h2>Gameplay-affecting Settings</h2></a></header>
								</legend>
								<header id="draw-distance-options"><a href="#draw-distance-options-options" tabindex="-1"><h3>Draw-distance Options</h3></a></header>
								<label>
									<span>Mob draw-distance patch variant</span>
									<span>
										<select id="mob-draw-distance-patch-variant" required data-mob-draw-distance-patch-variant>
											<option value="None" $(if ('None' -eq $Script:MobDrawDistancePatchVariant) {'selected'})>None</option>
											<option value="OnlyVisual" $(if ('OnlyVisual' -eq $Script:MobDrawDistancePatchVariant) {'selected'})>Only visual</option>
											<option value="Real" $(if ('Real' -eq $Script:MobDrawDistancePatchVariant) {'selected'})>Real</option>
										</select>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Mob draw-distance patch patch variant&quot; setting." title="Information about the &quot;Mob draw-distance patch patch variant&quot; setting."></summary>
										<div>
											<p>This controls how the draw-distance for mobs in dungeons is patched when the aspect-ratio is wider than 4:3.</p>
											<p>When a mob in a dungeon goes off-screen (roughly speaking), the vanilla game stops simulating that mob entirely: it will not move, nor attack—it won't even animate.</p>
											<p>There are three options for how the patch handles the draw-distance of mobs:<br><strong>"Only visual"</strong> will cause mobs to always be displayed after they have been first revealed, but the mobs will not be simulated outside of the game's vanilla draw-distance, as described earlier.<br><strong>"Real"</strong> will cause mobs to always be displayed and simulated after they have been first revealed—this will make the game more difficult as mobs will chase the player-character from further away—this option is not intended to provide balanced gameplay.<br><strong>"None"</strong> will cause mobs to simply disappear when they are out of the game's vanilla draw-distance.</p>
										</div>
									</details>
								</label>
							</fieldset>
						</section>

						<section id="post-patch-operation-settings">
							<fieldset class="pane">
								<legend>
									<header><a href="#post-patch-operation-settings" tabindex="-1"><h2>Post-patch operations</h2></a></header>
								</legend>
								<label>
									<span>Set game window mode</span>
									<select data-set-game-window-mode>
										<option value="NoChange" $(if ('NoChange' -eq $Script:SetGameWindowMode) {'selected'})>(No change)</option>
										<option value="BorderlessWindowed" $(if ('BorderlessWindowed' -eq $Script:SetGameWindowMode) {'selected'})>Borderless Windowed</option>
										<option value="FullScreen" $(if ('FullScreen' -eq $Script:SetGameWindowMode) {'selected'})>Fullscreen</option>
										<option value="Windowed" $(if ('Windowed' -eq $Script:SetGameWindowMode) {'selected'})>Windowed</option>
									</select>
									<details>
										<summary aria-label="Information about the &quot;Set game window mode&quot; setting." title="Information about the &quot;Set game window mode&quot; setting."></summary>
										<div>
											<p>This option can be used to change the mode of operation for the game's window.</p>
										</div>
									</details>
								</label>
								<label>
									<span>Set vertical-sync setting</span>
									<select data-set-vertical-sync-enabled>
										<option value="NoChange" $(if ('NoChange' -eq $Script:SetVerticalSyncEnabled) {'selected'})>(No change)</option>
										<option value="0" $(if ($Script:SetVerticalSyncEnabled -eq $False) {'selected'})>Disabled</option>
										<option value="1" $(if ($Script:SetVerticalSyncEnabled -eq $True) {'selected'})>Enabled</option>
									</select>
									<details>
										<summary aria-label="Information about the &quot;Set vertical-sync setting&quot; setting." title="Information about the &quot;Set vertical-sync setting&quot; setting."></summary>
										<div>
											<p>This option can be used to change whether vertical-sync ("v-sync") is enabled or disabled.</p>
										</div>
									</details>
								</label>
								<label>
									<span>Set DirectX version to use</span>
									<select data-set-directx-version-to-use>
										<option value="NoChange" $(if ('NoChange' -eq $Script:SetDirectXVersionToUse) {'selected'})>(No change)</option>
										<option value="12" $(if ($Script:SetDirectXVersionToUse -eq 12) {'selected'})>12</option>
										<option value="9" $(if ($Script:SetDirectXVersionToUse -eq 9) {'selected'})>9</option>
										<option value="11" $(if ($Script:SetDirectXVersionToUse -eq 11) {'selected'})>11</option>
										<option value="8" $(if ($Script:SetDirectXVersionToUse -eq 8) {'selected'})>8.1</option>
									</select>
									<details>
										<summary aria-label="Information about the &quot;Set DirectX version to use&quot; setting." title="Information about the &quot;Set DirectX version to use&quot; setting."></summary>
										<div>
											<p>This option can be used to change which version of DirectX is used by the game. The versions are ordered from most preferred to least preferred. Each DirectX version performs differently with regards to frame-pacing (especially when vertical-sync is enabled) and in their support for windowed/fullscreen mode.</p>
											<p><strong>DirectX 12</strong> generally has the best results for frame-pacing, however it does not support fullscreen mode so borderless-windowed mode must be used instead.<br>If the game's resolution is configured to be the same as the monitor's resolution then DirectX 12 should be the first choice on machines that support DirectX 12, as it works well regardless of the vertical-sync setting, and has low-latency in borderless-windowed mode meaning the fast alt-tabbing of borderless-windowed mode can be availed of without the traditional drawbacks of borderless-windowed mode.<br>To be able to use DirectX 12, <strong>DxWrapper</strong> and <strong>dgVoodoo2</strong> must be installed.</p>
											<p><strong>DirectX 9</strong> has the next best results for frame-pacing, and it supports fullscreen mode, however it incurs additional latency when borderless-windowed mode is used.<br>If the game's resolution is configured to be smaller than the monitor's resolution and fullscreen is desired then DirectX 9 should be the first choice.<br>To be able to use DirectX 9, <strong>DxWrapper</strong> must be installed.</p>
											<p><strong>DirectX 11</strong> is very sensitive when it comes to frame-pacing, especially when vertical-sync is enabled, but it does support fullscreen mode, and does not incur additional latency when borderless-windowed mode is used.<br>If vertical-sync is disabled, DirectX 11 may be worth a try if DirectX 9 does not satisfy, or for usage of borderless-windowed mode on machines that do not support DirectX 12.<br>To be able to use DirectX 11, <strong>DxWrapper</strong> and <strong>dgVoodoo2</strong> must be installed.</p>
											<p><strong>DirectX 8.1</strong> is the version of DirectX used by the vanilla game. It has little advantage over the other versions of DirectX except for compatibility with very old hardware. Though, its usage does not require any third-party tools, so it can be useful for trouble-shooting.</p>
											<hr>
											<p>When DirectX 9 or later is used, DxWrapper is used to convert the game's usage of DirextX 8.1 to DirectX 9 (DxWrapper in turn uses "d3d8to9" for the conversion).<br>When DirectX 11 or later is used, DxWrapper is still used, and dgVoodoo2 is used to convert the game's usage of DirectX 9 to DirectX 11 or 12.<br>When DirectX 8.1 is used, neither DxWrapper nor dgVoodoo2 are used.</p>
										</div>
									</details>
								</label>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:GetGameWindowMode) {'checked'}) data-get-game-window-mode>
										<span>Get game window mode?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Get game window mode?&quot; setting." title="Information about the &quot;Get game window mode?&quot; setting."></summary>
										<div>
											<p>When this option is enabled, the PowerShell script will output the mode that the game's window is configured to use.</p>
										</div>
									</details>
								</label>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:GetVerticalSyncEnabled) {'checked'}) data-get-vertical-sync-enabled>
										<span>Get vertical-sync setting?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Get vertical-sync setting?&quot; setting." title="Information about the &quot;Get vertical-sync setting?&quot; setting."></summary>
										<div>
											<p>When this option is enabled, the PowerShell script will output whether the game is configured to use vertical-sync or not.</p>
										</div>
									</details>
								</label>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:GetDirectXVersionToUse) {'checked'}) data-get-directx-version-to-use>
										<span>Get DirectX version to use?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Get DirectX version to use?&quot; setting." title="Information about the &quot;Get DirectX version to use?&quot; setting."></summary>
										<div>
											<p>When this option is enabled, the PowerShell script will output the version of DirectX that the game is configured to use.</p>
										</div>
									</details>
								</label>
								<div>
									<details class="with-label">
										<summary aria-label="Information about the &quot;Third-party tool&quot; settings." title="Information about the &quot;Third-party tool&quot; settings."><span>Third-party tool options</span></summary>
										<div>
											<p>The "Third-party tool" options can be used to manage various third-party tools. There are four options which behave in the same way for each third-party tool.</p>
											<p>When the <strong>"Install?"</strong> option is enabled, a third-party tool will be installed. If the third-party tool cannot be found in the game's installation folder, the tool will be downloaded from the Internet (the file's SHA256 hash will be verified to ensure the file is safe to install). If the tool is already installed it will be reinstalled, overwriting any existing files (a backup of the existing files will be made, however).</p>
											<p>When the <strong>"Configure?"</strong> option is enabled, a third-party tool will be configured to use the settings recommended by this patch. If the "Install?" option or the "Reset configuration?" option is enabled, the tool will be configured regardless of whether the "Configure?" option is enabled or not.</p>
											<p>When the <strong>"Reset configuration?"</strong> option is enabled, a third-party tool's configuration will be entirely reset – this is achieved by clearing the configuration file entirely.</p>
											<p>When the <strong>"Check configuration?"</strong> option is enabled, the PowerShell script will output the difference between the recommended settings and the configured settings for a third-party tool's configuration.</p>
										</div>
									</details>
									<table>
										<thead>
											<tr>
												<th>Third-party tool</th>
												<th class="end-aligned-text">Install?</th>
												<th class="end-aligned-text">Configure?</th>
												<th class="end-aligned-text">Reset configuration?</th>
												<th class="end-aligned-text">Check configuration?</th>
											</tr>
										</thead>
										<tbody>
											<tr>
												<td><a target="_blank" rel="noopener noreferrer" href="https://github.com/elishacloud/dxwrapper" class="link">DxWrapper</a></td>
												<td>
													<label aria-label="Install DxWrapper?" title="Install DxWrapper?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:InstallDxWrapper) {'checked'}) data-install-dx-wrapper>
															<span>Install?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Configure DxWrapper?" title="Configure DxWrapper?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:ConfigureDxWrapper) {'checked'}) data-configure-dx-wrapper>
															<span>Configure?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Reset DxWrapper Configuration?" title="Reset DxWrapper Configuration?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:ResetDxWrapperConfiguration) {'checked'}) data-reset-dx-wrapper-configuration>
															<span>Reset Configuration?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Check DxWrapper Configuration?" title="Check DxWrapper Configuration?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:CheckDxWrapperConfiguration) {'checked'}) data-check-dx-wrapper-configuration>
															<span>Check Configuration?</span>
														</span>
													</label>
												</td>
											</tr>
											<tr>
												<td><a target="_blank" rel="noopener noreferrer" href="http://dege.freeweb.hu/dgVoodoo2/" class="link">dgVoodoo2</a></td>
												<td>
													<label aria-label="Install dgVoodoo2?" title="Install dgVoodoo2?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:InstallDgVoodoo2) {'checked'}) data-install-dgvoodoo2>
															<span>Install?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Configure dgVoodoo2?" title="Configure dgVoodoo2?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:ConfigureDgVoodoo2) {'checked'}) data-configure-dgvoodoo2>
															<span>Configure?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Reset dgVoodoo2 Configuration?" title="Reset dgVoodoo2 Configuration?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:ResetDgVoodoo2Configuration) {'checked'}) data-reset-dgvoodoo2-configuration>
															<span>Reset Configuration?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Check dgVoodoo2 Configuration?" title="Check dgVoodoo2 Configuration?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:CheckDgVoodoo2Configuration) {'checked'}) data-check-dgvoodoo2-configuration>
															<span>Check Configuration?</span>
														</span>
													</label>
												</td>
											</tr>
											<tr>
												<td><a target="_blank" rel="noopener noreferrer" href="https://special-k.info/" class="link">Special K</a></td>
												<td>
													<label aria-label="Install Special K?" title="Install Special K?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:InstallSpecialK) {'checked'}) data-install-special-k>
															<span>Install?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Configure Special K?" title="Configure Special K?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:ConfigureSpecialK) {'checked'}) data-configure-special-k>
															<span>Configure?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Reset Special K Configuration?" title="Reset Special K Configuration?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:ResetSpecialKConfiguration) {'checked'}) data-reset-special-k-configuration>
															<span>Reset Configuration?</span>
														</span>
													</label>
												</td>
												<td>
													<label aria-label="Check Special K Configuration?" title="Check Special K Configuration?" class="checkbox">
														<span>
															<input type="checkbox" $(if ($Script:CheckSpecialKConfiguration) {'checked'}) data-check-special-k-configuration>
															<span>Check Configuration?</span>
														</span>
													</label>
												</td>
											</tr>
										</tbody>
									</table>
								</div>
								<label class="checkbox">
									<span>
										<input type="checkbox" $(if ($Script:DoNotInstallThirdPartyToolsByDefaultNextTime) {'checked'}) data-do-not-install-third-party-tools-by-default-next-time>
										<span>Don't install third-party tools by default next time?</span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Don't install third-party tools by default next time?&quot; setting." title="Information about the &quot;Don't install third-party tools by default next time?&quot; setting."></summary>
										<div>
											<p>When this option is enabled, the "Install?" option for all third-party tools will be disabled by default when the "Save the current settings as the default settings for next time" button is pressed, or when the game is patched with the "Save these settings as the default settings for next time?" option enabled.</p>
										</div>
									</details>
								</label>
								$(
									if ($DxWrapperIsProbablyInstalled)
									{
@"
								<p class="austere">DxWrapper is assumed to be installed in the game's installation folder as "$DxWrapperDLL" and "$DxWrapperActualDLL".</p>
"@
									}
									else
									{
@"
								<p class="austere">DxWrapper can be installed in the game's installation folder as "$DxWrapperDLL" and "$DxWrapperActualDLL".</p>
"@
									}
								)
								$(
									if ($DgVoodoo2IsProbablyInstalled)
									{
@"
								<p class="austere">dgVoodoo2 is assumed to be installed in the game's installation folder as "$DgVoodoo2DLL".</p>
"@
									}
									else
									{
@"
								<p class="austere">dgVoodoo2 can be installed in the game's installation folder as "$DgVoodoo2DLL".</p>
"@
									}
								)
								$(
									if ($SpecialKIsProbablyInstalled)
									{
@"
								<p class="austere">Special K is assumed to be installed in the game's installation folder as "$SpecialKDLL".</p>
"@
									}
									else
									{
@"
								<p class="austere">Special K can be installed in the game's installation folder as "$SpecialKDLL".</p>
"@
									}
								)
							</fieldset>
						</section>

						<section id="float-interpolation-settings">
							<fieldset class="pane">
								<legend>
									<header><a href="#float-interpolation-settings" tabindex="-1"><h2>Float Interpolation Settings</h2></a></header>
								</legend>
								<label class="adorned checkbox">
									<span>
										<span>Camera smoothing variant</span>
										<span>
											<select id="camera-smoothing-variant" required data-camera-smoothing-variant>
												<option value $(if ($Null -eq $Script:CameraSmoothingVariant) {'selected'})>(Use recommended value)</option>
												<option value="None" $(if ('None' -eq $Script:CameraSmoothingVariant) {'selected'})>None</option>
												<option value="InterpolatedV2" $(if ('InterpolatedV2' -eq $Script:CameraSmoothingVariant) {'selected'})>Interpolated v2</option>
											</select>
										</span>
									</span>
									<span class="same-line-recommendation">
										<span>Recommended value: </span>
										<span data-camera-smoothing-variant-recommendation></span>
									</span>
									<details>
										<summary aria-label="Information about the &quot;Camera smoothing variant&quot; setting." title="Information about the &quot;Camera smoothing variant&quot; setting."></summary>
										<div>
											<p>This option controls how the game's camera smoothing is adapted to support frame-rates higher than 60 <abbr title="Frames-per-second">FPS</abbr>.</p>
											<p><strong>"Interpolated v2"</strong> aims to replicate the game's vanilla camera smoothing, but at a higher frame-rate.</p>
											<p><strong>"None"</strong> makes no changes to the game's camera smoothing, which generally results in choppy-looking motion.</p>
										</div>
									</details>
								</label>

								<header id="float-interpolation-options"><a href="#float-interpolation-options" tabindex="-1"><h3>Float Interpolation Options</h3></a></header>
								<div>
									<details class="with-label">
										<summary aria-label="Information about the &quot;Float interpolation&quot; settings." title="Information about the &quot;Float interpolation&quot; settings."><span>Float interpolation options</span></summary>
										<div>
											<p>Recettear's game logic is fixed at 60 <abbr title="Frames-per-second">FPS</abbr>, so merely raising the frame-rate limit is not enough to achieve high frame-rate motion. To give the appearance of high frame-rate motion, this patch can interpolate specific floating-point values during the frames that get presented between each frame of game logic. (This is done in a way that has only a visual effect, the game logic is exactly the same as it is in the vanilla game.)</p>
											<p>The "Float interpolation" options can be used to individually specify which floats should be interpolated for display at a frame-rate higher than 60 <abbr title="Frames-per-second">FPS</abbr>.</p>
										</div>
									</details>
									<table id="float-interpolation-options-table" class="float-interpolation-options-table">
										<col>
										<col>
										<col>
										<colgroup></colgroup>
										<thead>
											<tr>
												<th rowspan="2">Option</th>
												<th rowspan="2">
													<label class="checkbox">
														<span>
															<input type="checkbox" data-toggle-float-interpolation-for-all>
															<span>Enabled?</span>
														</span>
													</label>
												</th>
												<th rowspan="2">Synopsis</th>
												<th>Recommended value</th>
											</tr>
											<tr>
												<th>
													<button type="button" data-use-interpolated-float-recommendations>Use recommended value</button>
												</th>
											</tr>
										</thead>
										<tbody>
											$(
												foreach ($Float in $ConfigurableInterpolatedFloats)
												{
													$Name = $($Float.Metadata.Names[0])
													$FloatConfiguration = $InterpolatedFloatConfiguration[$Name].Enabled
@"
											<tr data-interpolated-float="$Name">
												<td>$Name</td>
												<td>
													<label class="checkbox">
														<span>
															<input type="checkbox" $(if ($FloatConfiguration) {'checked'}) $(if ($Null -eq $FloatConfiguration -or 'Recommended' -eq $FloatConfiguration) {'data-initialise-as-indeterminate'}) data-toggle-float-interpolation-for-one>
															<span>Enabled?</span>
														</span>
													</label>
												</td>
												<td>$($Float.Metadata.Synopsis)</td>
												<td data-recommendation></td>
											</tr>
"@
											}
										)
									</table>
								</div>
							</fieldset>
						</section>

						<section id="texture-filtering-settings">
							<fieldset class="pane">
								<legend>
									<header><a href="#texture-filtering-settings" tabindex="-1"><h2>Texture Filtering Settings</h2></a></header>
								</legend>
								<header id="texture-filtering-algorithm-options"><a href="#texture-filtering-algorithm-options" tabindex="-1"><h3>Texture Filtering Algorithm Options</h3></a></header>
								<div>
									<details class="with-label">
										<summary aria-label="Information about the &quot;Texture filtering algorithm&quot; settings." title="Information about the &quot;Texture filtering algorithm&quot; settings."><span>Texture filtering algorithm options</span></summary>
										<div>
											<p>Much of Recettear's 2D art was designed for a resolution of 640x480, which is then, usually, upscaled using bilinear interpolation: causing the art to looking extremely blurry at high resolutions. To remedy this this patch allows the texture-filtering algorithms used for upscaling different classes of textures to be configured separately.</p>
											<p>The "Texture filtering algorithm" options can be used to individually specify which texture-filtering algorithm is used to upscale a class of textures.</p>
											<p>As it is not known which textures some of the following options affect, they are named "Unknown" with a hexadecimal suffix.</p>
										</div>
									</details>
									<table id="texture-filtering-options-table" class="texture-filtering-options-table">
										<col>
										<colgroup></colgroup>
										<col>
										<col>
										<thead>
											<tr>
												<th rowspan="2">Option</th>
												<th scope="colgroup">
													<label for="select-texture-filtering-for-all">Texture filtering algorithm</label>
												</th>
												<th rowspan="2">Synopsis</th>
												<th>Recommended algorithm</th>
											</tr>
											<tr>
												<th scope="col" class="centre-aligned-text">
													<select id="select-texture-filtering-for-all" data-select-texture-filtering-for-all title="Select a texture-filtering algorithm for all options" class="unlabelled">
														<option>(Use recommended algorithm)</option>
														$(
															foreach ($Entry in $TextureFilteringAlgorithmFriendlyNameMapping.GetEnumerator())
															{
@"
														<option value="$($Entry.Value)">$($Entry.Key)</option>
"@
															}
														)
													</select>
												</th>
												<th>
													<button type="button" data-use-texture-filtering-recommendations>Use recommended algorithm</button>
												</th>
											</tr>
										</thead>
										<tbody>
											$(
												foreach ($Entry in $ConfigurableTextureFilterings)
												{
													$Name = $($Entry.Metadata.Names[0])
													$AlgorithmConfiguration = $TextureFilteringConfiguration[$Name].Algorithm

@"
											<tr data-texture-filtering="$Name">
												<td>$Name</td>
												<td class="centre-aligned-text">
													<select data-select-texture-filtering-for-one aria-label="Texture-filtering algorithm for $Name" title="Select a texture-filtering algorithm for $Name" class="unlabelled">
														<option value $(if ($Null -eq $AlgorithmConfiguration -or 'Recommended' -eq $AlgorithmConfiguration) {'selected'})>(Use recommended algorithm)</option>
														$(
															foreach ($Algorithm in $TextureFilteringAlgorithmFriendlyNameMapping.GetEnumerator())
															{
@"
														<option value="$($Algorithm.Value)" $(if ($AlgorithmConfiguration -eq $Algorithm.Value) {'selected'})>$($Algorithm.Key)</option>
"@
															}
														)
													</select>
												</td>
												<td>$($Entry.Metadata.Synopsis)</td>
												<td data-recommendation></td>
											</tr>
"@
											}
										)
										</tbody>
									</table>
								</div>
							</fieldset>
						</section>
					</section>

					<footer data-patching-footer>
						<button type="button" data-patch-game-with-these-settings-button class="as-button pane">Patch the game with these settings</button>
						<button type="button" data-save-current-settings-as-default-button class="as-button pane">Save the current settings as the default settings for next time</button>
						<button type="button" data-discard-changes-and-patch-game-button class="as-button pane">Discard any changes to these settings and patch the game</button>
					</footer>
				</main>
			</div>
		</div>
	</body>
</html>
"@

						Send-Response
					}
					elseif ($Context.Request.Url.AbsolutePath -eq '/save-settings-as-default')
					{
						$ConfigurationObject = Read-RequestBody | ConvertFrom-Json -ErrorAction Stop

						Write-Configuration $ConfigurationObject -ErrorAction Stop

						$Context.Response.StatusCode = 204

						Send-Response
					}
					elseif ($Context.Request.Url.AbsolutePath -eq '/patch-game')
					{
						$PatchRequest = Read-RequestBody | ConvertFrom-Json

						if ($Null -ne $PatchRequest.Configuration)
						{
							Use-ConfigurationObject $PatchRequest.Configuration
						}

						$Context.Response.StatusCode = 204

						Send-Response

						break
					}
					else
					{
						$Context.Response.StatusCode = 404

						Send-Response
					}
				}
				catch
				{
					Remove-ConfiguratorMessage
					Write-Error $_.Exception.ToString() -ErrorAction Continue
					Write-ConfiguratorMessage

					$Context.Response.StatusCode = 500

					Send-Response
				}
			}

			$Listener.Close()
		}
		catch
		{
			$Listener.Abort()

			Write-Error $_ -ErrorAction Continue
		}
		finally
		{
			[Console]::TreatControlCAsInput = $OriginalTreatControlCAsInput
			$StopWatch.Start()
		}
	}


	if ($ShouldExitAfterConfigurator)
	{
		exit
	}


	if ($Script:ReturnInformation)
	{
		Resolve-Configuration

		$PartiallyResolvedEffectiveConfiguration = New-ConfigurationHashTable
		$PartiallyResolvedEffectiveConfiguration.FloatInterpolation = New-FloatInterpolationConfigurationHashTable
		$PartiallyResolvedEffectiveConfiguration.TextureFiltering = New-TextureFilteringConfigurationHashTable

		Resolve-Configuration -Final

		$FullyResolvedEffectiveConfiguration = New-ConfigurationHashTable
		$FullyResolvedEffectiveConfiguration.FloatInterpolation = New-FloatInterpolationConfigurationHashTable
		$FullyResolvedEffectiveConfiguration.TextureFiltering = New-TextureFilteringConfigurationHashTable

		Update-ConfigurationDependentValues

		$Information = [Ordered] @{
			DetectedInstallations = Get-RecettearInstallations
			UsingIntegral2DScaling = $Script:UsingIntegral2DScaling
			DrawDistanceMultiplier = $DrawDistanceMultiplier
			PartiallyResolvedEffectiveConfiguration = $PartiallyResolvedEffectiveConfiguration
			FullyResolvedEffectiveConfiguration = $FullyResolvedEffectiveConfiguration
			RecettearExecutablePath = $RecettearExecutable.FullName
			BackupPath = $Script:BackupPath
			ClobberedByRestoredBackupBackupPath = $Script:ClobberedByRestoredBackupBackupPath
			Configuration = $Script:Configuration
		}

		if ($Null -ne $Script:PSBoundParameters.GameLanguageOverride) {$Information.GameLanguageOverride = $Script:GameLanguageOverride}
		if ($Null -ne $Script:PSBoundParameters.RestoreBackupAutomatically) {$Information.RestoreBackupAutomatically = $Script:RestoreBackupAutomatically}
		if ($Null -ne $Script:PSBoundParameters.ApplySupportedPatchAutomatically) {$Information.ApplySupportedPatchAutomatically = $Script:ApplySupportedPatchAutomatically}
		if ($Null -ne $Script:PSBoundParameters.ReturnInformation) {$Information.ReturnInformation = $Script:ReturnInformation}
		if ($Null -ne $Script:PSBoundParameters.SkipConfigurator) {$Information.SkipConfigurator = $Script:SkipConfigurator}
		if ($Null -ne $Script:PSBoundParameters.ConfiguratorPort) {$Information.ConfiguratorPort = $Script:ConfiguratorPort}
		if ($Null -ne $Script:PSBoundParameters.InterpolatedFloatsToIncludeInCheatTable) {$Information.InterpolatedFloatsToIncludeInCheatTable = $Script:InterpolatedFloatsToIncludeInCheatTable}

		$Information.ConfigurableInterpolatedFloats = $ConfigurableInterpolatedFloats.ForEach{$_.Metadata}
		$Information.ConfigurableTextureFilterings = $ConfigurableTextureFilterings.ForEach{$_.Metadata}

		return [PSCustomObject] $Information
	}


	if (-not $Script:SkipPatching)
	{
		Resolve-Configuration


		if ($Script:SaveSettingsToConfiguration)
		{
			$ConfigurationObject = New-ConfigurationHashTable `
			{
				Param ($Object)

				$Object.SchemaVersion = 1
			}

			$ConfigurationObject.FloatInterpolation = New-FloatInterpolationConfigurationHashTable
			$ConfigurationObject.TextureFiltering = New-TextureFilteringConfigurationHashTable

			Write-Configuration $ConfigurationObject -ErrorAction Stop
		}


		Resolve-Configuration -Final
		Update-ConfigurationDependentValues


		if ($Null -eq $InterpolatedFloatConfiguration.Values.Where({$_.Enabled}, 'First')[0])
		{
			$InterpolatingFloats = $Null
		}
		else
		{
			$InterpolatingFloats = @{}

			foreach ($Float in $InterpolatedFloatConfiguration.GetEnumerator())
			{
				$InterpolatingFloats[$Float.Key] = $Float.Value.Enabled
			}
		}


		Write-Host (
@"

Recettear is being patched as follows:
	FramerateLimit: $Script:FramerateLimit
	ResolutionWidth: $Script:ResolutionWidth
	ResolutionHeight: $Script:ResolutionHeight
	HUDWidth: $Script:HUDWidth
	UsingIntegral2DScaling: $Script:UsingIntegral2DScaling
	MobDrawDistancePatchVariant: $Script:MobDrawDistancePatchVariant
	CameraSmoothingVariant: $Script:CameraSmoothingVariant
	HideChangeCameraControlReminder: $Script:HideChangeCameraControlReminder
	HideSkipEventControlReminder: $Script:HideSkipEventControlReminder
	HideItemDetailsControlReminderWhenHaggling: $Script:HideItemDetailsControlReminderWhenHaggling
	HideItemDetailsControlReminderInItemMenus: $Script:HideItemDetailsControlReminderInItemMenus
	FloatInterpolation: $(
		foreach ($Float in $InterpolatedFloatConfiguration.GetEnumerator())
		{
@"

		$($Float.Key): $($Float.Value.Enabled)
"@
		}
	)
	TextureFiltering: $(
		foreach ($Entry in $TextureFilteringConfiguration.GetEnumerator())
		{
@"

		$($Entry.Key): $($Entry.Value.Algorithm)
"@
		}
	)
"@
		)


		$KnownVersions = @{
			EnglishV1_108 = [PSCustomObject] @{
				FriendlyName = 'English DRM-free version 1.108'

				ExecutableFingerprint = [PSCustomObject] @{
					FileSize = 5268554
					SHA256Hash = '19691EBC5F05BEE4BF40417F64214E99E0CB8D8D4AA6B3BBAFFF98824AB3AC50'
				}

				Addresses = @{
					PauseTransitionEffectConditional = [UInt32] 0x000547c7
					CameraSmoothingReset = [UInt32] 0x0004210c
					'CameraPositions[0]' = [UInt32] 0x0438cc38
					'CameraPositions[1]' = [UInt32] 0x0438cc3c
					'CameraPositions[2]' = [UInt32] 0x0438cc40
					'CameraPositions[3]' = [UInt32] 0x0438cc50
					'CameraPositions[4]' = [UInt32] 0x0438cc54
					'CameraPositions[5]' = [UInt32] 0x0438cc58
					CameraHeight = [UInt32] 0x06a46f9c
					ShouldInitialiseCameraPositions = [UInt32] 0x0438cc68
					SelectedSaveSlotIndex = [UInt32] 0x09643530
					SelectedSaveSlotPulsatingEffectCounter = [UInt32] 0x09643574
					CameraShakeActualValue = [UInt32] 0x0438cc20
					CameraModifier0 = [UInt32] 0x073de320
					CameraModifier1 = [UInt32] 0x073de32c
					CameraShakeConditional = [UInt32] 0x0004241d
					PlayerCharacterPossePositionResetHijack = [UInt32] 0x000373f7
					ProjectilePositionResetHijack = [UInt32] 0x00045ab8
					ArrowProjectilePositionResetHijack = [UInt32] 0x000437e0
					MovementParticlePositionResetHijack = [UInt32] 0x00047f92
					XPGemPositionResetHijack = [UInt32] 0x0004afa4
					ShopperPositionResetHijack = [UInt32] 0x0006f94f
					MobPositionResetHijack = [UInt32] 0x0001f933
					MirrorImageCounter = [UInt32] 0x056daae0
					ChestTeleporationPositionResetHijack = [UInt32] 0x000960a4
					NagiEncounterRNGOverrideHijack = [UInt32] 0x00031ea7
					ThreadHandle = [UInt32] 0x06a49950
					ThreadGuardA_A = [UInt32] 0x06a49954
					ThreadGuardA_B = [UInt32] 0x06a49958
					ThreadGuardB_A = [UInt32] 0x06a4995c
					ThreadGuardB_B = [UInt32] 0x06a49960
					ThreadGuardC_A = [UInt32] 0x0438b1cc
					ThreadGuardD_A = [UInt32] 0x0438b1d4
					'GameIsPaused?' = [UInt32] 0x06a499a0
					GameStateA = [UInt32] 0x06a4999c
					GameStateB = [UInt32] 0x0438b1c0
					GameStateC = [UInt32] 0x06a49990
					GameStateD = [UInt32] 0x068dd2f0
					GameStateE = [UInt32] 0x06a499a4
					GameStateF = [UInt32] 0x005c5958
					GameStateG = [UInt32] 0x073a3df0
					GameStateH = [UInt32] 0x06a49994
					GameStateI = [UInt32] 0x0438b1b0
					GameStateJ = [UInt32] 0x0438b1d0
					GameStateK = [UInt32] 0x0438b1d8
					'InAnEvent?' = [UInt32] 0x0438b1c8
					ShouldDisplayEndOfDaySummary = [UInt32] 0x06a4997c
					ShouldDrawTheHUD = [UInt32] 0x005c570c
					HUDSlideInPercentage = [UInt32] 0x0438b1dc
					LoadingDiscRotationAngle = [UInt32] 0x06a4998c
					CurrentMapClockMessage = [UInt32] 0x00529708
					WindowShopperPositionCount = [UInt32] 0x005c7dd4
					XPGemCount = [UInt32] 0x0076b968
					ShowItemInfoState = [UInt32] 0x0734b96c
					ShopIsOpen = [UInt32] 0x0438b7b0
					ShouldDrawSelectionHand = [UInt32] 0x0438b150
					ShouldDisplayFPSOSD = [UInt32] 0x0438cce0
					'ShouldDoFrame?' = [UInt32] 0x073dfca0
					SelectionHandX = [UInt32] 0x0438abf4
					SelectionHandY = [UInt32] 0x0438abf8
					PauseTransitionEffectCounter = [UInt32] 0x06a4999c
					LevelIntroductionCounter = [UInt32] 0x00648270
					NewsTickerCounter = [UInt32] 0x0438b92c
					ShopTillItemTransitionCounter = [UInt32] 0x0730b5a0
					ShopTillEntryTransitionCounter = [UInt32] 0x0730b530
					ShopTillCustomerPosition = [UInt32] 0x0730b52c
					TearMenuTransitionCounter = [UInt32] 0x0438b8c0
					TearLectureButtonTransitionCounter = [UInt32] 0x0438b750
					MenuPromptTransitionCounter = [UInt32] 0x0438af34
					FulfilOrderState = [UInt32] 0x0730b5d0
					FulfilOrderSelectionHandState = [UInt32] 0x0730b5cc
					GameWindowHWnd = [UInt32] 0x073dfc7c
					GameIsWindowed = [UInt32] 0x0438b164
					ShouldUseSavedWindowPosition = [UInt32] 0x0438b190
					SavedWindowLeft = [UInt32] 0x0438b1a4
					SavedWindowTop = [UInt32] 0x0438b1a8
					WindowAspectRatioIsFixed = [UInt32] 0x0438cce4
					ResolutionX = [UInt32] 0x005cbc04
					ResolutionY = [UInt32] 0x005cbc08
					PresentationParameters = [UInt32] 0x073de268
					PresentationParametersFullScreen_RefreshRateInHz = [UInt32] 0x073de294
					PresentationParametersFullScreen_PresentationInterval = [UInt32] 0x073de298
					AspectRatio = [UInt32] 0x00519338
					_640f = [UInt32] 0x00519358
					'128f' = [UInt32] 0x00519374
					'128nf' = [UInt32] 0x00519468
					BlackBarTexture = [UInt32] 0x073aa188
					AllEncompassingPositionResetHijack = [UInt32] 0x00036f97
					UIStuffFunction = [UInt32] 0x00004efc
					'UIStuffFunctionWrapper[0]' = [UInt32] 0x00004e61
					__ftol = [UInt32] 0x00503954
					PauseMenuFreezeEffect = [UInt32] 0x00054191
					FadeToFromBlackEffect = [UInt32] 0x00053e8f
					ShowNowLoadingMessage = [UInt32] 0x00053147
					HandleMainMenu = [UInt32] 0x0009a59e
					DrawTheHUD = [UInt32] 0x0000a765
					DrawShopHUD = [UInt32] 0x00009925
					DrawMerchantLevelNumber = [UInt32] 0x00081ec3
					DrawLevelIntroductionAndSomeHUD = [UInt32] 0x00006d50
					DrawHUDClockPix = [UInt32] 0x00006a60
					DrawTillUI = [UInt32] 0x0006602e
					DrawsCutsceneAndMore = [UInt32] 0x0006c9a2
					DrawBossAttackCameraEffect = [UInt32] 0x0005404b
					DrawFPSOSD = [UInt32] 0x000523e6
					DrawCombatHUD = [UInt32] 0x00007cac
					DrawLootedLoot = [UInt32] 0x0000c962
					DrawAdventurerHUD = [UInt32] 0x000072f5
					DrawHagglingUI = [UInt32] 0x00066b7b
					DrawMenu = [UInt32] 0x0006b00a
					DrawSkipEventPrompt = [UInt32] 0x0003537e
					DrawSelectionHand = [UInt32] 0x00035747
					DrawEncyclopediaItems = [UInt32] 0x0009f8b8
					DrawSaveSlots = [UInt32] 0x0009b556
					DrawText = [UInt32] 0x0007ca05
					SomeShopRelatedGameLogic = [UInt32] 0x00062403
					SetSomeMobData = [UInt32] 0x00030c6d
					DrawWorld = [UInt32] 0x00057714
					DrawFlora = [UInt32] 0x00059847
					ReallyBigPresentationFunction = [UInt32] 0x000176ff
					SomeRenderingFunction = [UInt32] 0x000552d0
					MoreMobRelatedRendering = [UInt32] 0x00056f56
					DrawShadows = [UInt32] 0x0005aa36
					DimScreenForDungeonCrawlingSaveWarning = [UInt32] 0x000351b4
					DrawEnqueuedTextures = [UInt32] 0x00005354
					SomeShopRelatedRendering = [UInt32] 0x00059dfd
					WindowProcedure = [UInt32] 0x0007b2e7
					WindowCreation = [UInt32] 0x0007aa8b
					Direct3DDeviceCreation = [UInt32] 0x0007ac6a
					ReadConfig = [UInt32] 0x0007a474
					GetModuleHandleA = [UInt32] 0x00515198
					GetProcAddress = [UInt32] 0x00515190
					GetClientRect = [UInt32] 0x00515258
					MoveWindow = [UInt32] 0x00515250
					GetWindowRect = [UInt32] 0x0051524c
					AdjustWindowRect = [UInt32] 0x00515200
					'TwoDimensionalStuff[0]' = [UInt32] 0x00004e98
					'TwoDimensionalStuff[2]' = [UInt32] 0x0000512e
					'TwoDimensionalStuff[3]' = [UInt32] 0x000054c0
					'TwoDimensionalStuff[4]' = [UInt32] 0x00006241
					'TwoDimensionalStuff[5]LoadingScreenDisc' = [UInt32] 0x000063c7
					'TwoDimensionalStuff[10]' = [UInt32] 0x00090cc6
					TownMapClearAndDraw = [UInt32] 0x0009e686
					'PositionTearMenuTransition[0][0]Hijack' = [UInt32] 0x0000b431
					'PositionTearMenuTransition[1][0]Hijack' = [UInt32] 0x0000b77f
					'PositionTearMenuTransition[2][0]Hijack' = [UInt32] 0x0000bbea
					'PositionTearMenuTransition[3][0]Hijack' = [UInt32] 0x0000bd76
					PlayerCharacterPosition = [UInt32] 0x056da1d8
					RecetWhenInDungeonPosition = [UInt32] 0x056da1e4
					TearPosition = [UInt32] 0x056da1f0
					ShopperPosition = [UInt32] 0x073a6ea8
					WindowShopperPosition = [UInt32] 0x073a7fac
					MobPosition = [UInt32] 0x0076b970
					MirrorImageReflectionPosition = [UInt32] 0x056dabac
					AttackProjectilePosition = [UInt32] 0x069324b0
					XPGemPosition = [UInt32] 0x06956cdc
					MovementParticlePosition = [UInt32] 0x069b2f84
					'TextureFiltering[0]' = [UInt32] 0x0001667f
					'TextureFiltering[1]' = [UInt32] 0x00006d94
					'TextureFiltering[2]' = [UInt32] 0x0005244a
					'TextureFiltering[3]' = [UInt32] 0x0007caba
					'TextureFiltering[4]' = [UInt32] 0x000531c1
					'TextureFiltering[5]' = [UInt32] 0x00059ead
					'TextureFiltering[6]' = [UInt32] 0x0005aadb
					'TextureFiltering[7]' = [UInt32] 0x0009b4df
					'TextureFiltering[8]' = [UInt32] 0x0000c765
					'TextureFiltering[9]' = [UInt32] 0x00016200
					'TextureFiltering[10]' = [UInt32] 0x00053ea9
					'TextureFiltering[11]' = [UInt32] 0x00055422
					'TextureFiltering[12]' = [UInt32] 0x00056cd8
					'TextureFiltering[13]' = [UInt32] 0x0006c9da
					'TextureFiltering[14]' = [UInt32] 0x0006d10e
					'TextureFiltering[15]' = [UInt32] 0x0007d24f
					'TextureFiltering[16]' = [UInt32] 0x0007d3de
					'TextureFiltering[17]' = [UInt32] 0x0007d497
					'TextureFiltering[18]' = [UInt32] 0x0001756d
					'TextureFiltering[19]' = [UInt32] 0x0005420f
					'TextureFiltering[20]' = [UInt32] 0x000575e0
					'TextureFiltering[21]' = [UInt32] 0x00058d2c
				}

				Offsets = @{
					PositionTearLectureButtonTransition = 2701
					SuppressChangeCameraControlReminder = 3294
					SuppressItemDetailsControlReminderWhenHaggling = 1953
					'TwoDimensionalStuff[7]ResolutionWidth' = 2377
					'TwoDimensionalStuff[7][0]' = 2391
					'TwoDimensionalStuff[7][1]Hijack' = 2398
					'ScaleDayIntoductionFadeFromBlack[0]' = 6955
					'ScaleDayIntoductionFadeFromBlack[1]' = 7365
					'PositionTheNewsTicker[0]' = 2858
					ScaleTheNewsTicker = 2883
					ScaleChestTeleportationFadeToFromWhite = 7541
					PositionHUDMerchantLevelXAndY = 1036
					PositionHUDChangeCameraX = 3382
					PositionHUDChangeCameraY = 3391
					PositionCombatAdventurerPanelVertically = 17
					'PositionCombatNewsHorizontally[0]' = 1898
					'PositionCombatNewsHorizontally[1]' = 1905
					PositionCombatNewsVertically = 1983
					PositionMinimapHorizontally = 2078
					PositionMinimapVertically = 2103
					PositionLevelNameY = 3504
					'PositionLevelNameX[0]' = 3553
					'PositionLevelNameX[1]' = 3635
					'PositionLevelNameX[2]' = 3723
					'PositionLevelNameX[3]' = 3917
					'PositionLevelNameX[4]' = 4034
					'PositionCombatChainX[0]' = 4213
					'PositionCombatChainX[1]' = 4319
					'PositionCombatChainY[0]' = 4222
					'PositionCombatChainY[1]' = 4328
					PositionEnemyHealthBarVertically = 6342
					'PositionEnemyHealthBarHorizontally[0]' = 6411
					'PositionEnemyHealthBarHorizontally[1]' = 6508
					'PositionEnemyHealthBarHorizontally[2]' = 6579
					'PositionEnemyHealthBarHorizontally[3]' = 6710
					'PositionEnemyHealthBarHorizontally[4]' = 6833
					'PositionEnemyHealthBarHorizontally[5]' = 7018
					'PositionEnemyHealthBarHorizontally[6]' = 7152
					'PositionEnemyHealthBarHorizontally[7]' = 7236
					MakeRoomForReturnHijackInHagglingUI = 5277
					JumpToStopPositioningHagglingUIVertically = 5301
					PositionSellingMenuInShopVertically = 2390
				}
			}

			JapaneseV1_126 = [PSCustomObject] @{
				FriendlyName = 'Japanese DRM-free version 1.126'

				ExecutableFingerprint = [PSCustomObject] @{
					FileSize = 5275699
					SHA256Hash = '189EED1CCB5E124D30A5E5ABBEE8AF281D9AF571327033236E1DD0F7F62C8403'
				}

				Addresses = @{
					PauseTransitionEffectConditional = [UInt32] 0x0005474c
					CameraSmoothingReset = [UInt32] 0x00042091
					'CameraPositions[0]' = [UInt32] 0x0438c8a8
					'CameraPositions[1]' = [UInt32] 0x0438c8ac
					'CameraPositions[2]' = [UInt32] 0x0438c8b0
					'CameraPositions[3]' = [UInt32] 0x0438c8c0
					'CameraPositions[4]' = [UInt32] 0x0438c8c4
					'CameraPositions[5]' = [UInt32] 0x0438c8c8
					CameraHeight = [UInt32] 0x06a46c0c
					ShouldInitialiseCameraPositions = [UInt32] 0x0438c8d8
					SelectedSaveSlotIndex = [UInt32] 0x0962d678
					SelectedSaveSlotPulsatingEffectCounter = [UInt32] 0x0962d6bc
					CameraShakeActualValue = [UInt32] 0x0438c890
					CameraModifier0 = [UInt32] 0x073d1d80
					CameraModifier1 = [UInt32] 0x073d1d8c
					CameraShakeConditional = [UInt32] 0x000423a2
					PlayerCharacterPossePositionResetHijack = [UInt32] 0x0003737c
					ProjectilePositionResetHijack = [UInt32] 0x00045a3d
					ArrowProjectilePositionResetHijack = [UInt32] 0x00043765
					MovementParticlePositionResetHijack = [UInt32] 0x00047f17
					XPGemPositionResetHijack = [UInt32] 0x0004af29
					ShopperPositionResetHijack = [UInt32] 0x0006f672
					MobPositionResetHijack = [UInt32] 0x0001f8b8
					MirrorImageCounter = [UInt32] 0x056da750
					ChestTeleporationPositionResetHijack = [UInt32] 0x00095d6e
					NagiEncounterRNGOverrideHijack = [UInt32] 0x00031e2c
					ThreadHandle = [UInt32] 0x06a495c0
					ThreadGuardA_A = [UInt32] 0x06a495c4
					ThreadGuardA_B = [UInt32] 0x06a495c8
					ThreadGuardB_A = [UInt32] 0x06a495cc
					ThreadGuardB_B = [UInt32] 0x06a495d0
					ThreadGuardC_A = [UInt32] 0x0438ae3c
					ThreadGuardD_A = [UInt32] 0x0438ae44
					'GameIsPaused?' = [UInt32] 0x06a49610
					GameStateA = [UInt32] 0x06a4960c
					GameStateB = [UInt32] 0x0438ae30
					GameStateC = [UInt32] 0x06a49600
					GameStateD = [UInt32] 0x068dcf60
					GameStateE = [UInt32] 0x06a49614
					GameStateF = [UInt32] 0x005c5730
					GameStateG = [UInt32] 0x073996f0
					GameStateH = [UInt32] 0x06a49604
					GameStateI = [UInt32] 0x0438ae20
					GameStateJ = [UInt32] 0x0438ae40
					GameStateK = [UInt32] 0x0438ae48
					'InAnEvent?' = [UInt32] 0x0438ae38
					ShouldDisplayEndOfDaySummary = [UInt32] 0x06a495ec
					ShouldDrawTheHUD = [UInt32] 0x005c54e4
					HUDSlideInPercentage = [UInt32] 0x0438ae4c
					LoadingDiscRotationAngle = [UInt32] 0x06a495fc
					CurrentMapClockMessage = [UInt32] 0x00529950
					WindowShopperPositionCount = [UInt32] 0x005c7adc
					XPGemCount = [UInt32] 0x0076b5d8
					ShowItemInfoState = [UInt32] 0x0734a95c
					ShopIsOpen = [UInt32] 0x0438b420
					ShouldDrawSelectionHand = [UInt32] 0x0438adc0
					ShouldDisplayFPSOSD = [UInt32] 0x0438c950
					'ShouldDoFrame?' = [UInt32] 0x073d33e0
					SelectionHandX = [UInt32] 0x0438a864
					SelectionHandY = [UInt32] 0x0438a868
					PauseTransitionEffectCounter = [UInt32] 0x06a4960c
					LevelIntroductionCounter = [UInt32] 0x00647ee8
					NewsTickerCounter = [UInt32] 0x0438b59c
					ShopTillItemTransitionCounter = [UInt32] 0x0730a590
					ShopTillEntryTransitionCounter = [UInt32] 0x0730a520
					ShopTillCustomerPosition = [UInt32] 0x0730a51c
					TearMenuTransitionCounter = [UInt32] 0x0438b530
					TearLectureButtonTransitionCounter = [UInt32] 0x0438b3c0
					MenuPromptTransitionCounter = [UInt32] 0x0438aba4
					FulfilOrderState = [UInt32] 0x0730a5c0
					FulfilOrderSelectionHandState = [UInt32] 0x0730a5bc
					GameWindowHWnd = [UInt32] 0x073d33bc
					GameIsWindowed = [UInt32] 0x0438add4
					ShouldUseSavedWindowPosition = [UInt32] 0x0438ae00
					SavedWindowLeft = [UInt32] 0x0438ae14
					SavedWindowTop = [UInt32] 0x0438ae18
					WindowAspectRatioIsFixed = [UInt32] 0x0438c954
					ResolutionX = [UInt32] 0x005cb908
					ResolutionY = [UInt32] 0x005cb90c
					PresentationParameters = [UInt32] 0x073d1cc8
					PresentationParametersFullScreen_RefreshRateInHz = [UInt32] 0x073d1cf4
					PresentationParametersFullScreen_PresentationInterval = [UInt32] 0x073d1cf8
					AspectRatio = [UInt32] 0x00519318
					_640f = [UInt32] 0x00519338
					'128f' = [UInt32] 0x00519354
					'128nf' = [UInt32] 0x00519448
					BlackBarTexture = [UInt32] 0x0739dbe8
					AllEncompassingPositionResetHijack = [UInt32] 0x00036f1c
					UIStuffFunction = [UInt32] 0x00004fd6
					'UIStuffFunctionWrapper[0]' = [UInt32] 0x00004f3b
					__ftol = [UInt32] 0x00503494
					PauseMenuFreezeEffect = [UInt32] 0x00054116
					FadeToFromBlackEffect = [UInt32] 0x00053e14
					ShowNowLoadingMessage = [UInt32] 0x000530cc
					HandleMainMenu = [UInt32] 0x0009a149
					DrawTheHUD = [UInt32] 0x0000a804
					DrawShopHUD = [UInt32] 0x00009a23
					DrawMerchantLevelNumber = [UInt32] 0x00081caf
					DrawLevelIntroductionAndSomeHUD = [UInt32] 0x00006e2a
					DrawHUDClockPix = [UInt32] 0x00006b3a
					DrawTillUI = [UInt32] 0x00065f25
					DrawsCutsceneAndMore = [UInt32] 0x0006c6c2
					DrawBossAttackCameraEffect = [UInt32] 0x00053fd0
					DrawFPSOSD = [UInt32] 0x0005236b
					DrawCombatHUD = [UInt32] 0x00007d86
					DrawLootedLoot = [UInt32] 0x0000c8fa
					DrawAdventurerHUD = [UInt32] 0x000073cf
					DrawHagglingUI = [UInt32] 0x00066a72
					DrawMenu = [UInt32] 0x0006ad2a
					DrawSkipEventPrompt = [UInt32] 0x00035303
					DrawSelectionHand = [UInt32] 0x000356cc
					DrawEncyclopediaItems = [UInt32] 0x0009f463
					DrawSaveSlots = [UInt32] 0x0009b101
					DrawText = [UInt32] 0x0007c859
					SomeShopRelatedGameLogic = [UInt32] 0x0006231e
					SetSomeMobData = [UInt32] 0x00030bf2
					DrawWorld = [UInt32] 0x00057699
					DrawFlora = [UInt32] 0x000597cc
					ReallyBigPresentationFunction = [UInt32] 0x00017684
					SomeRenderingFunction = [UInt32] 0x00055255
					MoreMobRelatedRendering = [UInt32] 0x00056edb
					DrawShadows = [UInt32] 0x0005a9bb
					DimScreenForDungeonCrawlingSaveWarning = [UInt32] 0x00035139
					DrawEnqueuedTextures = [UInt32] 0x0000542e
					SomeShopRelatedRendering = [UInt32] 0x00059d82
					WindowProcedure = [UInt32] 0x0007b12d
					WindowCreation = [UInt32] 0x0007a8d1
					Direct3DDeviceCreation = [UInt32] 0x0007aab0
					ReadConfig = [UInt32] 0x0007a2ba
					GetModuleHandleA = [UInt32] 0x0051516c
					GetProcAddress = [UInt32] 0x00515164
					GetClientRect = [UInt32] 0x00515248
					MoveWindow = [UInt32] 0x00515244
					GetWindowRect = [UInt32] 0x00515240
					AdjustWindowRect = [UInt32] 0x00515234
					'TwoDimensionalStuff[0]' = [UInt32] 0x00004f72
					'TwoDimensionalStuff[2]' = [UInt32] 0x00005208
					'TwoDimensionalStuff[3]' = [UInt32] 0x0000559a
					'TwoDimensionalStuff[4]' = [UInt32] 0x0000631b
					'TwoDimensionalStuff[5]LoadingScreenDisc' = [UInt32] 0x000064a1
					'TwoDimensionalStuff[10]' = [UInt32] 0x000909c4
					TownMapClearAndDraw = [UInt32] 0x0009e231
					'PositionTearMenuTransition[0][0]Hijack' = [UInt32] 0x0000b4b8
					'PositionTearMenuTransition[1][0]Hijack' = [UInt32] 0x0000b6c1
					'PositionTearMenuTransition[2][0]Hijack' = [UInt32] 0x0000ba79
					'PositionTearMenuTransition[3][0]Hijack' = [UInt32] 0x0000bc07
					PlayerCharacterPosition = [UInt32] 0x056d9e48
					RecetWhenInDungeonPosition = [UInt32] 0x056d9e54
					TearPosition = [UInt32] 0x056d9e60
					ShopperPosition = [UInt32] 0x0739a908
					WindowShopperPosition = [UInt32] 0x0739ba0c
					MobPosition = [UInt32] 0x0076b5e0
					MirrorImageReflectionPosition = [UInt32] 0x056da81c
					AttackProjectilePosition = [UInt32] 0x06932120
					XPGemPosition = [UInt32] 0x0695694c
					MovementParticlePosition = [UInt32] 0x069b2bf4
					'TextureFiltering[0]' = [UInt32] 0x00016604
					'TextureFiltering[1]' = [UInt32] 0x00006e6e
					'TextureFiltering[2]' = [UInt32] 0x000523cf
					'TextureFiltering[3]' = [UInt32] 0x0007c90e
					'TextureFiltering[4]' = [UInt32] 0x00053146
					'TextureFiltering[5]' = [UInt32] 0x00059e32
					'TextureFiltering[6]' = [UInt32] 0x0005aa60
					'TextureFiltering[7]' = [UInt32] 0x0009b08a
					'TextureFiltering[8]' = [UInt32] 0x0000c6fd
					'TextureFiltering[9]' = [UInt32] 0x00016185
					'TextureFiltering[10]' = [UInt32] 0x00053e2e
					'TextureFiltering[11]' = [UInt32] 0x000553a7
					'TextureFiltering[12]' = [UInt32] 0x00056c5d
					'TextureFiltering[13]' = [UInt32] 0x0006c6fa
					'TextureFiltering[14]' = [UInt32] 0x0006ce2e
					'TextureFiltering[15]' = [UInt32] 0x0007d1d5
					'TextureFiltering[16]' = [UInt32] 0x0007d28d
					'TextureFiltering[17]' = [UInt32] 0x0007d28d
					'TextureFiltering[18]' = [UInt32] 0x000174f2
					'TextureFiltering[19]' = [UInt32] 0x00054194
					'TextureFiltering[20]' = [UInt32] 0x00057565
					'TextureFiltering[21]' = [UInt32] 0x00058cb1
				}

				Offsets = @{
					PositionTearLectureButtonTransition = 2606
					SuppressChangeCameraControlReminder = 3199
					SuppressItemDetailsControlReminderWhenHaggling = 1725
					'TwoDimensionalStuff[7]ResolutionWidth' = 2415
					'TwoDimensionalStuff[7][0]' = 2429
					'TwoDimensionalStuff[7][1]Hijack' = 2436
					'ScaleDayIntoductionFadeFromBlack[0]' = 6430
					'ScaleDayIntoductionFadeFromBlack[1]' = 7102
					'PositionTheNewsTicker[0]' = 2802
					ScaleTheNewsTicker = 2827
					ScaleChestTeleportationFadeToFromWhite = 7278
					PositionHUDMerchantLevelXAndY = 941
					PositionHUDChangeCameraX = 3287
					PositionHUDChangeCameraY = 3296
					PositionCombatAdventurerPanelVertically = 15
					'PositionCombatNewsHorizontally[0]' = 1932
					'PositionCombatNewsHorizontally[1]' = 1941
					PositionCombatNewsVertically = 2013
					PositionMinimapHorizontally = 2114
					PositionMinimapVertically = 2140
					PositionLevelNameY = 3540
					'PositionLevelNameX[0]' = 3589
					'PositionLevelNameX[1]' = 3671
					'PositionLevelNameX[2]' = 3759
					'PositionLevelNameX[3]' = 3953
					'PositionLevelNameX[4]' = 4070
					'PositionCombatChainX[0]' = 4249
					'PositionCombatChainX[1]' = 4355
					'PositionCombatChainY[0]' = 4258
					'PositionCombatChainY[1]' = 4364
					PositionEnemyHealthBarVertically = 6378
					'PositionEnemyHealthBarHorizontally[0]' = 6447
					'PositionEnemyHealthBarHorizontally[1]' = 6544
					'PositionEnemyHealthBarHorizontally[2]' = 6615
					'PositionEnemyHealthBarHorizontally[3]' = 6746
					'PositionEnemyHealthBarHorizontally[4]' = 6869
					'PositionEnemyHealthBarHorizontally[5]' = 7054
					'PositionEnemyHealthBarHorizontally[6]' = 7188
					'PositionEnemyHealthBarHorizontally[7]' = 7272
					MakeRoomForReturnHijackInHagglingUI = 5042
					JumpToStopPositioningHagglingUIVertically = 5066
					PositionSellingMenuInShopVertically = 2395
				}
			}

			SteamEnglish = [PSCustomObject] @{
				FriendlyName = 'English Steam version'

				ExecutableFingerprint = [PSCustomObject] @{
					FileSize = 5629440
					SHA256Hash = '079B5B679F1D363EA3DCFE4EC931CEB6D9E4B4A288926FFC8ABB5814E80392B4'
				}
			}

			SteamJapanese = [PSCustomObject] @{
				FriendlyName = 'Japanese Steam version'

				ExecutableFingerprint = [PSCustomObject] @{
					FileSize = 5640192
					SHA256Hash = '4249A8F71D899FD11DF2E7C3C5A5A8D21D72170409B08129A804693A4EAD671B'
				}
			}
		}


		function Apply-Patch ($File, $Version)
		{
			$File.Position = 0

			Use-Disposable ([IO.StreamReader]::new($File, $Latin1, $False, 4096, $True)) `
			{
				Param ($Reader)

				$Bytes = $Reader.ReadToEnd()

				$Int = [Byte[]]::new(4)
				$Short = [Byte[]]::new(2)

				function Read-Int ($Position)
				{
					$File.Position = $Position
					$File.Read($Int, 0, 4) > $Null
					[BitConverter]::ToUInt32((LittleEndian $Int), 0)
				}

				function Read-Short ($Position)
				{
					$File.Position = $Position
					$File.Read($Short, 0, 2) > $Null
					[BitConverter]::ToUInt16((LittleEndian $Short), 0)
				}

				$PEOffset = (Read-Int 0x3C) + 4
				$OptionalHeaderOffset = $PEOffset + 20
				$SectionCount = Read-Short ($PEOffset + 2)
				$OptionalHeaderSize = Read-Short ($PEOffset + 16)
				$SectionTableOffset = $OptionalHeaderOffset + $OptionalHeaderSize
				$SizeOfCode = Read-Int ($OptionalHeaderOffset + 4)
				$SizeOfInitialisedData = Read-Int ($OptionalHeaderOffset + 8)
				${&EntryPoint} = Read-Int ($OptionalHeaderOffset + 16)
				$ImageBase = Read-Int ($OptionalHeaderOffset + 28)
				$SectionAlignment = Read-Int ($OptionalHeaderOffset + 32)
				$FileAlignment = Read-Int ($OptionalHeaderOffset + 36)
				$SizeOfImage = Read-Int ($OptionalHeaderOffset + 60)
				$SizeOfHeaders = Read-Int ($OptionalHeaderOffset + 64)

				$Sections = for ($Index = 0; $Index -lt $SectionCount; ++$Index)
				{
					$SectionOffset = $SectionTableOffset + 40 * $Index

					$Name = [Byte[]]::new(8)
					$File.Position = $SectionOffset
					$File.Read($Name, 0, 8) > $Null

					[PSCustomObject] @{
						Name = $Name
						VirtualSize = Read-Int ($SectionOffset + 8)
						VirtualAddress = Read-Int ($SectionOffset + 12)
						RawDataSize = Read-Int ($SectionOffset + 16)
						RawDataOffset = Read-Int ($SectionOffset + 20)
						Characteristics = Read-Int ($SectionOffset + 36)
						SectionOffsetInFile = $SectionOffset
						NextSection = $Null
					}
				}

				$Sections = $Sections | Sort-Object -Property VirtualAddress

				for ($Index = 0; $Index -lt $Sections.Count - 1; ++$Index)
				{
					$Sections[$Index].NextSection = $Sections[$Index + 1]
				}

				$FirstSectionOffset = ($Sections | Measure-Object -Property RawDataOffset -Minimum).Minimum
				$SectionsThatCanBeAddedCount = [UInt32] [Math]::Truncate(
					($FirstSectionOffset - ($SectionTableOffset + 40 * $SectionCount)) / 40
				)

				if ($SectionsThatCanBeAddedCount -lt 2)
				{
					throw [FancyScreenPatchForRecettearTooFewUnusedExecutableSectionSlotsException]::new('There''s not enough space in the executable to install the patch.', [PSCustomObject] @{RequiredUnusedExecutableSectionSlotCount = 2})
				}

				$LastSectionVirtually = $Sections[$Sections.Length - 1]

				$VirtualAddressOfEndOfLastSection = $LastSectionVirtually.VirtualAddress + $LastSectionVirtually.VirtualSize

				$VirtualAddressOfPatchCode = [UInt32] (Get-MultipleOfPowerOfTwoAwayFromZero $VirtualAddressOfEndOfLastSection $SectionAlignment)
				$VirtualSizeOfPatchCode = [UInt32] (Get-MultipleOfPowerOfTwoAwayFromZero 16KB $SectionAlignment)
				$VirtualAddressOfPatchData = [UInt32] ($VirtualAddressOfPatchCode + $VirtualSizeOfPatchCode)
				$VirtualSizeOfPatchData = [UInt32] (Get-MultipleOfPowerOfTwoAwayFromZero 256KB $SectionAlignment)

				$RawDataOffsetOfPatchCode = [UInt32] (Get-MultipleOfPowerOfTwoAwayFromZero $File.Length $SectionAlignment)
				$RawDataSizeOfPatchCode = $VirtualSizeOfPatchCode
				$RawDataOffsetOfPatchData = [UInt32] ($RawDataOffsetOfPatchCode + $RawDataSizeOfPatchCode)
				$RawDataSizeOfPatchData = 16KB

				$IMAGE_SCN_CNT_CODE = [UInt32] 0x20
				$IMAGE_SCN_CNT_INITIALIZED_DATA = [UInt32] 0x40
				$IMAGE_SCN_MEM_EXECUTE = [UInt32] 0x020000000
				$IMAGE_SCN_MEM_READ = [UInt32] 0x040000000
				$IMAGE_SCN_MEM_WRITE = [UInt32] 1 -shl 31

				$PatchCodeSection = [Byte[]] @(
					$UTF8.GetBytes('RecetMod'),
					(LittleEndian $VirtualSizeOfPatchCode),
					(LittleEndian $VirtualAddressOfPatchCode),
					(LittleEndian $RawDataSizeOfPatchCode),
					(LittleEndian $RawDataOffsetOfPatchCode),
					(LittleEndian ([UInt32] 0)),
					(LittleEndian ([UInt32] 0)),
					(LittleEndian ([UInt16] 0)),
					(LittleEndian ([UInt16] 0)),
					(LittleEndian ([UInt32] ($IMAGE_SCN_CNT_CODE -bor $IMAGE_SCN_MEM_EXECUTE -bor $IMAGE_SCN_MEM_READ)))
				).ForEach{$_}

				$PatchDataSection = [Byte[]] @(
					$UTF8.GetBytes("TearMod`0"),
					(LittleEndian $VirtualSizeOfPatchData),
					(LittleEndian $VirtualAddressOfPatchData),
					(LittleEndian $RawDataSizeOfPatchData),
					(LittleEndian $RawDataOffsetOfPatchData),
					(LittleEndian ([UInt32] 0)),
					(LittleEndian ([UInt32] 0)),
					(LittleEndian ([UInt16] 0)),
					(LittleEndian ([UInt16] 0)),
					(LittleEndian ([UInt32] ($IMAGE_SCN_CNT_INITIALIZED_DATA -bor $IMAGE_SCN_MEM_WRITE -bor $IMAGE_SCN_MEM_READ)))
				).ForEach{$_}

				$UnroundedPatchedSizeOfHeaders = [UInt32] ($SectionTableOffset + 40 * $PatchedSectionCount)

				$PatchedSectionCount = [UInt16] ($SectionCount + 2)
				$PatchedSizeOfCode = [UInt32] ($SizeOfCode + $VirtualSizeOfPatchCode)
				$PatchedSizeOfInitialisedData = [UInt32] ($SizeOfInitialisedData + $VirtualSizeOfPatchData)
				$PatchedSizeOfImage = [UInt32] (
					Get-MultipleOfPowerOfTwoAwayFromZero ($VirtualAddressOfPatchData + $VirtualSizeOfPatchData) $SectionAlignment
				)
				$PatchedSizeOfHeaders = [UInt32] (
					Get-MultipleOfPowerOfTwoAwayFromZero ($SectionTableOffset + 40 * $PatchedSectionCount) $FileAlignment
				)

				$FillerBytesNeededBeforeFirstPatchSectionCount = $RawDataOffsetOfPatchCode - $File.Length

				function Find-Section ([ScriptBlock] $Predicate)
				{
					for ($Index = 0; $Index -lt $SectionCount; ++$Index)
					{
						$Section = $Sections[$Index]

						if (& $Predicate $Section)
						{
							return $Section
						}
					}
				}

				function Get-MultipleOffsets ($Of, $From = [UInt64] 0, $Limit = [UInt32]::MaxValue)
				{
					$Needle = $Latin1.GetString($Of)
					$Counter = 0

					for (
						$Index = $From;
						$Counter -lt $Limit -and ($Offset = $Bytes.IndexOf($Needle, $Index, [StringComparison]::OrdinalIgnoreCase)) -ne -1;
						$Index = $Offset + $Of.Length
					)
					{
						++$Counter
						$Offset
					}
				}

				function FileOffsetOf ($Data, $From = 0)
				{
					$Offsets = Get-MultipleOffsets -Of $Data -From $From -Limit 2

					if ($Offsets.Count -gt 1)
					{
						Write-Error -ErrorAction Continue "Only one instance of the bytes `"$($Data.ForEach{$_.ToString('X02')} -join ' ')`" were expected, but at-least two instances are present. Resultingly, the applied patch may be invalid."

						return $Offsets[0]
					}

					if ($Offsets.Count -eq 0)
					{
						return -1
					}

					$Offsets
				}

				$AddressOf = $Version.Addresses
				$OffsetFor = $Version.Offsets

				$FrameTimeMultiplierOffset = FileOffsetOf (hex '8d 04 40 8b c8 8d 04 76 2b c1')

				if ($FrameTimeMultiplierOffset -eq -1)
				{
					throw [FancyScreenPatchForRecettearFailedToFindCodeException]::new('The framerate-limiting code could not be found.', [PSCustomObject] @{CodeID = 'FramerateLimiter'})
				}

				$SectionOfGameCode = Find-Section `
				{
					Param ($S)
					     $S.RawDataOffset -le $FrameTimeMultiplierOffset `
					-and $S.RawDataOffset + $S.RawDataSize -gt $FrameTimeMultiplierOffset
				}

				if ($Null -eq $SectionOfGameCode)
				{
					throw [FancyScreenPatchForRecettearFailedToFindSectionException]::new('The game''s executable''s code section could not found. (???) ¯\_(ツ)_/¯', [PSCustomObject] @{SectionID = 'Code'})
				}


				function SpecificAddress ([UInt32] $Address)
				{
					[UInt32] ($Address + $Version.DefaultOffset)
				}


				function FileOffsetToVirtualAddress ([Int32] $Offset)
				{
					[UInt32] ($SectionOfGameCode.VirtualAddress + ($Offset - $SectionOfGameCode.RawDataOffset))
				}

				function VirtualAddressToFileOffset ([UInt32] $Address)
				{
					foreach ($Section in $Sections)
					{
						if ($Address -ge $Section.VirtualAddress -and $Address -lt $Section.VirtualAddress + $Section.VirtualSize)
						{
							return [UInt32] ($Section.RawDataOffset + ($Address - $Section.VirtualAddress))
						}
					}
				}

				function FileOffsetOfCalledFunction ($Code, $CodeOffset, $CallOffset)
				{
					$CodeOffset + $CallOffset + 5 + [BitConverter]::ToInt32((LittleEndian $Code ($CallOffset + 1) 4), 0)
				}

				function Read-IntJumpDisplacement ($Code, $JumpOffset)
				{
					5 + [BitConverter]::ToInt32((LittleEndian $Code ($JumpOffset + 1) 4), 0)
				}

				function Apply-IntJumpDisplacement ($Code, $CodeOffset, $JumpOffset)
				{
					$CodeOffset + $JumpOffset + (Read-IntJumpDisplacement $Code ($CodeOffset + $JumpOffset))
				}

				function DestinationOfJump ($Code, $CodeOffset, $JumpOffset)
				{
					Apply-IntJumpDisplacement $Code $CodeOffset $JumpOffset
				}


				${@HandleFrame} = [UInt32] $FrameTimeMultiplierOffset - 30
				${&HandleFrame} = FileOffsetToVirtualAddress ${@HandleFrame}

				if ($Version -eq $KnownVersions.EnglishV1_108)
				{
					$HandleFrameEnd = [UInt32] $FrameTimeMultiplierOffset + 259
					$HandleFramePostPresentFrameOffset = 0
				}
				elseif ($Version -eq $KnownVersions.JapaneseV1_126)
				{
					$HandleFrameEnd = [UInt32] $FrameTimeMultiplierOffset + 273
					$HandleFramePostPresentFrameOffset = 14
				}

				${#HandleFrame} = $HandleFrameEnd - ${@HandleFrame}

				$OriginalHandleFrame = [Byte[]]::new(${#HandleFrame})
				$File.Position = ${@HandleFrame}
				$File.Read($OriginalHandleFrame, 0, $OriginalHandleFrame.Length) > $Null

				$PresentFrameOffset = FileOffsetOfCalledFunction $OriginalHandleFrame ${@HandleFrame} 190

				$IncrementStateSharedBetweenGameFrameAndPresentationFrameCall = [Byte[]]::new(5)
				$IncrementStateSharedBetweenGameFrameAndPresentationFrameCallOffset = $PresentFrameOffset + 16
				${&IncrementStateSharedBetweenGameFrameAndPresentationFrameCall} = FileOffsetToVirtualAddress $IncrementStateSharedBetweenGameFrameAndPresentationFrameCallOffset
				$File.Position = $IncrementStateSharedBetweenGameFrameAndPresentationFrameCallOffset
				$File.Read(
					$IncrementStateSharedBetweenGameFrameAndPresentationFrameCall,
					0,
					$IncrementStateSharedBetweenGameFrameAndPresentationFrameCall.Length
				) > $Null

				${@IncrementStateSharedBetweenGameFrameAndPresentationFrame} = (
					FileOffsetOfCalledFunction `
						$IncrementStateSharedBetweenGameFrameAndPresentationFrameCall `
						$IncrementStateSharedBetweenGameFrameAndPresentationFrameCallOffset `
						0
				)

				${&IncrementStateSharedBetweenGameFrameAndPresentationFrame} = FileOffsetToVirtualAddress ${@IncrementStateSharedBetweenGameFrameAndPresentationFrame}

				#addr${@PauseTransitionEffectConditional} = [UInt32] (FileOffsetOf (hex '39 35 a0 99 a4 06 75 13'))
				#addr${&PauseTransitionEffectConditional} = FileOffsetToVirtualAddress ${@PauseTransitionEffectConditional}
				${&PauseTransitionEffectConditional} = $AddressOf.PauseTransitionEffectConditional
				${@PauseTransitionEffectConditional} = VirtualAddressToFileOffset ${&PauseTransitionEffectConditional}
				${@AfterPauseTransitionEffectConditional} = ${@PauseTransitionEffectConditional} + 50
				${&AfterPauseTransitionEffectConditional} = ${&PauseTransitionEffectConditional} + 50

				#addr${@CameraSmoothingReset} = [UInt32] (FileOffsetOf (hex 'd9 85 00 ff ff ff 89 35 68 cc 38 04 d9 1d 38 cc 38 04'))
				#addr${&CameraSmoothingReset} = FileOffsetToVirtualAddress ${@CameraSmoothingReset}
				${&CameraSmoothingReset} = $AddressOf.CameraSmoothingReset
				${@CameraSmoothingReset} = VirtualAddressToFileOffset ${&CameraSmoothingReset}

				$CameraPositionCount = 6

				${&CameraPositions[]} = [UInt32[]] @(
					$AddressOf.'CameraPositions[0]',
					$AddressOf.'CameraPositions[1]',
					$AddressOf.'CameraPositions[2]',
					$AddressOf.'CameraPositions[3]',
					$AddressOf.'CameraPositions[4]',
					$AddressOf.'CameraPositions[5]'
				)

				$CameraPositionStackOffsets = @(
					-256,
					-252,
					-248,
					-244,
					-240,
					-236
				)

				${&CameraHeight} = $AddressOf.CameraHeight

				$CameraHeightStackOffset = -4

				${&ShouldInitialiseCameraPositions} = $AddressOf.ShouldInitialiseCameraPositions

				${@CameraSmoothingHijack} = ${@CameraSmoothingReset} + 251
				${&CameraSmoothingHijack} = ${&CameraSmoothingReset} + 251
				${&PostCameraSmoothingHijack} = ${&CameraSmoothingHijack} + 6
				${@CameraInterpolationHijack} = ${@CameraSmoothingReset} - 8
				${&CameraInterpolationHijack} = ${&CameraSmoothingReset} - 8
				${&PostCameraInterpolationHijack} = ${&CameraInterpolationHijack} + 6
				${@CameraHeightSmoothingHijack} = ${@CameraSmoothingReset} - 893
				${&CameraHeightSmoothingHijack} = ${&CameraSmoothingReset} - 893
				${@PostCameraHeightSmoothingHijack} = ${@CameraHeightSmoothingHijack} + 49
				${&PostCameraHeightSmoothingHijack} = ${&CameraHeightSmoothingHijack} + 49

				${&CameraShakeConditional} = $AddressOf.CameraShakeConditional
				${@CameraShakeConditional} = VirtualAddressToFileOffset ${&CameraShakeConditional}
				${@AfterCameraShakeConditional} = ${@CameraShakeConditional} + 156
				${&AfterCameraShakeConditional} = ${&CameraShakeConditional} + 156

				${&ProjectilePositionResetHijack} = $AddressOf.ProjectilePositionResetHijack
				${@ProjectilePositionResetHijack} = VirtualAddressToFileOffset ${&ProjectilePositionResetHijack}

				${&MovementParticlePositionResetHijack} = $AddressOf.MovementParticlePositionResetHijack
				${@MovementParticlePositionResetHijack} = VirtualAddressToFileOffset ${&MovementParticlePositionResetHijack}

				${&XPGemPositionResetHijack} = $AddressOf.XPGemPositionResetHijack
				${@XPGemPositionResetHijack} = VirtualAddressToFileOffset ${&XPGemPositionResetHijack}

				${&MobPositionResetHijack} = $AddressOf.MobPositionResetHijack
				${@MobPositionResetHijack} = VirtualAddressToFileOffset ${&MobPositionResetHijack}

				#${@AllEncompassingPositionResetHijack} = [UInt32] (FileOffsetOf (hex '55 8b ec 83 ec 7c a1 e0 b1 38 04'))
				#${&AllEncompassingPositionResetHijack} = FileOffsetToVirtualAddress ${@AllEncompassingPositionResetHijack}
				${&AllEncompassingPositionResetHijack} = $AddressOf.AllEncompassingPositionResetHijack
				${@AllEncompassingPositionResetHijack} = VirtualAddressToFileOffset ${&AllEncompassingPositionResetHijack}

				${&ChestTeleporationPositionResetHijack} = $AddressOf.ChestTeleporationPositionResetHijack
				${@ChestTeleporationPositionResetHijack} = VirtualAddressToFileOffset ${&ChestTeleporationPositionResetHijack}

				${&NagiEncounterRNGOverrideHijack} = $AddressOf.NagiEncounterRNGOverrideHijack
				${@NagiEncounterRNGOverrideHijack} = VirtualAddressToFileOffset ${&NagiEncounterRNGOverrideHijack}

				$Nops = [Byte[][]] @(
					@(),
					@(0x90),
					@(0x66, 0x90),
					@(0x0F, 0x1F, 0x00),
					@(0x0F, 0x1F, 0x40, 0x00),
					@(0x0F, 0x1F, 0x44, 0x00, 0x00),
					@(0x66, 0x0F, 0x1F, 0x44, 0x00, 0x00),
					@(0x0F, 0x1F, 0x80, 0x00, 0x00, 0x00, 0x00),
					@(0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00),
					@(0x66, 0x0F, 0x1F, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00)
				)

				function Get-Nop ($Length)
				{
					$Nops[$Length]
				}

				function Get-Nops ($Length)
				{
					for (; $Length -ge 9; $Length -= 9)
					{
						$Nops[9]
					}

					if ($Length -gt 0)
					{
						$Nops[$Length]
					}
				}

				function ModRM ([Byte] $Mod, [Byte] $R, [Byte] $M)
				{
					[Byte] (($Mod -shl 6) -bor ($R -shl 3) -bor $M)
				}

				function SIB ([Byte] $Scale, [Byte] $Index, [Byte] $Base)
				{
					[Byte] (($Scale -shl 6) -bor ($Index -shl 3) -bor $Base)
				}

				function VirtualAddressOfCalledFunction ($Code, $CodeOffset, $CallOffset)
				{
					FileOffsetToVirtualAddress (FileOffsetOfCalledFunction $Code $CodeOffset $CallOffset)
				}

				function DisplacementFrom ($From, $To)
				{
					[Int32] $To - [Int32] $From
				}

				New-Alias -Name Displace -Value DisplacementFrom

				function DisplacementForJump ($FunctionOffset, $CodeOffset, $CallOffset)
				{
					DisplacementFrom (FileOffsetToVirtualAddress ($CodeOffset + $CallOffset + 5)) -To $FunctionOffset
				}

				function Reserve ([UInt32] $ByteCount, [ScriptBlock] $For)
				{
					[ValueTuple[UInt32, Object]]::new($ByteCount, $For)
				}


				$Preassemblies = [Collections.Generic.List[PSCustomObject]]::new()
				$AssemblyIDs = [Collections.Generic.List[String]]::new()
				$Script:LastAutomaticallyPositionedAssemblyID = $Null
				$LabelRegEx = '[A-Za-z0-9_\[\]\?]+'
				$LabelDefinitionRegEx = [RegEx]::new("^($LabelRegEx):(?:(?<DataLength>[0-9]+)?(?::\((?<TypeHint>[^\)]+)\))?|\+(?<LabelToCopy>$LabelRegEx))$", [Text.RegularExpressions.RegexOptions]::Compiled)
				$LabelReferenceRegEx = [RegEx]::new("^&($LabelRegEx)$", [Text.RegularExpressions.RegexOptions]::Compiled)
				$LabelDisplacementRegEx = [RegEx]::new("^([0-9]+):($LabelRegEx)(?:/($LabelRegEx))?(?:\s*([\+\-])\s*(-?[0-9]+))?$", [Text.RegularExpressions.RegexOptions]::Compiled)


				class Call
				{
					static SetNewVariable ($Name, $Value)
					{
						$Existing = $Global:ExecutionContext.SessionState.PSVariable.Get($Name)

						if ($Script:ExtendedDebug -and $Null -ne $Existing -and -not [Object]::Equals($Existing.Value, $Value))
						{
							Write-Error "A variable named '$Name' already exists."

							return
						}

						$Global:ExecutionContext.SessionState.PSVariable.Set("Script:$Name", $Value)
					}

					static NewLabel ($Identifier, [UInt32] $VirtuallyFrom, $PhysicallyFrom)
					{
						[Call]::NewLabel($Identifier, $VirtuallyFrom, $PhysicallyFrom, $Null, $Null)
					}

					static NewLabel ($Identifier, [UInt32] $VirtuallyFrom, $PhysicallyFrom, $Length)
					{
						[Call]::NewLabel($Identifier, $VirtuallyFrom, $PhysicallyFrom, $Length, $Null)
					}

					static NewLabel ($Identifier, [UInt32] $VirtuallyFrom, $PhysicallyFrom, $Length, $TypeHint)
					{
						[Call]::SetNewVariable("&$Identifier", $VirtuallyFrom)

						if ($Null -ne $PhysicallyFrom)
						{
							$PhysicallyFrom = [UInt32] $PhysicallyFrom
							[Call]::SetNewVariable("@$Identifier", $PhysicallyFrom)
						}

						if ($Null -ne $Length)
						{
							$LengthValue = [UInt32] $Length
							[Call]::SetNewVariable("&$Identifier$", ($VirtuallyFrom + $LengthValue))
							[Call]::SetNewVariable("@$Identifier$", ([UInt32] $PhysicallyFrom + $LengthValue))
							[Call]::SetNewVariable("#$Identifier", $LengthValue)
						}

						if ($Null -ne $TypeHint)
						{
							[Call]::SetNewVariable("typeof($Identifier)", $TypeHint)
						}
					}

					static [Object[]] NewInterpolatedFloat ($Name)
					{
						return @(
							"$($Name)Interpolation:12"
							"Actual$($Name):+$Name"
							"Held$($Name):4:(float)", (LE 0)
							"$($Name)Delta:4:(float)", (LE 0)
							"$($Name)Target:4:(float)", (LE 0)
						)
					}
				}


				function Preassemble ([String] $Name, $VirtuallyFrom, $PhysicallyFrom, $Code)
				{
					$Index = [UInt32] 0

					if ($VirtuallyFrom -is [Array] -and $Null -eq $PhysicallyFrom)
					{
						$Code = $VirtuallyFrom
						$VirtuallyFrom = [UInt32] (Get-MultipleOfPowerOfTwoAwayFromZero $Variables.GetValue("&$Script:LastAutomaticallyPositionedAssemblyID`$") 4)
						$PhysicallyFrom = [UInt32] (Get-MultipleOfPowerOfTwoAwayFromZero $Variables.GetValue("@$Script:LastAutomaticallyPositionedAssemblyID`$") 4)
						$Script:LastAutomaticallyPositionedAssemblyID = $Name
					}

					if ($Verbose)
					{
						Write-Verbose "Preassembling $Name at: &$($VirtuallyFrom.ToString('x08')) | @$($PhysicallyFrom.ToString('x08'))"
					}

					$Preassembly = [PSCustomObject] @{
						Code = $Null
						VirtualAddress = $VirtuallyFrom
						PhysicalOffset = $PhysicallyFrom
						DefinedLabels = [Collections.Generic.List[String]]::new()
						UnresolvedReservations = [Collections.Generic.List[ValueTuple[UInt32, ValueTuple[UInt32, Object]]]]::new()
					}

					$Preassembly.Code = [Byte[]] $Code.ForEach{
						if ($_ -is [String])
						{
							if ($_ -cmatch $LabelDefinitionRegEx)
							{
								$LabelToCopy = $Matches.LabelToCopy

								if ($Null -ne $LabelToCopy)
								{
									[Call]::NewLabel(
										$Matches[1],
										$Variables.GetValue("&$LabelToCopy"),
										$Variables.GetValue("@$LabelToCopy"),
										$Variables.GetValue("#$LabelToCopy"),
										$Variables.GetValue("typeof($LabelToCopy)")
									)
								}
								else
								{
									[Call]::NewLabel(
										$Matches[1],
										($VirtuallyFrom + $Index),
										($PhysicallyFrom + $Index),
										$Matches.DataLength,
										$Matches.TypeHint
									)
								}

								$Preassembly.DefinedLabels.Add($Matches[1])
							}
							elseif ($_ -cmatch $LabelReferenceRegEx)
							{
								$Address = $Variables.GetValue("&$($Matches[1])")
								[Byte[]] @(($Address -band 0xFF), (($Address -shr 8) -band 0xFF), (($Address -shr 16) -band 0xFF), (($Address -shr 24) -band 0xFF))
								$Index += 4
							}
							elseif ($_ -cmatch $LabelDisplacementRegEx)
							{
								$Size = [UInt32] $Matches[1]

								if ($Null -ne $Matches[3])
								{
									$Base = $Matches[2]
									$Target = $Matches[3]
								}
								else
								{
									$Base = '$'
									$Target = $Matches[2]
								}

								if ($Null -ne $Matches[4])
								{
									$Adjustment = " $($Matches[4]) $($Matches[5])"
								}
								else
								{
									$Adjustment = [String]::Empty
								}

								$Preassembly.UnresolvedReservations.Add(
									[ValueTuple[UInt32, ValueTuple[UInt32, Object]]]::new(
										$Index,
										[ValueTuple[UInt32, Object]]::new(
											$Size,
											"LE ([$($IntTypes[$Size])] (Displace `${&$Base} -To (`${&$Target}$Adjustment)))"
										)
									)
								)
								[Byte[]]::new($Size)
								$Index += $Size
							}
							else
							{
								Write-Error "Unexpected label ``$_`` at the offset: $Index."
							}
						}
						elseif ($_ -is [ValueTuple[UInt32, Object]])
						{
							$Preassembly.UnresolvedReservations.Add([ValueTuple[UInt32, ValueTuple[UInt32, Object]]]::new($Index, $_))
							[Byte[]]::new($_.Item1)
							$Index += $_.Item1
						}
						else
						{
							if ($_ -is [ScriptBlock])
							{
								$Offset = $Index
								${&} = $VirtuallyFrom + $Offset
								${@} = $PhysicallyFrom + $Offset
								$Bytes = [Byte[]] (& $_).ForEach([Byte])
							}
							else
							{
								$Bytes = [Byte[]] $_.ForEach([Byte])
							}

							$Bytes
							$Index += $Bytes.Length
						}
					}

					[Call]::SetNewVariable($Name, $Preassembly)
					[Call]::NewLabel($Name, $VirtuallyFrom, $PhysicallyFrom, $Preassembly.Code.Length)
					[Call]::SetNewVariable("*$Name", $Preassembly.Code)
					[Call]::SetNewVariable("$Name.DefinedLabels", $Preassembly.DefinedLabels)

					$AssemblyIDs.Add($Name)
					$Preassemblies.Add($Preassembly)
				}

				function Resolve-Assembly
				{
					foreach ($Preassembly in $Preassemblies)
					{
						foreach ($Reservation in $Preassembly.UnresolvedReservations)
						{
							$Offset = $Reservation.Item1
							${&} = $Preassembly.VirtualAddress + $Offset
							${&$} = ${&} + $Reservation.Item2.Item1
							${@} = $Preassembly.PhysicalOffset + $Offset
							${@$} = ${@} + $Reservation.Item2.Item1
							$Bytes = [Byte[]] ($Reservation.Item2.Item2 | Invoke-Expression).ForEach{$_}

							if ($Bytes.Length -ne $Reservation.Item2.Item1)
							{
								throw [FancyScreenPatchForRecettearBugException]::new(
									"A length of $($Reservation.Item2.Item1) byte(s) was expected from $($Reservation.Item2.Item2).",
									[PSCustomObject] @{Bug = 'WrongByteCountForReservationInPreassembly'; ExpectedByteCount = $Reservation.Item2.Item1; ActualByteCount = $Bytes.Length}
								)
							}

							$Bytes.CopyTo($Preassembly.Code, $Reservation.Item1)
						}

						$Preassembly.UnresolvedReservations.Clear()
					}
				}

				function Hijack ([String] $Name, [String] $Target, [UInt32] $Offset, [UInt32] $Length, $Code)
				{
					$VirtuallyFrom = $Variables.GetValue("&$Target")
					$PhysicallyFrom = $Variables.GetValue("@$Target")

					if ($Verbose)
					{
						Write-Verbose "Hijacking $Target as $Name at: &$($VirtuallyFrom.ToString('x08')) + $Offset (&$(($VirtuallyFrom + $Offset).ToString('x08'))) | @$($PhysicallyFrom.ToString('x08')) + $Offset (&$(($PhysicallyFrom + $Offset).ToString('x08')))"
					}

					Preassemble "$($Name)_Hijack" ($VirtuallyFrom + $Offset) ($PhysicallyFrom + $Offset) @(
						0xE9, "4:$Name"          <# jmp $Name #>
						(Get-Nops ($Length - 5)) <# nop #>
					"Post_$($Name)_Hijack:"
					)

					Preassemble $Name @(
						$Code
						0xE9, "4:Post_$($Name)_Hijack" <# jmp Post_$($Name)_Hijack #>
					)
				}

				${&GetPerformanceCounter} = VirtualAddressOfCalledFunction $OriginalHandleFrame ${@HandleFrame} 12
				${&HandleInput} = VirtualAddressOfCalledFunction $OriginalHandleFrame ${@HandleFrame} 59
				${&ProcessGameFrameA} = VirtualAddressOfCalledFunction $OriginalHandleFrame ${@HandleFrame} 147
				${&ProcessGameFrameB} = VirtualAddressOfCalledFunction $OriginalHandleFrame ${@HandleFrame} 152
				${&PresentFrame} = VirtualAddressOfCalledFunction $OriginalHandleFrame ${@HandleFrame} 190
				if ($Version -eq $KnownVersions.JapaneseV1_126)
				{
					${&JapaneseSpecificPresentationRelatedFunction} = VirtualAddressOfCalledFunction $OriginalHandleFrame ${@HandleFrame} 210
				}
				${@PresentFrame} = VirtualAddressToFileOffset ${&PresentFrame}
				${&FPSLimitOption} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 1 4), 0)
				${&PreviousGameFrameTime} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 20 4), 0)
				${&CurrentGameFrameTime} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 26 4), 0)
				${&GameFrameTimeSpillover} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 42 4), 0)
				${&TimeElapsedSinceLastGameFrame} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 71 4), 0)
				${&UnknownA?} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 131 4), 0)
				${&UnknownB?} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 139 4), 0)
				${&Direct3D} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 170 4), 0)
				${&Direct3DDevice} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 179 4), 0)
				${&SomeCounter?} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame 197 4), 0)
				${#SomeCounter?} = [UInt32] 4
				${&SomeGuard?} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame (212 + $HandleFramePostPresentFrameOffset) 4), 0)
				${&InputDeviceState?} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame (223 + $HandleFramePostPresentFrameOffset) 4), 0)
				${&UnknownC?} = [BitConverter]::ToUInt32((LittleEndian $OriginalHandleFrame (231 + $HandleFramePostPresentFrameOffset) 4), 0)

				${@GetPerformanceCounter} = [UInt32] (VirtualAddressToFileOffset ${&GetPerformanceCounter})
				$GetPerformanceCounter = [Byte[]]::new(99)
				$File.Position = ${@GetPerformanceCounter}
				$File.Read($GetPerformanceCounter, 0, $GetPerformanceCounter.Length) > $Null

				${&QueryPerformanceFrequency} = [BitConverter]::ToUInt32((LittleEndian $GetPerformanceCounter 27 4), 0)
				${&QueryPerformanceCounter} = [BitConverter]::ToUInt32((LittleEndian $GetPerformanceCounter 37 4), 0)


				$CameraPositionLabels = for ($Index = 0; $Index -lt $CameraPositionCount; ++$Index)
				{
					$Name = "CameraPosition$Index"
					$Address = ${&CameraPositions[]}[$Index]
					[Call]::NewLabel($Name, $Address, (VirtualAddressToFileOffset $Address), 4, 'float')
					$Name
				}

				[Call]::NewLabel('SelectedSaveSlotIndex', $AddressOf.SelectedSaveSlotIndex, $Null, 4, 'float')
				[Call]::NewLabel('SelectedSaveSlotPulsatingEffectCounter', $AddressOf.SelectedSaveSlotPulsatingEffectCounter, $Null, 4, 'float')
				[Call]::NewLabel('CameraHeight', $AddressOf.CameraHeight, $Null, 4, 'float')
				[Call]::NewLabel('CameraShakeActualValue', $AddressOf.CameraShakeActualValue, $Null, 4, 'float')
				[Call]::NewLabel('CameraModifier0', $AddressOf.CameraModifier0, $Null, 4, 'float')
				[Call]::NewLabel('CameraModifier1', $AddressOf.CameraModifier1, $Null, 4, 'float')
				[Call]::NewLabel('ShouldInitialiseCameraPositions', $AddressOf.ShouldInitialiseCameraPositions, $Null, 4)
				[Call]::NewLabel('ThreadHandle', $AddressOf.ThreadHandle, $Null, 4)
				[Call]::NewLabel('ThreadGuardA_A', $AddressOf.ThreadGuardA_A, $Null, 4)
				[Call]::NewLabel('ThreadGuardA_B', $AddressOf.ThreadGuardA_B, $Null, 4)
				[Call]::NewLabel('ThreadGuardB_A', $AddressOf.ThreadGuardB_A, $Null, 4)
				[Call]::NewLabel('ThreadGuardB_B', $AddressOf.ThreadGuardB_B, $Null, 4)
				[Call]::NewLabel('ThreadGuardC_A', $AddressOf.ThreadGuardC_A, $Null, 4)
				[Call]::NewLabel('ThreadGuardD_A', $AddressOf.ThreadGuardD_A, $Null, 4)
				[Call]::NewLabel('GameIsPaused?', $AddressOf.'GameIsPaused?', $Null, 4)
				[Call]::NewLabel('GameStateA', $AddressOf.GameStateA, $Null, 4)
				[Call]::NewLabel('GameStateB', $AddressOf.GameStateB, $Null, 4)
				[Call]::NewLabel('GameStateC', $AddressOf.GameStateC, $Null, 4)
				[Call]::NewLabel('GameStateD', $AddressOf.GameStateD, $Null, 4)
				[Call]::NewLabel('GameStateE', $AddressOf.GameStateE, $Null, 4)
				[Call]::NewLabel('GameStateF', $AddressOf.GameStateF, $Null, 4)
				[Call]::NewLabel('GameStateG', $AddressOf.GameStateG, $Null, 4)
				[Call]::NewLabel('GameStateH', $AddressOf.GameStateH, $Null, 4)
				[Call]::NewLabel('GameStateI', $AddressOf.GameStateI, $Null, 4)
				[Call]::NewLabel('GameStateJ', $AddressOf.GameStateJ, $Null, 4)
				[Call]::NewLabel('GameStateK', $AddressOf.GameStateK, $Null, 4)
				[Call]::NewLabel('InAnEvent?', $AddressOf.'InAnEvent?', $Null, 4)
				[Call]::NewLabel('ShouldDisplayEndOfDaySummary', $AddressOf.ShouldDisplayEndOfDaySummary, $Null, 4)
				[Call]::NewLabel('ShouldDrawTheHUD', $AddressOf.ShouldDrawTheHUD, $Null, 4)
				[Call]::NewLabel('HUDSlideInPercentage', $AddressOf.HUDSlideInPercentage, $Null, 4, 'float')
				[Call]::NewLabel('LoadingDiscRotationAngle', $AddressOf.LoadingDiscRotationAngle, $Null, 4, 'float')
				[Call]::NewLabel('CurrentMapClockMessage', $AddressOf.CurrentMapClockMessage, $Null, 4)
				[Call]::NewLabel('WindowShopperPositionCount', $AddressOf.WindowShopperPositionCount, $Null, 4)
				[Call]::NewLabel('XPGemCount', $AddressOf.XPGemCount, $Null, 4)
				[Call]::NewLabel('MirrorImageCounter', $AddressOf.MirrorImageCounter, $Null, 4)
				[Call]::NewLabel('ShowItemInfoState', $AddressOf.ShowItemInfoState, $Null, 4)
				[Call]::NewLabel('ShopIsOpen', $AddressOf.ShopIsOpen, $Null, 4)
				[Call]::NewLabel('ShouldDrawSelectionHand', $AddressOf.ShouldDrawSelectionHand, $Null, 4)
				[Call]::NewLabel('ShouldDisplayFPSOSD', $AddressOf.ShouldDisplayFPSOSD, $Null, 4)
				[Call]::NewLabel('ShouldDoFrame?', $AddressOf.'ShouldDoFrame?', $Null, 4)

				[Call]::NewLabel('SelectionHandX', $AddressOf.SelectionHandX, $Null, 4, 'float')
				[Call]::NewLabel('SelectionHandY', $AddressOf.SelectionHandY, $Null, 4, 'float')

				[Call]::NewLabel('PauseTransitionEffectCounter', $AddressOf.PauseTransitionEffectCounter, $Null, 4)
				[Call]::NewLabel('LevelIntroductionCounter', $AddressOf.LevelIntroductionCounter, $Null, 4)
				[Call]::NewLabel('NewsTickerCounter', $AddressOf.NewsTickerCounter, $Null, 4)
				[Call]::NewLabel('ShopTillItemTransitionCounter', $AddressOf.ShopTillItemTransitionCounter, $Null, 4)
				[Call]::NewLabel('ShopTillEntryTransitionCounter', $AddressOf.ShopTillEntryTransitionCounter, $Null, 4)
				[Call]::NewLabel('ShopTillCustomerPosition', $AddressOf.ShopTillCustomerPosition, $Null, 4)
				[Call]::NewLabel('TearMenuTransitionCounter', $AddressOf.TearMenuTransitionCounter, $Null, 4)
				[Call]::NewLabel('TearLectureButtonTransitionCounter', $AddressOf.TearLectureButtonTransitionCounter, $Null, 4)
				[Call]::NewLabel('MenuPromptTransitionCounter', $AddressOf.MenuPromptTransitionCounter, $Null, 4)
				[Call]::NewLabel('FulfilOrderState', $AddressOf.FulfilOrderState, $Null, 4)
				[Call]::NewLabel('FulfilOrderSelectionHandState', $AddressOf.FulfilOrderSelectionHandState, $Null, 4)

				[Call]::NewLabel('GameWindowHWnd', $AddressOf.GameWindowHWnd, $Null, 4)
				[Call]::NewLabel('GameIsWindowed', $AddressOf.GameIsWindowed, $Null, 4, 'uint')
				[Call]::NewLabel('ShouldUseSavedWindowPosition', $AddressOf.ShouldUseSavedWindowPosition, $Null, 4, 'uint')
				[Call]::NewLabel('SavedWindowLeft', $AddressOf.SavedWindowLeft, $Null, 4, 'int')
				[Call]::NewLabel('SavedWindowTop', $AddressOf.SavedWindowTop, $Null, 4, 'int')
				[Call]::NewLabel('WindowAspectRatioIsFixed', $AddressOf.WindowAspectRatioIsFixed, $Null, 4, 'int')
				[Call]::NewLabel('ResolutionX', $AddressOf.ResolutionX, $Null, 4, 'uint')
				[Call]::NewLabel('ResolutionY', $AddressOf.ResolutionY, $Null, 4, 'uint')
				[Call]::NewLabel('PresentationParameters', $AddressOf.PresentationParameters, $Null)
				[Call]::NewLabel('PresentationParametersFullScreen_RefreshRateInHz', $AddressOf.PresentationParametersFullScreen_RefreshRateInHz, $Null, 4, 'uint')
				[Call]::NewLabel('PresentationParametersFullScreen_PresentationInterval', $AddressOf.PresentationParametersFullScreen_PresentationInterval, $Null, 4, 'uint')
				[Call]::NewLabel('AspectRatio', $AddressOf.AspectRatio, (VirtualAddressToFileOffset ($AddressOf.AspectRatio - $ImageBase)), 4, 'float')
				[Call]::NewLabel('_640f', $AddressOf._640f, (VirtualAddressToFileOffset ($AddressOf._640f - $ImageBase)), 4, 'float')
				[Call]::NewLabel('128f', $AddressOf.'128f', (VirtualAddressToFileOffset ($AddressOf.'128f' - $ImageBase)), 4, 'float')
				[Call]::NewLabel('128nf', $AddressOf.'128nf', (VirtualAddressToFileOffset ($AddressOf.'128nf' - $ImageBase)), 4, 'float')

				[Call]::NewLabel('BlackBarTexture', $AddressOf.BlackBarTexture, $Null, 4)

				[Call]::NewLabel('PauseMenuFreezeEffect', $AddressOf.PauseMenuFreezeEffect, (VirtualAddressToFileOffset $AddressOf.PauseMenuFreezeEffect), 1391, $Null)
				[Call]::NewLabel('FadeToFromBlackEffect', $AddressOf.FadeToFromBlackEffect, (VirtualAddressToFileOffset $AddressOf.FadeToFromBlackEffect), 444, $Null)
				[Call]::NewLabel('ShowNowLoadingMessage', $AddressOf.ShowNowLoadingMessage, (VirtualAddressToFileOffset $AddressOf.ShowNowLoadingMessage), 362, $Null)
				[Call]::NewLabel('HandleMainMenu', $AddressOf.HandleMainMenu, (VirtualAddressToFileOffset $AddressOf.HandleMainMenu), 3719, $Null)
				[Call]::NewLabel('DrawTheHUD', $AddressOf.DrawTheHUD, (VirtualAddressToFileOffset $AddressOf.DrawTheHUD), 7558, $Null)
				[Call]::NewLabel('DrawShopHUD', $AddressOf.DrawShopHUD, (VirtualAddressToFileOffset $AddressOf.DrawShopHUD), 3434, $Null)
				[Call]::NewLabel('DrawMerchantLevelNumber', $AddressOf.DrawMerchantLevelNumber, (VirtualAddressToFileOffset $AddressOf.DrawMerchantLevelNumber), 368, $Null)
				[Call]::NewLabel('DrawLevelIntroductionAndSomeHUD', $AddressOf.DrawLevelIntroductionAndSomeHUD, (VirtualAddressToFileOffset $AddressOf.DrawLevelIntroductionAndSomeHUD), 1445, $Null)
				[Call]::NewLabel('DrawHUDClockPix', $AddressOf.DrawHUDClockPix, (VirtualAddressToFileOffset $AddressOf.DrawHUDClockPix), 1445, $Null)
				[Call]::NewLabel('DrawTillUI', $AddressOf.DrawTillUI, (VirtualAddressToFileOffset $AddressOf.DrawTillUI), 2668, $Null)
				[Call]::NewLabel('DrawsCutsceneAndMore', $AddressOf.DrawsCutsceneAndMore, (VirtualAddressToFileOffset $AddressOf.DrawsCutsceneAndMore), 3800, $Null)
				[Call]::NewLabel('DrawBossAttackCameraEffect', $AddressOf.DrawBossAttackCameraEffect, (VirtualAddressToFileOffset $AddressOf.DrawBossAttackCameraEffect), 326, $Null)
				[Call]::NewLabel('DrawFPSOSD', $AddressOf.DrawFPSOSD, (VirtualAddressToFileOffset $AddressOf.DrawFPSOSD), 326, $Null)
				[Call]::NewLabel('DrawCombatHUD', $AddressOf.DrawCombatHUD, (VirtualAddressToFileOffset $AddressOf.DrawCombatHUD), 7289, $Null)
				[Call]::NewLabel('DrawLootedLoot', $AddressOf.DrawLootedLoot, (VirtualAddressToFileOffset $AddressOf.DrawLootedLoot), 799, $Null)
				[Call]::NewLabel('DrawAdventurerHUD', $AddressOf.DrawAdventurerHUD, (VirtualAddressToFileOffset $AddressOf.DrawAdventurerHUD), 1983, $Null)
				[Call]::NewLabel('DrawHagglingUI', $AddressOf.DrawHagglingUI, (VirtualAddressToFileOffset $AddressOf.DrawHagglingUI), 5305, $Null)
				[Call]::NewLabel('DrawMenu', $AddressOf.DrawMenu, (VirtualAddressToFileOffset $AddressOf.DrawMenu), 3657, $Null)
				[Call]::NewLabel('DrawSkipEventPrompt', $AddressOf.DrawSkipEventPrompt, (VirtualAddressToFileOffset $AddressOf.DrawSkipEventPrompt), 660, $Null)
				[Call]::NewLabel('DrawSelectionHand', $AddressOf.DrawSelectionHand, (VirtualAddressToFileOffset $AddressOf.DrawSelectionHand), 300, $Null)
				[Call]::NewLabel('DrawEncyclopediaItems', $AddressOf.DrawEncyclopediaItems, (VirtualAddressToFileOffset $AddressOf.DrawEncyclopediaItems), 2033, $Null)
				[Call]::NewLabel('DrawSaveSlots', $AddressOf.DrawSaveSlots, (VirtualAddressToFileOffset $AddressOf.DrawSaveSlots), 2810, $Null)
				[Call]::NewLabel('SomeShopRelatedGameLogic', $AddressOf.SomeShopRelatedGameLogic, (VirtualAddressToFileOffset $AddressOf.SomeShopRelatedGameLogic), 5618, $Null)
				[Call]::NewLabel('SetSomeMobData', $AddressOf.SetSomeMobData, (VirtualAddressToFileOffset $AddressOf.SetSomeMobData), 3025, $Null)
				[Call]::NewLabel('DrawWorld', $AddressOf.DrawWorld, (VirtualAddressToFileOffset $AddressOf.DrawWorld), 5323, $Null)
				[Call]::NewLabel('DrawFlora', $AddressOf.DrawFlora, (VirtualAddressToFileOffset $AddressOf.DrawFlora), 1462, $Null)
				[Call]::NewLabel('ReallyBigPresentationFunction', $AddressOf.ReallyBigPresentationFunction, (VirtualAddressToFileOffset $AddressOf.ReallyBigPresentationFunction), 30395, $Null)
				[Call]::NewLabel('SomeRenderingFunction', $AddressOf.SomeRenderingFunction, (VirtualAddressToFileOffset $AddressOf.SomeRenderingFunction), 5210, $Null)
				[Call]::NewLabel('MoreMobRelatedRendering', $AddressOf.MoreMobRelatedRendering, (VirtualAddressToFileOffset $AddressOf.MoreMobRelatedRendering), 1982, $Null)
				[Call]::NewLabel('DrawShadows', $AddressOf.DrawShadows, (VirtualAddressToFileOffset $AddressOf.DrawShadows), 4493, $Null)
				[Call]::NewLabel('DimScreenForDungeonCrawlingSaveWarning', $AddressOf.DimScreenForDungeonCrawlingSaveWarning, (VirtualAddressToFileOffset $AddressOf.DimScreenForDungeonCrawlingSaveWarning), 5, $Null)
				[Call]::NewLabel('DrawEnqueuedTextures', $AddressOf.DrawEnqueuedTextures, (VirtualAddressToFileOffset $AddressOf.DrawEnqueuedTextures), 76, $Null)
				[Call]::NewLabel('SomeShopRelatedRendering', $AddressOf.SomeShopRelatedRendering, (VirtualAddressToFileOffset $AddressOf.SomeShopRelatedRendering), 1906, $Null)
				[Call]::NewLabel('WindowProcedure', $AddressOf.WindowProcedure, (VirtualAddressToFileOffset $AddressOf.WindowProcedure), 1059, $Null)
				[Call]::NewLabel('WindowCreation', $AddressOf.WindowCreation, (VirtualAddressToFileOffset $AddressOf.WindowCreation), 402, $Null)
				[Call]::NewLabel('Direct3DDeviceCreation', $AddressOf.Direct3DDeviceCreation, (VirtualAddressToFileOffset $AddressOf.Direct3DDeviceCreation), 507, $Null)
				[Call]::NewLabel('ReadConfig', $AddressOf.ReadConfig, (VirtualAddressToFileOffset $AddressOf.ReadConfig), 912, $Null)

				[Call]::NewLabel('PlayerCharacterPossePositionResetHijack', $AddressOf.PlayerCharacterPossePositionResetHijack, (VirtualAddressToFileOffset $AddressOf.PlayerCharacterPossePositionResetHijack), 6, $Null)
				[Call]::NewLabel('ArrowProjectilePositionResetHijack', $AddressOf.ArrowProjectilePositionResetHijack, (VirtualAddressToFileOffset $AddressOf.ArrowProjectilePositionResetHijack), 6, $Null)
				[Call]::NewLabel('ShopperPositionResetHijack', $AddressOf.ShopperPositionResetHijack, (VirtualAddressToFileOffset $AddressOf.ShopperPositionResetHijack), 6, $Null)

				[Call]::NewLabel('GetModuleHandleA', $AddressOf.GetModuleHandleA, (VirtualAddressToFileOffset $AddressOf.GetModuleHandleA), 4, $Null)
				[Call]::NewLabel('GetProcAddress', $AddressOf.GetProcAddress, (VirtualAddressToFileOffset $AddressOf.GetProcAddress), 4, $Null)
				[Call]::NewLabel('GetClientRect', $AddressOf.GetClientRect, (VirtualAddressToFileOffset $AddressOf.GetClientRect), 4, $Null)
				[Call]::NewLabel('MoveWindow', $AddressOf.MoveWindow, (VirtualAddressToFileOffset $AddressOf.MoveWindow), 4, $Null)
				[Call]::NewLabel('GetWindowRect', $AddressOf.GetWindowRect, (VirtualAddressToFileOffset $AddressOf.GetWindowRect), 4, $Null)
				[Call]::NewLabel('AdjustWindowRect', $AddressOf.AdjustWindowRect, (VirtualAddressToFileOffset $AddressOf.AdjustWindowRect), 4, $Null)


				foreach ($ConfigurableTextureFiltering in $ConfigurableTextureFilterings)
				{
					if ($ConfigurableTextureFiltering.VirtualAddressSource -is [String])
					{
						$ConfigurableTextureFiltering.VirtualAddress = $AddressOf[$ConfigurableTextureFiltering.VirtualAddressSource]
					}
				}


				${@IncrementSelectedSaveSlotPulsatingEffectCounter} = [UInt32] (FileOffsetOf ([Byte[]] @(0xFF, (ModRM 0 0 5), (LE ${&SelectedSaveSlotPulsatingEffectCounter})).ForEach{$_}))
				${&IncrementSelectedSaveSlotPulsatingEffectCounter} = FileOffsetToVirtualAddress ${@IncrementSelectedSaveSlotPulsatingEffectCounter}


				$IntegersToMirrorAsFloats = @(
					@{Name = 'ShopTillEntryTransitionFloatMirror'; VirtualAddress = ${&ShopTillEntryTransitionCounter}}
					@{Name = 'ShopTillCustomerPositionFloatMirror'; VirtualAddress = ${&ShopTillCustomerPosition}}
					@{Name = 'TearMenuTransitionCounterFloatMirror'; VirtualAddress = ${&TearMenuTransitionCounter}}
					@{Name = 'TearLectureButtonTransitionCounterFloatMirror'; VirtualAddress = ${&TearLectureButtonTransitionCounter}}
				)


				$HUDSlideInPercentageMaximumDelta = 0.11
				$DoNotInterpolateFloatNaNValue = [UInt32] 0x7fc00002
				#$OnePixelWidthLeft = 1 / $GameBaseWidth
				#$TwoPixelWidthLeft = 2 / $GameBaseWidth
				#$OnePixelWidthRight = ($GameBaseWidth - 1) / $GameBaseWidth
				#$TwoPixelWidthRight = ($GameBaseWidth - 2) / $GameBaseWidth

				$OnePixelWidthLeft = 1
				$TwoPixelWidthLeft = 2
				$OnePixelWidthRight = $GameBaseWidth - 1
				$TwoPixelWidthRight = $GameBaseWidth - 2


				Preassemble 'PatchData' ($ImageBase + $VirtualAddressOfPatchData) $RawDataOffsetOfPatchData @(
				'MagicHeader:16:(char[16])', $UTF8.GetBytes('FancyScreenPatch')
				'HeaderVersion:4', (LittleEndian 1)
				'HeaderReservedSpace:44', ([Byte[]]::new(44))

				'PresentationFrameTiming:'
				'PresentationFrameTime:4', (LE 0)
				'PresentationFrameTimeIntegralPart:4', (LE 0)
				'PresentationFrameTimeFractionalPartNumerator:4', (LE 0)
				'PresentationFrameTimeFractionalPartDenominator:4', (LE 1)
				'LeapPresentationFrameCounter:4', (LE 1)
				'PreviousPresentationFrameTimeLessSpillover:4', (LE 0)
				'PresentationFramerateLimit:4', (LE 0)
				'PresentationFrameProcessingBitMask:4', (LE (1 -shl 0))

				'GameFrameTiming:'
				'GameFrameTime:4', (LE 0)
				'GameFrameTimeIntegralPart:4', (LE 0)
				'GameFrameTimeFractionalPartNumerator:4', (LE 0)
				'GameFrameTimeFractionalPartDenominator:4', (LE 1)
				'LeapGameFrameCounter:4', (LE 1)
				'PreviousGameFrameTimeLessSpillover:4', (LE 0)
				'GameFramerateLimit:4', (LE 0)
				'GameFrameProcessingBitMask:4', (LE (1 -shl 1))

				'CommonFrameTimePresentationScale:4', (LE 0)
				'CommonFrameTimeGameScale:4', (LE 0)
				'CommonFrameTimeDenominator:4', (LE 0)
				'CommonFrameTimePresentationFrameNumerator:4', (LE 0)
				'CommonFrameTimeGameFrameNumerator:4', (LE 0)
				'CommonFrameTimeInterpolationFactor:4', (LE 0)

				'FrameInterpolationInitialOffset:4:(float)', (LE ([Float] ([Double] $GameFramerate / [Double] $Script:FramerateLimit)))
				'FrameInterpolationTimeScale:4:(float)', (LE ([Float] ([Double] ($Script:FramerateLimit - $GameFramerate) / [Double] $Script:FramerateLimit)))
				'FrameInterpolationTimeOffset:4:(float)', (LE ([Float] 0))
				'FrameInterpolationScaledTimeOffset:4:(float)', (LE ([Float] 0))
				'FrameInterpolationValue:4:(float)', (LE ([Float] 0))

				'PresentationFrameIndex:4', (LE 0)
				'PresentationTimeSinceGameFrame:4', (LE 0)
				'PresentationTimeSinceGameFrameFraction:4:(float)', (LE ([Float] 0))

					{[Byte[]]::new(8 - ($Offset -band 7))}
				'PerformanceFrequency:8', (LE ([UInt64] 0))

				'HeldCameraPosition0:4:(float)', (LE ([Float] 0))
				'HeldCameraPosition1:4:(float)', (LE ([Float] 0))
				'HeldCameraPosition2:4:(float)', (LE ([Float] 0))
				'HeldCameraPosition3:4:(float)', (LE ([Float] 0))
				'HeldCameraPosition4:4:(float)', (LE ([Float] 0))
				'HeldCameraPosition5:4:(float)', (LE ([Float] 0))
				'HeldCameraHeight:4:(float)', (LE ([Float] 0))
				'CameraPositionDelta0:4:(float)', (LE ([Float] 0))
				'CameraPositionDelta1:4:(float)', (LE ([Float] 0))
				'CameraPositionDelta2:4:(float)', (LE ([Float] 0))
				'CameraPositionDelta3:4:(float)', (LE ([Float] 0))
				'CameraPositionDelta4:4:(float)', (LE ([Float] 0))
				'CameraPositionDelta5:4:(float)', (LE ([Float] 0))
				'CameraHeightDelta:4:(float)', (LE ([Float] 0))
				'CameraModifier0Backup:4:(float)', (LE ([Float] 0))
				'CameraModifier1Backup:4:(float)', (LE ([Float] 0))
				'CameraShakeTarget:4:(float)', (LE ([Float] 0))
				'CameraSmoothingDivisor:4:(float)', (LE ([Float] 5))
				'CurrentCameraSmoothingDivisor:4:(float)', (LE ([Float] 1))
				'CameraHeightSmoothingDivsor:4:(float)', (LE ([Float] 10))
				'CurrentCameraHeightSmoothingDivisor:4:(float)', (LE ([Float] 1))
				'CameraHeightSmoothingAdjustment:4:(float)', (LE ([Float] 0.3))
				'CameraHeightInitialisationAdjustment:4:(float)', (LE ([Float] 3.0))
				'CurrentCameraHeightSmoothingAdjustment:4:(float)', (LE ([Float] 0))

				'PlayerCharacterPositionBackup:12'
				'PlayerCharacterPositionBackupX:4:(float)', (LE ([Float] 0))
				'PlayerCharacterPositionBackupY:4:(float)', (LE ([Float] 0))
				'PlayerCharacterPositionBackupZ:4:(float)', (LE ([Float] 0))

				'FloatsWereInterpolated:4', (LE 0)
				'StopInterpolatingFloatsUntilNextGameFrame:4', (LE 0)
				'DoNotInterpolateFloatNaN:4:(float)', (LE $DoNotInterpolateFloatNaNValue)
				'HUDSlideInPercentageMaximumDelta:4:(float)', (LE ([Float] $HUDSlideInPercentageMaximumDelta))

				'AlwaysSpawnNagiCheat:', (LE 0)

				'SkipUIStuffReplacement:4', (LE 0)
				'Anchor2DToBottom:4', (LE 0)
				'BlackBarFlags:4', (LE 0)

				'4f:4:(float)', (LE ([Float] 4))
				'12f:4:(float)', (LE ([Float] 12))
				'32f:4:(float)', (LE ([Float] 32))
				'_640fv:4:(float)', (LE ([Float] 640))
				'_100_0f:4:(float)', (LE ([Float] 100))
				'2DResolutionWidth:4:(float)', (LE ([Float] $2DResolutionWidth))
				'2DResolutionHeight:4:(float)', (LE ([Float] $2DResolutionHeight))
				'XScale:4:(float)', (LE ([Float] $XScale))
				'2DTo3DScale:4:(float)', (LE ([Float] $2DTo3DScale))
				'PillarboxWidth:4:(float)', (LE ([Float] $PillarboxWidth))
				'2DPillarboxWidth:4:(float)', (LE ([Float] $2DPillarboxWidth))
				'2DLetterboxHeight:4:(float)', (LE ([Float] $2DLetterboxHeight))
				'2DTotalLetterboxHeight:4:(float)', (LE ([Float] $2DTotalLetterboxHeight))
				'2DPillarboxWidthNegative:4:(float)', (LE ([Float] $2DPillarboxWidthNegative))
				'UIPillarboxWidth:4:(float)', (LE ([Float] $UIPillarboxWidth))
				'UIPillarboxWidthNegative:4:(float)', (LE ([Float] $UIPillarboxWidthNegative))
				'HUDPillarboxWidth:4:(float)', (LE ([Float] $HUDPillarboxWidth))
				'HUDPillarboxWidthNegative:4:(float)', (LE ([Float] $HUDPillarboxWidthNegative))
				'2DLetterboxHeightNegative:4:(float)', (LE ([Float] $2DLetterboxHeightNegative))
				'ScaledBaseWidth:4:(float)', (LE ([Float] $ScaledBaseWidth))
				'2DScaledBaseWidth:4:(float)', (LE ([Float] $2DScaledBaseWidth))
				'2DScaledBaseHeight:4:(float)', (LE ([Float] $2DScaledBaseHeight))
				'GameBaseHeightPlus2DLetterbox:4:(float)', (LE ([Float] $GameBaseHeightPlus2DLetterbox))
				'GameBaseWidthPlusUIPillarbox:4:(float)', (LE ([Float] $GameBaseWidthPlusUIPillarbox))
				'FullWidth:4:(float)', (LE ([Float] $FullWidth))
				'2DFullWidth:4:(float)', (LE ([Float] $2DFullWidth))
				'HUDClockHandX:4:(float)', (LE ([Float] $HUDClockHandX))
				'HUDClockHandY:4:(float)', (LE ([Float] $HUDClockHandY))
				'HUDClockDayOneDigitX:4:(float)', (LE ([Float] $HUDClockDayOneDigitX))
				'HUDClockDayTwoDigitX:4:(float)', (LE ([Float] $HUDClockDayTwoDigitX))
				'HUDClockDayThreeDigitX:4:(float)', (LE ([Float] $HUDClockDayThreeDigitX))
				'HUDClockDayFourDigitX:4:(float)', (LE ([Float] $HUDClockDayFourDigitX))
				'HUDClockDayY:4:(float)', (LE ([Float] $HUDClockDayY))
				'HUDClockPixX:4:(float)', (LE ([Float] $HUDClockPixX))
				'HUDClockPixY:4:(float)', (LE ([Float] $HUDClockPixY))
				'HUDMerchantLevelYOffset:4:(float)', (LE ([Float] $HUDMerchantLevelYOffset))
				'HUDChangeCameraX:4:(float)', (LE ([Float] $HUDChangeCameraX))
				'HUDChangeCameraY:4:(float)', (LE ([Float] $HUDChangeCameraY))
				'HUDFPSOSDX:4:(float)', (LE ([Float] $HUDFPSOSDX))
				'HUDFPSOSDY:4:(float)', (LE ([Float] $HUDFPSOSDY))
				'HUDFPSCounterX:4:(float)', (LE ([Float] $HUDFPSCounterX))
				'HUDFPSCounterY:4:(float)', (LE ([Float] $HUDFPSCounterY))
				'HUDFPSCounterXIncrement:4:(float)', (LE ([Float] $HUDFPSCounterXIncrement))
				'HUDEnemyHealthBarXOffset416:4:(float)', (LE ([Float] $HUDEnemyHealthBarXOffset416))
				'HUDEnemyHealthBarXOffset360:4:(float)', (LE ([Float] $HUDEnemyHealthBarXOffset360))
				'HUDEnemyHealthBarXOffset364:4:(float)', (LE ([Float] $HUDEnemyHealthBarXOffset364))
				'HUDEnemyHealthBarXOffset404:4:(float)', (LE ([Float] $HUDEnemyHealthBarXOffset404))
				'HUDEnemyHealthBarXOffset418:4:(float)', (LE ([Float] $HUDEnemyHealthBarXOffset418))
				'HUDEnemyHealthBarXOffset456:4:(float)', (LE ([Float] $HUDEnemyHealthBarXOffset456))
				'HUDEnemyHealthBarXOffset488:4:(float)', (LE ([Float] $HUDEnemyHealthBarXOffset488))
				'HUDCombatChainXOffset16:4:(float)', (LE ([Float] $HUDCombatChainXOffset16))
				'HUDCombatChainXOffset96:4:(float)', (LE ([Float] $HUDCombatChainXOffset96))
				'HUDCombatChainY:4:(float)', (LE ([Float] $HUDCombatChainY))
				'HUDLevelNameXOffset460:4:(float)', (LE ([Float] $HUDLevelNameXOffset460))
				'HUDLevelNameXOffset468:4:(float)', (LE ([Float] $HUDLevelNameXOffset468))
				'HUDLevelNameXOffset560:4:(float)', (LE ([Float] $HUDLevelNameXOffset560))
				'HUDLevelNameXOffset600:4:(float)', (LE ([Float] $HUDLevelNameXOffset600))
				'HUDLevelNameYOffset:4:(float)', (LE ([Float] $HUDLevelNameYOffset))
				'HUDLootedLootXOffset:4:(float)', (LE ([Float] $HUDLootedLootXOffset))
				'HUDLootedLootXOffsetMaximum:4:(float)', (LE ([Float] $HUDLootedLootXOffsetMaximum))
				'HUDLootedLootYOffset104:4:(float)', (LE ([Float] $HUDLootedLootYOffset104))
				'HUDLootedLootYOffset98:4:(float)', (LE ([Float] $HUDLootedLootYOffset98))
				'HUDHealthBarXOffset:4:(float)', (LE ([Float] $HUDHealthBarXOffset))
				'HUDHealthBarYOffset:4:(float)', (LE ([Float] $HUDHealthBarYOffset))
				'HUDSPBarYOffset:4:(float)', (LE ([Float] $HUDSPBarYOffset))
				'HUDAdventurerPanelYOffset:4:(float)', (LE ([Float] $HUDAdventurerPanelYOffset))
				'HUDCombatNewsHorizontalPositionMultiplier:4:(float)', (LE ([Float] $HUDCombatNewsHorizontalPositionMultiplier))
				'HUDCombatNewsXOffset:4:(float)', (LE ([Float] $HUDCombatNewsXOffset))
				'HUDCombatNewsXOffsetMaximum:4:(float)', (LE ([Float] $HUDCombatNewsXOffsetMaximum))
				'HUDCombatNewsYOffset:4:(float)', (LE ([Float] $HUDCombatNewsYOffset))
				'HUDJapaneseCombatNewsXOffset:4:(float)', (LE ([Float] $HUDJapaneseCombatNewsXOffset))
				'HUDMinimapXOffset:4:(float)', (LE ([Float] $HUDMinimapXOffset))
				'HUDMinimapYOffset:4:(float)', (LE ([Float] $HUDMinimapYOffset))
				'HUDArrowPowerArrowXOffset:4:(float)', (LE ([Float] $HUDArrowPowerArrowXOffset))
				'HUDArrowPowerArrowYOffset:4:(float)', (LE ([Float] $HUDArrowPowerArrowYOffset))
				'HUDArrowPowerPOWERXOffset:4:(float)', (LE ([Float] $HUDArrowPowerPOWERXOffset))
				'HUDArrowPowerPOWERYOffset:4:(float)', (LE ([Float] $HUDArrowPowerPOWERYOffset))
				'HUDAmmoNotchXOffset:4:(float)', (LE ([Float] $HUDAmmoNotchXOffset))
				'HUDAmmoNotchYOffset:4:(float)', (LE ([Float] $HUDAmmoNotchYOffset))
				'HUDAmmoReloadXOffset:4:(float)', (LE ([Float] $HUDAmmoReloadXOffset))
				'HUDAmmoReloadYOffset:4:(float)', (LE ([Float] $HUDAmmoReloadYOffset))
				'ShopTillCustomerPositionOffset:4:(float)', (LE ([Float] $ShopTillCustomerPositionOffset))
				'ShopTillCustomerPositionCounterOriginalMultiplier:4:(float)', (LE ([Float] $ShopTillCustomerPositionCounterOriginalMultiplier))
				'ShopTillCustomerPositionCounterOriginalLimit:4:(float)', (LE ([Float] $ShopTillCustomerPositionCounterOriginalLimit))
				'ShopTillCustomerPositionCounterLinearConvergence:4:(float)', (LE ([Float] $ShopTillCustomerPositionCounterLinearConvergence))
				'ShopTillCustomerPositionCounterLinearConvergenceLimit:4:(float)', (LE ([Float] $ShopTillCustomerPositionCounterLinearConvergenceLimit))
				'ShopTillCustomerPositionCounterLinearConvergenceDivisor:4:(float)', (LE ([Float] $ShopTillCustomerPositionCounterLinearConvergenceDivisor))
				'ShopTillCustomerPositionCounterMultiplier:4:(float)', (LE ([Float] $ShopTillCustomerPositionCounterMultiplier))
				'ShopTillRecetPositionOffset:4:(float)', (LE ([Float] $ShopTillRecetPositionOffset))
				'ShopTillRecetPositionMinimum:4:(float)', (LE ([Float] $ShopTillRecetPositionMinimum))
				'ShopSpeechBubbleButtonYOffset186:4:(float)', (LE ([Float] $ShopSpeechBubbleButtonYOffset186))
				'ShopSpeechBubbleButtonYOffset362:4:(float)', (LE ([Float] $ShopSpeechBubbleButtonYOffset362))
				'ShopSpeechBubbleYOffset:4:(float)', (LE ([Float] $ShopSpeechBubbleYOffset))
				'ShopEquipmentStatDiffYOffset24:4:(float)', (LE ([Float] $ShopEquipmentStatDiffYOffset24))
				'ShopEquipmentStatDiffYOffset36:4:(float)', (LE ([Float] $ShopEquipmentStatDiffYOffset36))
				'ShopEquipmentStatDiffYOffset44:4:(float)', (LE ([Float] $ShopEquipmentStatDiffYOffset44))
				'ShowCaseItemSparklesYOffset:4:(float)', (LE ([Float] $ShowCaseItemSparklesYOffset))
				'SelectionHandOriginalYOffset:4:(float)', (LE ([Float] $SelectionHandOriginalYOffset))
				'SelectionHandYOffset:4:(float)', (LE ([Float] $SelectionHandYOffset))
				'NewsTickerXOffset208:4:(float)', (LE ([Float] $NewsTickerXOffset208))
				'NewsTickerTextXOffset:4:(float)', (LE ([Float] $NewsTickerTextXOffset))
				'TearMenuTransitionCounterMultiplier:4:(float)', (LE ([Float] $TearMenuTransitionCounterMultiplier))
				'TearLectureButtonTransitionCounterMultiplier:4:(float)', (LE ([Float] $TearLectureButtonTransitionCounterMultiplier))
				'SelectionHandRestingX:4:(float)', (LE ([Float] $SelectionHandRestingX))
				'SelectionHandRestingY:4:(float)', (LE ([Float] $SelectionHandRestingY))
				'NowLoadingTextX:4:(float)', (LE ([Float] $NowLoadingTextX))
				'NowLoadingTextY:4:(float)', (LE ([Float] $NowLoadingTextY))
				'NowLoadingDiscX:4:(float)', (LE ([Float] $NowLoadingDiscX))
				'NowLoadingDiscY:4:(float)', (LE ([Float] $NowLoadingDiscY))
				'WorldDrawDistanceShort:4:(float)', (LE ([Float] $WorldDrawDistanceShort))
				'WorldDrawDistanceLong:4:(float)', (LE ([Float] $WorldDrawDistanceLong))
				'MobDrawDistanceShort:4:(float)', (LE ([Float] $MobDrawDistanceShort))
				'MobDrawDistanceLong:4:(float)', (LE ([Float] $MobDrawDistanceLong))
				'FloraDrawDistance:4:(float)', (LE ([Float] $FloraDrawDistance))
				'ShadowDrawDistance:4:(float)', (LE ([Float] $ShadowDrawDistance))
				'Scaled16f:4:(float)', (LE ([Float] $Scaled16f))
				'OnePixelWidthLeft:4:(float)', (LE ([Float] $OnePixelWidthLeft))
				'TwoPixelWidthLeft:4:(float)', (LE ([Float] $TwoPixelWidthLeft))
				'OnePixelWidthRight:4:(float)', (LE ([Float] $OnePixelWidthRight))
				'TwoPixelWidthRight:4:(float)', (LE ([Float] $TwoPixelWidthRight))

				'LoadingDiscSpinRate:4:(float)', (LE ([Float] $LoadingDiscSpinRate))

				'ShouldEnableVerticalSync:4', (LE 0)

				'PatchIsDPIAware:4', (LE 0)
				'GameWindowDPI:4', (LE 0)

				'GameWindowStyle:4', (LE 0)
				'GameWindowHasMenu:4', (LE 0)

				'CurrentWindowX:4:(int)', (LE 0)
				'CurrentWindowY:4:(int)', (LE 0)
				'CurrentWindowWidth:4:(int)', (LE 0)
				'CurrentWindowHeight:4:(int)', (LE 0)

				'CurrentClientAreaWidth:4', (LE 0)
				'CurrentClientAreaHeight:4', (LE 0)

				'ScratchRect:16',
				'ScratchRectLeft:4:(int)', (LE 0)
				'ScratchRectTop:4:(int)', (LE 0)
				'ScratchRectRight:4:(int)', (LE 0)
				'ScratchRectBottom:4:(int)', (LE 0)

				'ViewportX:4', (LE 0)
				'ViewportY:4', (LE 0)
				'ViewportWidth:4', (LE 0)
				'ViewportHeight:4', (LE 0)
				'ViewportMinZ:4:(float)', (LE ([Float] 0))
				'ViewportMaxZ:4:(float)', (LE ([Float] 0))

				'User32DLLHandle:4', (LE 0)
				'SetProcessDpiAwarenessContext:4', (LE 0)
				'GetDpiForWindow:4', (LE 0)
				'AdjustWindowRectExForDpi:4', (LE 0)
				'SetWindowPos:4', (LE 0)
				'MonitorFromWindow:4', (LE 0)
				'GetMonitorInfoW:4', (LE 0)
				'GetSystemMetricsForDpi:4', (LE 0)

				'User32DLLName:10:(char[10])', $UTF8.GetBytes("User32.dll`0")
					[Byte[]]::new(1)
				'SetProcessDpiAwarenessContextName:29:(char[29])', $UTF8.GetBytes("SetProcessDpiAwarenessContext`0")
					[Byte[]]::new(2)
				'GetDpiForWindowName:15:(char[15])', $UTF8.GetBytes("GetDpiForWindow`0")
				'AdjustWindowRectExForDpiName:24:(char[24])', $UTF8.GetBytes("AdjustWindowRectExForDpi`0")
					[Byte[]]::new(3)
				'GetSystemMetricsForDpiName:22:(char[22])', $UTF8.GetBytes("GetSystemMetricsForDpi`0")
					[Byte[]]::new(1)
				'SetWindowPosName:12:(char[12])', $UTF8.GetBytes("SetWindowPos`0")
					[Byte[]]::new(3)
				'MonitorFromWindowName:17:(char[17])', $UTF8.GetBytes("MonitorFromWindow`0")
					[Byte[]]::new(2)
				'GetMonitorInfoWName:15:(char[15])', $UTF8.GetBytes("GetMonitorInfoW`0")

				'PrecalculatedClientArea[0]:8:(uint[2])'
				'PrecalculatedClientArea[0]Width:4', (LE ([UInt32] $Script:ResolutionWidth))
				'PrecalculatedClientArea[0]Height:4', (LE ([UInt32] $Script:ResolutionHeight))
				'PrecalculatedClientArea[1]Width:4', (LE ([UInt32] ($Script:ResolutionWidth -shr 1)))
				'PrecalculatedClientArea[1]Height:4', (LE ([UInt32] ($Script:ResolutionHeight -shr 1)))
				'PrecalculatedClientArea[2]Width:4', (LE ([UInt32] $Script:ResolutionWidth))
				'PrecalculatedClientArea[2]Height:4', (LE ([UInt32] $Script:ResolutionHeight))
				'PrecalculatedClientArea[3]Width:4', (LE ([UInt32] ($Script:ResolutionWidth + ($Script:ResolutionWidth -shr 1))))
				'PrecalculatedClientArea[3]Height:4', (LE ([UInt32] ($Script:ResolutionHeight + ($Script:ResolutionHeight -shr 1))))
				'PrecalculatedClientArea[4]Width:4', (LE ([UInt32] ($Script:ResolutionWidth -shl 1)))
				'PrecalculatedClientArea[4]Height:4', (LE ([UInt32] ($Script:ResolutionHeight -shl 1)))
				'PrecalculatedClientArea[5]Width:4', (LE ([UInt32] (($Script:ResolutionWidth -shl 1) + ($Script:ResolutionWidth -shr 1))))
				'PrecalculatedClientArea[5]Height:4', (LE ([UInt32] (($Script:ResolutionHeight -shl 1) + ($Script:ResolutionHeight -shr 1))))
				'PrecalculatedClientArea[6]Width:4', (LE ([UInt32] (($Script:ResolutionWidth -shl 1) + $Script:ResolutionWidth)))
				'PrecalculatedClientArea[6]Height:4', (LE ([UInt32] (($Script:ResolutionHeight -shl 1) + $Script:ResolutionHeight)))

					foreach ($Integer in $IntegersToMirrorAsFloats)
					{
					"$($Integer.Name):4:(float)", (LE ([Float] 0))
					}
				)

				[Call]::NewLabel('AlwaysSpawnNagi', ${&AlwaysSpawnNagiCheat}, ${@AlwaysSpawnNagiCheat}, 4, 'uint')

				#${&InterpolatedFloats[]} = [UInt32[]] @(
				#<# The player-character's position: #>
				#	0x056da1d8
				#	0x056da1dc
				#	0x056da1e0
				#<# Recet's position, whilst following the player-character in a dungeon: #>
				#	0x056da1e4
				#	0x056da1e8
				#	0x056da1ec
				#<# Tear's position: #>
				#	0x056da1f0
				#	0x056da1f4
				#	0x056da1f8
				#	# Near the end?: Recettear.exe+52DA3C0
		#
				#	for ($Index = 0; $Index -lt 128; ++$Index)
				#	{
				#		(0x0076b970 + $Index * 0xba4) + 0x3f0
				#		(0x0076b970 + $Index * 0xba4) + 0x3f4
				#		(0x0076b970 + $Index * 0xba4) + 0x3f8
				#	}
				#)

				$PlayerCharacterPositionInterpolation = @{
					Name = 'PlayerCharacterPosition'
					VirtualAddress = $AddressOf.PlayerCharacterPosition
					FloatOffsets = @(@{Key = 'X'; Value = 0}, @{Key = 'Y'; Value = 4}, @{Key = 'Z'; Value = 8})
				}

				$RecetWhenInDungeonPositionInterpolation = @{
					Name = 'RecetWhenInDungeonPosition'
					VirtualAddress = $AddressOf.RecetWhenInDungeonPosition
					FloatOffsets = @(@{Key = 'X'; Value = 0}, @{Key = 'Y'; Value = 4}, @{Key = 'Z'; Value = 8})
				}

				$TearPositionInterpolation = @{
					Name = 'TearPosition'
					VirtualAddress = $AddressOf.TearPosition
					FloatOffsets = @(@{Key = 'X'; Value = 0}, @{Key = 'Y'; Value = 4}, @{Key = 'Z'; Value = 8})
				}

				$ShopperPositionInterpolation = @{
					Name = 'ShopperPosition'
					VirtualAddress = $AddressOf.ShopperPosition
					Structure = @{Size = [UInt32] 0x90; Count = 30}
					FloatOffsets = @(@{Key = 'X'; Value = -44}, @{Key = 'Y'; Value = -40}, @{Key = 'Z'; Value = -36})
				}

				$WindowShopperPositionInterpolation = @{
					Name = 'WindowShopperPosition'
					VirtualAddress = $AddressOf.WindowShopperPosition
					Structure = @{Size = [UInt32] 0x64; Count = [UInt32] 6}
					FloatOffsets = @(@{Key = 'X'; Value = 0}, @{Key = 'Y'; Value = 4}, @{Key = 'Z'; Value = 8})
				}

				$MobPositionInterpolation = @{
					Name = 'MobPosition'
					VirtualAddress = $AddressOf.MobPosition
					Structure = @{Size = [UInt32] 0xba4; Count = [UInt32] 128}
					FloatOffsets = @(@{Key = 'X'; Value = 0x3f0}, @{Key = 'Y'; Value = 0x3f4}, @{Key = 'Z'; Value = 0x3f8})
				}

				$MirrorImageReflectionPositionInterpolation = @{
					Name = 'MirrorImageReflectionPosition'
					VirtualAddress = $AddressOf.MirrorImageReflectionPosition
					Structure = @{Size = [UInt32] 0x44; Count = [UInt32] 20}
					FloatOffsets = @(@{Key = 'X'; Value = -20}, @{Key = 'Y'; Value = -16}, @{Key = 'Z'; Value = -12})
				}

				$AttackProjectilePositionInterpolation = @{
					Name = 'AttackProjectilePosition'
					VirtualAddress = $AddressOf.AttackProjectilePosition
					Structure = @{Size = [UInt32] 0x124; Count = [UInt32] 512}
					FloatOffsets = @(@{Key = 'X'; Value = 0x5c}, @{Key = 'Y'; Value = 0x60}, @{Key = 'Z'; Value = 0x64})
				}

				$XPGemPositionInterpolation = @{
					Name = 'XPGemPosition'
					VirtualAddress = $AddressOf.XPGemPosition
					Structure = @{Size = [UInt32] 0x94; Count = [UInt32] 200}
					FloatOffsets = @(@{Key = 'X'; Value = -44}, @{Key = 'Y'; Value = -40}, @{Key = 'Z'; Value = -36})
				}

				$MovementParticlePositionInterpolation = @{
					Name = 'MovementParticlePosition'
					VirtualAddress = $AddressOf.MovementParticlePosition
					Structure = @{Size = [UInt32] 0x94; Count = [UInt32] 4096}
					FloatOffsets = @(@{Key = 'X'; Value = 0}, @{Key = 'Y'; Value = 4}, @{Key = 'Z'; Value = 8})
				}

				$HUDSlideInInterpolation = @{
					Name = 'HUDSlideIn'
					VirtualAddress = ${&HUDSlideInPercentage}
					FloatOffsets = @(@{Key = 'Percentage'; Value = 0})
				}


				$FloatsToAllocate = @(
					if ($InterpolatingFloats.PlayerCharacterPosition -or $InterpolatingFloats.RecetWhenInDungeonPosition -or $InterpolatingFloats.TearPosition)
					{
						[ValueTuple[Object, Bool]]::new($PlayerCharacterPositionInterpolation, $InterpolatingFloats.PlayerCharacterPosition)
						[ValueTuple[Object, Bool]]::new($RecetWhenInDungeonPositionInterpolation, $InterpolatingFloats.RecetWhenInDungeonPosition)
						[ValueTuple[Object, Bool]]::new($TearPositionInterpolation, $InterpolatingFloats.TearPosition)
					}

					if ($InterpolatingFloats.ShopperPosition) {[ValueTuple[Object, Bool]]::new($ShopperPositionInterpolation, $True)}
					if ($InterpolatingFloats.WindowShopperPosition) {[ValueTuple[Object, Bool]]::new($WindowShopperPositionInterpolation, $True)}
					if ($InterpolatingFloats.MobPosition) {[ValueTuple[Object, Bool]]::new($MobPositionInterpolation, $True)}
					if ($InterpolatingFloats.MirrorImageReflectionPosition) {[ValueTuple[Object, Bool]]::new($MirrorImageReflectionPositionInterpolation, $True)}
					if ($InterpolatingFloats.AttackProjectilePosition) {[ValueTuple[Object, Bool]]::new($AttackProjectilePositionInterpolation, $True)}
					if ($InterpolatingFloats.XPGemPosition) {[ValueTuple[Object, Bool]]::new($XPGemPositionInterpolation, $True)}
					if ($InterpolatingFloats.MovementParticlePosition) {[ValueTuple[Object, Bool]]::new($MovementParticlePositionInterpolation, $True)}
					if ($InterpolatingFloats.HUDSlideIn) {[ValueTuple[Object, Bool]]::new($HUDSlideInInterpolation, $True)}

					foreach ($Integer in $IntegersToMirrorAsFloats)
					{
						[ValueTuple[Object, Bool]]::new(
							@{
								Name = "Interpolated$($Integer.Name)"
								VirtualAddress = $Variables.GetValue("&$($Integer.Name)")
								FloatOffsets = @(@{Key = 'Scalar'; Value = 0})
							},
							$True
						)
					}
				).ForEach{$_}

				$FloatsToInterpolate = $FloatsToAllocate.Where{$_.Item2}.ForEach{$_.Item1}


				$InterpolatedFloatEntrySize = [UInt32] 12
				$InterpolatedFloatHeldValueOffset = 0
				$InterpolatedFloatDeltaOffset = 4
				$InterpolatedFloatTargetOffset = 8

				${&InterpolatedFloatData} = ${&PatchData} + $RawDataSizeOfPatchData
				${&InterpolatedFloatData$} = ${&InterpolatedFloatData}


				foreach ($Pair in $FloatsToAllocate)
				{
					$Float = $Pair.Item1
					$Singular = $Null -eq $Float.Structure
					$Count = [UInt32] $(if ($Singular) {1} else {if ($Float.Structure.Count -is [String]) {$Float.Structure.MaximumCount} else {$Float.Structure.Count}})

					if ($Count -eq 0)
					{
						continue
					}

					for ($Index = 0; $Index -lt [Math]::Min(1, $Count); ++$Index)
					{
						$BaseName = "$($Float.Name)$(if (-not $Singular) {"[$Index]"})"

						foreach ($Offset in $Float.FloatOffsets)
						{
							$Name = "$($BaseName)_$($Offset.Key)"

							[Call]::NewLabel("$($Name)_ActualValue", $Float.VirtualAddress + $Index * $Float.Structure.Size + $Offset.Value, $Null, 4, 'float')
							[Call]::NewLabel("$($Name)_Entry", ${&InterpolatedFloatData$}, $Null, $InterpolatedFloatEntrySize, $Null)
							[Call]::NewLabel("$($Name)_HeldValue", ${&InterpolatedFloatData$} + $InterpolatedFloatHeldValueOffset, $Null, 4, 'float')
							[Call]::NewLabel("$($Name)_Delta", ${&InterpolatedFloatData$} + $InterpolatedFloatDeltaOffset, $Null, 4, 'float')
							[Call]::NewLabel("$($Name)_Target", ${&InterpolatedFloatData$} + $InterpolatedFloatTargetOffset, $Null, 4, 'float')

							${&InterpolatedFloatData$} += $InterpolatedFloatEntrySize
						}
					}

					${&InterpolatedFloatData$} += ($Count - 1) * $Float.FloatOffsets.Length * $InterpolatedFloatEntrySize
				}

				${&HeldCameraPositions[]} = @(
					${&HeldCameraPosition0},
					${&HeldCameraPosition1},
					${&HeldCameraPosition2},
					${&HeldCameraPosition3},
					${&HeldCameraPosition4},
					${&HeldCameraPosition5}
				)

				${&CameraPositionDeltas[]} = @(
					${&CameraPositionDelta0},
					${&CameraPositionDelta1},
					${&CameraPositionDelta2},
					${&CameraPositionDelta3},
					${&CameraPositionDelta4},
					${&CameraPositionDelta5}
				)


				${@EntryPoint} = VirtualAddressToFileOffset ${&EntryPoint}

				$GameFrameRateTrailingZeroCount = 31 -bxor [Convert]::ToString($GameFrameRate, 2).PadLeft(32, '0').LastIndexOf('1')
				$GameFrameRateMadeOdd = $GameFrameRate -shr $GameFrameRateTrailingZeroCount

				$PresentationFrameRateTrailingZeroCount = 31 -bxor [Convert]::ToString($Script:FramerateLimit, 2).PadLeft(32, '0').LastIndexOf('1')
				$PresentationFrameRateMadeOdd = $Script:FramerateLimit -shr $PresentationFrameRateTrailingZeroCount


				$RestoreTargetPlayerCharacterPosition = @(
					foreach ($Axis in 'X', 'Y', 'Z')
					{
						0xD9, (ModRM 0 0 5), "&PlayerCharacterPosition_$($Axis)_ActualValue" <# fld [&PlayerCharacterPosition_$($Axis)_ActualValue] #>
						0xD9, (ModRM 0 3 5), "&PlayerCharacterPositionBackup$Axis"           <# fstp [&PlayerCharacterPositionBackup$Axis] #>
						0xD9, (ModRM 0 0 5), "&PlayerCharacterPosition_$($Axis)_Target"      <# fld [&PlayerCharacterPosition_$($Axis)_Target] #>
						0xD9, (ModRM 0 3 5), "&PlayerCharacterPosition_$($Axis)_ActualValue" <# fstp [&PlayerCharacterPosition_$($Axis)_ActualValue] #>
					}
				)

				$RestoreInterpolatedPlayerCharacterPosition = @(
					foreach ($Axis in 'X', 'Y', 'Z')
					{
						0xD9, (ModRM 0 0 5), "&PlayerCharacterPositionBackup$Axis"           <# fld [&PlayerCharacterPositionBackup$Axis] #>
						0xD9, (ModRM 0 3 5), "&PlayerCharacterPosition_$($Axis)_ActualValue" <# fstp [&PlayerCharacterPosition_$($Axis)_ActualValue] #>
					}
				)


				$DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4


				Preassemble 'PatchEntryPoint' $VirtualAddressOfPatchCode $RawDataOffsetOfPatchCode @(
					0x68, '&User32DLLName'                                                 <# push &User32DLLName #>
					0x8B, (ModRM 0 7 5), '&GetProcAddress'                                 <# mov edi, [&GetProcAddress] #>
					0xFF, (ModRM 0 2 5), '&GetModuleHandleA'                               <# call [&GetModuleHandleA] #>
					0xA3, '&User32DLLHandle'                                               <# mov [&User32DLLHandle], eax #>
					0x8B, (ModRM 3 6 0)                                                    <# mov esi, eax #>
					0x68, '&SetWindowPosName'                                              <# push &SetWindowPosName #>
					0x56                                                                   <# push esi #>
					0xFF, (ModRM 3 2 7)                                                    <# call [edi] #>
					0xA3, '&SetWindowPos'                                                  <# mov [&SetWindowPos], eax #>
					0x68, '&MonitorFromWindowName'                                         <# push &MonitorFromWindowName #>
					0x56                                                                   <# push esi #>
					0xFF, (ModRM 3 2 7)                                                    <# call [edi] #>
					0xA3, '&MonitorFromWindow'                                             <# mov [&MonitorFromWindow], eax #>
					0x68, '&GetMonitorInfoWName'                                           <# push &GetMonitorInfoWName #>
					0x56                                                                   <# push esi #>
					0xFF, (ModRM 3 2 7)                                                    <# call [edi] #>
					0xA3, '&GetMonitorInfoW'                                               <# mov [&GetMonitorInfoW], eax #>
					0x68, '&SetProcessDpiAwarenessContextName'                             <# push &SetProcessDpiAwarenessContextName #>
					0x56                                                                   <# push esi #>
					0xFF, (ModRM 3 2 7)                                                    <# call [edi] #>
					0x85, (ModRM 3 0 0)                                                    <# test eax, eax #>
					0x74, '1:PastDPIAwarenessSetup'                                        <# jz PastDPIAwarenessSetup #>
					0xA3, '&SetProcessDpiAwarenessContext'                                 <# mov [&SetProcessDpiAwarenessContext], eax #>
					0xFF, (ModRM 0 0 5), '&PatchIsDPIAware'                                <# inc [&PatchIsDPIAware] #>
					0x68, (LE $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)                 <# push $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 #>
					0xFF, (ModRM 3 2 0)                                                    <# call [eax] #>
					0x68, '&GetDpiForWindowName'                                           <# push &GetDpiForWindowName #>
					0x56                                                                   <# push esi #>
					0xFF, (ModRM 3 2 7)                                                    <# call [edi] #>
					0xA3, '&GetDpiForWindow'                                               <# mov [&GetDpiForWindow], eax #>
					0x68, '&AdjustWindowRectExForDpiName'                                  <# push &AdjustWindowRectExForDpiName #>
					0x56                                                                   <# push esi #>
					0xFF, (ModRM 3 2 7)                                                    <# call [edi] #>
					0xA3, '&AdjustWindowRectExForDpi'                                      <# mov [&AdjustWindowRectExForDpi], eax #>
					0x68, '&GetSystemMetricsForDpiName'                                    <# push &GetSystemMetricsForDpiName #>
					0x56                                                                   <# push esi #>
					0xFF, (ModRM 3 2 7)                                                    <# call [edi] #>
					0xA3, '&GetSystemMetricsForDpi'                                        <# mov [&GetSystemMetricsForDpi], eax #>
				'PastDPIAwarenessSetup:'
					0x68, '&PerformanceFrequency'                                          <# push &PerformanceFrequency #>
					0xFF, (ModRM 0 2 5), '&QueryPerformanceFrequency'                      <# call [&QueryPerformanceFrequency] #>
					0xA1, '&PerformanceFrequency'                                          <# mov eax, [&PerformanceFrequency] #>
					0xB9, (LE $GameFrameRate)                                              <# mov ecx, $GameFrameRate #>
					0x8B, (ModRM 0 2 5), (LE (${&PerformanceFrequency} + 4))               <# mov edx, [&PerformanceFrequency + 4] #>
					0xF7, (ModRM 3 6 1)                                                    <# div ecx #>
					0xA3, '&GameFrameTimeIntegralPart'                                     <# mov [&GameFrameTimeIntegralPart], eax #>
					0x85, (ModRM 3 2 2)                                                    <# test edx, edx #>
					0x74, '1:PostHandlingGameFrameTimeRemainder'                           <# jz PostHandlingGameFrameTimeRemainder #>
					0x40                                                                   <# inc eax #>
				'PostHandlingGameFrameTimeRemainder:'
					0xA3, '&GameFrameTime'                                                 <# mov [&GameFrameTime], eax #>
					0x85, (ModRM 3 2 2)                                                    <# test edx, edx #>
					0x74, '1:InitialPresentationFrameTimeCalculations'                     <# jz InitialPresentationFrameTimeCalculations #>
					0x8B, (ModRM 3 0 2)                                                    <# mov eax, edx #>
					0xF3, 0x0F, 0xBC, (ModRM 3 1 2)                                        <# tzcnt ecx, edx #>
					0xBB, (LE $GameFrameRateMadeOdd)                                       <# mov ebx, $GameFrameRateMadeOdd #>
					0xD3, (ModRM 3 5 2)                                                    <# shr edx, cl #>
				'CalculatingGCFOfGameFrameTimeFraction:'
					0x33, (ModRM 3 7 7)                                                    <# xor edi, edi #>
					0x8B, (ModRM 3 6 2)                                                    <# mov esi, edx #>
					0x2B, (ModRM 3 2 3)                                                    <# sub edx, ebx #>
					0x0F, 0x48, (ModRM 3 3 6)                                              <# cmovs ebx, esi #>
					0xF3, 0x0F, 0xBC, (ModRM 3 1 2)                                        <# tzcnt ecx, edx #>
					0x2B, (ModRM 3 7 2)                                                    <# sub edi, edx #>
					0x0F, 0x4D, (ModRM 3 2 7)                                              <# cmovns edx, edi #>
					0xD3, (ModRM 3 5 2)                                                    <# shr edx, cl #>
					0x72, '1:CalculatingGCFOfGameFrameTimeFraction'                        <# jc CalculatingGCFOfGameFrameTimeFraction #>
					0xF3, 0x0F, 0xBC, (ModRM 3 7 0)                                        <# tzcnt edi, eax #>
					0xB9, (LE $GameFrameRateTrailingZeroCount)                             <# mov ecx, GameFrameRateTrailingZeroCount #>
					0x3B, (ModRM 3 7 1)                                                    <# cmp edi, ecx #>
					0x0F, 0x42, (ModRM 3 1 7)                                              <# cmovb ecx, edi #>
					0xD3, (ModRM 3 4 3)                                                    <# shl ebx, cl #>
					0x33, (ModRM 3 2 2)                                                    <# xor edx, edx #>
					0xF7, (ModRM 3 6 3)                                                    <# div ebx #>
					0xA3, '&GameFrameTimeFractionalPartNumerator'                          <# mov [&GameFrameTimeFractionalPartNumerator], eax #>
					0x33, (ModRM 3 2 2)                                                    <# xor edx, edx #>
					0xB8, (LE $GameFrameRate)                                              <# mov eax, $GameFrameRate #>
					0xF7, (ModRM 3 6 3)                                                    <# div ebx #>
					0xA3, '&GameFrameTimeFractionalPartDenominator'                        <# mov [&GameFrameTimeFractionalPartDenominator], eax #>
					0xA3, '&LeapGameFrameCounter'                                          <# mov [&LeapGameFrameCounter], eax #>

				'InitialPresentationFrameTimeCalculations:'
					0xB9, (LE $Script:FramerateLimit)                                      <# mov ecx, $Script:FramerateLimit #>
					0x8B, (ModRM 0 2 5), (LE (${&PerformanceFrequency} + 4))               <# mov edx, [&PerformanceFrequency + 4] #>
					0xA1, '&PerformanceFrequency'                                          <# mov eax, [&PerformanceFrequency] #>
					0xF7, (ModRM 3 6 1)                                                    <# div ecx #>
					0xA3, '&PresentationFrameTimeIntegralPart'                             <# mov [&PresentationFrameTimeIntegralPart], eax #>
					0x85, (ModRM 3 2 2)                                                    <# test edx, edx #>
					0x74, '1:PostHandlingPresentationFrameTimeRemainder'                   <# jz PostHandlingPresentationFrameTimeRemainder #>
					0x40                                                                   <# inc eax #>
				'PostHandlingPresentationFrameTimeRemainder:'
					0xA3, '&PresentationFrameTime'                                         <# mov [&PresentationFrameTime], eax #>
					0x85, (ModRM 3 2 2)                                                    <# test edx, edx #>
					0x74, '1:InitialCommonFrameTimeCalculations'                           <# jz InitialCommonFrameTimeCalculations #>
					0x8B, (ModRM 3 0 2)                                                    <# mov eax, edx #>
					0xF3, 0x0F, 0xBC, (ModRM 3 1 2)                                        <# tzcnt ecx, edx #>
					0xBB, (LE $PresentationFrameRateMadeOdd)                               <# mov ebx, $PresentationFrameRateMadeOdd #>
					0xD3, (ModRM 3 5 2)                                                    <# shr edx, cl #>
				'CalculatingGCFOfPresentationFrameTimeFraction:'
					0x33, (ModRM 3 7 7)                                                    <# xor edi, edi #>
					0x8B, (ModRM 3 6 2)                                                    <# mov esi, edx #>
					0x2B, (ModRM 3 2 3)                                                    <# sub edx, ebx #>
					0x0F, 0x48, (ModRM 3 3 6)                                              <# cmovs ebx, esi #>
					0xF3, 0x0F, 0xBC, (ModRM 3 1 2)                                        <# tzcnt ecx, edx #>
					0x2B, (ModRM 3 7 2)                                                    <# sub edi, edx #>
					0x0F, 0x4D, (ModRM 3 2 7)                                              <# cmovns edx, edi #>
					0xD3, (ModRM 3 5 2)                                                    <# shr edx, cl #>
					0x72, '1:CalculatingGCFOfPresentationFrameTimeFraction'                <# jc CalculatingGCFOfPresentationFrameTimeFraction #>
					0xF3, 0x0F, 0xBC, (ModRM 3 7 0)                                        <# tzcnt edi, eax #>
					0xB9, (LE $PresentationFrameRateTrailingZeroCount)                     <# mov ecx, PresentationFrameRateTrailingZeroCount #>
					0x3B, (ModRM 3 7 1)                                                    <# cmp edi, ecx #>
					0x0F, 0x42, (ModRM 3 1 7)                                              <# cmovb ecx, edi #>
					0xD3, (ModRM 3 4 3)                                                    <# shl ebx, cl #>
					0x33, (ModRM 3 2 2)                                                    <# xor edx, edx #>
					0xF7, (ModRM 3 6 3)                                                    <# div ebx #>
					0xA3, '&PresentationFrameTimeFractionalPartNumerator'                  <# mov [&PresentationFrameTimeFractionalPartNumerator], eax #>
					0x33, (ModRM 3 2 2)                                                    <# xor edx, edx #>
					0xB8, (LE $Script:FramerateLimit)                                      <# mov eax, $Script:FramerateLimit #>
					0xF7, (ModRM 3 6 3)                                                    <# div ebx #>
					0xA3, '&PresentationFrameTimeFractionalPartDenominator'                <# mov [&PresentationFrameTimeFractionalPartDenominator], eax #>
					0xA3, '&LeapPresentationFrameCounter'                                  <# mov [&LeapPresentationFrameCounter], eax #>

				'InitialCommonFrameTimeCalculations:'
					0x8B, (ModRM 0 2 5), '&GameFrameTimeFractionalPartDenominator'         <# mov edx, [&GameFrameTimeFractionalPartDenominator] #>
					0x8B, (ModRM 0 3 5), '&PresentationFrameTimeFractionalPartDenominator' <# mov ebx, [&PresentationFrameTimeFractionalPartDenominator] #>
					0xF3, 0x0F, 0xBC, (ModRM 3 0 2)                                        <# tzcnt eax, edx #>
					0x8B, (ModRM 3 7 0)                                                    <# mov edi, eax #>
					0xF3, 0x0F, 0xBC, (ModRM 3 1 3)                                        <# tzcnt ecx, ebx #>
					0x3B, (ModRM 3 1 0)                                                    <# cmp ecx, eax #>
					0x0F, 0x42, (ModRM 3 7 1)                                              <# cmovb edi, ecx #>
					0xD3, (ModRM 3 5 3)                                                    <# shr ebx, cl #>
					0x8B, (ModRM 3 1 0)                                                    <# mov ecx, eax #>
					0xD3, (ModRM 3 5 2)                                                    <# shr edx, cl #>
				'CalculatingGCFOfCommonFrameTimeDenominators:'
					0x33, (ModRM 3 0 0)                                                    <# xor eax, eax #>
					0x8B, (ModRM 3 6 2)                                                    <# mov esi, edx #>
					0x2B, (ModRM 3 2 3)                                                    <# sub edx, ebx #>
					0x0F, 0x48, (ModRM 3 3 6)                                              <# cmovs ebx, esi #>
					0xF3, 0x0F, 0xBC, (ModRM 3 1 2)                                        <# tzcnt ecx, edx #>
					0x2B, (ModRM 3 0 2)                                                    <# sub eax, edx #>
					0x0F, 0x4D, (ModRM 3 2 0)                                              <# cmovns edx, eax #>
					0xD3, (ModRM 3 5 2)                                                    <# shr edx, cl #>
					0x72, '1:CalculatingGCFOfCommonFrameTimeDenominators'                  <# jc CalculatingGCFOfCommonFrameTimeDenominators #>
					0x8B, (ModRM 3 1 7)                                                    <# mov ecx, edi #>
					0xA1, '&GameFrameTimeFractionalPartDenominator'                        <# mov eax, [&GameFrameTimeFractionalPartDenominator] #>
					0xD3, (ModRM 3 4 3)                                                    <# shl ebx, cl #>
					0x33, (ModRM 3 2 2)                                                    <# xor edx, edx #>
					0xF7, (ModRM 3 6 3)                                                    <# div ebx #>
					0xF7, (ModRM 0 4 5), '&PresentationFrameTimeFractionalPartDenominator' <# mul [&PresentationFrameTimeFractionalPartDenominator] #>
					0xA3, '&CommonFrameTimeDenominator'                                    <# mov [&CommonFrameTimeDenominator], eax #>
					0x33, (ModRM 3 2 2)                                                    <# xor edx, edx #>
					0xF7, (ModRM 0 6 5), '&PresentationFrameTimeFractionalPartDenominator' <# div [&PresentationFrameTimeFractionalPartDenominator] #>
					0xA3, '&CommonFrameTimePresentationScale'                              <# mov [&CommonFrameTimePresentationScale], eax #>
					0xF7, (ModRM 0 4 5), '&PresentationFrameTimeFractionalPartNumerator'   <# mul [&PresentationFrameTimeFractionalPartNumerator] #>
					0x8B, (ModRM 3 6 0)                                                    <# mov esi, eax #>
					0xA1, '&CommonFrameTimeDenominator'                                    <# mov eax, [&CommonFrameTimeDenominator] #>
					0xF7, (ModRM 0 4 5), '&PresentationFrameTimeIntegralPart'              <# mul [&PresentationFrameTimeIntegralPart] #>
					0x03, (ModRM 3 0 6)                                                    <# add eax, esi #>
					0x8B, (ModRM 3 7 0)                                                    <# mov edi, eax #>
					0xA3, '&CommonFrameTimePresentationFrameNumerator'                     <# mov [&CommonFrameTimePresentationFrameNumerator], eax #>
					0x33, (ModRM 3 2 2)                                                    <# xor edx, edx #>
					0xA1, '&CommonFrameTimeDenominator'                                    <# mov eax, [&CommonFrameTimeDenominator] #>
					0xF7, (ModRM 0 6 5), '&GameFrameTimeFractionalPartDenominator'         <# div [&GameFrameTimeFractionalPartDenominator] #>
					0xA3, '&CommonFrameTimeGameScale'                                      <# mov [&CommonFrameTimeGameScale], eax #>
					0xF7, (ModRM 0 4 5), '&GameFrameTimeFractionalPartNumerator'           <# mul [&GameFrameTimeFractionalPartNumerator] #>
					0x8B, (ModRM 3 6 0)                                                    <# mov esi, eax #>
					0xA1, '&CommonFrameTimeDenominator'                                    <# mov eax, [&CommonFrameTimeDenominator] #>
					0xF7, (ModRM 0 4 5), '&GameFrameTimeIntegralPart'                      <# mul [&GameFrameTimeIntegralPart] #>
					0x03, (ModRM 3 0 6)                                                    <# add eax, esi #>
					0xA3, '&CommonFrameTimeGameFrameNumerator'                             <# mov [&CommonFrameTimeGameFrameNumerator], eax #>

					0xC7, (ModRM 3 0 1), 0xFF, 0xFF, 0xFF, 0xFF                            <# mov ecx, 0xFFFFFFFF #>
					0x8B, (ModRM 3 2 0)                                                    <# mov edx, eax #>
					0x33, (ModRM 3 6 6)                                                    <# xor esi, esi #>
				'CalculatingLatestExpectedPresentationFrameTime:'
					0x03, (ModRM 3 6 7)                                                    <# add esi, edi #>
					0x3B, (ModRM 3 6 2)                                                    <# cmp esi, edx #>
					0x74, '1:CalculatedLatestExpectedPresentationFrameTime'                <# jz CalculatedLatestExpectedPresentationFrameTime #>
					0x72, '1:PastPotentiallyNextGameFrame'                                 <# jb PastPotentiallyNextGameFrame #>
					0x03, (ModRM 3 2 0)                                                    <# add edx, eax #>
				'PastPotentiallyNextGameFrame:'
					0x8B, (ModRM 3 3 2)                                                    <# mov ebx, edx #>
					0x2B, (ModRM 3 3 6)                                                    <# sub ebx, esi #>
					0x3B, (ModRM 3 3 1)                                                    <# cmp ebx, ecx #>
					0x0F, 0x42, (ModRM 3 1 3),                                             <# cmovb ecx, ebx #>
					0xEB, '1:CalculatingLatestExpectedPresentationFrameTime'               <# jmp CalculatingLatestExpectedPresentationFrameTime #>
				'CalculatedLatestExpectedPresentationFrameTime:'
					0x2B, (ModRM 3 0 1)                                                    <# sub eax, ecx #>
					0xA3, '&CommonFrameTimeInterpolationFactor'                            <# mov [&CommonFrameTimeInterpolationFactor], eax #>

					0xE9, '4:EntryPoint'                                                   <# jmp EntryPoint #>
				)


				$Script:LastAutomaticallyPositionedAssemblyID = 'PatchEntryPoint'


				Hijack 'PostReadConfig' 'ReadConfig' 905 6 @(
					if ($Script:PatchingResolution)
					{
						0xC7, (ModRM 0 0 5), '&ResolutionX', (LE $Script:ResolutionWidth)  <# mov [&ResolutionX], $Script:ResolutionWidth #>
						0xC7, (ModRM 0 0 5), '&ResolutionY', (LE $Script:ResolutionHeight) <# mov [&ResolutionY], $Script:ResolutionHeight #>
					}

					0xA1, '&GameIsWindowed'                                                  <# mov eax, [&GameIsWindowed] #>
					0x25, 0xFF, 0xFF, 0xFE, 0xFF                                             <# and eax, ~(1 << 16) #>
					0x3B, (ModRM 0 0 5)	, '&GameIsWindowed'                                  <# cmp eax, [&GameIsWindowed] #>
					0x74, '1:PastSettingOfShouldEnableVerticalSync'                          <# je PastSettingOfShouldEnableVerticalSync #>
					0xC7, (ModRM 0 0 5), '&ShouldEnableVerticalSync', 0x01, 0x00, 0x00, 0x00 <# mov [&ShouldEnableVerticalSync], 1 #>
				'PastSettingOfShouldEnableVerticalSync:'
					0xA3, '&GameIsWindowed'                                                  <# mov [&GameIsWindowed], eax #>
					0x83, (ModRM 0 7 5), '&GameIsWindowed', 0x01                             <# cmp [&GameIsWindowed], 1 #>
					0x75, '1:SetNonWindowedGameWindowStyle'                                  <# jne SetNonWindowedGameWindowStyle #>
					0xC7, (ModRM 0 0 5), '&GameWindowStyle', 0x00, 0x00, 0xCF, 0x00          <# mov [&GameWindowStyle], 0x00CF0000 #>
					0xC7, (ModRM 0 0 5), '&GameWindowHasMenu', 0x01, 0x00, 0x00, 0x00        <# mov [&GameWindowHasMenu], 1 #>
					0xEB, '1:PastSettingOfGameWindowStyle'                                   <# jmp PastSettingOfGameWindowStyle #>
				'SetNonWindowedGameWindowStyle:'
					0xC7, (ModRM 0 0 5), '&GameWindowStyle', 0x00, 0x00, 0x00, 0x80          <# mov [&GameWindowStyle], 0x80000000 #>
					0x83, (ModRM 0 4 5), '&GameWindowHasMenu', 0x00                          <# and [&GameWindowHasMenu], 0 #>
				'PastSettingOfGameWindowStyle:'
					0x81, (ModRM 3 0 4), 0x14, 0x02, 0x00, 0x00                              <# add esp, 532 #>
				)


				Preassemble 'UseFullScreenOnlyWhenWinmodeIsZero[0]' (${&Direct3DDeviceCreation} + 69) (${@Direct3DDeviceCreation} + 69) @(
					0x83, (ModRM 0 7 5), '&GameIsWindowed', 0x00 <# cmp [&GameIsWindowed], 0 #>
				)

				Preassemble 'UseFullScreenOnlyWhenWinmodeIsZero[1]' (${&Direct3DDeviceCreation} + 77) (${@Direct3DDeviceCreation} + 77) @(
					0x74 <# je #>
				)


				Preassemble 'UseDiscardSwapEffectInFullscreenMode' (${&Direct3DDeviceCreation} + 125) (${@Direct3DDeviceCreation} + 125) @(
					0x01
				)


				$D3DPRESENT_INTERVAL_IMMEDIATE = 0x80000000
				$D3DPRESENT_RATE_UNLIMITED = 0x7fffffff


				Hijack 'DisableVSyncInFullscreenMode' 'Direct3DDeviceCreation' 129 6 @(
					0x83, (ModRM 0 7 5), '&ShouldEnableVerticalSync', 0x00                                                             <# cmp [&ShouldEnableVerticalSync], 0 #>
					0x74, '1:NotUsingVerticalSyncForPresentation'                                                                      <# je NotUsingVerticalSyncForPresentation #>
					0xC7, (ModRM 0 0 5), '&PresentationParametersFullScreen_PresentationInterval', 0x01, 0x00, 0x00, 0x00              <# mov [&PresentationParametersFullScreen_PresentationInterval], 1 #>
					0xEB, '1:PastSettingOfPresentationInterval'                                                                        <# jmp PastSettingOfPresentationInterval #>
				'NotUsingVerticalSyncForPresentation:'
					0xC7, (ModRM 0 0 5), '&PresentationParametersFullScreen_PresentationInterval', (LE $D3DPRESENT_INTERVAL_IMMEDIATE) <# mov [&PresentationParametersFullScreen_PresentationInterval], $D3DPRESENT_INTERVAL_IMMEDIATE #>
				'PastSettingOfPresentationInterval:'
				)


				#Hijack 'UnlimitedRefreshRateInFullscreenMode' 'Direct3DDeviceCreation' 135 6 @(
				#	0xC7, (ModRM 0 0 5), '&PresentationParametersFullScreen_RefreshRateInHz', (LE $D3DPRESENT_RATE_UNLIMITED) <# mov [&PresentationParametersFullScreen_RefreshRateInHz], $D3DPRESENT_RATE_UNLIMITED #>
				#)


				$WM_CREATE = 0x0001
				$WM_WINDOWPOSCHANGED = 0x0047
				$WM_DPICHANGED = 0x02E0
				$WM_GETDPISCALEDSIZE = 0x02E4

				$SWP_NOACTIVATE = 0x0010
				$SWP_NOCOPYBITS = 0x0100
				$SWP_NOZORDER = 0x0004

				$WindowLocationChangeFlags = $SWP_NOACTIVATE -bor $SWP_NOCOPYBITS -bor $SWP_NOZORDER

				Preassemble 'WindowProcedurePrefix' @(
					0x8B, (ModRM 1 0 4), (SIB 0 4 4), 0x08                   <# mov eax, [esp + 8] #>
					0x83, (ModRM 0 7 5), '&PatchIsDPIAware', 0x00            <# cmp [&PatchIsDPIAware], 0 #>
					0x0F, 0x84, '4:PastDPIAwareHandling'                     <# je PastDPIAwareHandling #>
					0x81, (ModRM 3 7 0), (LE $WM_DPICHANGED)                 <# cmp eax, $WM_DPICHANGED #>
					0x75, '1:PastWMDPIChangedHandling'                       <# jne PastWMDPIChangedHandling #>
					0x66, 0x8B, (ModRM 1 0 4), (SIB 0 4 4), 0x0C             <# mov eax, word ptr [esp + 12] #>
					0x8B, (ModRM 1 1 4), (SIB 0 4 4), 0x10                   <# mov ecx, [esp + 16] #>
					0xA3, '&GameWindowDPI'                                   <# mov [&GameWindowDPI], eax #>
					0x8B, (ModRM 1 2 1), 0x08                                <# mov edx, [ecx + 8] #>
					0x2B, (ModRM 0 2 1)                                      <# sub edx, [ecx] #>
					0x8B, (ModRM 1 0 1), 0x0C                                <# mov eax, [ecx + 12] #>
					0x2B, (ModRM 1 0 1), 0x04                                <# sub eax, [ecx + 4] #>
					0x68, (LE $WindowLocationChangeFlags)                    <# push $WindowLocationChangeFlags #>
					0x50                                                     <# push eax #>
					0x52                                                     <# push edx #>
					0xFF, (ModRM 1 6 1), 0x04                                <# push [ecx + 4] #>
					0xFF, (ModRM 0 6 1)                                      <# push [ecx] #>
					0x68, 0x00, 0x00, 0x00, 0x00                             <# push 0 #>
					0xFF, (ModRM 1 6 4), (SIB 0 4 4), 0x1C                   <# push [esp + 28] #>
					0xFF, (ModRM 0 2 5), '&SetWindowPos'                     <# call [&SetWindowPos] #>
					0x33, (ModRM 3 0 0)                                      <# xor eax, eax #>
					0xC2, 0x10, 0x00                                         <# ret 16 #>
				'PastWMDPIChangedHandling:'
					0x81, (ModRM 3 7 0), (LE $WM_GETDPISCALEDSIZE)           <# cmp eax, $WM_GETDPISCALEDSIZE #>
					0x75, '1:PastGetDPIScaledSizeHandling'                   <# jne PastGetDPIScaledSizeHandling #>
					0x68, '&ScratchRect'                                     <# push &ScratchRect #>
					0xFF, (ModRM 1 6 4), (SIB 0 4 4), 0x08                   <# push [esp + 8] #>
					0xFF, (ModRM 0 2 5), '&GetClientRect'                    <# call [&GetClientRect] #>
					0xFF, (ModRM 1 6 4), (SIB 0 4 4), 0x0C                   <# push [esp + 12] #>
					0x68, 0x00, 0x00, 0x00, 0x00                             <# push 0 #>
					0xFF, (ModRM 0 6 5), '&GameWindowHasMenu'                <# push [&GameWindowHasMenu] #>
					0xFF, (ModRM 0 6 5), '&GameWindowStyle'                  <# push [&GameWindowStyle] #>
					0x68, '&ScratchRect'                                     <# push &ScratchRect #>
					0xFF, (ModRM 0 2 5), '&AdjustWindowRectExForDpi'         <# call [&AdjustWindowRectExForDpi] #>
					0x8B, (ModRM 1 1 4), (SIB 0 4 4), 0x10                   <# mov ecx, [esp + 16] #>
					0xA1, '&ScratchRectRight'                                <# mov eax, [&ScratchRectRight] #>
					0x2B, (ModRM 0 0 5), '&ScratchRectLeft'                  <# sub eax, [&ScratchRectLeft] #>
					0x89, (ModRM 0 0 1)                                      <# mov [ecx], eax #>
					0x8B, (ModRM 0 2 5), '&ScratchRectBottom'                <# mov edx, [&ScratchRectBottom] #>
					0x2B, (ModRM 0 2 5), '&ScratchRectTop'                   <# sub edx, [&ScratchRectTop] #>
					0x89, (ModRM 1 2 1), 0x04                                <# mov [ecx + 4], edx #>
					0xC2, 0x10, 0x00                                         <# ret 16 #>
				'PastGetDPIScaledSizeHandling:'
				'PastDPIAwareHandling:'
					0x83, (ModRM 3 7 0), (LE ([SByte] $WM_WINDOWPOSCHANGED)) <# cmp eax, $WM_WINDOWPOSCHANGED #>
					0x0F, 0x85, '4:PastWMWindowPosChangedHandling'           <# jne PastWMWindowPosChangedHandling #>
					0x8B, (ModRM 1 1 4), (SIB 0 4 4), 0x10                   <# mov ecx, [esp + 16] #>
					0x8B, (ModRM 1 0 1), 0x08                                <# mov eax, [ecx + 8] #>
					0x8B, (ModRM 1 2 1), 0x0C                                <# mov edx, [ecx + 12] #>
					0xA3, '&CurrentWindowX'                                  <# mov [&CurrentWindowX], eax #>
					0x8B, (ModRM 1 0 1), 0x10                                <# mov eax, [ecx + 16] #>
					0x89, (ModRM 0 2 5), '&CurrentWindowY'                   <# mov [&CurrentWindowY], edx #>
					0x8B, (ModRM 1 2 1), 0x14                                <# mov edx, [ecx + 20] #>
					0xA3, '&CurrentWindowWidth'                              <# mov [&CurrentWindowWidth], eax #>
					0x89, (ModRM 0 2 5), '&CurrentWindowHeight'              <# mov [&CurrentWindowHeight], edx #>
					0x68, '&ScratchRect'                                     <# push &ScratchRect #>
					0xFF, (ModRM 1 6 4), (SIB 0 4 4), 0x08                   <# push [esp + 8] #>
					0xFF, (ModRM 0 2 5), '&GetClientRect'                    <# call [&GetClientRect] #>
					0xA1, '&ScratchRectRight'                                <# mov eax, [&ScratchRectRight] #>
					0x8B, (ModRM 0 2 5), '&ScratchRectBottom'                <# mov edx, [&ScratchRectBottom] #>
					0xA3, '&CurrentClientAreaWidth'                          <# mov [&CurrentClientAreaWidth], eax #>
					0x89, (ModRM 0 2 5), '&CurrentClientAreaHeight'          <# mov [&CurrentClientAreaHeight], edx #>
					0x83, (ModRM 0 7 5), '&WindowAspectRatioIsFixed', 0x00   <# cmp [&WindowAspectRatioIsFixed], 0 #>
					0x0F, 0x84, '4:PastFixedWindowAspectRatioAdjustments'    <# je PastFixedWindowAspectRatioAdjustments #>
					0xA1, '&CurrentClientAreaHeight'                         <# mov eax, [&CurrentClientAreaHeight] #>
					0xBA, (LE $PatchedAspectRatioNumerator)                  <# mov edx, $PatchedAspectRatioNumerator #>
					0xF7, (ModRM 3 4 2)                                      <# mul edx #>
					0xB9, (LE $PatchedAspectRatioDenominator)                <# mov ecx, $PatchedAspectRatioDenominator #>
					0xF7, (ModRM 3 6 1)                                      <# div ecx #>
					0x8B, (ModRM 0 2 5), '&CurrentClientAreaHeight'          <# mov edx, [&CurrentClientAreaHeight] #>
					0xA3, '&ScratchRectRight'                                <# mov [&ScratchRectRight], eax #>
					0x89, (ModRM 0 2 5), '&ScratchRectBottom'                <# mov [&ScratchRectBottom], edx #>
					0x83, (ModRM 0 4 5), '&ScratchRectLeft', 0x00            <# and [&ScratchRectLeft], 0 #>
					0x83, (ModRM 0 4 5), '&ScratchRectTop', 0x00             <# and [&ScratchRectTop], 0 #>
					0x83, (ModRM 0 7 5), '&PatchIsDPIAware', 0x00            <# cmp [&PatchIsDPIAware], 0 #>
					0x0F, 0x84, '4:NonDPIAwareAdjustmentOfResizedWindowSize' <# je NonDPIAwareAdjustmentOfResizedWindowSize #>
					0xB9, '&AdjustWindowRectExForDpi'                        <# mov ecx, &AdjustWindowRectExForDpi #>
					0xFF, (ModRM 0 6 5), '&GameWindowDPI'                    <# push [&GameWindowDPI] #>
					0x68, 0x00, 0x00, 0x00, 0x00                             <# push 0 #>
					0xEB, '1:AdjustmentOfResizedWindowSize'                  <# jmp AdjustmentOfResizedWindowSize #>
				'NonDPIAwareAdjustmentOfResizedWindowSize:'
					0xB9, '&AdjustWindowRect'                                <# mov ecx, &AdjustWindowRect #>
				'AdjustmentOfResizedWindowSize:'
					0xFF, (ModRM 0 6 5), '&GameWindowHasMenu'                <# push [&GameWindowHasMenu] #>
					0xFF, (ModRM 0 6 5), '&GameWindowStyle'                  <# push [&GameWindowStyle] #>
					0x68, '&ScratchRect'                                     <# push &ScratchRect #>
					0xFF, (ModRM 0 2 1)                                      <# call [ecx] #>
					0xA1, '&ScratchRectRight'                                <# mov eax, [&ScratchRectRight] #>
					0x2B, (ModRM 0 0 5), '&ScratchRectLeft'                  <# sub eax, [&ScratchRectLeft] #>
					0x8B, (ModRM 0 2 5), '&ScratchRectBottom'                <# mov edx, [&ScratchRectBottom] #>
					0x2B, (ModRM 0 2 5), '&ScratchRectTop'                   <# sub edx, [&ScratchRectTop] #>
					0x68, 0x01, 0x00, 0x00, 0x00                             <# push 1 #>
					0x52                                                     <# push edx #>
					0x50                                                     <# push eax #>
					0xFF, (ModRM 0 6 5), '&CurrentWindowY'                   <# push [&CurrentWindowY] #>
					0xFF, (ModRM 0 6 5), '&CurrentWindowX'                   <# push [&CurrentWindowX] #>
					0xFF, (ModRM 0 6 5), '&GameWindowHWnd'                   <# push [&GameWindowHWnd] #>
					0xFF, (ModRM 0 2 5), '&MoveWindow'                       <# call [&MoveWindow] #>
				'PastFixedWindowAspectRatioAdjustments:'
					0x33, (ModRM 3 0 0)                                      <# xor eax, eax #>
					0xC2, 0x10, 0x00                                         <# ret 16 #>
				'PastWMWindowPosChangedHandling:'
					0x83, (ModRM 3 7 0), (LE ([SByte] $WM_CREATE))           <# cmp eax, $WM_CREATE #>
					0x75, '1:PastWMCreateHandling'                           <# jne PastWMCreateHandling #>
					0xFF, (ModRM 1 6 4), (SIB 0 4 4), 0x04                   <# push [esp + 4] #>
					0xFF, (ModRM 0 2 5), '&GetDpiForWindow'                  <# call [&GetDpiForWindow] #>
					0xA3, '&GameWindowDPI'                                   <# mov [&GameWindowDPI], eax #>
				'PastWMCreateHandling:'
				'JumpToOriginalWindowProcedure:'
					0xE9, '4:WindowProcedure'                                <# jmp WindowProcedure #>
				)


				Preassemble 'HookWindowProcedure' (${&WindowCreation} + 55) (${@WindowCreation} + 55) @((LE (${&WindowProcedurePrefix} + $ImageBase)))


				Hijack 'GiveTheWindowAMenuOnlyInWindowedMode' 'WindowCreation' 116 6 @(
					0x33, (ModRM 3 0 0)                           <# xor eax, eax #>
					0x83, (ModRM 0 7 5), '&GameIsWindowed', 0x01  <# cmp [&GameIsWindowed], 1 #>
					0x75, '1:PastAssignmentOfWindowClassMenuName' <# jne PastAssignmentOfWindowClassMenuName #>
					0xB0, (LE ([Byte] 183))                       <# mov al, 183 #>
				'PastAssignmentOfWindowClassMenuName:'
					0x89, (ModRM 1 0 5), 0xCC                     <# mov [ebp - 52], eax #>
					0x8D, (ModRM 1 0 5), 0xA8                     <# lea eax, [ebp - 88] #>
				)


				Preassemble 'InitialWindowSizeHijack' (${&WindowCreation} + 323) (${@WindowCreation} + 323) @(
					0xE9, '4:SetTheInitialSizeOfTheWindowProperly' <# jmp SetTheInitialSizeOfTheWindowProperly #>
					(Get-Nop 9)                                    <# nop #>
					(Get-Nop 8)                                    <# nop #>
				'PostInitialWindowSizeHijack:'
				)


				$MONITOR_DEFAULTTONEAREST = 0x00000002


				Hijack 'CentreTheWindowIfItIsBorderless' 'WindowCreation' 390 5 @(
					0xA3, '&GameWindowHWnd'                                  <# mov [&GameWindowHWnd], eax #>
					0xA1, '&GameIsWindowed'                                  <# mov eax, [&GameIsWindowed] #>
					0x25, 0xFF, 0xFF, 0xFE, 0xFF                             <# and eax, ~(1 << 16) #>
					0x83, (ModRM 3 7 0), 0x02                                <# cmp eax, 2 #>
					0x0F, 0x82, '4:PastCentringOfBorderlessWindow'           <# jb PastCentringOfBorderlessWindow #>
					0x68, '&ScratchRect'                                     <# push &ScratchRect #>
					0xFF, (ModRM 0 6 5), '&GameWindowHWnd'                   <# push [&GameWindowHWnd] #>
					0xFF, (ModRM 0 2 5), '&GetClientRect'                    <# call [&GetClientRect] #>
					0x68, (LE $MONITOR_DEFAULTTONEAREST)                     <# push $MONITOR_DEFAULTTONEAREST #>
					0xFF, (ModRM 0 6 5), '&GameWindowHWnd'                   <# push [&GameWindowHWnd] #>
					0xFF, (ModRM 0 2 5), '&MonitorFromWindow'                <# call [&MonitorFromWindow] #>
					0x83, (ModRM 3 5 4), 0x28                                <# sub esp, 40 #>
					0x8D, (ModRM 0 2 4), (SIB 0 4 4)                         <# lea edx, [esp] #>
					0xC7, (ModRM 0 0 2), 0x28, 0x00, 0x00, 0x00              <# mov [edx], 40 #>
					0x52                                                     <# push edx #>
					0x50                                                     <# push eax #>
					0xFF, (ModRM 0 2 5), '&GetMonitorInfoW'                  <# call [&GetMonitorInfoW] #>
					0xA1, '&ScratchRectRight'                                <# mov eax, [&ScratchRectRight] #>
					0x2B, (ModRM 0 0 5), '&ScratchRectLeft'                  <# sub eax, [&ScratchRectLeft] #>
					0x8B, (ModRM 1 2 4), (SIB 0 4 4), 0x0C                   <# mov edx, [esp + 12] #>
					0x2B, (ModRM 1 2 4), (SIB 0 4 4), 0x04                   <# sub edx, [esp + 4] #>
					0x2B, (ModRM 3 2 0)                                      <# sub edx, eax #>
					0xD1, (ModRM 3 5 2)                                      <# shr edx, 1 #>
					0x03, (ModRM 1 2 4), (SIB 0 4 4), 0x04                   <# add edx, [esp + 4] #>
					0x8B, (ModRM 3 6 2)                                      <# mov esi, edx #>
					0xA1, '&ScratchRectBottom'                               <# mov eax, [&ScratchRectBottom] #>
					0x2B, (ModRM 0 0 5), '&ScratchRectTop'                   <# sub eax, [&ScratchRectTop] #>
					0x8B, (ModRM 1 2 4), (SIB 0 4 4), 0x10                   <# mov edx, [esp + 16] #>
					0x2B, (ModRM 1 2 4), (SIB 0 4 4), 0x08                   <# sub edx, [esp + 8] #>
					0x2B, (ModRM 3 2 0)                                      <# sub edx, eax #>
					0xD1, (ModRM 3 5 2)                                      <# shr edx, 1 #>
					0x03, (ModRM 1 2 4), (SIB 0 4 4), 0x08                   <# add edx, [esp + 8] #>
					0x8B, (ModRM 3 7 2)                                      <# mov edi, edx #>
					0x83, (ModRM 3 0 4), 0x28                                <# add esp, 40 #>
					0xA1, '&ScratchRectRight'                                <# mov eax, [&ScratchRectRight] #>
					0x2B, (ModRM 0 0 5), '&ScratchRectLeft'                  <# sub eax, [&ScratchRectLeft] #>
					0x8B, (ModRM 0 2 5), '&ScratchRectBottom'                <# mov edx, [&ScratchRectBottom] #>
					0x2B, (ModRM 0 2 5), '&ScratchRectTop'                   <# sub edx, [&ScratchRectTop] #>
					0x68, 0x01, 0x00, 0x00, 0x00                             <# push 1 #>
					0x52                                                     <# push edx #>
					0x50                                                     <# push eax #>
					0x57                                                     <# push edi #>
					0x56                                                     <# push esi #>
					0xFF, (ModRM 0 6 5), '&GameWindowHWnd'                   <# push [&GameWindowHWnd] #>
					0xFF, (ModRM 0 2 5), '&MoveWindow'                       <# call [&MoveWindow] #>
				'PastCentringOfBorderlessWindow:'
				)


				Preassemble 'SetTheInitialSizeOfTheWindowProperly' @(
					0x83, (ModRM 0 4 5), '&ScratchRectLeft', 0x00            <# and [&ScratchRectLeft], 0 #>
					0x83, (ModRM 0 4 5), '&ScratchRectTop', 0x00             <# and [&ScratchRectTop], 0 #>
					0xA1, '&PrecalculatedClientArea[0]Width'                 <# mov eax, [&PrecalculatedClientArea[0]Width] #>
					0x8B, (ModRM 0 2 5), '&PrecalculatedClientArea[0]Height' <# mov edx, [&PrecalculatedClientArea[0]Height] #>
					0xA3, '&ScratchRectRight'                                <# mov [&ScratchRectRight], eax #>
					0x89, (ModRM 0 2 5), '&ScratchRectBottom'                <# mov [&ScratchRectBottom], edx #>
					0x83, (ModRM 0 7 5), '&PatchIsDPIAware', 0x00            <# cmp [&PatchIsDPIAware], 0 #>
					0x0F, 0x84, '4:NonDPIAwareAdjustmentOfInitialWindowSize' <# je NonDPIAwareAdjustmentOfInitialWindowSize #>
					0xB9, '&AdjustWindowRectExForDpi'                        <# mov ecx, &AdjustWindowRectExForDpi #>
					0xFF, (ModRM 0 6 5), '&GameWindowDPI'                    <# push [&GameWindowDPI] #>
					0x68, 0x00, 0x00, 0x00, 0x00                             <# push 0 #>
					0xEB, '1:AdjustmentOfInitialWindowSize'                  <# jmp AdjustmentOfInitialWindowSize #>
				'NonDPIAwareAdjustmentOfInitialWindowSize:'
					0xB9, '&AdjustWindowRect'                                <# mov ecx, &AdjustWindowRect #>
				'AdjustmentOfInitialWindowSize:'
					0xFF, (ModRM 0 6 5), '&GameWindowHasMenu'                <# push [&GameWindowHasMenu] #>
					0xFF, (ModRM 0 6 5), '&GameWindowStyle'                  <# push [&GameWindowStyle] #>
					0x68, '&ScratchRect'                                     <# push &ScratchRect #>
					0xFF, (ModRM 0 2 1)                                      <# call [ecx] #>
					0xA1, '&ScratchRectRight'                                <# mov eax, [&ScratchRectRight] #>
					0x2B, (ModRM 0 0 5), '&ScratchRectLeft'                  <# sub eax, [&ScratchRectLeft] #>
					0x8B, (ModRM 0 2 5), '&ScratchRectBottom'                <# mov edx, [&ScratchRectBottom] #>
					0x2B, (ModRM 0 2 5), '&ScratchRectTop'                   <# sub edx, [&ScratchRectTop] #>
					0x68, 0x01, 0x00, 0x00, 0x00                             <# push 1 #>
					0x52                                                     <# push edx #>
					0x50                                                     <# push eax #>
					0xFF, (ModRM 1 6 5), 0xDC                                <# push [ebp - 36] #>
					0xFF, (ModRM 1 6 5), 0xD8                                <# push [ebp - 40] #>
					0xFF, (ModRM 0 6 5), '&GameWindowHWnd'                   <# push [&GameWindowHWnd] #>
					0xFF, (ModRM 0 2 5), '&MoveWindow'                       <# call [&MoveWindow] #>
					0xE9, '4:PostInitialWindowSizeHijack'                    <# jmp PostInitialWindowSizeHijack #>
				)


				Preassemble 'AdjustTheInitialWindowSizeOnlyWhenAppropriate' @(
					0x83, (ModRM 0 7 5), '&GameIsWindowed', 0x02 <# cmp [&GameIsWindowed], 2 #>
					0x73, '1:DoNotAdjustTheInitialWindowSize'    <# jae DoNotAdjustTheInitialWindowSize #>
					0xFF, (ModRM 0 4 5), '&AdjustWindowRect'     <# jmp [&AdjustWindowRect] #>
				'DoNotAdjustTheInitialWindowSize:'
					0xC2, 0x0C, 0x00                             <# ret 12 #>
				)


				Preassemble 'AdjustTheInitialWindowSizeOnlyWhenAppropriateHijack' (${&WindowCreation} + 176) (${@WindowCreation} + 176) @(
					0xE8, '4:AdjustTheInitialWindowSizeOnlyWhenAppropriate' <# call AdjustTheInitialWindowSizeOnlyWhenAppropriate #>
					0x90                                                    <# nop #>
				)


				Preassemble 'WindowScalingSizeHijack' (${&WindowProcedure} + 567) (${@WindowProcedure} + 567) @(
					0xE9, '4:SetTheWindowScalingSizesProperly' <# jmp SetTheWindowScalingSizesProperly #>
				)


				Preassemble 'PostWindowScalingSizeHijack' (${&WindowProcedure} + 682) (${@WindowProcedure} + 682) @()


				Preassemble 'SetTheWindowScalingSizesProperly' @(
					0x8B, (ModRM 0 0 4), (SIB 3 1 5), '&PrecalculatedClientArea[0]Width'  <# mov eax, [&PrecalculatedClientArea[0]Width + ecx * 8] #>
					0x8B, (ModRM 0 2 4), (SIB 3 1 5), '&PrecalculatedClientArea[0]Height' <# mov edx, [&PrecalculatedClientArea[0]Height + ecx * 8] #>
					0xA3, '&ScratchRectRight'                                             <# mov [&ScratchRectRight], eax #>
					0x89, (ModRM 0 2 5), '&ScratchRectBottom'                             <# mov [&ScratchRectBottom], edx #>
					0x83, (ModRM 0 4 5), '&ScratchRectLeft', 0x00                         <# and [&ScratchRectLeft], 0 #>
					0x83, (ModRM 0 4 5), '&ScratchRectTop', 0x00                          <# and [&ScratchRectTop], 0 #>
					0x83, (ModRM 0 7 5), '&PatchIsDPIAware', 0x00                         <# cmp [&PatchIsDPIAware], 0 #>
					0x0F, 0x84, '4:NonDPIAwareAdjustmentOfScaledWindowSize'               <# je NonDPIAwareAdjustmentOfScaledWindowSize #>
					0xB9, '&AdjustWindowRectExForDpi'                                     <# mov ecx, &AdjustWindowRectExForDpi #>
					0xFF, (ModRM 0 6 5), '&GameWindowDPI'                                 <# push [&GameWindowDPI] #>
					0x68, 0x00, 0x00, 0x00, 0x00                                          <# push 0 #>
					0xEB, '1:AdjustmentOfScaledWindowSize'                                <# jmp AdjustmentOfScaledWindowSize #>
				'NonDPIAwareAdjustmentOfScaledWindowSize:'
					0xB9, '&AdjustWindowRect'                                             <# mov ecx, &AdjustWindowRect #>
				'AdjustmentOfScaledWindowSize:'
					0xFF, (ModRM 0 6 5), '&GameWindowHasMenu'                             <# push [&GameWindowHasMenu] #>
					0xFF, (ModRM 0 6 5), '&GameWindowStyle'                               <# push [&GameWindowStyle] #>
					0x68, '&ScratchRect'                                                  <# push &ScratchRect #>
					0xFF, (ModRM 0 2 1)                                                   <# call [ecx] #>
					0xA1, '&ScratchRectRight'                                             <# mov eax, [&ScratchRectRight] #>
					0x2B, (ModRM 0 0 5), '&ScratchRectLeft'                               <# sub eax, [&ScratchRectLeft] #>
					0x8B, (ModRM 0 2 5), '&ScratchRectBottom'                             <# mov edx, [&ScratchRectBottom] #>
					0x2B, (ModRM 0 2 5), '&ScratchRectTop'                                <# sub edx, [&ScratchRectTop] #>
					0x68, 0x01, 0x00, 0x00, 0x00                                          <# push 1 #>
					0x52                                                                  <# push edx #>
					0x50                                                                  <# push eax #>
					0xFF, (ModRM 0 6 5), '&CurrentWindowY'                                <# push [&CurrentWindowY] #>
					0xFF, (ModRM 0 6 5), '&CurrentWindowX'                                <# push [&CurrentWindowX] #>
					0xFF, (ModRM 0 6 5), '&GameWindowHWnd'                                <# push [&GameWindowHWnd] #>
					0xFF, (ModRM 0 2 5), '&MoveWindow'                                    <# call [&MoveWindow] #>
					0xE9, '4:PostWindowScalingSizeHijack'                                 <# jmp PostWindowScalingSizeHijack #>
				)


				Preassemble 'IncrementStateSharedThrottle' @(
					0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00                         <# cmp [&PresentationFrameIndex], 0 #>
					0x75, '1:PastCallOfIncrementStateSharedBetweenGameFrameAndPresentationFrame' <# jne PastCallOfIncrementStateSharedBetweenGameFrameAndPresentationFrame #>
					0xE8, '4:IncrementStateSharedBetweenGameFrameAndPresentationFrame'           <# call IncrementStateSharedBetweenGameFrameAndPresentationFrame #>
				'PastCallOfIncrementStateSharedBetweenGameFrameAndPresentationFrame:'
					0xE9, '4:PresentFrame + 21'                                                  <# jmp [&PresentFrame + 21] #>
				)


				Preassemble 'PauseTransitionEffectSpeedFix' @(
					0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00       <# cmp [&PresentationFrameIndex], 0 #>
					0x0F, 0x85, '4:AfterPauseTransitionEffectConditional'      <# jne AfterPauseTransitionEffectConditional #>
				'TestPauseTransitionEffectConditional:'
					0x39, (ModRM 0 6 5), '&GameIsPaused?'                      <# cmp GameIsPaused?, esi #>
					0xE9, '4:PostPauseTransitionEffectConditionalHijack'       <# jmp PostPauseTransitionEffectConditionalHijack #>
				)


				Preassemble 'PauseTransitionEffectConditionalHijack' ${&PauseTransitionEffectConditional} ${@PauseTransitionEffectConditional} @(
					0xE9, '4:PauseTransitionEffectSpeedFix' <# jmp PauseTransitionEffectSpeedFix #>
					0x90                                    <# nop #>
				'PostPauseTransitionEffectConditionalHijack:'
				)


				Preassemble 'PauseTransitionEffectMalfunctionFix' @(
					0x0F, 0x85, '4:AfterPauseTransitionEffectMalfunctionConditional' <# jne AfterPauseTransitionEffectMalfunctionConditional #>
					0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00             <# cmp [&PresentationFrameIndex], 0 #>
					0x0F, 0x85, '4:AfterPauseTransitionEffectMalfunctionConditional' <# jne AfterPauseTransitionEffectMalfunctionConditional #>
					0xE9, '4:PostPauseTransitionEffectMalfunctionFixHijack'          <# jmp PostPauseTransitionEffectMalfunctionFixHijack #>
				)


				Preassemble 'PauseTransitionEffectMalfunctionFixHijack' (${&PauseMenuFreezeEffect} + 323) (${@PauseMenuFreezeEffect} + 323) @(
					0xE9, '4:PauseTransitionEffectMalfunctionFix' <# jmp PauseTransitionEffectMalfunctionFix #>
					0x90                                          <# nop #>
				'PostPauseTransitionEffectMalfunctionFixHijack:'
				)


				Preassemble 'AfterPauseTransitionEffectMalfunctionConditional' (${&PauseMenuFreezeEffect} + 988) (${@PauseMenuFreezeEffect} + 988) @()


				Preassemble 'IncrementSelectedSaveSlotPulsatingEffectCounterSpeedFix' @(
					0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00                <# cmp [&PresentationFrameIndex], 0 #>
					0x75, '1:PastIncrementOfSelectedSaveSlotPulsatingEffectCounter'     <# jne PastIncrementOfSelectedSaveSlotPulsatingEffectCounter #>
					0xFF, (ModRM 0 0 5), '&SelectedSaveSlotPulsatingEffectCounter'      <# inc [&SelectedSaveSlotPulsatingEffectCounter] #>
				'PastIncrementOfSelectedSaveSlotPulsatingEffectCounter:'
					0xE9, '4:PostIncrementSelectedSaveSlotPulsatingEffectCounterHijack' <# jmp PostIncrementSelectedSaveSlotPulsatingEffectCounterHijack #>
				)


				Preassemble 'IncrementSelectedSaveSlotPulsatingEffectCounterHijack' ${&IncrementSelectedSaveSlotPulsatingEffectCounter} ${@IncrementSelectedSaveSlotPulsatingEffectCounter} @(
					0xE9, '4:IncrementSelectedSaveSlotPulsatingEffectCounterSpeedFix' <# jmp IncrementSelectedSaveSlotPulsatingEffectCounterSpeedFix #>
					0x90                                    <# nop #>
				'PostIncrementSelectedSaveSlotPulsatingEffectCounterHijack:'
				)


				Preassemble 'LoadingDiscSpinRateFix' (${&ShowNowLoadingMessage} + 263) (${@ShowNowLoadingMessage} + 263) @('&LoadingDiscSpinRate')


				Preassemble 'CallSetTextureStageStateOnTheDirect3DDevice' @(
					0xA1, '&Direct3DDevice'                     <# mov eax, [&Direct3DDevice] #>
					0x5A                                        <# pop edx #>
					0x50                                        <# push eax #>
					0x8B, (ModRM 0 1 0)                         <# mov ecx, [eax] #>
					0x52                                        <# push edx #>
					0xFF, (ModRM 2 4 1), 0xFC, 0x00, 0x00, 0x00 <# jmp [ecx + 0xFC] #>
				)


				Preassemble 'InterpolateCameraHeight' @(
					if ($Script:CameraSmoothingVariant -eq 'InterpolatedV2')
					{
						if ($InterpolatingFloats.PlayerCharacterPosition)
						{
							0x83, (ModRM 0 7 5), '&FloatsWereInterpolated', 0x00                 <# cmp [&FloatsWereInterpolated], 0 #>
							0x74, '1:PastCameraHeightRestorationOfTargetPlayerCharacterPosition' <# je PastCameraHeightRestorationOfTargetPlayerCharacterPosition #>
							$RestoreTargetPlayerCharacterPosition
						}
					'PastCameraHeightRestorationOfTargetPlayerCharacterPosition:'

						0x83, (ModRM 0 7 5), '&ShouldInitialiseCameraPositions', 0x00  <# cmp [&ShouldInitialiseCameraPositions], 0 #>
						0x75, '1:InitialisingCameraHeight'                             <# jnz InitialisingCameraHeight #>
						0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00           <# cmp [&PresentationFrameIndex], 0 #>
						0x75, '1:SetCameraHeight'                                      <# jnz SetCameraHeight #>
						0xEB, '1:SmoothingCameraHeight'                                <# jmp SmoothingCameraHeight #>
					'InitialisingCameraHeight:'
						0xD9, (ModRM 0 0 5), '&CameraHeightInitialisationAdjustment'   <# fld [&CameraHeightInitialisationAdjustment] #>
						0xD9, 0xEE                                                     <# fldz #>
						0xD9, (ModRM 2 0 5), (LE $CameraHeightStackOffset)             <# fld [ebp + $CameraHeightStackOffset] #>
						0xD8, 0xC2                                                     <# fadd st(0), st(2) #>
						0xD9, (ModRM 0 2 5), '&CameraHeight'                           <# fst [&CameraHeight] #>
						0xD9, (ModRM 0 3 5), '&HeldCameraHeight'                       <# fstp [&HeldCameraHeight] #>
						0xD9, (ModRM 0 2 5), '&CameraHeightDelta'                      <# fst [&CameraHeightDelta] #>
						0xD9, 0xE8                                                     <# fld1 #>
						0xEB, '1:BeforeSetCameraHeight'                                <# jmp BeforeSetCameraHeight #>
					'SmoothingCameraHeight:'
						0xD9, (ModRM 0 0 5), '&CameraHeightSmoothingAdjustment'        <# fld [&CameraHeightSmoothingAdjustment] #>
						0xD9, (ModRM 0 0 5), '&CameraHeightSmoothingDivsor'            <# fld [&CameraHeightSmoothingDivsor] #>
						0xD9, (ModRM 2 0 5), (LE $CameraHeightStackOffset)             <# fld [ebp + $CameraHeightStackOffset] #>
						0xD9, (ModRM 0 0 5), '&CameraHeight'                           <# fld [&CameraHeight] #>
						0xD9, (ModRM 0 2 5), '&HeldCameraHeight'                       <# fst [&HeldCameraHeight] #>
						0xDE, 0xE9                                                     <# fsubp #>
						0xD9, (ModRM 0 3 5), '&CameraHeightDelta'                      <# fstp [&CameraHeightDelta] #>
					'BeforeSetCameraHeight:'
						0xD9, (ModRM 0 3 5), '&CurrentCameraHeightSmoothingDivisor'    <# fstp [&CurrentCameraHeightSmoothingDivisor] #>
						0xD9, (ModRM 0 3 5), '&CurrentCameraHeightSmoothingAdjustment' <# fstp [&CurrentCameraHeightSmoothingAdjustment] #>
					'SetCameraHeight:'
						0xD9, (ModRM 0 0 5), '&CameraHeightDelta'                      <# fld [&CameraHeightDelta] #>
						0xD8, (ModRM 0 1 5), '&FrameInterpolationValue'                <# fmul [&FrameInterpolationValue] #>
						0xD8, (ModRM 0 6 5), '&CurrentCameraHeightSmoothingDivisor'    <# fdiv [&CurrentCameraHeightSmoothingDivisor] #>
						0xD9, (ModRM 0 0 5), '&CurrentCameraHeightSmoothingAdjustment' <# fld [&CurrentCameraHeightSmoothingAdjustment] #>
						0xD8, (ModRM 0 1 5), '&FrameInterpolationValue'                <# fmul [&FrameInterpolationValue] #>
						0xDE, 0xC1                                                     <# faddp #>
						0xD8, (ModRM 0 0 5), '&HeldCameraHeight'                       <# fadd [&HeldCameraHeight] #>
						0xD9, (ModRM 0 3 5), '&CameraHeight'                           <# fstp [&CameraHeight] #>

						if ($InterpolatingFloats.PlayerCharacterPosition)
						{
							0x83, (ModRM 0 7 5), '&FloatsWereInterpolated', 0x00                       <# cmp [&FloatsWereInterpolated], 0 #>
							0x74, '1:PastCameraHeightRestorationOfInterpolatedPlayerCharacterPosition' <# je PastCameraHeightRestorationOfInterpolatedPlayerCharacterPosition #>
							$RestoreInterpolatedPlayerCharacterPosition
						}
					'PastCameraHeightRestorationOfInterpolatedPlayerCharacterPosition:'

						0xE9, '4:PostCameraHeightSmoothingHijack' <# jmp PostCameraSmoothingHijack #>
					}
				)


				Preassemble 'InterpolateCameraPositions' @(
					if ($Script:CameraSmoothingVariant -eq 'InterpolatedV2')
					{
						if ($InterpolatingFloats.PlayerCharacterPosition)
						{
							0x83, (ModRM 0 7 5), '&FloatsWereInterpolated', 0x00                   <# cmp [&FloatsWereInterpolated], 0 #>
							0x74, '1:PastCameraPositionRestorationOfTargetPlayerCharacterPosition' <# je PastCameraPositionRestorationOfTargetPlayerCharacterPosition #>
							$RestoreTargetPlayerCharacterPosition
						}
					'PastCameraPositionRestorationOfTargetPlayerCharacterPosition:'

						0x83, (ModRM 0 7 5), '&ShouldInitialiseCameraPositions', 0x00 <# cmp [&ShouldInitialiseCameraPositions], 0 #>
						0x75, '1:InitialisingCameraPositions'                         <# jnz InitialisingCameraPositions #>
						0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00          <# cmp [&PresentationFrameIndex], 0 #>
						0x0F, 0x85, '4:SetCameraPositions'                            <# jnz SetCameraPositions #>
						0xE9, '4:SmoothingCameraPositions'                            <# jmp SmoothingCameraPositions #>
					'InitialisingCameraPositions:'
						0xD9, 0xE8                                                    <# fld1 #>
						0xD9, 0xEE                                                    <# fldz #>

						for ($Index = 0; $Index -lt $CameraPositionCount; ++$Index)
						{
							0xD9, (ModRM 2 0 5), (LE $CameraPositionStackOffsets[$Index]) <# fld [ebp + $CameraPositionStackOffsets[$Index]] #>
							0xD9, (ModRM 0 2 5), (LE ${&CameraPositions[]}[$Index])       <# fst [&CameraPositions[$Index]] #>
							0xD9, (ModRM 0 3 5), (LE ${&HeldCameraPositions[]}[$Index])   <# fstp [&HeldCameraPositions[$Index]] #>
							0xD9, (ModRM 0 2 5), (LE ${&CameraPositionDeltas[]}[$Index])  <# fst [&CameraPositionDeltas[$Index]] #>
						}

						0xDD, 0xD8                                     <# fstp st(0) #>
						0xE9, '4:BeforeSetCameraPositions'             <# jmp BeforeSetCameraPositions #>
					'SmoothingCameraPositions:'
						0xD9, (ModRM 0 0 5), '&CameraSmoothingDivisor' <# fld [&CameraSmoothingDivisor] #>

						for ($Index = 0; $Index -lt $CameraPositionCount; ++$Index)
						{
							0xD9, (ModRM 2 0 5), (LE $CameraPositionStackOffsets[$Index]) <# fld [ebp + $CameraPositionStackOffsets[$Index]] #>
							0xD9, (ModRM 0 0 5), (LE ${&CameraPositions[]}[$Index])       <# fld [&CameraPositions[$Index]] #>
							0xD9, (ModRM 0 2 5), (LE ${&HeldCameraPositions[]}[$Index])   <# fst [&HeldCameraPositions[$Index]] #>
							0xDE, 0xE9                                                    <# fsubp #>
							0xD9, (ModRM 0 3 5), (LE ${&CameraPositionDeltas[]}[$Index])  <# fstp [&CameraPositionDeltas[$Index]] #>
						}

					'BeforeSetCameraPositions:'
						0xD9, (ModRM 0 3 5), '&CurrentCameraSmoothingDivisor' <# fstp [&CurrentCameraSmoothingDivisor] #>
					'SetCameraPositions:'
						0xD9, (ModRM 0 0 5), '&CurrentCameraSmoothingDivisor' <# fld [&CurrentCameraSmoothingDivisor] #>
						0xD9, (ModRM 0 0 5), '&FrameInterpolationValue'       <# fld [&FrameInterpolationValue] #>

						for ($Index = 0; $Index -lt $CameraPositionCount; ++$Index)
						{
							0xD9, (ModRM 0 0 5), (LE ${&CameraPositionDeltas[]}[$Index]) <# fld [&CameraPositionDeltas[$Index]] #>
							0xD8, 0xF2                                                   <# fdiv st(0), st(2) #>
							0xD8, 0xC9                                                   <# fmul st(0), st(1) #>
							0xD8, (ModRM 0 0 5), (LE ${&HeldCameraPositions[]}[$Index])  <# fadd [&HeldCameraPositions[$Index]] #>
							0xD9, (ModRM 0 3 5), (LE ${&CameraPositions[]}[$Index])      <# fstp [&CameraPositions[$Index]] #>
						}

						0xDD, 0xD8                                                                   <# fstp st(0) #>
						0xDD, 0xD8                                                                   <# fstp st(0) #>

						if ($InterpolatingFloats.PlayerCharacterPosition)
						{
							0x83, (ModRM 0 7 5), '&FloatsWereInterpolated', 0x00                         <# cmp [&FloatsWereInterpolated], 0 #>
							0x74, '1:PastCameraPositionRestorationOfInterpolatedPlayerCharacterPosition' <# je PastCameraPositionRestorationOfInterpolatedPlayerCharacterPosition #>
							$RestoreInterpolatedPlayerCharacterPosition
						}
					'PastCameraPositionRestorationOfInterpolatedPlayerCharacterPosition:'

						0xE9, '4:PostCameraSmoothingHijack'                                          <# jmp PostCameraSmoothingHijack #>
					}
				)


				Preassemble 'RestrictCameraShakeConditional' @(
					if ($Script:CameraSmoothingVariant -eq 'InterpolatedV2')
					{
						0x7F, '1:JumpConditionallyIntoCameraShakeConditional' <# jg JumpConditionallyIntoCameraShakeConditional #>
						0xE9, '4:AfterCameraShakeConditional'                 <# jmp AfterCameraShakeConditional #>
					'JumpConditionallyIntoCameraShakeConditional:'
						0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00  <# cmp [&PresentationFrameIndex], 0 #>
						0x0F, 0x85, '4:AfterCameraShakeConditional'           <# jne AfterCameraShakeConditional #>
						0xE9, '4:PostCameraShakeConditionalHijack'            <# jmp PostCameraShakeConditionalHijack #>
					}
					else
					{
						0xE9, '4:AfterCameraShakeConditional' <# jmp AfterCameraShakeConditional #>
					}
				)


				Preassemble 'InterpolateCameraShake' @(
					if ($Script:CameraSmoothingVariant -eq 'InterpolatedV2')
					{
						0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00 <# cmp [&PresentationFrameIndex], 0 #>
						0x75, '1:UseHeldCameraShakeValues'                   <# jne UseHeldCameraShakeValues #>
						0xD9, (ModRM 0 0 5), '&CameraModifier0'              <# fld [&CameraModifier0] #>
						0xD9, (ModRM 0 3 5), '&CameraModifier0Backup'        <# fstp [&CameraModifier0Backup] #>
						0xD9, (ModRM 0 0 5), '&CameraModifier1'              <# fld [&CameraModifier1] #>
						0xD9, (ModRM 0 3 5), '&CameraModifier1Backup'        <# fstp [&CameraModifier1Backup] #>
						0xD9, (ModRM 0 0 5), '&CameraShakeActualValue'       <# fld [&CameraShakeActualValue] #>
						0xD9, (ModRM 0 2 5), '&CameraShakeTarget'            <# fst [&CameraShakeTarget] #>
						0xD8, (ModRM 0 1 5), '&FrameInterpolationValue'      <# fmul [&FrameInterpolationValue] #>
						0xD9, (ModRM 0 2 5), '&CameraShakeActualValue'       <# fst [&CameraShakeActualValue] #>
						0xE9, '4:PostAfterCameraShakeConditionallHijack'     <# jmp PostAfterCameraShakeConditionallHijack #>
					'UseHeldCameraShakeValues:'
						0xD9, (ModRM 0 0 5), '&CameraModifier0Backup'        <# fld [&CameraModifier0Backup] #>
						0xD9, (ModRM 0 3 5), '&CameraModifier0'              <# fstp [&CameraModifier0] #>
						0xD9, (ModRM 0 0 5), '&CameraModifier1Backup'        <# fld [&CameraModifier1Backup] #>
						0xD9, (ModRM 0 3 5), '&CameraModifier1'              <# fstp [&CameraModifier1] #>
						0xD9, (ModRM 0 0 5), '&CameraShakeTarget'            <# fld [&CameraShakeTarget] #>
						0xD8, (ModRM 0 1 5), '&FrameInterpolationValue'      <# fmul [&FrameInterpolationValue] #>
						0xD9, (ModRM 0 2 5), '&CameraShakeActualValue'       <# fst [&CameraShakeActualValue] #>
						0xE9, '4:PostAfterCameraShakeConditionallHijack'     <# jmp PostAfterCameraShakeConditionallHijack #>
					}
					else
					{
						0xD9, (ModRM 0 0 5), '&CameraShakeActualValue'   <# fld [&CameraShakeActualValue] #>
						0xE9, '4:PostAfterCameraShakeConditionallHijack' <# jmp PostAfterCameraShakeConditionallHijack #>
					}
				)


				Preassemble 'CameraShakeConditionalHijack' ${&CameraShakeConditional} ${@CameraShakeConditional} @(
					0xE9, '4:RestrictCameraShakeConditional' <# jmp RestrictCameraShakeConditional #>
					0x90                                     <# nop #>
				'PostCameraShakeConditionalHijack:'
				)


				Preassemble 'AfterCameraShakeConditionalHijack' ${&AfterCameraShakeConditional} ${@AfterCameraShakeConditional} @(
					0xE9, '4:InterpolateCameraShake' <# jmp InterpolateCameraShake #>
					0x90                             <# nop #>
				'PostAfterCameraShakeConditionallHijack:'
				)


				function New-LoopForInterpolatedFloat ($Float, $LoopLabel, $CodeForSingular, $CodeForPlural)
				{
					if ($Null -eq $Float.Structure)
					{
						foreach ($Offset in $Float.FloatOffsets)
						{
							& $CodeForSingular -Offset $Offset
						}
					}
					else
					{
						if ($Float.Structure.Count -is [String])
						{
							0xA1, "&$($Float.Structure.Count)"                                    <# mov eax, [&$Float.Structure.Count] #>
							0xBA, (LE $Float.Structure.Size)                                      <# mov edx, $Float.Structure.MaximumCount #>
							0x3B, (ModRM 3 0 2)                                                   <# cmp eax, edx #>
							0x0F, 0x42, (ModRM 3 2 0)                                             <# cmovb edx, eax #>
							0xB8, (LE ($InterpolatedFloatEntrySize * $Float.FloatOffsets.Length)) <# mov eax, $InterpolatedFloatEntrySize * $Float.FloatOffsets.Length #>
							0xF7, (ModRM 3 4 2)                                                   <# mul edx #>
							0x05, "&$($Float.Name)[0]_$($Float.FloatOffsets[0].Key)_Entry"        <# add eax, &$($Float.Name)[0]_$($Float.FloatOffsets[0].Key)_Entry #>
							0x8B, (ModRM 3 1 0)                                                   <# mov ecx, eax #>
							0xA1, "&$($Float.Structure.Count)"                                    <# mov eax, [&$Float.Structure.Count] #>
							0xBA, (LE $Float.Structure.Size)                                      <# mov edx, $Float.Structure.MaximumCount #>
							0x3B, (ModRM 3 0 2)                                                   <# cmp eax, edx #>
							0x0F, 0x42, (ModRM 3 2 0)                                             <# cmovb edx, eax #>
							0xB8, (LE $Float.Structure.Size)                                      <# mov eax, $Float.Structure.Size #>
							0xF7, (ModRM 3 4 2)                                                   <# mul edx #>
							0x05, (LE $Float.VirtualAddress)                                      <# add eax, $Float.VirtualAddress #>
						}
						else
						{
							0xB8, (LE ($Float.VirtualAddress + $Float.Structure.Count * $Float.Structure.Size))                                                                                            <# mov eax, $Float.VirtualAddress + $Float.Structure.Count * $Float.Structure.Size #>
							0xB9, (LE ($Variables.GetValue("&$($Float.Name)[0]_$($Float.FloatOffsets[0].Key)_Entry") + $Float.Structure.Count * $InterpolatedFloatEntrySize * $Float.FloatOffsets.Length)) <# mov ecx, &$($Float.Name)[0]_$($Float.FloatOffsets[0].Key)_Entry + $Float.Structure.Count * $InterpolatedFloatEntrySize * $Float.FloatOffsets.Length #>
						}

					"$LoopLabel$($Float.Name):"
						0x3D, (LE $Float.VirtualAddress)       <# cmp eax, $Float.VirtualAddress #>
						0x74, "1:Past$LoopLabel$($Float.Name)" <# je Past$LoopLabel$($Float.Name) #>
						0x2D, (LE $Float.Structure.Size)       <# sub eax, $Float.Structure.Size #>

						for ($Index = $Float.FloatOffsets.Length; ($Index--) -gt 0;)
						{
							0x83, (ModRM 3 5 1), (LE ([SByte] $InterpolatedFloatEntrySize)) <# sub ecx, $InterpolatedFloatEntrySize #>
							& $CodeForPlural -Offset $Float.FloatOffsets[$Index]
						}

						0xEB, "1:$LoopLabel$($Float.Name)" <# jmp $LoopLabel$($Float.Name) #>
					"Past$LoopLabel$($Float.Name):"
					}
				}


				if ($InterpolatingFloats.PlayerCharacterPosition -or $InterpolatingFloats.RecetWhenInDungeonPosition -or $InterpolatingFloats.TearPosition)
				{
					Hijack 'StopInterpolationOfPlayerCharacterPossePosition' 'PlayerCharacterPossePositionResetHijack' 0 6 @(
						0x52                                                                                                                      <# push edx #>
						0xB8, (LE ([UInt32] ($InterpolatedFloatEntrySize * $PlayerCharacterPositionInterpolation.FloatOffsets.Length)))           <# mov eax, $InterpolatedFloatEntrySize * $PlayerCharacterPositionInterpolation.FloatOffsets.Length #>
						0xF7, (ModRM 3 4 7)                                                                                                       <# mul edi #>
						0x05, "&$($PlayerCharacterPositionInterpolation.Name)_$($PlayerCharacterPositionInterpolation.FloatOffsets[0].Key)_Entry" <# add eax, &$($PlayerCharacterPositionInterpolation.Name)_$($PlayerCharacterPositionInterpolation.FloatOffsets[0].Key)_Entry #>

						foreach ($Offset in $PlayerCharacterPositionInterpolation.FloatOffsets)
						{
							0xC7, (ModRM 1 0 0), (LE ([SByte] $InterpolatedFloatHeldValueOffset)), (LE ([UInt32] $DoNotInterpolateFloatNaNValue)) <# mov [eax + $InterpolatedFloatHeldValueOffset], $DoNotInterpolateFloatNaNValue #>
							0x81, (ModRM 3 0 0), (LE ([UInt32] $InterpolatedFloatEntrySize))                                                      <# add eax, $InterpolatedFloatEntrySize #>
						}

						0x5A                             <# pop edx #>
						0x8D, (ModRM 0 0 4), (SIB 1 7 7) <# lea eax, [edi + edi * 2] #>
						0x8D, (ModRM 0 1 4), (SIB 1 7 7) <# lea ecx, [edi + edi * 2] #>
					)
				}


				if ($InterpolatingFloats.ShopperPosition)
				{
					Hijack 'StopInterpolationOfShopperPosition' 'ShopperPositionResetHijack' 0 6 @(
						0x50                                                                                                         <# push eax #>
						0x52                                                                                                         <# push edx #>
						0xB8, (LE ([UInt32] ($InterpolatedFloatEntrySize * $ShopperPositionInterpolation.FloatOffsets.Length)))      <# mov eax, $InterpolatedFloatEntrySize * $ShopperPositionInterpolation.FloatOffsets.Length #>
						0xF7, (ModRM 3 4 7)                                                                                          <# mul edi #>
						0x05, "&$($ShopperPositionInterpolation.Name)[0]_$($ShopperPositionInterpolation.FloatOffsets[0].Key)_Entry" <# add eax, &$($ShopperPositionInterpolation.Name)[0]_$($ShopperPositionInterpolation.FloatOffsets[0].Key)_Entry #>

						foreach ($Offset in $ShopperPositionInterpolation.FloatOffsets)
						{
							0xC7, (ModRM 1 0 0), (LE ([SByte] $InterpolatedFloatHeldValueOffset)), (LE ([UInt32] $DoNotInterpolateFloatNaNValue)) <# mov [eax + $InterpolatedFloatHeldValueOffset], $DoNotInterpolateFloatNaNValue #>
							0x81, (ModRM 3 0 0), (LE ([UInt32] $InterpolatedFloatEntrySize))                                                      <# add eax, $InterpolatedFloatEntrySize #>
						}

						0x5A                                        <# pop edx #>
						0x58                                        <# pop eax #>
						0x39, (ModRM 2 2 0), 0xE0, 0xCD, 0x02, 0x00 <# cmp [eax + 183776], edx #>
					)
				}


				Preassemble 'MobPositionResetHijack' ${&MobPositionResetHijack} ${@MobPositionResetHijack} @(
					if ($InterpolatingFloats.MobPosition)
					{
						0xE9, '4:StopInterpolationOfResetMobPositions' <# jmp StopInterpolationOfResetMobPositions #>
						(Get-Nop 5)                                    <# nop #>
					'PostMobPositionResetHijack:'
					}
				)


				Preassemble 'StopInterpolationOfResetMobPositions' @(
					if ($InterpolatingFloats.MobPosition)
					{
						0xB8, (LE ($InterpolatedFloatEntrySize * $MobPositionInterpolation.FloatOffsets.Length))             <# mov eax, $InterpolatedFloatEntrySize * $MobPositionInterpolation.FloatOffsets.Length #>
						0xF7, (ModRM 2 4 6), 0x3C, 0x0B, 0x00, 0x00                                                          <# mul [esi + 0xb3c] #>
						0x05, "&$($MobPositionInterpolation.Name)[0]_$($MobPositionInterpolation.FloatOffsets[0].Key)_Entry" <# add eax, &$($MobPositionInterpolation.Name)[0]_$($MobPositionInterpolation.FloatOffsets[0].Key)_Entry #>

						foreach ($Offset in $MobPositionInterpolation.FloatOffsets)
						{
							0xC7, (ModRM 1 0 0), (LE ([SByte] $InterpolatedFloatHeldValueOffset)), (LE ([UInt32] $DoNotInterpolateFloatNaNValue)) <# mov [eax + $InterpolatedFloatHeldValueOffset], $DoNotInterpolateFloatNaNValue #>
							0x05, (LE ([UInt32] $InterpolatedFloatEntrySize))                                                                     <# add eax, $InterpolatedFloatEntrySize #>
						}

						0xC7, (ModRM 2 0 6), 0x28, 0x04, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 <# mov [esi + 1064], 1 #>
						0xE9, '4:PostMobPositionResetHijack'                                <# jmp PostMobPositionResetHijack #>
					}
				)


				Preassemble 'ProjectilePositionResetHijack' ${&ProjectilePositionResetHijack} ${@ProjectilePositionResetHijack} @(
					if ($InterpolatingFloats.AttackProjectilePosition)
					{
						0xE9, '4:StopInterpolationOfResetProjectilePositions' <# jmp StopInterpolationOfResetProjectilePositions #>
						0x90                                                  <# nop #>
					'PostProjectilePositionResetHijack:'
					}
				)


				Preassemble 'StopInterpolationOfResetProjectilePositions' @(
					if ($InterpolatingFloats.AttackProjectilePosition)
					{
						0xB8, (LE ($InterpolatedFloatEntrySize * $AttackProjectilePositionInterpolation.FloatOffsets.Length))                          <# mov eax, $InterpolatedFloatEntrySize * $AttackProjectilePositionInterpolation.FloatOffsets.Length #>
						0xF7, (ModRM 1 4 5), 0xD8                                                                                                      <# mul [ebp - 40] #>
						0x05, "&$($AttackProjectilePositionInterpolation.Name)[0]_$($AttackProjectilePositionInterpolation.FloatOffsets[0].Key)_Entry" <# add eax, &$($AttackProjectilePositionInterpolation.Name)[0]_$($AttackProjectilePositionInterpolation.FloatOffsets[0].Key)_Entry #>

						foreach ($Offset in $AttackProjectilePositionInterpolation.FloatOffsets)
						{
							0xC7, (ModRM 1 0 0), (LE ([SByte] $InterpolatedFloatHeldValueOffset)), (LE ([UInt32] $DoNotInterpolateFloatNaNValue)) <# mov [eax + $InterpolatedFloatHeldValueOffset], $DoNotInterpolateFloatNaNValue #>
							0x05, (LE ([UInt32] $InterpolatedFloatEntrySize))                                                                     <# add eax, $InterpolatedFloatEntrySize #>
						}

						0x8B, (ModRM 1 0 5), 0x10                   <# mov eax, [ebp + 16] #>
						0x8B, (ModRM 1 2 5), 0x0C                   <# mov edx, [ebp + 12] #>
						0xE9, '4:PostProjectilePositionResetHijack' <# jmp PostProjectilePositionResetHijack #>
					}
				)

				if ($InterpolatingFloats.AttackProjectilePosition)
				{
					Hijack 'StopInterpolationOfArrowProjectilePosition' 'ArrowProjectilePositionResetHijack' 0 6 @(
						0x50                                                                                                                           <# push eax #>
						0x52                                                                                                                           <# push edx #>
						0xB8, (LE ([UInt32] ($InterpolatedFloatEntrySize * $AttackProjectilePositionInterpolation.FloatOffsets.Length)))               <# mov eax, $InterpolatedFloatEntrySize * $AttackProjectilePositionInterpolation.FloatOffsets.Length #>
						0xF7, (ModRM 1 4 5), 0xE8                                                                                                      <# mul [ebp - 24] #>
						0x05, "&$($AttackProjectilePositionInterpolation.Name)[0]_$($AttackProjectilePositionInterpolation.FloatOffsets[0].Key)_Entry" <# add eax, &$($AttackProjectilePositionInterpolation.Name)[0]_$($AttackProjectilePositionInterpolation.FloatOffsets[0].Key)_Entry #>

						foreach ($Offset in $AttackProjectilePositionInterpolation.FloatOffsets)
						{
							0xC7, (ModRM 1 0 0), (LE ([SByte] $InterpolatedFloatHeldValueOffset)), (LE ([UInt32] $DoNotInterpolateFloatNaNValue)) <# mov [eax + $InterpolatedFloatHeldValueOffset], $DoNotInterpolateFloatNaNValue #>
							0x81, (ModRM 3 0 0), (LE ([UInt32] $InterpolatedFloatEntrySize))                                                      <# add eax, $InterpolatedFloatEntrySize #>
						}

						0x5A                      <# pop edx #>
						0x58                      <# pop eax #>
						0xD9, (ModRM 1 0 0), 0x20 <# fld [eax + 32] #>
						0xD9, (ModRM 1 3 3), 0x5C <# fstp [ebx + 92] #>
					)
				}


				Preassemble 'StopInterpolationOfResetXPGemPositions' @(
					if ($InterpolatingFloats.XPGemPosition)
					{
						0xB8, (LE ([UInt32] ($InterpolatedFloatEntrySize * $XPGemPositionInterpolation.FloatOffsets.Length)))    <# mov eax, $InterpolatedFloatEntrySize * $XPGemPositionInterpolation.FloatOffsets.Length #>
						0xF7, (ModRM 1 4 5), 0x18                                                                                <# mul [ebp + 24] #>
						0x05, "&$($XPGemPositionInterpolation.Name)[0]_$($XPGemPositionInterpolation.FloatOffsets[0].Key)_Entry" <# add eax, &$($XPGemPositionInterpolation.Name)[0]_$($XPGemPositionInterpolation.FloatOffsets[0].Key)_Entry #>

						foreach ($Offset in $XPGemPositionInterpolation.FloatOffsets)
						{
							0xC7, (ModRM 1 0 0), (LE ([SByte] $InterpolatedFloatHeldValueOffset)), (LE ([UInt32] $DoNotInterpolateFloatNaNValue)) <# mov [eax + $InterpolatedFloatHeldValueOffset], $DoNotInterpolateFloatNaNValue #>
							0x05, (LE ([UInt32] $InterpolatedFloatEntrySize))                                                                     <# add eax, $InterpolatedFloatEntrySize #>
						}

						0xD9, (ModRM 1 3 6), 0xC4              <# fstp [esi - 60] #>
						0xD9, (ModRM 1 0 5), 0x10              <# fld [ebp + 16] #>
						0xE9, '4:PostXPGemPositionResetHijack' <# jmp PostXPGemPositionResetHijack #>
					}
				)


				Preassemble 'XPGemPositionResetHijack' ${&XPGemPositionResetHijack} ${@XPGemPositionResetHijack} @(
					if ($InterpolatingFloats.XPGemPosition)
					{
						0xE9, '4:StopInterpolationOfResetXPGemPositions' <# jmp StopInterpolationOfResetXPGemPositions #>
						0x90                                             <# nop #>
					'PostXPGemPositionResetHijack:'
					}
				)


				Preassemble 'StopInterpolationOfResetMovementParticlePositions' @(
					if ($InterpolatingFloats.MovementParticlePosition)
					{
						0xB8, (LE ([UInt32] ($InterpolatedFloatEntrySize * $MovementParticlePositionInterpolation.FloatOffsets.Length)))               <# mov eax, $InterpolatedFloatEntrySize * $MovementParticlePositionInterpolation.FloatOffsets.Length #>
						0xF7, (ModRM 1 4 5), 0xF4                                                                                                      <# mul [ebp - 12] #>
						0x05, "&$($MovementParticlePositionInterpolation.Name)[0]_$($MovementParticlePositionInterpolation.FloatOffsets[0].Key)_Entry" <# add eax, &$($MovementParticlePositionInterpolation.Name)[0]_$($MovementParticlePositionInterpolation.FloatOffsets[0].Key)_Entry #>

						foreach ($Offset in $MovementParticlePositionInterpolation.FloatOffsets)
						{
							0xC7, (ModRM 1 0 0), (LE ([SByte] $InterpolatedFloatHeldValueOffset)), (LE ([UInt32] $DoNotInterpolateFloatNaNValue)) <# mov [eax + $InterpolatedFloatHeldValueOffset], $DoNotInterpolateFloatNaNValue #>
							0x05, (LE ([UInt32] $InterpolatedFloatEntrySize))                                                                     <# add eax, $InterpolatedFloatEntrySize #>
						}

						0xD9, (ModRM 1 3 3), 0x04                         <# fstp [ebx + 4] #>
						0x33, (ModRM 3 0 0)                               <# xor eax, eax #>
						0xD9, (ModRM 1 0 5), 0x14                         <# fld [ebp + 20] #>
						0xE9, '4:PostMovementParticlePositionResetHijack' <# jmp PostMovementParticlePositionResetHijack #>
					}
				)


				Preassemble 'MovementParticlePositionResetHijack' ${&MovementParticlePositionResetHijack} ${@MovementParticlePositionResetHijack} @(
					if ($InterpolatingFloats.MovementParticlePosition)
					{
						0xE9, '4:StopInterpolationOfResetMovementParticlePositions' <# jmp StopInterpolationOfResetMovementParticlePositions #>
						0x90                                                <# nop #>
					'PostMovementParticlePositionResetHijack:'
					}
				)


				Preassemble 'StopInterpolationWhenAllEncompassingPositionResetIsCalled' @(
					if ($InterpolatingFloats)
					{
						0xC7, (ModRM 0 0 5), '&StopInterpolatingFloatsUntilNextGameFrame', 0x01, 0x00, 0x00, 0x00 <# mov [&StopInterpolatingFloatsUntilNextGameFrame], 1 #>
						0x55                                                                                      <# push ebp #>
						0x8B, (ModRM 3 5 4)                                                                       <# mov ebp, esp #>
						0x83, (ModRM 3 5 4), 0x7C                                                                 <# sub esp, 124 #>
						0xE9, '4:PostAllEncompassingPositionResetHijack'                                          <# jmp PostAllEncompassingPositionResetHijack #>
					}
				)


				Preassemble 'AllEncompassingPositionResetHijack' ${&AllEncompassingPositionResetHijack} ${@AllEncompassingPositionResetHijack} @(
					if ($InterpolatingFloats)
					{
						0xE9, '4:StopInterpolationWhenAllEncompassingPositionResetIsCalled' <# jmp StopInterpolationWhenAllEncompassingPositionResetIsCalled #>
						0x90                                                                <# nop #>
					'PostAllEncompassingPositionResetHijack:'
					}
				)


				Preassemble 'StopInterpolationWhenChestTeleportationIsCalled' @(
					if ($InterpolatingFloats)
					{
						0xC7, (ModRM 0 0 5), '&StopInterpolatingFloatsUntilNextGameFrame', 0x01, 0x00, 0x00, 0x00 <# mov [&StopInterpolatingFloatsUntilNextGameFrame], 1 #>
						0x55                                                                                      <# push ebp #>
						0x8B, (ModRM 3 5 4)                                                                       <# mov ebp, esp #>
						0x83, (ModRM 3 5 4), 0x74                                                                 <# sub esp, 116 #>
						0xE9, '4:PostChestTeleporationPositionResetHijack'                                        <# jmp PostChestTeleporationPositionResetHijack #>
					}
				)


				Preassemble 'ChestTeleporationPositionResetHijack' ${&ChestTeleporationPositionResetHijack} ${@ChestTeleporationPositionResetHijack} @(
					if ($InterpolatingFloats)
					{
						0xE9, '4:StopInterpolationWhenChestTeleportationIsCalled' <# jmp StopInterpolationWhenChestTeleportationIsCalled #>
						0x90                                                      <# nop #>
					'PostChestTeleporationPositionResetHijack:'
					}
				)


				Preassemble 'BeforeGameFrame' @(
					foreach ($Integer in $IntegersToMirrorAsFloats)
					{
						0xDB, (ModRM 0 0 5), (LE $Integer.VirtualAddress) <# fild [$Integer.VirtualAddress] #>
						0xD9, (ModRM 0 3 5), "&$($Integer.Name)"          <# fstp [&$($Integer.Name)] #>
					}

					if ($Script:CameraSmoothingVariant -eq 'InterpolatedV2')
					{
						0xD9, (ModRM 0 0 5), '&CameraShakeTarget'                      <# fld [&CameraShakeTarget] #>
						0xD9, (ModRM 0 0 5), '&CameraModifier0Backup'                  <# fld [&CameraModifier0Backup] #>
						0xD8, 0xC1                                                     <# fadd st(0), st(1) #>
						0xD9, (ModRM 0 3 5), '&CameraModifier0'                        <# fstp [&CameraModifier0] #>
						0xD9, (ModRM 0 0 5), '&CameraModifier1Backup'                  <# fld [&CameraModifier1Backup] #>
						0xD8, 0xC1                                                     <# fadd st(0), st(1) #>
						0xD9, (ModRM 0 3 5), '&CameraModifier1'                        <# fstp [&CameraModifier1] #>
						0xD9, (ModRM 0 3 5), '&CameraShakeActualValue'                 <# fstp [&CameraShakeActualValue] #>

						0xDB, (ModRM 0 0 5), '&PresentationTimeSinceGameFrame'         <# fild [&PresentationTimeSinceGameFrame] #>
						0xDA, (ModRM 0 6 5), '&GameFrameTime'                          <# fdiv [&GameFrameTime] #>
						0xD9, (ModRM 0 3 5), '&PresentationTimeSinceGameFrameFraction' <# fstp [&PresentationTimeSinceGameFrameFraction] #>
						0xD9, (ModRM 0 0 5), '&CurrentCameraSmoothingDivisor'          <# fld [&CurrentCameraSmoothingDivisor] #>

						for ($Index = 0; $Index -lt $CameraPositionCount; ++$Index)
						{
							0xD9, (ModRM 0 0 5), (LE ${&CameraPositionDeltas[]}[$Index]) <# fld [&CameraPositionDeltas[$Index]] #>
							0xD8, 0xF1                                                   <# fdiv st(0), st(1) #>
							0xD8, (ModRM 0 0 5), (LE ${&HeldCameraPositions[]}[$Index])  <# fadd [&HeldCameraPositions[$Index]] #>
							0xD9, (ModRM 0 3 5), (LE ${&CameraPositions[]}[$Index])      <# fstp [&CameraPositions[$Index]] #>
						}

						0xDD, 0xD8                                                     <# fstp st(0) #>

						0xD9, (ModRM 0 0 5), '&CameraHeightDelta'                      <# fld [&CameraHeightDelta] #>
						0xD8, (ModRM 0 6 5), '&CurrentCameraHeightSmoothingDivisor'    <# fdiv [&CurrentCameraHeightSmoothingDivisor] #>
						0xD8, (ModRM 0 0 5), '&CurrentCameraHeightSmoothingAdjustment' <# fadd [&CurrentCameraHeightSmoothingAdjustment] #>
						0xD8, (ModRM 0 0 5), '&HeldCameraHeight'                       <# fadd [&HeldCameraHeight] #>
						0xD9, (ModRM 0 3 5), '&CameraHeight'                           <# fstp [&CameraHeight] #>

						0x83, (ModRM 0 4 5), '&ShouldInitialiseCameraPositions', 0x00 <# and [&ShouldInitialiseCameraPositions], 0 #>
					}

					if ($InterpolatingFloats)
					{
						0x83, (ModRM 0 7 5), '&FloatsWereInterpolated', 0x00                    <# cmp [&FloatsWereInterpolated], 0 #>
						0x75, '1:InterpolatingFloatsBeforeGameFrame'                            <# jne InterpolatingFloatsBeforeGameFrame #>
						0xE9, '4:PastUseOfInterpolatedFloatTargets'                             <# jmp PastUseOfInterpolatedFloatTargets #>

					'InterpolatingFloatsBeforeGameFrame:'
						0x83, (ModRM 0 7 5), '&StopInterpolatingFloatsUntilNextGameFrame', 0x00 <# cmp [&StopInterpolatingFloatsUntilNextGameFrame], 0 #>
						0x0F, 0x85, '4:PastUseOfInterpolatedFloatTargets'                       <# jne PastUseOfInterpolatedFloatTargets #>

						#foreach ($Float in $FloatsToInterpolate)
						#{
						#	0xD9, (ModRM 0 0 5), "&$($Float)Target" <# fld [&$($Float)Target] #>
						#	0xD9, (ModRM 0 2 5), "&Held$Float"      <# fst [&Held$Float] #>
						#	0xD9, (ModRM 0 3 5), "&$Float"          <# fstp [&$Float] #>
						#}

						foreach ($Float in $FloatsToInterpolate)
						{
							New-LoopForInterpolatedFloat $Float 'UseOfInterpolatedTargetsFor' `
								-CodeForSingular `
								{
									Param ($Offset)

									0xD9, (ModRM 0 0 5), "&$($Float.Name)_$($Offset.Key)_Target"      <# fld [&$_Target] #>
									0xD9, (ModRM 0 2 5), "&$($Float.Name)_$($Offset.Key)_HeldValue"   <# fst [&$_HeldValue] #>
									0xD9, (ModRM 0 3 5), "&$($Float.Name)_$($Offset.Key)_ActualValue" <# fstp [&$_ActualValue] #>
								} `
								-CodeForPlural `
								{
									Param ($Offset)

									0xD9, (ModRM 1 0 1), (LE ([SByte] $InterpolatedFloatTargetOffset))    <# fld [ecx + $InterpolatedFloatTargetOffset] #>
									0xD9, (ModRM 1 2 1), (LE ([SByte] $InterpolatedFloatHeldValueOffset)) <# fst [ecx + $InterpolatedFloatHeldValueOffset] #>
									0xD9, (ModRM 2 3 0), (LE ([Int32] $Offset.Value))                     <# fstp [eax + $Offset.Value] #>
								}
						}

					'PastUseOfInterpolatedFloatTargets:'
						0x83, (ModRM 0 4 5), '&FloatsWereInterpolated', 0x00 <# and [&FloatsWereInterpolated], 0 #>
					}

					0xE9, '4:PostBeforeGameFrameJump' <# jmp PostBeforeGameFrameJump #>
				)


				Preassemble 'AfterGameFrame' @(
					foreach ($Integer in $IntegersToMirrorAsFloats)
					{
						0xDB, (ModRM 0 0 5), (LE $Integer.VirtualAddress) <# fild [$Integer.VirtualAddress] #>
						0xD9, (ModRM 0 3 5), "&$($Integer.Name)"          <# fstp [&$($Integer.Name)] #>
					}

					if ($Script:CameraSmoothingVariant -eq 'InterpolatedV2')
					{
						0xD9, (ModRM 0 0 5), "&CameraShakeActualValue" <# fld [&$CameraShakeActualValue] #>
						0xD9, (ModRM 0 3 5), "&CameraShakeTarget"      <# fstp [&$CameraShakeTarget] #>
					}

					0x8B, (ModRM 0 1 5), '&GameStateB'       <# mov ecx, [&GameStateB] #>
					0xA1, '&BlackBarFlags'                   <# mov eax, [&BlackBarFlags] #>

					0x83, (ModRM 0 7 5), '&InAnEvent?', 0x00 <# cmp [&InAnEvent?], 0 #>
					0x75, '1:AllTheBlackBars'                <# jne AllTheBlackBars #>
					0x83, (ModRM 3 7 1), 0x00                <# cmp ecx, 0 #>
					0x74, '1:AllTheBlackBars'                <# je AllTheBlackBars #>
					0x83, (ModRM 3 7 1), 0x09                <# cmp ecx, 9 #>
					0x74, '1:NoBlackBars'                    <# je NoBlackBars #>
				'PostPauseTransitionBlackBarCheck:'
					0x83, (ModRM 3 7 1), 0x01                <# cmp ecx, 1 #>
					0x75, '1:LowerRightBlackBars'            <# jne LowerRightBlackBars #>
					0xEB, '1:NoBlackBars'                    <# jmp NoBlackBars #>
				'LowerRightBlackBars:'
					0xB8, 0x0A, 0x00, 0x00, 0x00             <# mov eax, 0b1010 #>
					0xEB, '1:PostSettingOfBlackBarFlags'     <# jmp PostSettingOfBlackBarFlags #>
				'AllTheBlackBars:'
					0xB8, 0x0F, 0x00, 0x00, 0x00             <# mov eax, 0b1111 #>
					0xEB, '1:PostSettingOfBlackBarFlags'     <# jmp PostSettingOfBlackBarFlags #>
				'NoBlackBars:'
					0x33, (ModRM 3 0 0)                      <# xor eax, eax #>
				'PostSettingOfBlackBarFlags:'
					0xA3, '&BlackBarFlags'                   <# mov [&BlackBarFlags], eax #>

					0xE9, '4:PostAfterGameFrameJump'         <# jmp PostAfterGameFrameJump #>
				)


				Preassemble 'BeforePresentationFrame' @(
					foreach ($Integer in $IntegersToMirrorAsFloats)
					{
						0xDB, (ModRM 0 0 5), (LE $Integer.VirtualAddress) <# fild [$Integer.VirtualAddress] #>
						0xD9, (ModRM 0 3 5), "&$($Integer.Name)"          <# fstp [&$($Integer.Name)] #>
					}

					0xF7, (ModRM 0 4 5), '&CommonFrameTimeDenominator'         <# mul [&CommonFrameTimeDenominator] #>
					0x89, (ModRM 1 0 4), (SIB 0 4 4), 0x00                     <# mov [esp], eax #>
					0xDB, (ModRM 0 0 5), '&CommonFrameTimeInterpolationFactor' <# fild [&CommonFrameTimeInterpolationFactor] #>
					0xDA, (ModRM 1 7 4), (SIB 0 4 4), 0x00                     <# fidivr [esp] #>
					0xD9, (ModRM 0 2 5), '&FrameInterpolationTimeOffset'       <# fst [&FrameInterpolationTimeOffset] #>
					0xD8, (ModRM 0 1 5), '&FrameInterpolationTimeScale'        <# fmul [&FrameInterpolationTimeScale] #>
					0xD9, (ModRM 0 2 5), '&FrameInterpolationScaledTimeOffset' <# fst [&FrameInterpolationScaledTimeOffset] #>
					0xD8, (ModRM 0 0 5), '&FrameInterpolationInitialOffset'    <# fadd [&FrameInterpolationInitialOffset] #>
					#0xD9, 0xE8,                                               <# fld1 #>
					#0xDB, 0xF1,                                               <# fcomi st(0), st(1) #>
					#0xDB, 0xC1                                                <# fcmovnb st(0), st(1)  #>
					0xD9, (ModRM 0 3 5), '&FrameInterpolationValue'            <# fstp [&FrameInterpolationValue] #>
					#0xDD, 0xD8                                                <# fstp st(0) #>

					if ($InterpolatingFloats)
					{
						0x83, (ModRM 0 7 5), '&ThreadGuardA_A', 0x00                                              <# cmp [&ThreadGuardA_A], 0 #>
						0x74, '1:PastCheckingOfThreadGuardBeforeFrameInterpolation'                               <# jz PastCheckingOfThreadGuardBeforeFrameInterpolation #>
						0xC7, (ModRM 0 0 5), '&StopInterpolatingFloatsUntilNextGameFrame', 0x01, 0x00, 0x00, 0x00 <# mov [&StopInterpolatingFloatsUntilNextGameFrame], 1 #>
						0xE9, '4:PastFloatInterpolation'                                                          <# jmp PastFloatInterpolation #>
					'PastCheckingOfThreadGuardBeforeFrameInterpolation:'
						0x83, (ModRM 0 7 5), '&PresentationFrameIndex', 0x00                                      <# cmp [&PresentationFrameIndex], 0 #>
						0x75, '1:ChecksForNonInitialPresentationFrames'                                           <# jne ChecksForNonInitialPresentationFrames #>
						0x83, (ModRM 0 4 5), '&StopInterpolatingFloatsUntilNextGameFrame', 0x00                   <# and [&StopInterpolatingFloatsUntilNextGameFrame], 0 #>
						0xC7, (ModRM 0 0 5), '&FloatsWereInterpolated', 0x01, 0x00, 0x00, 0x00                    <# mov [&FloatsWereInterpolated], 1 #>
						0xEB, '1:DeltaCalculations'                                                               <# jmp DeltaCalculations #>
					'ChecksForNonInitialPresentationFrames:'
						0x83, (ModRM 0 7 5), '&StopInterpolatingFloatsUntilNextGameFrame', 0x00                   <# cmp [&StopInterpolatingFloatsUntilNextGameFrame], 0 #>
						0x0F, 0x84, '4:PastDeltaCalculations'                                                     <# je PastDeltaCalculations #>
						0xE9, '4:PastFloatInterpolation'                                                          <# jmp PastFloatInterpolation #>
					'DeltaCalculations:'
						foreach ($Float in $FloatsToInterpolate)
						{
							New-LoopForInterpolatedFloat $Float 'DeltaCalculationsFor' `
								-CodeForSingular `
								{
									Param ($Offset)

									0xD9, (ModRM 0 0 5), "&$($Float.Name)_$($Offset.Key)_ActualValue" <# fld [&$_ActualValue] #>
									0xD9, (ModRM 0 2 5), "&$($Float.Name)_$($Offset.Key)_Target"      <# fst [&$_Target] #>
									0xD8, (ModRM 0 4 5), "&$($Float.Name)_$($Offset.Key)_HeldValue"   <# fsub [&$_HeldValue] #>

									if ($Float.Name -eq 'HUDSlideIn')
									{
										0xD9, (ModRM 0 0 5), '&HUDSlideInPercentageMaximumDelta' <# fld [&HUDSlideInPercentageMaximumDelta] #>
										0xDF, 0xF1                                               <# fcomip st(0), st(1) #>
										0x77, '1:PastDeltaChoiceForHudSlideInPercentage'         <# ja PastDeltaChoiceForHudSlideInPercentage #>
										0xDD, 0xD8                                               <# fstp st(0) #>
										0xD9, (ModRM 0 0 5), '&DoNotInterpolateFloatNaN'         <# fld [&DoNotInterpolateFloatNaN] #>
									'PastDeltaChoiceForHudSlideInPercentage:'
									}

									0xD9, (ModRM 0 3 5), "&$($Float.Name)_$($Offset.Key)_Delta" <# fstp [&$_Delta] #>
								} `
								-CodeForPlural `
								{
									Param ($Offset)

									0xD9, (ModRM 2 0 0), (LE ([Int32] $Offset.Value))                     <# fld [eax + $Offset.Value] #>
									0xD9, (ModRM 1 2 1), (LE ([SByte] $InterpolatedFloatTargetOffset))    <# fst [ecx + $InterpolatedFloatTargetOffset] #>
									0xD8, (ModRM 1 4 1), (LE ([SByte] $InterpolatedFloatHeldValueOffset)) <# fsub [ecx + $InterpolatedFloatHeldValueOffset] #>

									if ($Float.Name -eq 'MirrorImageReflectionPosition')
									{
										0x83, (ModRM 0 7 5), '&MirrorImageCounter', 0x1D <# cmp [&MirrorImageCounter], 29 #>
										0x75, 0x08                                       <# jne PastDeltaChoiceForMirrorImageReflectionPosition #>
										0xDD, 0xD8                                       <# fstp st(0) #>
										0xD9, (ModRM 0 0 5), '&DoNotInterpolateFloatNaN' <# fld [&DoNotInterpolateFloatNaN] #>
									<# PastDeltaChoiceForMirrorImageReflectionPosition: #>
									}

									0xD9, (ModRM 1 3 1), (LE ([SByte] $InterpolatedFloatDeltaOffset))     <# fstp [ecx + $InterpolatedFloatDeltaOffset] #>
								}
						}

						#foreach ($Float in $FloatsToInterpolate)
						#{
						#	0xD9, (ModRM 0 0 5), "&$Float"          <# fld [&$Float] #>
						#	0xD9, (ModRM 0 2 5), "&$($Float)Target" <# fst [&$($Float)Target] #>
						#	0xD8, (ModRM 0 4 5), "&Held$Float"      <# fsub [&Held$Float] #>
						#	0xD9, (ModRM 0 3 5), "&$($Float)Delta"  <# fstp [&$($Float)Delta] #>
						#}

					'PastDeltaCalculations:'
						0xD9, (ModRM 0 0 5), '&FrameInterpolationValue' <# fld [&FrameInterpolationValue] #>

						foreach ($Float in $FloatsToInterpolate)
						{
							New-LoopForInterpolatedFloat $Float 'FloatInterpolationOf' `
								-CodeForSingular `
								{
									Param ($Offset)

									0xD9, (ModRM 0 0 5), "&$($Float.Name)_$($Offset.Key)_Delta"       <# fld [&$_Delta] #>
									0xDB, 0xF0                                                        <# fcomi st(0), st(0) #>
									0x7A, 0x0E                                                        <# jp PastDeltaCalculationFloat #>
									0xD8, 0xC9                                                        <# fmul st(0), st(1) #>
									0xD8, (ModRM 0 0 5), "&$($Float.Name)_$($Offset.Key)_HeldValue"   <# fadd [&$_HeldValue] #>
									0xD9, (ModRM 0 2 5), "&$($Float.Name)_$($Offset.Key)_ActualValue" <# fst [&$_ActualValue] #>
								<# PastDeltaCalculationForFloat: #>
									0xDD, 0xD8                                                        <# fstp st(0) #>
								} `
								-CodeForPlural `
								{
									Param ($Offset)

									0xD9, (ModRM 1 0 1), (LE ([SByte] $InterpolatedFloatDeltaOffset))     <# fld [ecx + $InterpolatedFloatDeltaOffset] #>
									0xDB, 0xF0                                                            <# fcomi st(0), st(0) #>
									0x7A, 0x0B                                                            <# jp PastDeltaCalculationFloat #>
									0xD8, 0xC9                                                            <# fmul st(0), st(1) #>
									0xD8, (ModRM 1 0 1), (LE ([SByte] $InterpolatedFloatHeldValueOffset)) <# fadd [ecx + $InterpolatedFloatHeldValueOffset] #>
									0xD9, (ModRM 2 2 0), (LE ([Int32] $Offset.Value))                     <# fst [eax + $Offset.Value] #>
								<# PastDeltaCalculationForFloat: #>
									0xDD, 0xD8                                                            <# fstp st(0) #>
								}
						}

						#foreach ($Float in $FloatsToInterpolate)
						#{
						#	0xD9, (ModRM 0 0 5), "&$($Float)Delta"     <# fld [&$($Float)Delta] #>
						#	0xD8, 0xC9                                 <# fmul st(0), st(1) #>
						#	0xD8, (ModRM 0 0 5), "&Held$Float"         <# fadd [&Held$Float] #>
						#	0xD9, (ModRM 0 3 5), "&$Float"             <# fstp [&$Float] #>
						#}

						0xDD, 0xD8 <# fstp st(0) #>
					'PastFloatInterpolation:'
					}

					0xE9, '4:PostBeforePresentationFrameJump' <# jmp PostBeforePresentationFrameJump #>
				)


				Preassemble 'AfterPresentationFrame' @(
					foreach ($Integer in $IntegersToMirrorAsFloats)
					{
						0xDB, (ModRM 0 0 5), (LE $Integer.VirtualAddress) <# fild [$Integer.VirtualAddress] #>
						0xD9, (ModRM 0 3 5), "&$($Integer.Name)"          <# fstp [&$($Integer.Name)] #>
					}

					0xE9, '4:PostAfterPresentationFrameJump' <# jmp PostAfterPresentationFrameJump #>
				)


				Preassemble 'HandleFrame' ${&HandleFrame} ${@HandleFrame} @(
					0x53                                                                            <# push ebx #>
					0x55                                                                            <# push ebp #>
					0x56                                                                            <# push esi #>
					0x57                                                                            <# push edi #>
					0x8B, (ModRM 3 5 4)                                                             <# mov ebp, esp #>
					0x83, (ModRM 3 5 4), 0x08                                                       <# sub esp, 8 #>
					0x54                                                                            <# push esp #>
					0x33, (ModRM 3 7 7)                                                             <# xor edi, edi #>
					0xFF, (ModRM 0 2 5), '&QueryPerformanceCounter'                                 <# call QueryPerformanceCounter #>
					0x8B, (ModRM 1 0 5), 0xF8                                                       <# mov eax, [ebp - 8] #>
					0xBD, '&PresentationFrameTiming'                                                <# mov ebp, &PresentationFrameTiming #>
					0x8B, (ModRM 3 6 0)                                                             <# mov esi, eax #>
				'FrameMaths:'
					0x8B, (ModRM 1 1 5), '1:GameFrameTiming/GameFrameTimeIntegralPart'              <# mov ecx, [ebp + GameFrameTimeIntegralPart] #>
					0xFF, (ModRM 1 1 5), '1:GameFrameTiming/LeapGameFrameCounter'                   <# dec, [ebp + LeapGameFrameCounter] #>
					0x8B, (ModRM 1 2 5), '1:GameFrameTiming/GameFrameTimeFractionalPartNumerator'   <# mov edx, [ebp + GameFrameTimeFractionalPartNumerator] #>
					0x3B, (ModRM 1 2 5), '1:GameFrameTiming/LeapGameFrameCounter'                   <# cmp edx, [ebp + LeapGameFrameCounter] #>
					0x73, '1:PastLeapGameFrameIncrement'                                            <# jae PastLeapGameFrameIncrement #>
					0x41                                                                            <# inc ecx #>
				'PastLeapGameFrameIncrement:'
					0x33, (ModRM 3 2 2)                                                             <# xor edx, edx #>
					0x3B, (ModRM 1 2 5), '1:GameFrameTiming/LeapGameFrameCounter'                   <# cmp edx, [ebp + LeapGameFrameCounter] #>
					0x75, '1:PastLeapGameFrameCounterReset'                                         <# jnz PastLeapGameFrameCounterReset #>
					0x8B, (ModRM 1 3 5), '1:GameFrameTiming/GameFrameTimeFractionalPartDenominator' <# mov ebx, [ebp + GameFrameTimeFractionalPartDenominator] #>
					0x89, (ModRM 1 3 5), '1:GameFrameTiming/LeapGameFrameCounter'                   <# mov [ebp + LeapGameFrameCounter], ebx #>
				'PastLeapGameFrameCounterReset:'
					0x8B, (ModRM 3 0 6)                                                             <# mov eax, esi #>
					0x2B, (ModRM 1 0 5), '1:GameFrameTiming/PreviousGameFrameTimeLessSpillover'     <# sub eax, [&PreviousGameFrameTimeLessSpillover] #>
					0x3B, (ModRM 3 0 1)                                                             <# cmp eax, ecx #>
					0x72, '1:MaybeNotPresentingFrame'                                               <# jb MaybeNotPresentingFrame #>
				'PresentingFrame:'
					0x8B, (ModRM 3 3 6)                                                             <# mov ebx, esi #>
					0xF7, (ModRM 3 6 1)                                                             <# div ecx #>
					0x0B, (ModRM 1 7 5), '1:GameFrameTiming/GameFrameProcessingBitMask'             <# or edi, [ebp + GameFrameProcessingBitMask] #>
					0x2B, (ModRM 3 3 2)                                                             <# sub ebx, edx #>
					0x89, (ModRM 1 3 5), '1:GameFrameTiming/PreviousGameFrameTimeLessSpillover'     <# mov [&PreviousGameFrameTimeLessSpillover], ebx #>
				'MaybeNotPresentingFrame:'
					0x81, (ModRM 3 7 5), '&GameFrameTiming'                                         <# cmp ebp, &GameFrameTiming #>
					0x74, '1:PastFrameMaths'                                                        <# je PastFrameMaths #>
					0x83, (ModRM 3 0 5), '1:PresentationFrameTiming/GameFrameTiming'                <# add ebp, &GameFrameTiming - &PresentationFrameTiming #>
					0xEB, '1:FrameMaths'                                                            <# jmp FrameMaths #>
				'PastFrameMaths:'

				'MaybeNotProcessingGameFrame:'
					0x66, 0xF7, (ModRM 3 0 7), 0x02, 0x00                                           <# test di, 0b10 #>
					0x74, '1:MaybeNotHandlingInput'                                                 <# jz MaybeNotHandlingInput #>
				'HandlingInput:'
					0xE8, '4:HandleInput'                                                           <# call HandleInput #>
				'MaybeNotHandlingInput:'
					0xF7, (ModRM 0 0 5), (LE ${&SomeGuard?}), 0xFD, 0xFF, 0xFF, 0xFF                <# test [&SomeGuard?], 0xFFFFFF_0b1111_1101 #>
					0x0F, 0x85, '4:ReturnOne'                                                       <# jnz ReturnOne #>
					0xA1, (LE ${&UnknownA?})                                                        <# mov eax, [&UnknownA?] #>
					0x66, 0xF7, (ModRM 3 0 7), 0x02, 0x00                                           <# test di, 0b10 #>
					0xA3, (LE ${&UnknownB?})                                                        <# mov [&UnknownB?], eax #>
					0x74, '1:SkipGameFrame'                                                         <# jz SkipGameFrame #>
					0x81, (ModRM 0 7 5), '&FPSLimitOption', 0xFF, 0xFF, 0xFF, 0xFF                  <# cmp [&FPSLimitOption], -1 #>
					0x74, '1:SkipGameFrame'                                                         <# je SkipGameFrame #>
					0xE9, '4:BeforeGameFrame'                                                       <# jmp BeforeGameFrame #>
				'PostBeforeGameFrameJump:'
					0xE8, '4:ProcessGameFrameA'                                                     <# call ProcessGameFrameA #>
					0xE8, '4:ProcessGameFrameB'                                                     <# call ProcessGameFrameB #>
					0x83, (ModRM 1 4 5), '1:GameFrameTiming/PresentationFrameIndex', 0x00           <# and [&PresentationFrameIndex], 0 #>
					0xE9, '4:AfterGameFrame'                                                        <# jmp AfterGameFrame #>
				'PostAfterGameFrameJump:'
				'SkipGameFrame:'
					0xA1, '&Direct3D'                                                               <# mov eax, [&Direct3D] #>
					0x0B, (ModRM 0 0 5), '&Direct3DDevice'                                          <# or eax, [&Direct3DDevice] #>
					0x74, '1:ReturnZero'                                                            <# jz ReturnZero #>
					0x66, 0xF7, (ModRM 3 0 7), 0x01, 0x00                                           <# test di, 0b01 #>
					0x74, '1:SkipPresentationFrame'                                                 <# jz SkipPresentationFrame #>
					0x8B, (ModRM 3 0 6)                                                             <# mov eax, esi #>
					0x2B, (ModRM 0 0 5), '&PreviousGameFrameTimeLessSpillover'                      <# sub eax, [&PreviousGameFrameTimeLessSpillover] #>
					0xA3, '&PresentationTimeSinceGameFrame'                                         <# mov [&PresentationTimeSinceGameFrame], eax #>
					0xE9, '4:BeforePresentationFrame'                                               <# jmp BeforePresentationFrame #>
				'PostBeforePresentationFrameJump:'
					0xE8, '4:PresentFrame'                                                          <# call PresentFrame #>
					0xE9, '4:AfterPresentationFrame'                                                <# jmp AfterPresentationFrame #>
				'PostAfterPresentationFrameJump:'
					0x83, (ModRM 1 7 5), '1:GameFrameTiming/PresentationFrameIndex', 0x00           <# cmp [&PresentationFrameIndex], 0 #>
					0x75, '1:PastIncrementOfSomeCounter'                                            <# jne PastIncrementOfSomeCounter #>
					0xFF, (ModRM 0 0 5), (LE ${&SomeCounter?})                                      <# inc [&SomeCounter?] #>
					if ($Version -eq $KnownVersions.JapaneseV1_126)
					{
						0x83, (ModRM 0 7 5), '&SomeCounter?', 0x05                         <# cmp [&SomeCounter?], 5 #>
						0x75, '1:PastCallingOfJapaneseSpecificPresentationRelatedFunction' <# jne PastCallingOfJapaneseSpecificPresentationRelatedFunction #>
						0xE8, '4:JapaneseSpecificPresentationRelatedFunction'              <# call JapaneseSpecificPresentationRelatedFunction #>
					'PastCallingOfJapaneseSpecificPresentationRelatedFunction:'
					}
				'PastIncrementOfSomeCounter:'
					0xFF, (ModRM 1 0 5), '1:GameFrameTiming/PresentationFrameIndex'                 <# inc [&PresentationFrameIndex] #>
				'SkipPresentationFrame:'
					0x83, (ModRM 0 7 5), (LE ${&SomeGuard?}), 0x02                                  <# cmp [&SomeGuard?], 2 #>
					0x75, '1:SkipSettingGuard'                                                      <# jne SkipSettingGuard #>
					0xC7, (ModRM 0 0 5), (LE ${&SomeGuard?}), 0x01, 0x00, 0x00, 0x00                <# mov [&SomeGuard?], 1 #>
				'SkipSettingGuard:'
					0x66, 0xC7, (ModRM 0 0 5), (LE ${&InputDeviceState?}), 0x00, 0x00               <# mov word ptr [&InputDeviceState?], 0 #>
					0x66, 0xC7, (ModRM 0 0 5), (LE ${&UnknownC?}), 0x00, 0x00                       <# mov word ptr [&UnknownC?], 0 #>
				'ReturnZero:'
					0x33, (ModRM 3 0 0)                                                             <# xor eax, eax #>
					0xEB, '1:Return'                                                                <# jmp Return #>
				'ReturnOne:'
					0xB8, 0x01, 0x0, 0x0, 0x0                                                       <# mov eax, 1 #>
				'Return:'
					0x83, (ModRM 3 0 4), 0x08                                                       <# add esp, 8 #>
					0x5F                                                                            <# pop edi #>
					0x5E                                                                            <# pop esi #>
					0x5D                                                                            <# pop ebp #>
					0x5B                                                                            <# pop ebx #>
					0xC3                                                                            <# ret #>
					{@(0x00) * (${#HandleFrame} - $Offset)}
				)


				Preassemble 'DisableMainMenuOpeningFilm' (${&HandleMainMenu} + 3675) (${@HandleMainMenu} + 3675) @(
					0xEB, '1:PastPlayingOfMainMenuOpeningFilm' <# jmp PastPlayingOfMainMenuOpeningFilm #>
					(Get-Nops 20)
				'PastPlayingOfMainMenuOpeningFilm:'
				)


				if ($PatchingFPSDisplay)
				{
					$FPSDisplayFunctionOffset = ${@DrawFPSOSD}
				}


				if ($Script:CameraSmoothingVariant -eq 'InterpolatedV2')
				{
					Preassemble 'CameraHeightSmoothingHijack' ${&CameraHeightSmoothingHijack} ${@CameraHeightSmoothingHijack} @(
						0xE9, '4:InterpolateCameraHeight' <# jmp InterpolateCameraHeight #>
						0x90                              <# nop #>
					)

					Preassemble 'CameraInterpolationHijack' ${&CameraInterpolationHijack} ${@CameraInterpolationHijack} @(
						0xE9, '4:InterpolateCameraPositions' <# jmp InterpolateCameraPositions #>
						0x90                                 <# nop #>
					'PostCameraInterpolationHijack:'
					)
				}


				Hijack 'ShopTillUIEntryTransitionInterpolation[0]' 'DrawTillUI' 66 25 @(
					0xD9, (ModRM 0 0 5), '&InterpolatedShopTillEntryTransitionFloatMirror_Scalar_ActualValue' <# fld [&InterpolatedShopTillEntryTransitionFloatMirror_Scalar_ActualValue] #>
					0xD8, (ModRM 0 1 5), '&4f'                                                                <# fmul [&4f] #>
					0xD9, 0xEE                                                                                <# fldz #>
					0xDF, 0xF1                                                                                <# fcomip st(0), st(1) #>
					0xD9, (ModRM 1 3 5), 0xFC                                                                 <# fstp [ebp - 4] #>
					0x0F, 0x83, '4:AfterShopTillUIBlackBarConditional'                                        <# jae AfterShopTillUIBlackBarConditional #>
					0xD9, (ModRM 1 0 5), 0xFC                                                                 <# fld [ebp - 4] #>
					0xD9, (ModRM 0 0 5), '&32f'                                                               <# fld [&32f] #>
					0xDB, 0xF1                                                                                <# fcomi st(0), st(1) #>
					0x73, '1:ShopTillUIBlackBarInBounds'                                                      <# jae ShopTillUIBlackBarInBounds #>
					0xD9, (ModRM 1 3 5), 0xFC                                                                 <# fstp [ebp - 4] #>
					0xEB, '1:PostShopTillUIBlackBarComparison'                                                <# jmp PostShopTillUIBlackBarComparison #>
				'ShopTillUIBlackBarInBounds:'
					0xDD, 0xD8                                                                                <# fstp st(0) #>
				'PostShopTillUIBlackBarComparison:'
					0xDD, 0xD8                                                                                <# fstp st(0) #>
				)

				Preassemble 'ShopTillUIEntryTransitionInterpolation[1]' (${&DrawTillUI} + 180) (${@DrawTillUI} + 180) @(
					0xD9, (ModRM 1 0 5), 0xFC <# fld [ebp - 4] #>
				)

				Hijack 'ShopTillUIEntryTransitionInterpolation[2]' 'DrawTillUI' 205 5 @(
					0x89, (ModRM 1 0 5), 0xD0 <# mov [ebp - 48], eax #>
					0xDB, (ModRM 1 0 5), 0xD0 <# fild [ebp - 48] #>
					0xD8, (ModRM 1 4 5), 0xFC <# fsub [ebp - 4] #>
					0xD9, (ModRM 1 3 5), 0xD0 <# fstp [ebp - 48] #>
					0x8B, (ModRM 1 0 5), 0xD0 <# mov eax, [ebp - 48] #>
					0xD9, (ModRM 1 3 5), 0xD0 <# fstp [ebp - 48] #>
				)

				if ($Script:UsingIntegral2DScaling)
				{
					Hijack 'ShopTillUIEntryTransitionInterpolation[3]' 'DrawTillUI' 214 6 @(
						0x8D, (ModRM 1 0 5), 0xC0                 <# lea eax, [ebp - 64] #>
						0xD9, (ModRM 1 0 5), 0xF0                 <# fld [ebp - 16] #>
						0xD8, (ModRM 0 0 5), '&2DLetterboxHeight' <# fadd [&2DLetterboxHeight] #>
					)
				}
				else
				{
					Preassemble 'ShopTillUIEntryTransitionInterpolation[3]' (${&DrawTillUI} + 217) (${@DrawTillUI} + 217) @(
						0xD9, (ModRM 1 0 5), 0xF0 <# fld [ebp - 16] #>
					)
				}

				Hijack 'ShopTillUIEntryTransitionInterpolation[4]' 'DrawTillUI' 264 12 @(
					0xD9, (ModRM 0 0 5), '&InterpolatedShopTillEntryTransitionFloatMirror_Scalar_ActualValue' <# fld [&InterpolatedShopTillEntryTransitionFloatMirror_Scalar_ActualValue] #>
					0xD8, (ModRM 0 1 5), '&ShopTillCustomerPositionCounterMultiplier'                         <# fmul [&ShopTillCustomerPositionCounterMultiplier] #>
				)

				Preassemble 'AfterShopTillUIBlackBarConditional' (${&DrawTillUI} + 264) (${@DrawTillUI} + 264) @()

				Preassemble 'PositionShopTillUIRecetPositionOffset' (${&DrawTillUI} + 284) (${@DrawTillUI} + 284) @('&ShopTillRecetPositionOffset')

				Hijack 'ShopTillUICustomerPositionInterpolation' 'DrawTillUI' 444 12 @(
					0xD9, (ModRM 0 0 5), '&InterpolatedShopTillCustomerPositionFloatMirror_Scalar_ActualValue' <# fld [&InterpolatedShopTillCustomerPositionFloatMirror_Scalar_ActualValue] #>
					0xD8, (ModRM 0 1 5), '&ShopTillCustomerPositionCounterMultiplier'                          <# fmul [&ShopTillCustomerPositionCounterMultiplier] #>
				)

				if ($Script:UsingIntegral2DScaling)
				{
					Hijack 'PositionTillUIRecetVertically' 'DrawTillUI' 397 5 @(
						0xD9, (ModRM 0 0 5), '&2DLetterboxHeight' <# fld [&2DLetterboxHeight] #>
						0xD9, (ModRM 1 3 5), 0xD4                 <# fstp [ebp - 44] #>
					)

					Hijack 'PositionTillUICustomerVertically' 'DrawTillUI' 581 5 @(
						0xD9, (ModRM 0 0 5), '&2DLetterboxHeight' <# fld [&2DLetterboxHeight] #>
						0xD9, (ModRM 1 3 5), 0xD4                 <# fstp [ebp - 44] #>
					)

					Preassemble 'PositionTillUIEquipmentStatDiffVertically[0]' (${&DrawTillUI} + 1911) (${@DrawTillUI} + 1911) @('&ShopEquipmentStatDiffYOffset24')
					Preassemble 'PositionTillUIEquipmentStatDiffVertically[1]' (${&DrawTillUI} + 1958) (${@DrawTillUI} + 1958) @('&ShopEquipmentStatDiffYOffset36')
					Preassemble 'PositionTillUIEquipmentStatDiffVertically[2]' (${&DrawTillUI} + 2007) (${@DrawTillUI} + 2007) @('&ShopEquipmentStatDiffYOffset44')

					Preassemble 'PositionTillUIShowcaseItemSparklesVertically[0]' (${&SomeShopRelatedGameLogic} + 513) (${@SomeShopRelatedGameLogic} + 513) @('&ShowCaseItemSparklesYOffset')
					Preassemble 'PositionTillUIShowcaseItemSparklesVertically[1]' (${&SomeShopRelatedGameLogic} + 598) (${@SomeShopRelatedGameLogic} + 598) @('&ShowCaseItemSparklesYOffset')
				}


				$MultiplyTearMenuTransitionCounter =
				{
					Param ([SByte] $Offset)
					@(
						0xD9, (ModRM 0 0 5), '&InterpolatedTearMenuTransitionCounterFloatMirror_Scalar_ActualValue' <# fld [&InterpolatedTearMenuTransitionCounterFloatMirror_Scalar_ActualValue] #>
						0xD8, (ModRM 0 1 5), '&TearMenuTransitionCounterMultiplier'                                 <# fmul [&TearMenuTransitionCounterMultiplier] #>
						0xD9, (ModRM 1 3 5), (LE $Offset)                                                           <# fstp [ebp + $Offset] #>
					)
				}

				$LoadMultipliedTearMenuTransitionCounter =
				{
					Param ([SByte] $Offset)
					@(
						0xD9, (ModRM 1 0 5), (LE $Offset) <# fld [ebp + $Offset] #>
					)
				}


				[Call]::NewLabel('PositionTearMenuTransition[0][0]Hijack', $AddressOf.'PositionTearMenuTransition[0][0]Hijack', (VirtualAddressToFileOffset $AddressOf.'PositionTearMenuTransition[0][0]Hijack'))
				[Call]::NewLabel('PositionTearMenuTransition[1][0]Hijack', $AddressOf.'PositionTearMenuTransition[1][0]Hijack', (VirtualAddressToFileOffset $AddressOf.'PositionTearMenuTransition[1][0]Hijack'))
				[Call]::NewLabel('PositionTearMenuTransition[2][0]Hijack', $AddressOf.'PositionTearMenuTransition[2][0]Hijack', (VirtualAddressToFileOffset $AddressOf.'PositionTearMenuTransition[2][0]Hijack'))
				[Call]::NewLabel('PositionTearMenuTransition[3][0]Hijack', $AddressOf.'PositionTearMenuTransition[3][0]Hijack', (VirtualAddressToFileOffset $AddressOf.'PositionTearMenuTransition[3][0]Hijack'))
				# Broken in Japanese version.

				if ($Version -eq $KnownVersions.EnglishV1_108)
				{
					Hijack 'PositionTearMenuTransition[0][0]' 'PositionTearMenuTransition[0][0]Hijack' 0 6 (& $MultiplyTearMenuTransitionCounter -4)
					Preassemble 'PositionTearMenuTransition[0][1]' (${&PositionTearMenuTransition[0][0]Hijack} + 11) (${@PositionTearMenuTransition[0][0]Hijack} + 11) (& $LoadMultipliedTearMenuTransitionCounter -4)
					Preassemble 'PositionTearMenuTransition[0][2]' (${&PositionTearMenuTransition[0][0]Hijack} + 27) (${@PositionTearMenuTransition[0][0]Hijack} + 27) @('&GameBaseWidthPlusUIPillarbox')
					Hijack 'PositionTearMenuTransition[1][0]' 'PositionTearMenuTransition[1][0]Hijack' 0 6 (& $MultiplyTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[1][1]' (${&PositionTearMenuTransition[1][0]Hijack} + 11) (${@PositionTearMenuTransition[1][0]Hijack} + 11) (& $LoadMultipliedTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[1][2]' (${&PositionTearMenuTransition[1][0]Hijack} + 26) (${@PositionTearMenuTransition[1][0]Hijack} + 26) @('&GameBaseWidthPlusUIPillarbox')
					Hijack 'PositionTearMenuTransition[2][0]' 'PositionTearMenuTransition[2][0]Hijack' 0 6 (& $MultiplyTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[2][1]' (${&PositionTearMenuTransition[2][0]Hijack} + 11) (${@PositionTearMenuTransition[2][0]Hijack} + 11) (& $LoadMultipliedTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[2][2]' (${&PositionTearMenuTransition[2][0]Hijack} + 26) (${@PositionTearMenuTransition[2][0]Hijack} + 26) @('&GameBaseWidthPlusUIPillarbox')
					Hijack 'PositionTearMenuTransition[3][0]' 'PositionTearMenuTransition[3][0]Hijack' 0 6 (& $MultiplyTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[3][1]' (${&PositionTearMenuTransition[3][0]Hijack} + 11) (${@PositionTearMenuTransition[3][0]Hijack} + 11) (& $LoadMultipliedTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[3][2]' (${&PositionTearMenuTransition[3][0]Hijack} + 26) (${@PositionTearMenuTransition[3][0]Hijack} + 26) @('&GameBaseWidthPlusUIPillarbox')
				}
				elseif ($Version -eq $KnownVersions.JapaneseV1_126)
				{
					Hijack 'PositionTearMenuTransition[0][0]' 'PositionTearMenuTransition[0][0]Hijack' 0 6 (& $MultiplyTearMenuTransitionCounter -4)
					Preassemble 'PositionTearMenuTransition[0][1]' (${&PositionTearMenuTransition[0][0]Hijack} + 11) (${@PositionTearMenuTransition[0][0]Hijack} + 11) (& $LoadMultipliedTearMenuTransitionCounter -4)
					Preassemble 'PositionTearMenuTransition[0][2]' (${&PositionTearMenuTransition[0][0]Hijack} + 27) (${@PositionTearMenuTransition[0][0]Hijack} + 27) @('&GameBaseWidthPlusUIPillarbox')
					Hijack 'PositionTearMenuTransition[1][0]' 'PositionTearMenuTransition[1][0]Hijack' 0 6 (& $MultiplyTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[1][1]' (${&PositionTearMenuTransition[1][0]Hijack} + 11) (${@PositionTearMenuTransition[1][0]Hijack} + 11) (& $LoadMultipliedTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[1][2]' (${&PositionTearMenuTransition[1][0]Hijack} + 27) (${@PositionTearMenuTransition[1][0]Hijack} + 27) @('&GameBaseWidthPlusUIPillarbox')
					Hijack 'PositionTearMenuTransition[2][0]' 'PositionTearMenuTransition[2][0]Hijack' 0 6 (& $MultiplyTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[2][1]' (${&PositionTearMenuTransition[2][0]Hijack} + 11) (${@PositionTearMenuTransition[2][0]Hijack} + 11) (& $LoadMultipliedTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[2][2]' (${&PositionTearMenuTransition[2][0]Hijack} + 27) (${@PositionTearMenuTransition[2][0]Hijack} + 27) @('&GameBaseWidthPlusUIPillarbox')
					Hijack 'PositionTearMenuTransition[3][0]' 'PositionTearMenuTransition[3][0]Hijack' 0 6 (& $MultiplyTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[3][1]' (${&PositionTearMenuTransition[3][0]Hijack} + 11) (${@PositionTearMenuTransition[3][0]Hijack} + 11) (& $LoadMultipliedTearMenuTransitionCounter -24)
					Preassemble 'PositionTearMenuTransition[3][2]' (${&PositionTearMenuTransition[3][0]Hijack} + 28) (${@PositionTearMenuTransition[3][0]Hijack} + 28) @('&GameBaseWidthPlusUIPillarbox')
				}

				Hijack 'PositionTearLectureButtonTransition' 'DrawShopHUD' $OffsetFor.PositionTearLectureButtonTransition 11 @(
					0xD9, (ModRM 0 0 5), '&InterpolatedTearLectureButtonTransitionCounterFloatMirror_Scalar_ActualValue' <# fld [&InterpolatedTearLectureButtonTransitionCounterFloatMirror_Scalar_ActualValue] #>
					0xD8, (ModRM 0 1 5), '&TearLectureButtonTransitionCounterMultiplier'                                 <# fmul [&TearLectureButtonTransitionCounterMultiplier] #>
					0xD8, (ModRM 0 4 5), '&UIPillarboxWidth'                                                             <# fsub [&UIPillarboxWidth] #>
				)


				Preassemble 'AlwaysSpawnNagiWhenCheatIsEnabled' @(
					0x83, (ModRM 1 4 5), 0xD0, 0x00                    <# and [ebp - 48], 0 #>
					0x83, (ModRM 1 4 5), 0xCC, 0x00                    <# and [ebp - 52], 0 #>
					0x83, (ModRM 0 7 5), '&AlwaysSpawnNagi', 0x00      <# cmp [&AlwaysSpawnNagi], 0 #>
					0x0F, 0x84, '4:PostNagiEncounterRNGOverrideHijack' <# je PostNagiEncounterRNGOverrideHijack #>
					0xFF, (ModRM 1 0 5), 0xD0                          <# inc [ebp - 48] #>
					0xE9, '4:PostNagiEncounterRNGOverrideHijack'       <# jmp PostNagiEncounterRNGOverrideHijack #>
				)


				Preassemble 'NagiEncounterRNGOverrideHijack' ${&NagiEncounterRNGOverrideHijack} ${@NagiEncounterRNGOverrideHijack} @(
					0xE9, '4:AlwaysSpawnNagiWhenCheatIsEnabled' <# jmp AlwaysSpawnNagiWhenCheatIsEnabled #>
					(Get-Nop 3)                                 <# nop #>
				'PostNagiEncounterRNGOverrideHijack:'
				)


				if ($Script:HideChangeCameraControlReminder)
				{
					Preassemble 'SuppressChangeCameraControlReminder' (${&DrawShopHUD} + $OffsetFor.SuppressChangeCameraControlReminder) (${@DrawShopHUD} + $OffsetFor.SuppressChangeCameraControlReminder) @(
						0x90 <# nop #>
						0xE9 <# jmp #>
					)
				}


				if ($Script:HideSkipEventControlReminder)
				{
					Preassemble 'SuppressSkipEventControlReminder' (${&DrawsCutsceneAndMore} + 3660) (${@DrawsCutsceneAndMore} + 3660) @(
						0x90 <# nop #>
						0xE9 <# jmp #>
					)
				}


				if ($Script:HideItemDetailsControlReminderWhenHaggling)
				{
					Preassemble 'SuppressItemDetailsControlReminderWhenHaggling' (${&DrawHagglingUI} + $OffsetFor.SuppressItemDetailsControlReminderWhenHaggling) (${@DrawHagglingUI} + $OffsetFor.SuppressItemDetailsControlReminderWhenHaggling) @(
						0xEB, '1:PostSuppressItemDetailsControlReminderWhenHaggling' <# jmp PostSuppressItemDetailsControlReminderWhenHaggling #>
						(Get-Nops 119)                                               <# nop #>
					'PostSuppressItemDetailsControlReminderWhenHaggling:'
					)
				}


				if ($Script:HideItemDetailsControlReminderInItemMenus)
				{
					Preassemble 'SuppressItemDetailsControlReminderInItemMenus' (${&DrawMenu} + 3515) (${@DrawMenu} + 3515) @(
						0xEB, '1:PostSuppressItemDetailsControlReminderInItemMenus' <# jmp PostSuppressItemDetailsControlReminderInItemMenus #>
						(Get-Nops 119)                                              <# nop #>
					'PostSuppressItemDetailsControlReminderInItemMenus:'
					)
				}


				if ($Script:PatchingAspectRatio)
				{
					if ('Real' -eq $Script:MobDrawDistancePatchVariant)
					{
						Preassemble 'OverrideMobDrawDistance[0]' (${&SetSomeMobData} + 776) (${@SetSomeMobData} + 776) @('&MobDrawDistanceShort')
						Preassemble 'OverrideMobDrawDistance[1]' (${&SetSomeMobData} + 804) (${@SetSomeMobData} + 804) @('&MobDrawDistanceLong')
						Preassemble 'OverrideMobDrawDistance[2]' (${&SetSomeMobData} + 832) (${@SetSomeMobData} + 832) @('&MobDrawDistanceLong')
					}
					elseif ('OnlyVisual' -eq $Script:MobDrawDistancePatchVariant)
					{
						#Preassemble 'IgnoreMobDrawDistance[0]' @(
						#	0x83, (ModRM 0 7 7), 0x02                          <# cmp [edi], 2 #>
						#	0x0F, 0x84, '4:PostIgnoreMobDrawDistance[0]Hijack' <# je PostIgnoreMobDrawDistance[0]Hijack #>
						#	0xE9, '4:IgnoreMobDrawDistance[0]AfterConditional' <# jmp IgnoreMobDrawDistance[0]AfterConditional #>
						#)
#
						#Preassemble 'IgnoreMobDrawDistance[0]Hijack' (${&ReallyBigPresentationFunction} + 10129) (${@ReallyBigPresentationFunction} + 10129) @(
						#	'4:IgnoreMobDrawDistance[0]'
						#'PostIgnoreMobDrawDistance[0]Hijack:'
						#)
#
						#Preassemble 'IgnoreMobDrawDistance[0]AfterConditional' (${&ReallyBigPresentationFunction} + 10618) (${@ReallyBigPresentationFunction} + 10618) @()

						#Preassemble 'IgnoreMobDrawDistance[1]' @(
						#	0x83, (ModRM 2 7 7), 0xD0, 0x06, 0x00, 0x00, 0x02  <# cmp [edi + 1744], 2 #>
						#	0x0F, 0x84, '4:PostIgnoreMobDrawDistance[1]Hijack' <# je PostIgnoreMobDrawDistance[1]Hijack #>
						#	0xE9, '4:IgnoreMobDrawDistance[1]AfterConditional' <# jmp IgnoreMobDrawDistance[1]AfterConditional #>
						#)
#
						#Preassemble 'IgnoreMobDrawDistance[1]Hijack' (${&SomeRenderingFunction} + 465) (${@SomeRenderingFunction} + 465) @(
						#	'4:IgnoreMobDrawDistance[1]'
						#'PostIgnoreMobDrawDistance[1]Hijack:'
						#)
#
						#Preassemble 'IgnoreMobDrawDistance[1]AfterConditional' (${&SomeRenderingFunction} + 751) (${@SomeRenderingFunction} + 751) @()

						Preassemble 'IgnoreMobDrawDistance[2]' @(
							0x83, (ModRM 2 7 6), 0xA4, 0x06, 0x00, 0x00, 0x02  <# cmp [esi + 1700], 2 #>
							0x0F, 0x84, '4:PostIgnoreMobDrawDistance[2]Hijack' <# je PostIgnoreMobDrawDistance[2]Hijack #>
							0xE9, '4:IgnoreMobDrawDistance[2]AfterConditional' <# jmp IgnoreMobDrawDistance[2]AfterConditional #>
						)

						Preassemble 'IgnoreMobDrawDistance[2]Hijack' (${&SomeRenderingFunction} + 4696) (${@SomeRenderingFunction} + 4696) @(
							'4:IgnoreMobDrawDistance[2]'
						'PostIgnoreMobDrawDistance[2]Hijack:'
						)

						Preassemble 'IgnoreMobDrawDistance[2]AfterConditional' (${&SomeRenderingFunction} + 5158) (${@SomeRenderingFunction} + 5158) @()

						#Preassemble 'IgnoreMobDrawDistance[3]' @(
						#	0x83, (ModRM 0 7 6), 0x02                          <# cmp [esi], 2 #>
						#	0x0F, 0x84, '4:PostIgnoreMobDrawDistance[3]Hijack' <# je PostIgnoreMobDrawDistance[3]Hijack #>
						#	0xE9, '4:IgnoreMobDrawDistance[3]AfterConditional' <# jmp IgnoreMobDrawDistance[3]AfterConditional #>
						#)
#
						#Preassemble 'IgnoreMobDrawDistance[3]Hijack' (${&MoreMobRelatedRendering} + 1255) (${@MoreMobRelatedRendering} + 1255) @(
						#	'4:IgnoreMobDrawDistance[3]'
						#'PostIgnoreMobDrawDistance[3]Hijack:'
						#)
#
						#Preassemble 'IgnoreMobDrawDistance[3]AfterConditional' (${&MoreMobRelatedRendering} + 1650) (${@MoreMobRelatedRendering} + 1650) @()
#
						#Hijack 'IgnoreMobDrawDistance[4]Hijack' 'MoreMobRelatedRendering' 1855 10 @(
						#	0x83, (ModRM 0 7 6), 0x02                                <# cmp [esi], 2 #>
						#	0x74, '1:IgnoringMobDrawDistance[4]'                     <# je IgnoringMobDrawDistance[4] #>
						#	0x39, (ModRM 0 3 6)                                      <# cmp [esi], ebx #>
						#	0x0F, 0x8F, '4:IgnoreMobDrawDistance[4]AfterConditional' <# jg IgnoreMobDrawDistance[4]AfterConditional #>
						#'IgnoringMobDrawDistance[4]:'
						#	0x8B, (ModRM 2 0 5), 0x30, 0xF9, 0xFF, 0xFF              <# mov eax, [esi - 1744] #>
						#)
#
						#Preassemble 'IgnoreMobDrawDistance[4]AfterConditional' (${&MoreMobRelatedRendering} + 1902) (${@MoreMobRelatedRendering} + 1902) @()
#
						Preassemble 'IgnoreMobDrawDistance[5]' @(
							0x83, (ModRM 2 7 3), 0xF0, 0x00, 0x00, 0x00, 0x02  <# cmp [ebx + 240], 2 #>
							0x0F, 0x84, '4:PostIgnoreMobDrawDistance[5]Hijack' <# je PostIgnoreMobDrawDistance[5]Hijack #>
							0xE9, '4:IgnoreMobDrawDistance[5]AfterConditional' <# jmp IgnoreMobDrawDistance[5]AfterConditional #>
						)

						Preassemble 'IgnoreMobDrawDistance[5]Hijack' (${&DrawShadows} + 1084) (${@DrawShadows} + 1084) @(
							'4:IgnoreMobDrawDistance[5]'
						'PostIgnoreMobDrawDistance[5]Hijack:'
						)

						Preassemble 'IgnoreMobDrawDistance[5]AfterConditional' (${&DrawShadows} + 1729) (${@DrawShadows} + 1729) @()
					}


					Preassemble 'OverrideWorldDrawDistance[0]' (${&DrawWorld} + 1123) (${@DrawWorld} + 1123) @('&WorldDrawDistanceShort')
					Preassemble 'OverrideWorldDrawDistance[1]' (${&DrawWorld} + 1115) (${@DrawWorld} + 1115) @('&WorldDrawDistanceLong')

					Preassemble 'OverrideFloraDrawDistance' (${&DrawFlora} + 866) (${@DrawFlora} + 866) @('&FloraDrawDistance')

					Preassemble 'OverrideShadowDrawDistance' (${&DrawShadows} + 2826) (${@DrawShadows} + 2826) @('&ShadowDrawDistance')


					Preassemble 'WindowProcedureAspectRatioFixingHeight' (${&WindowProcedure} + 173) (${@WindowProcedure} + 173) @((LE $PatchedAspectRatioDenominator))
					Preassemble 'WindowProcedureAspectRatioFixingWidth' (${&WindowProcedure} + 179) (${@WindowProcedure} + 179) @((LE $PatchedAspectRatioNumerator))

					${&UIStuffFunction} = $AddressOf.UIStuffFunction
					${@UIStuffFunction} =  VirtualAddressToFileOffset ${&UIStuffFunction}

					[Call]::NewLabel('UIStuffFunction', ${&UIStuffFunction}, ${@UIStuffFunction}, 562, $Null)
					[Call]::NewLabel('UIStuffFunctionWrapper[0]', $AddressOf.'UIStuffFunctionWrapper[0]', (VirtualAddressToFileOffset $AddressOf.'UIStuffFunctionWrapper[0]'), 55, $Null)

					${*UIStuffFunction} = [Byte[]]::new(${#UIStuffFunction})
					$File.Position = ${@UIStuffFunction}
					$File.Read(${*UIStuffFunction}, 0, ${#UIStuffFunction}) > $Null

					${*UIStuffFunctionWrapper[0]} = [Byte[]]::new(${#UIStuffFunctionWrapper[0]})
					$File.Position = ${@UIStuffFunctionWrapper[0]}
					$File.Read(${*UIStuffFunctionWrapper[0]}, 0, ${#UIStuffFunctionWrapper[0]}) > $Null


					Preassemble 'UIStuffFunctionHijack' ${&UIStuffFunction} ${@UIStuffFunction} @(
						0xE9, '4:UIStuffReplacementWithPillarboxing' <# jmp UIStuffReplacementWithPillarboxing #>
						0x90                                         <# nop #>
					)


					${&__ftol} = [UInt32] ($AddressOf.__ftol - $ImageBase)


					Preassemble 'UIStuffReplacement' @(
					'UIStuffReplacementWithHorizontalScaling:'
						0xBA, 0x03, 0x00, 0x00, 0x00                  <# mov edx, 0b0011 #>
						0xEB, '1:UIStuffReplacementWithArgumentInEDX' <# jmp UIStuffReplacementWithArgumentInEDX #>
					'UIStuffReplacementDirect:'
						0xBA, 0x08, 0x00, 0x00, 0x00                  <# mov edx, 0b1000 #>
						0xEB, '1:UIStuffReplacementWithArgumentInEDX' <# jmp UIStuffReplacementWithArgumentInEDX #>
					'UIStuffReplacementWithPillarboxing:'
						0x33, (ModRM 3 2 2)                           <# xor edx, edx #>
					'UIStuffReplacementWithArgumentInEDX:'

						if ($Debug)
						{
						'UIStuffReplacementSkip:'
							0x83, (ModRM 0 7 5), '&SkipUIStuffReplacement', 0x00 <# cmp [&SkipUIStuffReplacement], 0 #>
							0x74, '1:NotSkippingUIStuffReplacement'              <# je NotSkippingUIStuffReplacement #>
							0xFF, (ModRM 0 1 5), '&SkipUIStuffReplacement'       <# dec, [&SkipUIStuffReplacement] #>
							0xC3                                                 <# ret #>
						'NotSkippingUIStuffReplacement:'
						}

						(Slice ${*UIStuffFunction} 0 6)
						0xF7, (ModRM 3 0 2), 0x01, 0x00, 0x00, 0x00   <# test edx, 0b0001 #>

						if ($Script:UsingIntegral2DScaling)
						{
							0x74, '1:Using2DResolutionWidth'          <# jz Using2DResolutionWidth #>
							(Slice ${*UIStuffFunction} 6 12)
							0xEB, '1:LoadedResolutionWidth'           <# jmp LoadedResolutionWidth #>
						'Using2DResolutionWidth:'
							0xD9, (ModRM 0 0 5), '&2DResolutionWidth' <# fld [&2DResolutionWidth] #>
						'LoadedResolutionWidth:'
						}
						else
						{
							(Slice ${*UIStuffFunction} 6 12)
						}

						(Slice ${*UIStuffFunction} 12 16)
						0xD9, (ModRM 0 0 5), '&XScale'                <# fld [&XScale] #>
						0xF7, (ModRM 3 0 2), 0x08, 0x00, 0x00, 0x00   <# test edx, 0b1000 #>
						0x75, '1:PastMungingOfUIStuff'                <# jnz PastMungingOfUIStuff #>
						0xF7, (ModRM 3 0 2), 0x01, 0x00, 0x00, 0x00   <# test edx, 0b0001 #>
					# Offsets horizontally
						0xD9, (ModRM 0 0 6)                           <# fld [esi] #>
						0x74, '1:PillarboxHorizontalOffset'           <# jz PillarboxHorizontalOffset #>
					'ScaleHorizontalOffset:'
						0xD8, 0xC9                                    <# fmul st(0), st(1) #>
						0xEB, '1:PastMungingOfHorizontalOffset'       <# jmp PastMungingOfHorizontalOffset #>
					'PillarboxHorizontalOffset:'
						if ($Script:UsingIntegral2DScaling)
						{
							0xD8, (ModRM 0 0 5), '&2DPillarboxWidth' <# fadd [&2DPillarboxWidth] #>
						}
						else
						{
							0xD8, (ModRM 0 0 5), '&PillarboxWidth'   <# fadd [&PillarboxWidth] #>
						}
					'PastMungingOfHorizontalOffset:'
						0xD9, (ModRM 0 3 6)                           <# fstp [esi] #>
						if ($Script:UsingIntegral2DScaling)
						{
							0x83, (ModRM 0 7 5), '&Anchor2DToBottom', 0x00 <# cmp [&Anchor2DToBottom], 0 #>
							0x75, '1:ApplyLetterboxVerticalBottomOffset'   <# jne ApplyLetterboxVerticalBottomOffset #>
						'LetterboxVerticalOffset:'
							0xF7, (ModRM 3 0 2), 0x02, 0x00, 0x00, 0x00    <# test edx, 0b0010 #>
							0x75, '1:LetterboxVerticalBottomOffset'        <# jnz LetterboxVerticalBottomOffset #>
							0xD9, (ModRM 1 0 6), 0x04                      <# fld [esi + 4] #>
							0xD8, (ModRM 0 0 5), '&2DLetterboxHeight'      <# fadd [&2DLetterboxHeight] #>
							0xD9, (ModRM 1 3 6), 0x04                      <# fstp [esi + 4] #>
						'LetterboxVerticalBottomOffset:'
							0xF7, (ModRM 3 0 2), 0x04, 0x00, 0x00, 0x00    <# test edx, 0b0100 #>
							0x74, '1:PastMungingOfVerticalOffset'          <# jz PastMungingOfVerticalOffset #>
						'ApplyLetterboxVerticalBottomOffset:'
							0xD9, (ModRM 1 0 6), 0x04                      <# fld [esi + 4] #>
							0xD8, (ModRM 0 0 5), '&2DTotalLetterboxHeight' <# fadd [&2DTotalLetterboxHeight] #>
							0xD9, (ModRM 1 3 6), 0x04                      <# fstp [esi + 4] #>
						'PastMungingOfVerticalOffset:'
						}
					# Increases distance vertically
						#0xD9, (ModRM 1 0 6), 0x04                    <# fld [esi + 4] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 1 3 6), 0x04                    <# fstp [esi + 4] #>
					# Stretches horizontally
						0xF7, (ModRM 3 0 2), 0x01, 0x00, 0x00, 0x00   <# test edx, 0b0001 #>
						0x74, '1:PastHorizontalStretching'            <# jz PastHorizontalStretching #>
						0xD9, (ModRM 1 0 6), 0x08                     <# fld [esi + 8] #>
						0xD8, 0xC9                                    <# fmul st(0), st(1) #>
						0xD9, (ModRM 1 3 6), 0x08                     <# fstp [esi + 8] #>
					'PastHorizontalStretching:'
					'PastMungingOfUIStuff:'
					# Does nothing?
						#0xD9, (ModRM 1 0 6), 0x0C                    <# fld [esi + 12] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 1 3 6), 0x0C                    <# fstp [esi + 12] #>
						(Slice ${*UIStuffFunction} 16 19)
					# Crashes the game
						#0xD9, (ModRM 0 0 0)                          <# fld [eax] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 0 3 0)                          <# fstp [eax] #>
					# Oh my...
						#0xD9, (ModRM 1 0 0), 0x04                    <# fld [eax + 4] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 1 3 0), 0x04                    <# fstp [eax + 4] #>
					# ...Similarly
						#0xD9, (ModRM 1 0 0), 0x08                    <# fld [eax + 8] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 1 3 0), 0x08                    <# fstp [eax + 8] #>
					# Does nothing?
						#0xD9, (ModRM 1 0 0), 0x0C                    <# fld [eax + 12] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 1 3 0), 0x0C                    <# fstp [eax + 12] #>
						0xDD, 0xD8                                    <# fstp st(0) #>
						(Slice ${*UIStuffFunction} 19 25)
						0xD8, (ModRM 0 6 5), '&ScaledBaseWidth'       <# fdiv [&ScaledBaseWidth] #>
						#0xD8, (ModRM 0 6 5), '&_640fv'               <# fdiv [&_640fv] #>
						#0xD8, (ModRM 0 6 5), '&_640f'                <# fdiv [&_640f] #>
						(Slice ${*UIStuffFunction} 31 40)
						#0xD8, (ModRM 0 0 5), '&_100_0f'              <# fadd [&_100_0f] #>
						#0xD9, 0xEE                                   <# fldz #>
						#0xDE, 0xC1                                   <# faddp #>
						(Slice ${*UIStuffFunction} 40 93)
						0xE8, '4:__ftol'                              <# call __ftol #>
						(Slice ${*UIStuffFunction} 98 118)
						0xE8, '4:__ftol'                              <# call __ftol #>
						(Slice ${*UIStuffFunction} 123 129)
						#0xD9, (ModRM 0 0 5), '&XScale'               <# fld [&XScale] #>
					# Also a black screen
						#0xD9, (ModRM 0 0 2)                          <# fld [edx] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 0 3 2)                          <# fstp [edx] #>
					# Beats me
						#0xD9, (ModRM 1 0 2), 0x04                    <# fld [edx + 4] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 1 3 2), 0x04                    <# fstp [edx + 4] #>
					# Also unknown
						#0xD9, (ModRM 1 0 2), 0x08                    <# fld [edx + 8] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 1 3 2), 0x08                    <# fstp [edx + 8] #>
					# Unknown
						#0xD9, (ModRM 1 0 2), 0x0C                    <# fld [edx + 12] #>
						#0xD8, 0xC9                                   <# fmul st(0), st(1) #>
						#0xD9, (ModRM 1 3 2), 0x0C                    <# fstp [edx + 12] #>
						#0xDD, 0xD8                                   <# fstp st(0) #>
						(Slice ${*UIStuffFunction} 129 ${#UIStuffFunction})
					)


					Preassemble 'UIStuffFunctionWrapper[0]CloneWithScaling' @(
						(Slice ${*UIStuffFunctionWrapper[0]} 0 46)
						'4:UIStuffReplacementWithHorizontalScaling'
						(Slice ${*UIStuffFunctionWrapper[0]} 50 ${#UIStuffFunctionWrapper[0]})
					)


					Preassemble 'AspectRatioReplacement' ${&AspectRatio} ${@AspectRatio} @(
						(LE ([Float] $PatchedAspectRatio))
					)

					#Preassemble '_640fReplacement' ${&_640f} ${@_640f} @(
					#	(LE ([Float] $ScaledBaseWidth))
					#)

					[Call]::NewLabel('TwoDimensionalStuff[0]', $AddressOf.'TwoDimensionalStuff[0]', (VirtualAddressToFileOffset $AddressOf.'TwoDimensionalStuff[0]'), 100, $Null)
					#Preassemble 'TwoDimensionalStuff[0][0]' (${&TwoDimensionalStuff[0]} + 25) (${@TwoDimensionalStuff[0]} + 25) @('&ScaledBaseWidth')
					#Preassemble 'TwoDimensionalStuff[0][1]' (${&TwoDimensionalStuff[0]} + 46) (${@TwoDimensionalStuff[0]} + 46) @('&ScaledBaseWidth')
					#Preassemble 'TwoDimensionalStuff[0][2]' (${&TwoDimensionalStuff[0]} + 61) (${@TwoDimensionalStuff[0]} + 61) @('&ScaledBaseWidth')
					Preassemble 'TwoDimensionalStuff[0][3]' (${&TwoDimensionalStuff[0]} + 76) (${@TwoDimensionalStuff[0]} + 76) @('&ScaledBaseWidth')
					Preassemble 'TwoDimensionalStuff[0][4]' (${&TwoDimensionalStuff[0]} + 91) (${@TwoDimensionalStuff[0]} + 91) @('4:UIStuffReplacementWithHorizontalScaling')

					[Call]::NewLabel('TwoDimensionalStuff[2]', $AddressOf.'TwoDimensionalStuff[2]', (VirtualAddressToFileOffset $AddressOf.'TwoDimensionalStuff[2]'), 550, $Null)
					${*TwoDimensionalStuff[2]} = [Byte[]]::new(${#TwoDimensionalStuff[2]})
					$File.Position = ${@TwoDimensionalStuff[2]}
					$File.Read(${*TwoDimensionalStuff[2]}, 0, ${#TwoDimensionalStuff[2]}) > $Null

					Preassemble 'TwoDimensionalStuff[2]Replacement' @(
						(Slice ${*TwoDimensionalStuff[2]} 0 16)
						0xD9, (ModRM 0 0 6)                     <# fld [esi] #>
						0xD8, (ModRM 0 0 5), '&PillarboxWidth'  <# fadd [&PillarboxWidth] #>
						0xD9, (ModRM 0 3 6)                     <# fstp [esi] #>
						(Slice ${*TwoDimensionalStuff[2]} 16 25)
						0xD8, (ModRM 0 6 5), '&ScaledBaseWidth' <# fdiv [&ScaledBaseWidth] #>
						(Slice ${*TwoDimensionalStuff[2]} 31 93)
						0xE8, '4:__ftol'                        <# call __ftol #>
						(Slice ${*TwoDimensionalStuff[2]} 98 118)
						0xE8, '4:__ftol'                        <# call __ftol #>
						(Slice ${*TwoDimensionalStuff[2]} 123 ${#TwoDimensionalStuff[2]})
					)

					[Call]::NewLabel('TwoDimensionalStuff[3]', $AddressOf.'TwoDimensionalStuff[3]', (VirtualAddressToFileOffset $AddressOf.'TwoDimensionalStuff[3]'), 146, $Null)
					Preassemble 'TwoDimensionalStuff[3][0]' (${&TwoDimensionalStuff[3]} + 22) (${@TwoDimensionalStuff[3]} + 22) @('&ScaledBaseWidth')

					[Call]::NewLabel('TwoDimensionalStuff[4]', $AddressOf.'TwoDimensionalStuff[4]', (VirtualAddressToFileOffset $AddressOf.'TwoDimensionalStuff[4]'), 390, $Null)
					Preassemble 'TwoDimensionalStuff[4][0]' (${&TwoDimensionalStuff[4]} + 236) (${@TwoDimensionalStuff[4]} + 236) @('&ScaledBaseWidth')
					Preassemble 'TwoDimensionalStuff[4][1]' (${&TwoDimensionalStuff[4]} + 257) (${@TwoDimensionalStuff[4]} + 257) @('&ScaledBaseWidth')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'TwoDimensionalStuff[4][0]ResolutionWidth' (${&TwoDimensionalStuff[4]} + 202) (${@TwoDimensionalStuff[4]} + 202) @(
							0xD9, (ModRM 0 0 5), '&2DResolutionWidth' <# fld [&2DResolutionWidth] #>
						)

						if ($True)
						{
							Preassemble 'TwoDimensionalStuff[4][0]LetterboxHijack' (${&TwoDimensionalStuff[4]} + 252) (${@TwoDimensionalStuff[4]} + 252) @(
								0xE9, '4:TwoDimensionalStuff[4][0]Letterbox' <# jmp TwoDimensionalStuff[4][0]Letterbox #>
								(Get-Nop 4)                                  <# nop #>
							'PostTwoDimensionalStuff[4][0]LetterboxHijack:'
							)

							Preassemble 'TwoDimensionalStuff[4][0]Letterbox' @(
								0xD8, (ModRM 0 0 5), '&2DLetterboxHeight'              <# fadd [&2DLetterboxHeight] #>
								0xD8, (ModRM 1 1 5), 0xFC                              <# fmul [ebp - 4] #>
								0xD8, (ModRM 0 6 5), '&ScaledBaseWidth'                <# fdiv [&ScaledBaseWidth] #>
								0xE9, '4:PostTwoDimensionalStuff[4][0]LetterboxHijack' <# jmp PostTwoDimensionalStuff[4][0]LetterboxHijack #>
							)
						}
					}

					Preassemble 'TwoDimensionalStuff[4][0]Hijack'(${&TwoDimensionalStuff[4]} + 231) (${@TwoDimensionalStuff[4]} + 231) @(
						0xE9, '4:TwoDimensionalStuff[4][0]ClockHandOffset' <# jmp TwoDimensionalStuff[4][0]ClockHandOffset #>
						(Get-Nop 4)                                        <# nop #>
					'PostTwoDimensionalStuff[4][0]Hijack:'
					)

					Preassemble 'TwoDimensionalStuff[4][0]ClockHandOffset' @(
						0xD8, (ModRM 0 0 5), '&2DPillarboxWidth'      <# fadd [&2DPillarboxWidth] #>
						0xD8, (ModRM 1 1 5), 0xFC                     <# fmul [ebp - 4] #>
						0xD8, (ModRM 0 6 5), '&ScaledBaseWidth'       <# fdiv [&ScaledBaseWidth] #>
						0xE9, '4:PostTwoDimensionalStuff[4][0]Hijack' <# jmp PostTwoDimensionalStuff[4][0]Hijack #>
					)

					[Call]::NewLabel('TwoDimensionalStuff[5]LoadingScreenDisc', $AddressOf.'TwoDimensionalStuff[5]LoadingScreenDisc', (VirtualAddressToFileOffset $AddressOf.'TwoDimensionalStuff[5]LoadingScreenDisc'), 394, $Null)

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'TwoDimensionalStuff[5]ResolutionWidth' (${&TwoDimensionalStuff[5]LoadingScreenDisc} + 201) (${@TwoDimensionalStuff[5]LoadingScreenDisc} + 201) @(
							0xD9, (ModRM 0 0 5), '&2DResolutionWidth' <# fld [&2DResolutionWidth] #>
						)
					}

					Preassemble 'TwoDimensionalStuff[5]LoadingScreenDisc[1]' (${&TwoDimensionalStuff[5]LoadingScreenDisc} + 239) (${@TwoDimensionalStuff[5]LoadingScreenDisc} + 239) @('&ScaledBaseWidth')
					Preassemble 'TwoDimensionalStuff[5]LoadingScreenDisc[2]' (${&TwoDimensionalStuff[5]LoadingScreenDisc} + 260) (${@TwoDimensionalStuff[5]LoadingScreenDisc} + 260) @('&ScaledBaseWidth')

					Preassemble 'TwoDimensionalStuff[5]LoadingScreenDisc[0]Hijack' (${&TwoDimensionalStuff[5]LoadingScreenDisc} + 14) (${@TwoDimensionalStuff[5]LoadingScreenDisc} + 14) @(
						0xE9, '4:TwoDimensionalStuff[5]OffsetLoadingScreenDisc' <# jmp TwoDimensionalStuff[5]OffsetLoadingScreenDisc #>
						0x90                                                    <# nop #>
					'PostTwoDimensionalStuff[5]LoadingScreenDisc[0]Hijack:'
					)

					Preassemble 'TwoDimensionalStuff[5]OffsetLoadingScreenDisc' @(
						0xD9, (ModRM 0 0 6)                      <# fld [esi] #>
						0xD8, (ModRM 0 0 5), '&2DPillarboxWidth' <# fadd [&2DPillarboxWidth] #>
						0xD9, (ModRM 0 3 6)                      <# fstp [esi] #>

						if ($Script:UsingIntegral2DScaling)
						{
							0xD9, (ModRM 1 0 6), 0x04                 <# fld [esi + 4] #>
							0xD8, (ModRM 0 0 5), '&2DLetterboxHeight' <# fadd [&2DLetterboxHeight] #>
							0xD9, (ModRM 1 3 6), 0x04                 <# fstp [esi + 4] #>
						}

						0xD9, (ModRM 1 0 6), 0x08                                      <# fld [esi + 8] #>
						0xD9, (ModRM 1 3 5), 0x08                                      <# fstp [ebp + 8] #>
						0xE9, '4:PostTwoDimensionalStuff[5]LoadingScreenDisc[0]Hijack' <# jmp PostTwoDimensionalStuff[5]LoadingScreenDisc[0]Hijack #>
					)

					<# Combat HUD related #>
					[Call]::NewLabel('TwoDimensionalStuff[6]', $AddressOf.DrawAdventurerHUD, (VirtualAddressToFileOffset $AddressOf.DrawAdventurerHUD), 1983, $Null)

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'TwoDimensionalStuff[6]ResolutionWidth[0]' (${&TwoDimensionalStuff[6]} + 320) (${@TwoDimensionalStuff[6]} + 320) @(
							0xD9, (ModRM 0 0 5), '&2DResolutionWidth' <# fld [&2DResolutionWidth] #>
						)

						Preassemble 'TwoDimensionalStuff[6]ResolutionWidth[1]' (${&TwoDimensionalStuff[6]} + 563) (${@TwoDimensionalStuff[6]} + 563) @(
							0xD9, (ModRM 0 0 5), '&2DResolutionWidth' <# fld [&2DResolutionWidth] #>
						)

						Preassemble 'TwoDimensionalStuff[6][0]LetterboxHijack'(${&TwoDimensionalStuff[6]} + 390) (${@TwoDimensionalStuff[6]} + 390) @(
							0xE9, '4:TwoDimensionalStuff[6][0]XPOffsetLetterbox' <# jmp TwoDimensionalStuff[6][0]XPOffsetLetterbox #>
							(Get-Nop 4)                                          <# nop #>
						'PostTwoDimensionalStuff[6][0]LetterboxHijack:'
						)

						Preassemble 'TwoDimensionalStuff[6][0]XPOffsetLetterbox' @(
							0xD8, (ModRM 0 0 5), '&2DLetterboxHeight'              <# fadd [&2DLetterboxHeight] #>
							0xD8, (ModRM 1 1 5), 0xF4                              <# fmul [ebp - 12] #>
							0xD8, (ModRM 0 6 5), '&ScaledBaseWidth'                <# fdiv [&ScaledBaseWidth] #>
							0xE9, '4:PostTwoDimensionalStuff[6][0]LetterboxHijack' <# jmp PostTwoDimensionalStuff[6][0]LetterboxHijack #>
						)

						Preassemble 'TwoDimensionalStuff[6][1]LetterboxHijack'(${&TwoDimensionalStuff[6]} + 622) (${@TwoDimensionalStuff[6]} + 622) @(
							0xE9, '4:TwoDimensionalStuff[6][1]XPOffsetLetterbox' <# jmp TwoDimensionalStuff[6][1]XPOffsetLetterbox #>
							(Get-Nop 4)                                          <# nop #>
						'PostTwoDimensionalStuff[6][1]LetterboxHijack:'
						)

						Preassemble 'TwoDimensionalStuff[6][1]XPOffsetLetterbox' @(
							0xD8, (ModRM 0 0 5), '&2DLetterboxHeight'              <# fadd [&2DLetterboxHeight] #>
							0xD8, (ModRM 1 1 5), 0xF4                              <# fmul [ebp - 12] #>
							0xD8, (ModRM 0 6 5), '&ScaledBaseWidth'                <# fdiv [&ScaledBaseWidth] #>
							0xE9, '4:PostTwoDimensionalStuff[6][1]LetterboxHijack' <# jmp PostTwoDimensionalStuff[6][1]LetterboxHijack #>
						)
					}

					Preassemble 'TwoDimensionalStuff[6][0]' (${&TwoDimensionalStuff[6]} + 365) (${@TwoDimensionalStuff[6]} + 365) @('&ScaledBaseWidth')
					Preassemble 'TwoDimensionalStuff[6][1]' (${&TwoDimensionalStuff[6]} + 395) (${@TwoDimensionalStuff[6]} + 395) @('&ScaledBaseWidth')
					Preassemble 'TwoDimensionalStuff[6][2]' (${&TwoDimensionalStuff[6]} + 603) (${@TwoDimensionalStuff[6]} + 603) @('&ScaledBaseWidth')
					Preassemble 'TwoDimensionalStuff[6][3]' (${&TwoDimensionalStuff[6]} + 627) (${@TwoDimensionalStuff[6]} + 627) @('&ScaledBaseWidth')

					Preassemble 'TwoDimensionalStuff[6][0]Hijack'(${&TwoDimensionalStuff[6]} + 357) (${@TwoDimensionalStuff[6]} + 357) @(
						0xE9, '4:TwoDimensionalStuff[6][0]XPOffset' <# jmp TwoDimensionalStuff[6][0]XPOffset #>
						0x90                                        <# nop #>
					'PostTwoDimensionalStuff[6][0]Hijack:'
					)

					Preassemble 'TwoDimensionalStuff[6][0]XPOffset' @(
						0x89, (ModRM 1 1 5), 0xE0                     <# mov [ebp - 32], ecx #>
						0xD8, (ModRM 0 0 5), '&UIPillarboxWidth'      <# fadd [&UIPillarboxWidth] #>
						0xD8, (ModRM 1 1 5), 0xF4                     <# fmul [ebp - 12] #>
						0xE9, '4:PostTwoDimensionalStuff[6][0]Hijack' <# jmp PostTwoDimensionalStuff[6][0]Hijack #>
					)

					Preassemble 'TwoDimensionalStuff[6][2]Hijack'(${&TwoDimensionalStuff[6]} + 598) (${@TwoDimensionalStuff[6]} + 598) @(
						0xE9, '4:TwoDimensionalStuff[6][2]XPOffset' <# jmp TwoDimensionalStuff[6][2]XPOffset #>
						(Get-Nop 4)                                 <# nop #>
					'PostTwoDimensionalStuff[6][2]Hijack:'
					)

					Preassemble 'TwoDimensionalStuff[6][2]XPOffset' @(
						0xD8, (ModRM 0 0 5), '&UIPillarboxWidth'      <# fadd [&UIPillarboxWidth] #>
						0xD8, (ModRM 1 1 5), 0xF4                     <# fmul [ebp - 12] #>
						0xD8, (ModRM 0 6 5), '&ScaledBaseWidth'       <# fdiv [&ScaledBaseWidth] #>
						0xE9, '4:PostTwoDimensionalStuff[6][2]Hijack' <# jmp PostTwoDimensionalStuff[6][2]Hijack #>
					)

					<# Minimap related #>
					[Call]::NewLabel('TwoDimensionalStuff[7]', $AddressOf.DrawCombatHUD, (VirtualAddressToFileOffset $AddressOf.DrawCombatHUD), 7289, $Null)

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'TwoDimensionalStuff[7]ResolutionWidth' (${&TwoDimensionalStuff[7]} + $OffsetFor.'TwoDimensionalStuff[7]ResolutionWidth') (${@TwoDimensionalStuff[7]} + $OffsetFor.'TwoDimensionalStuff[7]ResolutionWidth') @(
							0xD9, (ModRM 0 0 5), '&2DResolutionWidth' <# fld [&2DResolutionWidth] #>
						)
					}

					Preassemble 'TwoDimensionalStuff[7][0]' (${&TwoDimensionalStuff[7]} + $OffsetFor.'TwoDimensionalStuff[7][0]') (${@TwoDimensionalStuff[7]} + $OffsetFor.'TwoDimensionalStuff[7][0]') @('&ScaledBaseWidth')

					Preassemble 'TwoDimensionalStuff[7][1]Hijack' (${&TwoDimensionalStuff[7]} + $OffsetFor.'TwoDimensionalStuff[7][1]Hijack') (${@TwoDimensionalStuff[7]} + $OffsetFor.'TwoDimensionalStuff[7][1]Hijack') @(
						0xE9, '4:TwoDimensionalStuff[7][1]MinimapOffset' <# jmp TwoDimensionalStuff[7][1]MinimapOffset #>
						(Get-Nop 9)                    	                 <# nop #>
						(Get-Nop 4)                                      <# nop #>
					'PostTwoDimensionalStuff[7][1]Hijack:'
					)

					if ($Version -eq $KnownVersions.EnglishV1_108)
					{
						$DivisionResultOffset = 0xD4
						$FirstMultiplierOffset = 0xB8
						$SecondMultiplierOffset = 0xFC
					}
					elseif ($Version -eq $KnownVersions.JapaneseV1_126)
					{
						$DivisionResultOffset = 0xF8
						$FirstMultiplierOffset = 0xB4
						$SecondMultiplierOffset = 0xD4
					}

					Preassemble 'TwoDimensionalStuff[7][1]MinimapOffset' @(
						0xD9, (ModRM 1 0 5), $DivisionResultOffset    <# fld [ebp + $DivisionResultOffset] #>
						0xD9, (ModRM 1 0 5), $FirstMultiplierOffset   <# fld [ebp + $FirstMultiplierOffset] #>
						0xD8, (ModRM 0 0 5), '&2DPillarboxWidth'      <# fadd [&2DPillarboxWidth] #>
						0xDE, 0xC9                                    <# fmulp #>
						0xD9, (ModRM 1 3 5), 0xD8                     <# fstp [ebp - 40] #>
						0xD9, (ModRM 1 0 5), $DivisionResultOffset    <# fld [ebp + $DivisionResultOffset] #>
						0xD9, (ModRM 1 0 5), $SecondMultiplierOffset  <# fld [ebp + $SecondMultiplierOffset] #>
						if ($Script:UsingIntegral2DScaling)
						{
							0xD8, (ModRM 0 0 5), '&2DLetterboxHeight' <# fadd [&2DLetterboxHeight] #>
						}
						0xDE, 0xC9                                    <# fmulp #>
						0xD9, (ModRM 1 3 5), 0xDC                     <# fstp [ebp - 36] #>
						0xE9, '4:PostTwoDimensionalStuff[7][1]Hijack' <# jmp PostTwoDimensionalStuff[7][1]Hijack #>
					)

					[Call]::NewLabel('TwoDimensionalStuff[8]', $AddressOf.DrawText, (VirtualAddressToFileOffset $AddressOf.DrawText), 454, $Null)
					#Preassemble 'TwoDimensionalStuff[8][0]' (${&TwoDimensionalStuff[8]} + 110) (${@TwoDimensionalStuff[8]} + 110) @('&ScaledBaseWidth')

					#Preassemble 'GetTextXOffsetHijack' (${&TwoDimensionalStuff[8]} + 105) (${@TwoDimensionalStuff[8]} + 105) @(
					#	0xE9, '4:GetTextXOffset' <# jmp GetTextXOffset #>
					#	(Get-Nop 4)              <# nop #>
					#'PostGetTextXOffsetHijack:'
					#)
		#
					#Preassemble 'GetTextXOffset' @(
					#	0xD9, (ModRM 1 0 5), 0x18                <# fld [ebp + 24] #>
					#	0xD8, (ModRM 0 0 5), '&2DPillarboxWidth' <# fadd [&2DPillarboxWidth] #>
					#	0xD8, (ModRM 0 1 5), '&ScaledBaseWidth'  <# fmul [&ScaledBaseWidth] #>
					#	0xE9, '4:PostGetTextXOffsetHijack'       <# jmp PostGetTextXOffsetHijack #>
					#)

					#[Call]::NewLabel('TwoDimensionalStuff[9]', 0x0007d2db, (VirtualAddressToFileOffset 0x0007d2db), 393, $Null)
					#Preassemble 'TwoDimensionalStuff[9][0]' (${&TwoDimensionalStuff[9]} + 160) (${@TwoDimensionalStuff[9]} + 160) @('&ScaledBaseWidth')

					[Call]::NewLabel('TwoDimensionalStuff[10]', $AddressOf.'TwoDimensionalStuff[10]', (VirtualAddressToFileOffset $AddressOf.'TwoDimensionalStuff[10]'), 99, $Null)

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'TwoDimensionalStuff[10][0]' (${&TwoDimensionalStuff[10]} + 60) (${@TwoDimensionalStuff[10]} + 60) @('&2DScaledBaseWidth')
						Preassemble 'TwoDimensionalStuff[10][1]' (${&TwoDimensionalStuff[10]} + 81) (${@TwoDimensionalStuff[10]} + 81) @('&2DScaledBaseHeight')
					}
					else
					{
						Preassemble 'TwoDimensionalStuff[10][0]' (${&TwoDimensionalStuff[10]} + 60) (${@TwoDimensionalStuff[10]} + 60) @('&ScaledBaseWidth')
					}

					<# Causes the map to stretch. #>
					#[Call]::NewLabel('TwoDimensionalStuff[11]', 0x0049e3a3, (VirtualAddressToFileOffset 0x0009e3a3), 739, $Null)
					#Preassemble 'TwoDimensionalStuff[11][0]' (${&TwoDimensionalStuff[11]} + 37) (${@TwoDimensionalStuff[11]} + 37) @('&ScaledBaseWidth')

					$ARGBlack = 0xFF000000

					Preassemble 'BlackInsteadOfBlueBars' (${&PresentFrame} + 291) (${@PresentFrame} + 291) @(
						(LE $ARGBlack)
					)

					[Call]::NewLabel('TownMapClearAndDraw', $AddressOf.TownMapClearAndDraw, (VirtualAddressToFileOffset $AddressOf.TownMapClearAndDraw), 45, $Null)
					Preassemble 'BlackInsteadOfBlueBarsInTownMap' (${&TownMapClearAndDraw} + 17) (${@TownMapClearAndDraw} + 17) (
						(LE $ARGBlack)
					)

					Preassemble 'ScaleFadeToFromBlackEffect' (${&FadeToFromBlackEffect} + 428) (${@FadeToFromBlackEffect} + 428) @('4:UIStuffReplacementWithHorizontalScaling')

					Preassemble 'ScaleDimScreenForDungeonCrawlingSaveWarning' (${&DimScreenForDungeonCrawlingSaveWarning} + 1) (${@DimScreenForDungeonCrawlingSaveWarning} + 1) @('4:UIStuffReplacementWithHorizontalScaling')


					#Preassemble 'ScalePauseMenuFreezeEffect[0]' (${&PauseMenuFreezeEffect} + 286) (${@PauseMenuFreezeEffect} + 286) @('&ScaledBaseWidth')
					# Causes wrap-round.
					#Preassemble 'ScalePauseMenuFreezeEffect[1]' (${&PauseMenuFreezeEffect} + 482) (${@PauseMenuFreezeEffect} + 482) @('&ScaledBaseWidth')
					# More to the right.
					#Preassemble 'ScalePauseMenuFreezeEffect[2]' (${&PauseMenuFreezeEffect} + 514) (${@PauseMenuFreezeEffect} + 514) @('&ScaledBaseWidth')
					#Preassemble 'ScalePauseMenuFreezeEffect[6]' (${&PauseMenuFreezeEffect} + 837) (${@PauseMenuFreezeEffect} + 837) @('&ScaledBaseWidth')
					##Preassemble 'ScalePauseMenuFreezeEffect[3]' (${&PauseMenuFreezeEffect} + 871) (${@PauseMenuFreezeEffect} + 871) @('&ScaledBaseWidth')

					# Causes a narrowing.
					#Preassemble 'ScalePauseMenuFreezeEffect[4]' (${&PauseMenuFreezeEffect} + 1064) (${@PauseMenuFreezeEffect} + 1064) @('&ScaledBaseWidth')

					#Preassemble 'HijackScalePauseMenuFreezeEffect[1]Offset' (${&PauseMenuFreezeEffect} + 502) (${@PauseMenuFreezeEffect} + 502) @(
					#	0xE9, '4:OffsetScalePauseMenuFreezeEffect[1]' <# jmp OffsetScalePauseMenuFreezeEffect[1] #>
					#'PostHijackScalePauseMenuFreezeEffect[1]Offset:'
					#)

					#Preassemble 'OffsetScalePauseMenuFreezeEffect[1]' @(
					#	0xD9, 0xEE                                              <# fldz #>
					#	0xD9, (ModRM 1 3 5), 0xD0                               <# fstp [ebp - 48] #>
					#	0xE9, '4:PostHijackScalePauseMenuFreezeEffect[1]Offset' <# jmp PostHijackScalePauseMenuFreezeEffect[1]Offset #>
					#)


					#Preassemble 'HijackScalePauseMenuFreezeEffect[3]Offset' (${&PauseMenuFreezeEffect} + 859) (${@PauseMenuFreezeEffect} + 859) @(
					#	0xE9, '4:OffsetScalePauseMenuFreezeEffect[3]' <# jmp OffsetScalePauseMenuFreezeEffect[3] #>
					#'PostHijackScalePauseMenuFreezeEffect[3]Offset:'
					#)

					Preassemble 'HijackScalePauseMenuFreezeEffect[3]UseArgumentInEDX' (${&PauseMenuFreezeEffect} + 888) (${@PauseMenuFreezeEffect} + 888) @(
						'4:UIStuffReplacementWithHorizontalScaling'
					)

					#Preassemble 'OffsetScalePauseMenuFreezeEffect[3]' @(
					#	0xD9, 0xEE                                              <# fldz #>
					#	0xD9, (ModRM 1 3 5), 0xD0                               <# fstp [ebp - 48] #>
					#	0xE9, '4:PostHijackScalePauseMenuFreezeEffect[3]Offset' <# jmp PostHijackScalePauseMenuFreezeEffect[3]Offset #>
					#)


					#Preassemble 'ScalePauseMenuFreezeEffect[5]' (${&PauseMenuFreezeEffect} + 1103) (${@PauseMenuFreezeEffect} + 1103) @('&ScaledBaseWidth')

					#Preassemble 'HijackScalePauseMenuFreezeEffect[5]Offset' (${&PauseMenuFreezeEffect} + 1090) (${@PauseMenuFreezeEffect} + 1090) @(
					#	0xE9, '4:OffsetScalePauseMenuFreezeEffect[5]' <# jmp OffsetScalePauseMenuFreezeEffect[5] #>
					#	0x90                                          <# nop #>
					#'PostHijackScalePauseMenuFreezeEffect[5]Offset:'
					#)

					Preassemble 'HijackScalePauseMenuFreezeEffect[5]UseArgumentInEDX' (${&PauseMenuFreezeEffect} + 1120) (${@PauseMenuFreezeEffect} + 1120) @(
						'4:UIStuffReplacementWithHorizontalScaling'
					)

					#Preassemble 'OffsetScalePauseMenuFreezeEffect[5]' @(
					#	0xD9, 0xEE                                              <# fldz #>
					#	0x50                                                    <# push eax #>
					#	0xD9, (ModRM 1 3 5), 0xD0                               <# fstp [ebp - 48] #>
					#	0xE9, '4:PostHijackScalePauseMenuFreezeEffect[5]Offset' <# jmp PostHijackScalePauseMenuFreezeEffect[5]Offset #>
					#)

					#Preassemble 'ScaleTopBlackBarOfHUDTransition' (${&DrawTheHUD} + 488) (${@DrawTheHUD} + 488) @('4:UIStuffReplacementWithHorizontalScaling')
					#Preassemble 'ScaleBottomBlackBarOfHUDTransition' (${&DrawTheHUD} + 563) (${@DrawTheHUD} + 563) @('4:UIStuffReplacementWithHorizontalScaling')
					#Preassemble 'ScaleTheNewsTicker' (${&DrawTheHUD} + 2897) (${@DrawTheHUD} + 2897) @('4:UIStuffReplacementWithHorizontalScaling')
					Preassemble 'ScaleAdventurerBlindness[0]' (${&DrawTheHUD} + 273) (${@DrawTheHUD} + 273) @('4:UIStuffReplacementWithHorizontalScaling')

					Hijack 'ScaleAdventurerBlindness[1]' 'DrawTheHUD' 280 5 @(
						0x6A, (LE ([Byte] $TextureFilteringAlgorithmLookup.Bilinear))                                             <# push $TextureFilteringAlgorithmLookup.Bilinear #>
						0x6A, 0x10                                                                                                <# push 16 #>
						0x6A, 0x00                                                                                                <# push 0 #>
						0xE8, '4:CallSetTextureStageStateOnTheDirect3DDevice'                                                     <# call CallSetTextureStageStateOnTheDirect3DDevice #>
						0xE8, '4:DrawEnqueuedTextures'                                                                            <# call DrawEnqueuedTextures #>
						0x6A, (LE ([Byte] $TextureFilteringAlgorithmLookup[$TextureFilteringConfiguration.Other2DArt.Algorithm])) <# push $TextureFilteringAlgorithmLookup[$TextureFilteringConfiguration.Other2DArt.Algorithm] #>
						0x6A, 0x10                                                                                                <# push 16 #>
						0x6A, 0x00                                                                                                <# push 0 #>
						0xE8, '4:CallSetTextureStageStateOnTheDirect3DDevice'                                                     <# call CallSetTextureStageStateOnTheDirect3DDevice #>
					)


					Preassemble 'ScaleDayIntoductionFadeFromBlack[0]' (${&DrawTheHUD} + $OffsetFor.'ScaleDayIntoductionFadeFromBlack[0]') (${@DrawTheHUD} + $OffsetFor.'ScaleDayIntoductionFadeFromBlack[0]') @('4:UIStuffReplacementWithHorizontalScaling')
					Preassemble 'ScaleDayIntoductionFadeFromBlack[1]' (${&DrawTheHUD} + $OffsetFor.'ScaleDayIntoductionFadeFromBlack[1]') (${@DrawTheHUD} + $OffsetFor.'ScaleDayIntoductionFadeFromBlack[1]') @('4:UIStuffReplacementWithHorizontalScaling')

					Preassemble 'ScaleLevelIntoductionFadeFromBlack[0]' (${&DrawLevelIntroductionAndSomeHUD} + 889) (${@DrawLevelIntroductionAndSomeHUD} + 889) @('4:UIStuffReplacementWithHorizontalScaling')
					#Preassemble 'ScaleLevelIntoductionFadeFromBlack[1]' (${&DrawLevelIntroductionAndSomeHUD} + 1428) (${@DrawLevelIntroductionAndSomeHUD} + 1428) @('4:UIStuffReplacementWithHorizontalScaling')


					if ($Version -eq $KnownVersions.EnglishV1_108)
					{
						$ValueOffset = 0xC8
					}
					elseif ($Version -eq $KnownVersions.JapaneseV1_126)
					{
						$ValueOffset = 0xCC
					}

					Hijack 'PositionTopBlackBarOfHUDTransition' 'DrawTheHUD' 450 7 @(
						0xD9, (ModRM 0 0 5), '&UIPillarboxWidthNegative'  <# fld [&UIPillarboxWidthNegative] #>
						0xD9, (ModRM 1 3 5), $ValueOffset                 <# fstp [ebp + $ValueOffset] #>
						0xD9, (ModRM 0 0 5), '&2DLetterboxHeightNegative' <# fld [&2DLetterboxHeightNegative] #>
					)

					Preassemble 'ScaleTopBlackBarOfHUDTransition' (${&DrawTheHUD} + 462) (${@DrawTheHUD} + 462) @('&2DFullWidth')

					Hijack 'PositionBottomBlackBarOfHUDTransition[0]' 'DrawTheHUD' 530 5 @(
						0xD9, (ModRM 0 0 5), '&UIPillarboxWidthNegative'  <# fld [&UIPillarboxWidthNegative] #>
						0xD9, (ModRM 1 3 5), $ValueOffset                 <# fstp [ebp + $ValueOffset] #>
					)

					Preassemble 'PositionBottomBlackBarOfHUDTransition[1]' (${&DrawTheHUD} + 537) (${@DrawTheHUD} + 537) @('&GameBaseHeightPlus2DLetterbox')

					Preassemble 'ScaleBottomBlackBarOfHUDTransition' (${&DrawTheHUD} + 549) (${@DrawTheHUD} + 549) @('&2DFullWidth')

					Hijack 'PositionTheNewsTicker[0]' 'DrawTheHUD' $OffsetFor.'PositionTheNewsTicker[0]' 5 @(
						0xD9, (ModRM 0 0 5), '&UIPillarboxWidthNegative'  <# fld [&UIPillarboxWidthNegative] #>
						0xD9, (ModRM 1 3 5), $ValueOffset                 <# fstp [ebp + $ValueOffset] #>
					)

					#Preassemble 'PositionTheNewsTicker[1]' (${&DrawTheHUD} + 2968) (${@DrawTheHUD} + 2968) @('&NewsTickerXOffset208')
					#Preassemble 'PositionTheNewsTicker[2]' (${&DrawTheHUD} + 3043) (${@DrawTheHUD} + 3043) @('&NewsTickerTextXOffset')

					Preassemble 'ScaleTheNewsTicker' (${&DrawTheHUD} + $OffsetFor.ScaleTheNewsTicker) (${@DrawTheHUD} + $OffsetFor.ScaleTheNewsTicker) @('&2DFullWidth')

					Preassemble 'ScaleChestTeleportationFadeToFromWhite' (${&DrawTheHUD} + $OffsetFor.ScaleChestTeleportationFadeToFromWhite) (${@DrawTheHUD} + $OffsetFor.ScaleChestTeleportationFadeToFromWhite) @('4:UIStuffReplacementWithHorizontalScaling')

					$ScaleBlackBarBarOfTillUI = @(
						0xD9, (ModRM 0 0 5), '&UIPillarboxWidthNegative' <# fld [&UIPillarboxWidthNegative] #>
						0xD9, (ModRM 1 3 5), 0xD0                        <# fstp [ebp - 48] #>
						0xD9, (ModRM 0 0 5), '&2DFullWidth'              <# fld [&2DFullWidth] #>
					)

					Hijack 'PositionTopBlackBarOfTillUI' 'DrawTillUI' 166 5 @(
						0xD9, (ModRM 0 0 5), '&2DLetterboxHeightNegative' <# fld [&2DLetterboxHeightNegative] #>
						0xD9, (ModRM 1 3 5), 0xD4                         <# fstp [ebp - 44] #>
					)

					Hijack 'ScaleTopBlackBarOfTillUI' 'DrawTillUI' 171 6 $ScaleBlackBarBarOfTillUI
					Hijack 'ScaleBottomBlackBarOfTillUI' 'DrawTillUI' 228 6 $ScaleBlackBarBarOfTillUI
					#Preassemble 'ScaleTopBlackBarOfTillUI' (${&DrawTillUI} + 193) (${@DrawTillUI} + 193) @('4:UIStuffFunctionWrapper[0]CloneWithScaling')
					#Preassemble 'ScaleBottomBlackBarOfTillUI' (${&DrawTillUI} + 244) (${@DrawTillUI} + 244) @('4:UIStuffFunctionWrapper[0]CloneWithScaling')

					if ($False)
					{
						Hijack 'PositionShopTillCustomerPosition' 'DrawTillUI' 459 12 @(
							0xD9, (ModRM 0 0 5), '&ShopTillCustomerPositionCounterLinearConvergence'                   <# fld [&ShopTillCustomerPositionCounterLinearConvergence] #>
							0xD9, (ModRM 0 0 5), '&InterpolatedShopTillCustomerPositionFloatMirror_Scalar_ActualValue' <# fld [&InterpolatedShopTillCustomerPositionFloatMirror_Scalar_ActualValue] #>
							0xDB, 0xF1                                                                                 <# fcomi st(0), st(1) #>
							0x72, '1:PostLinearConvergenceOfShopTillCustomerPositionCounter'                           <# jb PostLinearConvergenceOfShopTillCustomerPositionCounter #>
							0xDD, 0xD8                                                                                 <# fstp st(0) #>
							0xDD, 0XD1                                                                                 <# fst st(1) #>
						'PostLinearConvergenceOfShopTillCustomerPositionCounter:'
							0xD9, (ModRM 0 0 5), '&ShopTillCustomerPositionCounterLinearConvergenceLimit'              <# fld [&ShopTillCustomerPositionCounterLinearConvergenceLimit] #>
							0xD8, 0xE1                                                                                 <# fsub st(0), st(1) #>
							0xD8, 0xC9                                                                                 <# fmul st(0), st(1) #>
							0xD8, (ModRM 0 1 5), '&2DPillarboxWidth'                                                   <# fmul [&2DPillarboxWidth] #>
							0xD8, (ModRM 0 6 5), '&ShopTillCustomerPositionCounterLinearConvergenceDivisor'            <# fdiv [&ShopTillCustomerPositionCounterLinearConvergenceDivisor] #>
							0xD8, (ModRM 1 0 5), 0xFC                                                                  <# fadd [ebp - 4] #>
							0xD9, (ModRM 1 2 5), 0xFC                                                                  <# fst [ebp - 4] #>
							0xD8, (ModRM 0 5 5), '&ShopTillCustomerPositionOffset'                                     <# fsubr [&ShopTillCustomerPositionOffset] #>
							0xD9, (ModRM 1 3 5), 0xEC                                                                  <# fstp [ebp - 20] #>
							0xDD, 0xD8                                                                                 <# fstp st(0) #>
							0xDD, 0xD8                                                                                 <# fstp st(0) #>
						)
					}
					else
					{
						Preassemble 'PositionShopTillCustomerPositionOffset' (${&DrawTillUI} + 461) (${@DrawTillUI} + 461) @('&ShopTillCustomerPositionOffset')
					}

					Preassemble 'ScaleBossAttackCameraEffect' (${&DrawBossAttackCameraEffect} + 311) (${@DrawBossAttackCameraEffect} + 311) @('4:UIStuffReplacementWithHorizontalScaling')
					Preassemble 'ScaleBossDefeatCameraEffect' (${&PauseMenuFreezeEffect} + 1374) (${@PauseMenuFreezeEffect} + 1374) @('4:UIStuffReplacementWithHorizontalScaling')

					Hijack 'PositionHUDClock' 'DrawLevelIntroductionAndSomeHUD' 156 11 @(
						0xD9, (ModRM 0 0 5), '&HUDPillarboxWidthNegative' <# fld [&HUDPillarboxWidthNegative] #>
						0xD9, (ModRM 1 3 5), 0xCC                         <# fstp [ebp - 52] #>

						0xD9, (ModRM 1 0 5), 0xF8                         <# fld [ebp - 8] #>

						if ($Script:UsingIntegral2DScaling)
						{
							0xD8, (ModRM 0 4 5), '&2DLetterboxHeight' <# fsub [&2DLetterboxHeight] #>
						}

						0xD9, (ModRM 1 3 5), 0xD0                         <# fstp [ebp - 48] #>
					)

					Hijack 'PositionHUDClockMessageX' 'DrawLevelIntroductionAndSomeHUD' 334 6 @(
						0xD8, (ModRM 0 4 5), '&HUDPillarboxWidth' <# fsub [&HUDPillarboxWidth] #>
						0xD9, (ModRM 1 3 5), 0xCC                 <# fstp [ebp - 52] #>
						0xD9, (ModRM 1 0 5), 0xF8                 <# fld [ebp - 8] #>
					)

					if ($Script:UsingIntegral2DScaling)
					{
						Hijack 'PositionHUDClockMessageY' 'DrawLevelIntroductionAndSomeHUD' 355 5 @(
							0xDE, 0xE9                                <# fsubp #>
							0xD8, (ModRM 0 4 5), '&2DLetterboxHeight' <# fsub [&2DLetterboxHeight] #>
							0xD9, (ModRM 1 3 5), 0xD0                 <# fstp [ebp - 48] #>
						)

						Preassemble 'PositionHUDClockHandY' (${&DrawLevelIntroductionAndSomeHUD} + 520) (${@DrawLevelIntroductionAndSomeHUD} + 520) @('&HUDClockHandY')
					}

					Preassemble 'PositionHUDClockHandX' (${&DrawLevelIntroductionAndSomeHUD} + 530) (${@DrawLevelIntroductionAndSomeHUD} + 530) @('&HUDClockHandX')

					Preassemble 'PositionHUDClockDayOneDigitX' (${&DrawLevelIntroductionAndSomeHUD} + 659) (${@DrawLevelIntroductionAndSomeHUD} + 659) @('&HUDClockDayOneDigitX')
					Preassemble 'PositionHUDClockDayTwoDigitX' (${&DrawLevelIntroductionAndSomeHUD} + 651) (${@DrawLevelIntroductionAndSomeHUD} + 651) @('&HUDClockDayTwoDigitX')
					Preassemble 'PositionHUDClockDayThreeDigitX' (${&DrawLevelIntroductionAndSomeHUD} + 621) (${@DrawLevelIntroductionAndSomeHUD} + 621) @('&HUDClockDayThreeDigitX')
					Preassemble 'PositionHUDClockDayFourDigitX' (${&DrawLevelIntroductionAndSomeHUD} + 591) (${@DrawLevelIntroductionAndSomeHUD} + 591) @('&HUDClockDayFourDigitX')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionHUDClockDayY' (${&DrawLevelIntroductionAndSomeHUD} + 632) (${@DrawLevelIntroductionAndSomeHUD} + 632) @('&HUDClockDayY')
					}

					Preassemble 'PositionHUDClockPixX' (${&DrawLevelIntroductionAndSomeHUD} + 702) (${@DrawLevelIntroductionAndSomeHUD} + 702) @('&HUDClockPixX')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionHUDClockPixY' (${&DrawLevelIntroductionAndSomeHUD} + 682) (${@DrawLevelIntroductionAndSomeHUD} + 682) @('&HUDClockPixY')
					}

					#Preassemble 'ScaleCutscene' (${&DrawsCutsceneAndMore} + 1638) (${@DrawsCutsceneAndMore} + 1638) @('4:UIStuffReplacementWithHorizontalScaling')

					if ($Version -eq $KnownVersions.EnglishV1_108)
					{
						$XOffsetOffset = 0xF8
					}
					elseif ($Version -eq $KnownVersions.JapaneseV1_126)
					{
						$XOffsetOffset = 0xF4
					}

					Hijack 'PositionHUDMerchantLevelXAndY' 'DrawShopHUD' $OffsetFor.PositionHUDMerchantLevelXAndY 6 @(
						0xD9, (ModRM 1 0 5), $XOffsetOffset             <# fld [ebp + $XOffsetOffset] #>
						0xD8, (ModRM 0 4 5), '&HUDPillarboxWidth'       <# fsub [&HUDPillarboxWidth] #>
						0xD9, (ModRM 1 3 5), $XOffsetOffset             <# fstp [ebp + $XOffsetOffset] #>
						0xD8, (ModRM 0 0 5), '&HUDMerchantLevelYOffset' <# fadd HUDMerchantLevelYOffset #>
					)

					Preassemble 'PositionHUDChangeCameraX' (${&DrawShopHUD} + $OffsetFor.PositionHUDChangeCameraX) (${@DrawShopHUD} + $OffsetFor.PositionHUDChangeCameraX) @('&HUDChangeCameraX')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionHUDChangeCameraY' (${&DrawShopHUD} + $OffsetFor.PositionHUDChangeCameraY) (${@DrawShopHUD} + $OffsetFor.PositionHUDChangeCameraY) @('&HUDChangeCameraY')
					}

					Preassemble 'PositionHUDFPSOSDX' (${&DrawFPSOSD} + 184) (${@DrawFPSOSD} + 184) @('&HUDFPSOSDX')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionHUDFPSOSDY' (${&DrawFPSOSD} + 193) (${@DrawFPSOSD} + 193) @('&HUDFPSOSDY')

						Preassemble 'PositionHUDFPSCounterY' (${&DrawFPSOSD} + 335) (${@DrawFPSOSD} + 335) @('&HUDFPSCounterY')
					}

					Hijack 'PositionHUDFPSCounter' 'DrawFPSOSD' 235 7 @(
						0xD9, (ModRM 0 0 5), '&HUDFPSCounterX' <# fld [&HUDFPSCounterX] #>
						0xD9, (ModRM 1 3 5), 0xFC              <# fstp [ebp - 4] #>
					)

					Preassemble 'PositionHUDFPSCounterLoad' (${&DrawFPSOSD} + 327) (${@DrawFPSOSD} + 327) @(
						0xD9, (ModRM 1 0 5), 0xFC <# fld [ebp - 4] #>
					)

					Hijack 'PositionHUDFPSCounterIncrement' 'DrawFPSOSD' 365 7 @(
						0x83, (ModRM 3 0 4), 0x10                       <# add esp, 16 #>
						0xD9, (ModRM 1 0 5), 0xFC                       <# fld [ebp - 4] #>
						0xD8, (ModRM 0 0 5), '&HUDFPSCounterXIncrement' <# fadd [&HUDFPSCounterXIncrement] #>
						0xD9, (ModRM 1 3 5), 0xFC                       <# fstp [ebp - 4] #>
					)

					Hijack 'PositionCombatAdventurerPanelHorizontally' 'DrawCombatHUD' 37 6 @(
						0xD9, (ModRM 0 0 5), '&HUDPillarboxWidthNegative' <# fld [&HUDPillarboxWidthNegative] #>
						0x51                                              <# push ecx #>
						0xD9, (ModRM 0 3 4), (SIB 0 4 4)                  <# fstp [esp] #>
					)

					Preassemble 'PositionArrowPowerArrowHorizontally' (${&DrawCombatHUD} + 254) (${@DrawCombatHUD} + 254) @('&HUDArrowPowerArrowXOffset')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionArrowPowerArrowVertically' (${&DrawCombatHUD} + 279) (${@DrawCombatHUD} + 279) @('&HUDArrowPowerArrowYOffset')
					}

					Preassemble 'PositionArrowPowerPOWERHorizontally' (${&DrawCombatHUD} + 426) (${@DrawCombatHUD} + 426) @('&HUDArrowPowerPOWERXOffset')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionArrowPowerPOWERVertically' (${&DrawCombatHUD} + 447) (${@DrawCombatHUD} + 447) @('&HUDArrowPowerPOWERYOffset')
					}

					Preassemble 'PositionAmmoNotchHorizontally' (${&DrawCombatHUD} + 626) (${@DrawCombatHUD} + 626) @('&HUDAmmoNotchXOffset')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionAmmoNotchVertically' (${&DrawCombatHUD} + 647) (${@DrawCombatHUD} + 647) @('&HUDAmmoNotchYOffset')
					}

					Preassemble 'PositionAmmoReloadHorizontally' (${&DrawCombatHUD} + 1110) (${@DrawCombatHUD} + 1110) @('&HUDAmmoReloadXOffset')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionAmmoReloadVertically' (${&DrawCombatHUD} + 1051) (${@DrawCombatHUD} + 1051) @('&HUDAmmoReloadYOffset')
					}

					Preassemble 'PositionAmmoOKHorizontally' (${&DrawCombatHUD} + 1306) (${@DrawCombatHUD} + 1306) @('&HUDAmmoReloadXOffset')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionAmmoOKVertically' (${&DrawCombatHUD} + 1187) (${@DrawCombatHUD} + 1187) @('&HUDAmmoReloadYOffset')
					}

					if ($Script:UsingIntegral2DScaling)
					{
						Hijack 'PositionCombatAdventurerPanelVertically' 'DrawCombatHUD' $OffsetFor.PositionCombatAdventurerPanelVertically 6 @(
							0xD8, (ModRM 0 1 5), '&128f'              <# fmul [&128f] #>
							0xD8, (ModRM 0 0 5), '&2DLetterboxHeight' <# fadd [&2DLetterboxHeight] #>
						)
					}

					if ($Version -eq $KnownVersions.EnglishV1_108)
					{
						Preassemble 'PositionCombatNewsHorizontally[2]' (${&DrawCombatHUD} + 1913) (${@DrawCombatHUD} + 1913) @('&HUDCombatNewsXOffset')
						Preassemble 'PositionCombatNewsHorizontally[3]' (${&DrawCombatHUD} + 1928) (${@DrawCombatHUD} + 1928) @('&HUDCombatNewsXOffsetMaximum')
						Preassemble 'PositionCombatNewsHorizontally[4]' (${&DrawCombatHUD} + 1939) (${@DrawCombatHUD} + 1939) @('&HUDCombatNewsXOffsetMaximum')

						$XOffsetOffset = 0xF8
					}
					elseif ($Version -eq $KnownVersions.JapaneseV1_126)
					{
						Preassemble 'PositionCombatNewsHorizontally[2]' (${&DrawCombatHUD} + 1949) (${@DrawCombatHUD} + 1949) @('&HUDJapaneseCombatNewsXOffset')

						$XOffsetOffset = 0xFC
					}

					Hijack 'PositionCombatNewsHorizontally[0]' 'DrawCombatHUD' $OffsetFor.'PositionCombatNewsHorizontally[0]' 6 @(
						0x89, (ModRM 1 0 5), $XOffsetOffset                               <# mov [ebp + $XOffsetOffset], eax #>
						0xDB, (ModRM 1 0 5), $XOffsetOffset                               <# fild [ebp + $XOffsetOffset] #>
						0xD8, (ModRM 0 1 5), '&HUDCombatNewsHorizontalPositionMultiplier' <# fmul [&HUDCombatNewsHorizontalPositionMultiplier] #>
						0xD8, (ModRM 0 4 5), '&2DPillarboxWidth'                          <# fsub [&2DPillarboxWidth] #>
						0xD9, (ModRM 1 3 5), $XOffsetOffset                               <# fstp [ebp + $XOffsetOffset] #>
					)

					Preassemble 'PositionCombatNewsHorizontally[1]' (${&DrawCombatHUD} + $OffsetFor.'PositionCombatNewsHorizontally[1]') (${@DrawCombatHUD} + $OffsetFor.'PositionCombatNewsHorizontally[1]') @(
						0xD9 <# fld #>
					)

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionCombatNewsVertically' (${&DrawCombatHUD} + $OffsetFor.PositionCombatNewsVertically) (${@DrawCombatHUD} + $OffsetFor.PositionCombatNewsVertically) @('&HUDCombatNewsYOffset')
					}

					Preassemble 'PositionMinimapHorizontally' (${&DrawCombatHUD} + $OffsetFor.PositionMinimapHorizontally) (${@DrawCombatHUD} + $OffsetFor.PositionMinimapHorizontally) @('&HUDMinimapXOffset')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionMinimapVertically' (${&DrawCombatHUD} + $OffsetFor.PositionMinimapVertically) (${@DrawCombatHUD} + $OffsetFor.PositionMinimapVertically) @('&HUDMinimapYOffset')

						Preassemble 'PositionLevelNameY' (${&DrawCombatHUD} + $OffsetFor.PositionLevelNameY) (${@DrawCombatHUD} + $OffsetFor.PositionLevelNameY) @('&HUDLevelNameYOffset')
					}

					Preassemble 'PositionLevelNameX[0]' (${&DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[0]') (${@DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[0]') @('&HUDLevelNameXOffset460')
					Preassemble 'PositionLevelNameX[1]' (${&DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[1]') (${@DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[1]') @('&HUDLevelNameXOffset468')
					Preassemble 'PositionLevelNameX[2]' (${&DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[2]') (${@DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[2]') @('&HUDLevelNameXOffset468')
					Preassemble 'PositionLevelNameX[3]' (${&DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[3]') (${@DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[3]') @('&HUDLevelNameXOffset560')
					Preassemble 'PositionLevelNameX[4]' (${&DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[4]') (${@DrawCombatHUD} + $OffsetFor.'PositionLevelNameX[4]') @('&HUDLevelNameXOffset600')

					Preassemble 'PositionCombatChainX[0]' (${&DrawCombatHUD} + $OffsetFor.'PositionCombatChainX[0]') (${@DrawCombatHUD} + $OffsetFor.'PositionCombatChainX[0]') @('&HUDCombatChainXOffset16')
					Preassemble 'PositionCombatChainX[1]' (${&DrawCombatHUD} + $OffsetFor.'PositionCombatChainX[1]') (${@DrawCombatHUD} + $OffsetFor.'PositionCombatChainX[1]') @('&HUDCombatChainXOffset96')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionCombatChainY[0]' (${&DrawCombatHUD} + $OffsetFor.'PositionCombatChainY[0]') (${@DrawCombatHUD} + $OffsetFor.'PositionCombatChainY[0]') @('&HUDCombatChainY')
						Preassemble 'PositionCombatChainY[1]' (${&DrawCombatHUD} + $OffsetFor.'PositionCombatChainY[1]') (${@DrawCombatHUD} + $OffsetFor.'PositionCombatChainY[1]') @('&HUDCombatChainY')

						Hijack 'PositionEnemyHealthBarVertically' 'DrawCombatHUD' $OffsetFor.PositionEnemyHealthBarVertically 6 @(
							0xD8, (ModRM 0 1 5), '&128nf'             <# fmul [&128nf] #>
							0xD8, (ModRM 0 4 5), '&2DLetterboxHeight' <# fsub [&2DLetterboxHeight] #>
						)
					}

					Preassemble 'PositionEnemyHealthBarHorizontally[0]' (${&DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[0]') (${@DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[0]') @('&HUDEnemyHealthBarXOffset416')
					Preassemble 'PositionEnemyHealthBarHorizontally[1]' (${&DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[1]') (${@DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[1]') @('&HUDEnemyHealthBarXOffset416')
					Preassemble 'PositionEnemyHealthBarHorizontally[2]' (${&DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[2]') (${@DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[2]') @('&HUDEnemyHealthBarXOffset360')
					Preassemble 'PositionEnemyHealthBarHorizontally[3]' (${&DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[3]') (${@DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[3]') @('&HUDEnemyHealthBarXOffset364')
					Preassemble 'PositionEnemyHealthBarHorizontally[4]' (${&DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[4]') (${@DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[4]') @('&HUDEnemyHealthBarXOffset404')
					Preassemble 'PositionEnemyHealthBarHorizontally[5]' (${&DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[5]') (${@DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[5]') @('&HUDEnemyHealthBarXOffset418')
					Preassemble 'PositionEnemyHealthBarHorizontally[6]' (${&DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[6]') (${@DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[6]') @('&HUDEnemyHealthBarXOffset456')
					Preassemble 'PositionEnemyHealthBarHorizontally[7]' (${&DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[7]') (${@DrawCombatHUD} + $OffsetFor.'PositionEnemyHealthBarHorizontally[7]') @('&HUDEnemyHealthBarXOffset488')

					Preassemble 'PositionLootedLootHorizontally[0]' (${&DrawLootedLoot} + 101) (${@DrawLootedLoot} + 101) @('&HUDLootedLootXOffset')
					Preassemble 'PositionLootedLootHorizontally[1]' (${&DrawLootedLoot} + 113) (${@DrawLootedLoot} + 113) @('&HUDLootedLootXOffsetMaximum')
					Preassemble 'PositionLootedLootHorizontally[2]' (${&DrawLootedLoot} + 124) (${@DrawLootedLoot} + 124) @('&HUDLootedLootXOffsetMaximum')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionLootedLootVertically[0]' (${&DrawLootedLoot} + 290) (${@DrawLootedLoot} + 290) @('&HUDLootedLootYOffset104')
						Preassemble 'PositionLootedLootVertically[1]' (${&DrawLootedLoot} + 517) (${@DrawLootedLoot} + 517) @('&HUDLootedLootYOffset98')
					}


					Preassemble 'PositionNowLoadingTextHorizontally' (${&ShowNowLoadingMessage} + 211) (${@ShowNowLoadingMessage} + 211) @('&NowLoadingTextX')
					Preassemble 'PositionNowLoadingDiscHorizontally' (${&ShowNowLoadingMessage} + 307) (${@ShowNowLoadingMessage} + 307) @('&NowLoadingDiscX')

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'PositionNowLoadingTextVertically' (${&ShowNowLoadingMessage} + 220) (${@ShowNowLoadingMessage} + 220) @('&NowLoadingTextY')
						Preassemble 'PositionNowLoadingDiscVertically' (${&ShowNowLoadingMessage} + 316) (${@ShowNowLoadingMessage} + 316) @('&NowLoadingDiscY')

						#Preassemble 'PositionHagglingSpeechBubbleButtonsVertically[0]' (${&DrawHagglingUI} + 2943) (${@DrawHagglingUI} + 2943) @('&ShopSpeechBubbleButtonYOffset186')
						#Preassemble 'PositionHagglingSpeechBubbleButtonsVertically[1]' (${&DrawHagglingUI} + 2961) (${@DrawHagglingUI} + 2961) @('&ShopSpeechBubbleButtonYOffset362')

						#Preassemble 'PositionHagglingSpeechBubbleVertically' (${&DrawHagglingUI} + 3909) (${@DrawHagglingUI} + 3909) @('&ShopSpeechBubbleYOffset')

						Hijack 'PositionHagglingUIVertically' 'DrawHagglingUI' 3 6 @(
							0x81, (ModRM 3 5 4), 0x38, 0x02, 0x00, 0x00    <# sub esp, 568 #>
							0x83, (ModRM 0 1 5), '&Anchor2DToBottom', 0x01 <# or [&Anchor2DToBottom], 1 #>
						)

						Hijack 'MakeRoomForReturnHijackInHagglingUI' 'DrawHagglingUI' $OffsetFor.MakeRoomForReturnHijackInHagglingUI 10 @(
							0x6A, 0xFF                       <# push -1 #>
							0x50                             <# push eax #>
							0x51                             <# push ecx #>
							0xD9, (ModRM 0 3 4), (SIB 0 4 4) <# fstp [esp] #>
							0xD9, (ModRM 1 0 5), 0xFC        <# fld [ebp - 4] #>
						)

						Hijack 'StopPositioningHagglingUIVertically' 'DrawHagglingUI' ($OffsetFor.MakeRoomForReturnHijackInHagglingUI + 5) 5 @(
							0x83, (ModRM 0 4 5), '&Anchor2DToBottom', 0x00 <# and [&Anchor2DToBottom], 0 #>
							0x5E                                           <# pop esi #>
							0x5B                                           <# pop ebx #>
							0xC9                                           <# leave #>
							0xC3                                           <# ret #>
						)

						Preassemble 'JumpToStopPositioningHagglingUIVertically' (${&DrawHagglingUI} + $OffsetFor.JumpToStopPositioningHagglingUIVertically) (${@DrawHagglingUI} + $OffsetFor.JumpToStopPositioningHagglingUIVertically) @(
							0xEB, '1:StopPositioningHagglingUIVertically_Hijack' <# jmp StopPositioningHagglingUIVertically_Hijack #>
							(Get-Nop 2)                                          <# nop #>
						)

						Hijack 'PositionSellingMenuInShopVertically' 'DrawTheHUD' $OffsetFor.PositionSellingMenuInShopVertically 5 @(
							0x83, (ModRM 0 7 5), '&ShopIsOpen', 0x00       <# cmp [&ShopIsOpen], 0 #>
							0x74, '1:CallDrawMenu'                         <# je CallDrawMenu #>
							0x83, (ModRM 0 7 5), '&GameStateB', 0x01       <# cmp [&GameStateB], 1 #>
							0x75, '1:CallDrawMenu'                         <# jne CallDrawMenu #>
							0xA1, '&GameStateD'                            <# mov eax, [&GameStateD] #>
							0x83, (ModRM 0 7 0), 0x00                      <# cmp [eax], 0 #>
							0x75, '1:CallDrawMenu'                         <# jne CallDrawMenu #>
							0x83, (ModRM 0 1 5), '&Anchor2DToBottom', 0x01 <# or [&Anchor2DToBottom], 1 #>
						'CallDrawMenu:'
							0xE8, '4:DrawMenu'                             <# call DrawMenu #>
							0x83, (ModRM 0 4 5), '&Anchor2DToBottom', 0x00 <# and [&Anchor2DToBottom], 0 #>
						)

						Hijack 'PositionSelectionHandVertically' 'DrawSelectionHand' 258 6 @(
							0x83, (ModRM 0 7 5), '&ShopIsOpen', 0x00                             <# cmp [&ShopIsOpen], 0 #>
							0x74, '1:SubtractOriginalSelectionHandYOffset'                       <# je SubtractOriginalSelectionHandYOffset #>
							0x83, (ModRM 0 7 5), '&FulfilOrderState', 0x01                       <# cmp [&FulfilOrderState], 1 #>
							0x75, '1:PastFulfilOrderStateChecksForVerticalOffsetOfSelectionHand' <# jne PastFulfilOrderStateChecksForVerticalOffsetOfSelectionHand #>
							0x83, (ModRM 0 7 5), '&FulfilOrderSelectionHandState', 0x02          <# cmp [&FulfilOrderSelectionHandState], 2 #>
							0x75, '1:SubtractOriginalSelectionHandYOffset'                       <# jne SubtractOriginalSelectionHandYOffset #>
							0xEB, '1:SubtractVerticallyOffsetSelectionHandYOffset'               <# jmp SubtractVerticallyOffsetSelectionHandYOffset #>
						'PastFulfilOrderStateChecksForVerticalOffsetOfSelectionHand:'
							0x83, (ModRM 0 7 5), '&MenuPromptTransitionCounter', 0x00            <# cmp [&MenuPromptTransitionCounter], 0 #>
							0x75, '1:SubtractOriginalSelectionHandYOffset'                       <# jne SubtractOriginalSelectionHandYOffset #>
							0x83, (ModRM 0 7 5), '&GameStateB', 0x01                             <# cmp [&GameStateB], 1 #>
							0x75, '1:SubtractOriginalSelectionHandYOffset'                       <# jne SubtractOriginalSelectionHandYOffset #>
							0xA1, '&GameStateD'                                                  <# mov eax, [&GameStateD] #>
							0x83, (ModRM 0 7 0), 0x00                                            <# cmp [eax], 0 #>
							0x75, '1:SubtractOriginalSelectionHandYOffset'                       <# jne SubtractOriginalSelectionHandYOffset #>
						'SubtractVerticallyOffsetSelectionHandYOffset:'
							0xD8, (ModRM 0 4 5), '&SelectionHandYOffset'                         <# fsub [&SelectionHandYOffset] #>
							0xEB, '1:PostSelectionHandYOffset'                                   <# jmp PostSelectionHandYOffset #>
						'SubtractOriginalSelectionHandYOffset:'
							0xD8, (ModRM 0 4 5), '&SelectionHandOriginalYOffset'                 <# fsub [&SelectionHandOriginalYOffset] #>
						'PostSelectionHandYOffset:'
						)

						Hijack 'HideSelectionHandWhenAtRest' 'DrawSelectionHand' 184 7 @(
							0x83, (ModRM 0 7 5), '&ShouldDrawSelectionHand', 0x00 <# cmp [&ShouldDrawSelectionHand], 0 #>
							0x74, '1:PostPotentialSelectionHandHiding'            <# je PostPotentialSelectionHandHiding #>
							0xD9, (ModRM 0 0 5), '&SelectionHandY'                <# fld [&SelectionHandY] #>
							0xD9, (ModRM 0 0 5), '&SelectionHandRestingY'         <# fld [&SelectionHandRestingY] #>
							0xDF, 0xF1                                            <# fcomip st(0), st(1) #>
							0xDD, 0xD8                                            <# fstp st(0) #>
							0x75, '1:PostPotentialSelectionHandHiding'            <# jne PostPotentialSelectionHandHiding #>
							0xD9, (ModRM 0 0 5), '&SelectionHandX'                <# fld [&SelectionHandX] #>
							0xD9, (ModRM 0 0 5), '&SelectionHandRestingX'         <# fld [&SelectionHandRestingX] #>
							0xDF, 0xF1                                            <# fcomip st(0), st(1) #>
							0xDD, 0xD8                                            <# fstp st(0) #>
						'PostPotentialSelectionHandHiding:'
						)
					}

					Hijack 'PositionEncyclopediaItemPageHorizontally[0]' 'DrawEncyclopediaItems' 82 9 @(
						0x89, (ModRM 1 1 5), 0xFC               <# mov [ebp - 4], ecx #>
						0xDB, (ModRM 1 0 5), 0xFC               <# fild [ebp - 4] #>
						0xD8, (ModRM 0 1 5), '&ScaledBaseWidth' <# fmul [&ScaledBaseWidth] #>
						0xD9, (ModRM 1 3 5), 0xFC               <# fstp [ebp - 4] #>
					)

					Preassemble 'PositionEncyclopediaItemPageHorizontally[1]' (${&DrawEncyclopediaItems} + 96) (${@DrawEncyclopediaItems} + 96) @(
						0xD9 <# fld #>
					)

					Preassemble 'PositionEncyclopediaItemPageHorizontally[2]' (${&DrawEncyclopediaItems} + 128) (${@DrawEncyclopediaItems} + 128) @('&ScaledBaseWidth')


					Preassemble 'PositionSaveSlotsHorizontally[0]' (${&DrawSaveSlots} + 129) (${@DrawSaveSlots} + 129) @((LE 1))
					Preassemble 'PositionSaveSlotsHorizontally[1]' (${&DrawSaveSlots} + 646) (${@DrawSaveSlots} + 646) @((LE 1))
					Preassemble 'PositionSaveSlotsHorizontally[2]' (${&DrawSaveSlots} + 653) (${@DrawSaveSlots} + 653) @((LE 3))

					Hijack 'PositionSaveSlotsHorizontally[3]' 'DrawSaveSlots' 528 9 @(
						0xD8, (ModRM 0 4 5), '&ScaledBaseWidth' <# fsub [&ScaledBaseWidth] #>
						0xDB, (ModRM 1 0 5), 0xEC               <# fild [ebp - 20] #>
						0xD8, (ModRM 0 1 5), '&ScaledBaseWidth' <# fmul [&ScaledBaseWidth] #>
					)

					Preassemble 'PositionSaveSlotsHorizontally[4]' (${&DrawSaveSlots} + 888) (${@DrawSaveSlots} + 888) @('&ScaledBaseWidth')

					Hijack 'PositionSaveSlotsHorizontally[5]' 'DrawSaveSlots' 892 6 @(
						0xDB, (ModRM 1 0 5), 0xEC               <# fild [ebp - 20] #>
						0xD8, (ModRM 0 1 5), '&ScaledBaseWidth' <# fmul [&ScaledBaseWidth] #>
						0xD9, (ModRM 1 3 5), 0xFC               <# fstp [ebp - 4] #>
					)

					if ($Script:UsingIntegral2DScaling)
					{
						Preassemble 'HideFourthSaveSlot[0]' (${&DrawSaveSlots} + 633) (${@DrawSaveSlots} + 633) @((LE ([Byte] 4)))
						Preassemble 'HideFourthSaveSlot[1]' (${&DrawSaveSlots} + 2538) (${@DrawSaveSlots} + 2538) @((LE ([Byte] 4)))
					}


					$EnqueueBlackBar =
					{
						Param ([Float] $X, [Float] $Y, [Float] $Width, [Float] $Height)

						0xC7, (ModRM 0 0 4), (SIB 0 4 4), (LE $X)                  <# mov [esp], $X #>
						0xC7, (ModRM 1 0 4), (SIB 0 4 4), 0x04, (LE $Y)            <# mov [esp + 4], $Y #>
						0xC7, (ModRM 1 0 4), (SIB 0 4 4), 0x08, (LE $Width)        <# mov [esp + 8], $Width #>
						0xC7, (ModRM 1 0 4), (SIB 0 4 4), 0x0C, (LE $Height)       <# mov [esp + 12], $Height #>
						0xD9, 0xEE                                                 <# fldz #>
						0xD9, (ModRM 1 3 4), (SIB 0 4 4), 0x10                     <# fstp [esp + 16] #>
						0xD9, 0xEE                                                 <# fldz #>
						0xD9, (ModRM 1 3 4), (SIB 0 4 4), 0x14                     <# fstp [esp + 20] #>
						0xC7, (ModRM 1 0 4), (SIB 0 4 4), 0x18, (LE ([Float] 1.0)) <# mov [esp + 24], 1.0 #>
						0xC7, (ModRM 1 0 4), (SIB 0 4 4), 0x1C, (LE ([Float] 7.0)) <# mov [esp + 28], 7.0 #>
						0x8D, (ModRM 1 1 4), (SIB 0 4 4), 0x10                     <# lea ecx, [esp + 16] #>
						0x8D, (ModRM 0 0 4), (SIB 0 4 4)                           <# lea eax, [esp] #>
						0x68, 0x00, 0x00, 0x00, 0xFF                               <# push 0xFF000000 #>
						0x68, '&BlackBarTexture'                                   <# push &BlackBarTexture #>
						0x51                                                       <# push ecx #>
						0x50                                                       <# push eax #>
						0xE8, '4:UIStuffReplacementDirect'                         <# call UIStuffReplacementDirect #>
						0x83, (ModRM 3 0 4), 0x10                                  <# add esp, 16 #>
					}

					Preassemble 'DrawBlackBars' @(
						0xA1, '&Direct3DDevice'                                       <# mov eax, [&Direct3DDevice] #>
						0xFF, (ModRM 0 6 5), '&BlackBarTexture'                       <# push [&BlackBarTexture] #>
						0x68, 0x00, 0x00, 0x00, 0x00                                  <# push 0 #>
						0x8B, (ModRM 0 1 0)                                           <# mov ecx, [eax] #>
						0x50                                                          <# push eax #>
						0xFF, (ModRM 2 2 1), 0xF4, 0x00, 0x00, 0x00                   <# call [ecx + 244] #>

						0x83, (ModRM 3 5 4), 0x20                                     <# sub esp, 32 #>

						0xF7, (ModRM 0 0 5), '&BlackBarFlags', 0x01, 0x00, 0x00, 0x00 <# test [&BlackBarFlags], 0b0001 #>
						0x74, '1:PostDrawingOfLeftPillarbox'                          <# jz PostDrawingOfLeftPillarbox #>
						(& $EnqueueBlackBar 0 0 $2DPillarboxWidth $2DScaledBaseHeight)
					'PostDrawingOfLeftPillarbox:'
						0xF7, (ModRM 0 0 5), '&BlackBarFlags', 0x02, 0x00, 0x00, 0x00 <# test [&BlackBarFlags], 0b0010 #>
						0x74, '1:PostDrawingOfRightPillarbox'                         <# jz PostDrawingOfRightPillarbox #>
						(& $EnqueueBlackBar ($GameBaseWidth + $2DPillarboxWidth) 0 $2DPillarboxWidth $2DScaledBaseHeight)
					'PostDrawingOfRightPillarbox:'
						if ($Script:UsingIntegral2DScaling)
						{
							0xF7, (ModRM 0 0 5), '&BlackBarFlags', 0x04, 0x00, 0x00, 0x00 <# test [&BlackBarFlags], 0b0100 #>
							0x74, '1:PostDrawingOfUpperLetterbox'                         <# jz PostDrawingOfUpperLetterbox #>
							(& $EnqueueBlackBar 0 0 $2DScaledBaseWidth $2DLetterboxHeight)
						}
					'PostDrawingOfUpperLetterbox:'
						if ($Script:UsingIntegral2DScaling)
						{
							0xF7, (ModRM 0 0 5), '&BlackBarFlags', 0x08, 0x00, 0x00, 0x00 <# test [&BlackBarFlags], 0b1000 #>
							0x74, '1:PostDrawingOfLowerLetterbox'                         <# jz PostDrawingOfLowerLetterbox #>
							(& $EnqueueBlackBar 0 ($GameBaseHeight + $2DLetterboxHeight) $2DScaledBaseWidth $2DLetterboxHeight)
						}
					'PostDrawingOfLowerLetterbox:'
						0x83, (ModRM 3 0 4), 0x20                                     <# add esp, 32 #>
						#0xE8, '4:DrawEnqueuedTextures'                                <# call DrawEnqueuedTextures #>
						0xC3                                                          <# ret #>
					)

					Hijack 'DrawBlackBarsOverMostThings' 'PresentFrame' 1248 6 @(
						0x83, (ModRM 0 7 5), '&GameStateB', 0x09                   <# cmp [&GameStateB], 9 #>
						0x75, '1:DrawingOfBlackBarsOverMostThings'                 <# jne DrawingOfBlackBarsOverMostThings #>
						0x83, (ModRM 0 7 5), '&ShouldDisplayEndOfDaySummary', 0x00 <# cmp [&ShouldDisplayEndOfDaySummary], 0 #>
						0x74, '1:PostDrawingOfBlackBarsOverMostThings'             <# jz PostDrawingOfBlackBarsOverMostThings #>
						0x83, (ModRM 0 7 5), '&InAnEvent?', 0x00                   <# cmp [&InAnEvent?], 0 #>
						0x74, '1:PostDrawingOfBlackBarsOverMostThings'             <# jz PostDrawingOfBlackBarsOverMostThings #>
					'DrawingOfBlackBarsOverMostThings:'
						0xE8, '4:DrawBlackBars'                                    <# call DrawBlackBars #>
					'PostDrawingOfBlackBarsOverMostThings:'
						0x39, (ModRM 0 6 5), '&ShouldDisplayFPSOSD'                <# cmp [&ShouldDisplayFPSOSD], esi #>
					)

					if ($Script:UsingIntegral2DScaling)
					{
						#Preassemble 'PositionHealthBarHorizontally' (${&DrawAdventurerHUD} + 854) (${@DrawAdventurerHUD} + 854) @('&HUDHealthBarXOffset')
						#Preassemble 'PositionHealthBarVertically' (${&DrawAdventurerHUD} + 872) (${@DrawAdventurerHUD} + 872) @('&HUDHealthBarYOffset')
						#Preassemble 'PositionSPBarVertically' (${&DrawAdventurerHUD} + 1032) (${@DrawAdventurerHUD} + 1032) @('&HUDSPBarYOffset')
					}
				}


				$ShopShadowsTextureFilteringConfiguration = $TextureFilteringConfiguration.Values.Where({$_.ConfigurableTextureFiltering.PatchVariant -ceq 'ShopShadows'}, 'First')[0]
				$ShopItemsTextureFilteringWasPatched = $False


				foreach ($Entry in $TextureFilteringConfiguration.Values)
				{
					$Patch = $Entry.ConfigurableTextureFiltering

					if ($Patch.PatchVariant -ceq 'PushedImmediate')
					{
						Preassemble "TextureFilteringPatch_$($Patch.Metadata.Names[0])" ($Patch.VirtualAddress + 6) (VirtualAddressToFileOffset ($Patch.VirtualAddress + 6)) @(
							(LE ([Byte] $TextureFilteringAlgorithmLookup[$Entry.Algorithm]))
						)
					}
					elseif ($Patch.PatchVariant -ceq 'WrapperCall')
					{
						Preassemble "TextureFilteringPatch_$($Patch.Metadata.Names[0])" $Patch.VirtualAddress (VirtualAddressToFileOffset $Patch.VirtualAddress) @(
							0x6A, (LE ([Byte] $TextureFilteringAlgorithmLookup[$Entry.Algorithm])) <# push $TextureFilteringAlgorithmLookup[$Entry.Algorithm] #>
							0x6A, 0x10                                                             <# push 16 #>
							0x6A, 0x00                                                             <# push 0 #>
							0xE8, '4:CallSetTextureStageStateOnTheDirect3DDevice'                  <# call CallSetTextureStageStateOnTheDirect3DDevice #>
							(Get-Nop 7)                                                            <# nop #>
						)
					}

					if ('ShopItems' -in $Patch.Names)
					{
						$ShopItemsTextureFilteringWasPatched = $True
					}
				}

				if ($ShopItemsTextureFilteringWasPatched -or $Null -ne $ShopShadowsTextureFilteringConfiguration)
				{
					$Algorithm = if ($Null -ne $ShopShadowsTextureFilteringConfiguration)
					{
						([Byte] $TextureFilteringAlgorithmLookup[$ShopShadowsTextureFilteringConfiguration.Algorithm])
					}
					else
					{
						([Byte] $TextureFilteringAlgorithmLookup.Bilinear)
					}

					Hijack 'SceneryShadowTextureFiltering' 'SomeShopRelatedRendering' 1394 5 @(
						0x6A, (LE $Algorithm)                                 <# push $Algorithm #>
						0x6A, 0x10                                            <# push 16 #>
						0x6A, 0x00                                            <# push 0 #>
						0xE8, '4:CallSetTextureStageStateOnTheDirect3DDevice' <# call CallSetTextureStageStateOnTheDirect3DDevice #>
						#0x6A, 0x00                                            <# push 0 #> # Activates a debug OSD
						0xA1, '&GameStateD'                                   <# mov eax, GameStateD #>
					)
				}


				Resolve-Assembly


				if ($Debug)
				{
					Write-Debug "&SkipUIStuffReplacement: $(${&SkipUIStuffReplacement}.ToString('X08'))"
				}


				if ($Null -ne $Script:CheatEngineTablePath)
				{
					class CheatTableGenerator
					{
						static [String] $CRLF = "`r`n"
						static [String[]] $IndentBy = (0..16).ForEach{"`t" * $_}

						static [RegEx] $TypeRegex = [RegEx]::new(
							'^(?:(?<Type>u?int|u?long|u?byte|u?short|float|double|char)|(?<Type>char)\[(?<DataLength>[0-9]+)\])$',
							[Text.RegularExpressions.RegexOptions]::Compiled
						)

						static [HashTable] $TypeMap = @{
							char = 'Byte'
							byte = 'Byte'
							short = '2 Bytes'
							int = '4 Bytes'
							long = '8 Bytes'
							float = 'Float'
							double = 'Double'
						}

						static [Collections.Generic.Dictionary[ValueTuple[Object, Object], Object]] $TypeCache

						static [UInt32] $CheatEntryID
						static [Text.StringBuilder] $Text

						static [Object] GetCheatEngineType ($Type, $Size)
						{
							$ResolvedType = $Null

							if (
								[CheatTableGenerator]::TypeCache.TryGetValue(
									[ValueTuple[Object, Object]]::new($Type, $Size),
									[Ref] $ResolvedType
								)
							)
							{
								return $ResolvedType
							}

							if ($Null -eq $Type)
							{
								if ($Size -eq 1)
								{
									$ResolvedType = '<VariableType>Byte</VariableType>'
								}
								elseif ($Size -eq 4 -or $Size -eq 8 -or $Size -eq 2)
								{
									$ResolvedType = "<VariableType>$Size Bytes</VariableType>"
								}
							}
							elseif ($Type -cmatch [CheatTableGenerator]::TypeRegex)
							{
								if ($Null -ne $Matches.DataLength)
								{
									$ResolvedType = "<VariableType>String</VariableType><Length>$($Matches.DataLength)</Length>"
								}
								elseif ($Matches.Type[0] -ceq 'u' -or $Matches.Type[0] -ceq 'c')
								{
									$ResolvedType = "<VariableType>$([CheatTableGenerator]::TypeMap[$Matches.Type.Substring(1)])</VariableType>"
								}
								else
								{
									$ResolvedType = "<VariableType>$([CheatTableGenerator]::TypeMap[$Matches.Type])</VariableType><ShowAsSigned>1</ShowAsSigned>"
								}
							}

							[CheatTableGenerator]::TypeCache[[ValueTuple[Object, Object]]::new($Type, $Size)] = $ResolvedType

							return $ResolvedType
						}

						static [Bool] BeginCheatEntry ($Name, $VirtualAddress, $TypeHint, $Length, $Depth, $HasChildren)
						{
							$Indent = [CheatTableGenerator]::IndentBy[$Depth + 2]
							$Type = $Null

							if ($Null -ne $VirtualAddress)
							{
								$Type = [CheatTableGenerator]::GetCheatEngineType($TypeHint, $Length)

								if ($Null -eq $Type -and -not $HasChildren)
								{
									return $False
								}
							}

							[CheatTableGenerator]::Text.Append($Indent) > $Null
							[CheatTableGenerator]::Text.Append('<CheatEntry>') > $Null
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
							[CheatTableGenerator]::Text.Append($Indent) > $Null
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[1]) > $Null
							[CheatTableGenerator]::Text.Append('<ID>') > $Null
							[CheatTableGenerator]::Text.Append(([CheatTableGenerator]::CheatEntryID++)) > $Null
							[CheatTableGenerator]::Text.Append('</ID>') > $Null
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
							[CheatTableGenerator]::Text.Append($Indent) > $Null
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[1]) > $Null
							[CheatTableGenerator]::Text.Append('<Description>') > $Null
							[CheatTableGenerator]::Text.Append($Name) > $Null
							[CheatTableGenerator]::Text.Append('</Description>') > $Null
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null

							if ($Null -ne $Type)
							{
								[CheatTableGenerator]::Text.Append($Indent) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[1]) > $Null
								[CheatTableGenerator]::Text.Append($Type) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
								[CheatTableGenerator]::Text.Append($Indent) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[1]) > $Null
								[CheatTableGenerator]::Text.Append('<Address>') > $Null
								[CheatTableGenerator]::Text.AppendFormat('{0:X08}', $VirtualAddress) > $Null
								[CheatTableGenerator]::Text.Append('</Address>') > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
							}

							return $True
						}

						static EndCheatEntry ($Depth)
						{
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[$Depth + 2]) > $Null
							[CheatTableGenerator]::Text.Append('</CheatEntry>') > $Null
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
						}

						static [Bool] BeginCheatEntryForLabel ($Label, $Depth, $HasChildren)
						{
							return [CheatTableGenerator]::BeginCheatEntry(
								$Label,
								$Global:ExecutionContext.SessionState.PSVariable.GetValue("&$Label"),
								$Global:ExecutionContext.SessionState.PSVariable.GetValue("typeof($Label)"),
								$Global:ExecutionContext.SessionState.PSVariable.GetValue("#$Label"),
								$Depth,
								$HasChildren
							)
						}

						static AddCheatEntries ($Labels, $Depth)
						{
							$Indent = [CheatTableGenerator]::IndentBy[$Depth + 1]

							[CheatTableGenerator]::Text.Append($Indent) > $Null
							[CheatTableGenerator]::Text.Append('<CheatEntries>') > $Null
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null

							foreach ($Label in $Labels)
							{
								if ([CheatTableGenerator]::BeginCheatEntryForLabel($Label, $Depth, $False))
								{
									[CheatTableGenerator]::EndCheatEntry($Depth)
								}
							}

							[CheatTableGenerator]::Text.Append($Indent) > $Null
							[CheatTableGenerator]::Text.Append('</CheatEntries>') > $Null
							[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
						}
					}

					[CheatTableGenerator]::TypeCache = [Collections.Generic.Dictionary[ValueTuple[Object, Object], Object]]::new(16)
					[CheatTableGenerator]::CheatEntryID = 0
					[CheatTableGenerator]::Text = [Text.StringBuilder]::new(32MB)

					$GroupHeader = '<GroupHeader>1</GroupHeader><Options moManualExpandCollapse="1" moActivateChildrenAsWell="1" moDeactivateChildrenAsWell="1" />'

					$InterpolatedFloatBaseAddress = ${&InterpolatedFloatData}

					[CheatTableGenerator]::Text.Append("<?xml version=`"1.0`" encoding=`"utf-8`"?>`r`n<CheatTable CheatEngineTableVersion=`"45`">`r`n`t<CheatEntries>") > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null

					[CheatTableGenerator]::BeginCheatEntryForLabel('Cheats', 0, $True) > $Null
					[CheatTableGenerator]::AddCheatEntries(@('AlwaysSpawnNagi'), 2)
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[3]) > $Null
					[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
					[CheatTableGenerator]::EndCheatEntry(0)

					[CheatTableGenerator]::BeginCheatEntryForLabel('Camera', 0, $True) > $Null
					[CheatTableGenerator]::AddCheatEntries(@($CameraPositionLabels, 'CameraHeight', 'CameraShakeActualValue', 'CameraModifier0', 'CameraModifier1', 'ShouldInitialiseCameraPositions').ForEach{$_}, 2)
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[3]) > $Null
					[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
					[CheatTableGenerator]::EndCheatEntry(0)

					[CheatTableGenerator]::BeginCheatEntryForLabel('ThreadGuards', 0, $True) > $Null
					[CheatTableGenerator]::AddCheatEntries(@('ThreadGuardA_A', 'ThreadGuardA_B', 'ThreadGuardB_A', 'ThreadGuardB_B', 'ThreadGuardC_A', 'ThreadGuardD_A'), 2)
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[3]) > $Null
					[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
					[CheatTableGenerator]::EndCheatEntry(0)

					[CheatTableGenerator]::BeginCheatEntryForLabel('GameData', 0, $True) > $Null
					[CheatTableGenerator]::AddCheatEntries(@('ResolutionX', 'ResolutionY', 'AspectRatio', 'SomeCounter?', 'GameIsPaused?', 'GameStateA', 'GameStateB', 'GameStateC', 'GameStateD', 'GameStateE', 'GameStateF', 'GameStateG', 'GameStateH', 'GameStateI', 'GameStateJ', 'GameStateK', 'InAnEvent?', 'ShouldDrawTheHUD', 'HUDSlideInPercentage', 'LoadingDiscRotationAngle', 'WindowShopperPositionCount', 'PauseTransitionEffectCounter', 'LevelIntroductionCounter', 'NewsTickerCounter', 'ShopTillItemTransitionCounter', 'GameIsWindowed', 'CurrentMapClockMessage', 'SelectionHandX', 'SelectionHandY', 'ShouldDoFrame?'), 2)
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[3]) > $Null
					[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
					[CheatTableGenerator]::EndCheatEntry(0)
					[CheatTableGenerator]::BeginCheatEntryForLabel('PatchData', 0, $True) > $Null
					[CheatTableGenerator]::AddCheatEntries(${PatchData.DefinedLabels}, 2)
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[3]) > $Null
					[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
					[CheatTableGenerator]::EndCheatEntry(0)

					[CheatTableGenerator]::BeginCheatEntryForLabel('InterpolatedFloats', 0, $True) > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[3]) > $Null
					[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[3]) > $Null
					[CheatTableGenerator]::Text.Append('<CheatEntries>') > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null

					if ($InterpolatingFloats)
					{
						foreach ($Float in $FloatsToInterpolate)
						{
							if (-not $Script:InterpolatedFloatsToIncludeInCheatTable.Contains($Float.Name))
							{
								continue
							}

							if ($Null -eq $Float.Structure)
							{
								[CheatTableGenerator]::BeginCheatEntryForLabel($Float.Name, 2, $True) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[5]) > $Null
								[CheatTableGenerator]::Text.Append('<CheatEntries>') > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null

								foreach ($Offset in $Float.FloatOffsets)
								{
									$Name = "$($Float.Name)_$($Offset.Key)"

									[CheatTableGenerator]::BeginCheatEntryForLabel($Offset.Key, 4, $True) > $Null
									[CheatTableGenerator]::AddCheatEntries(@("$($Name)_ActualValue", "$($Name)_HeldValue", "$($Name)_Delta", "$($Name)_Target"), 6)
									[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[7]) > $Null
									[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
									[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
									[CheatTableGenerator]::EndCheatEntry(4)
								}

								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[5]) > $Null
								[CheatTableGenerator]::Text.Append('</CheatEntries>') > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[5]) > $Null
								[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
								[CheatTableGenerator]::EndCheatEntry(2)
							}
							else
							{
								$Count = if ($Float.Structure.Count -is [String]) {$Float.Structure.MaximumCount} else {$Float.Structure.Count}

								[CheatTableGenerator]::BeginCheatEntryForLabel($Float.Name, 2, $True) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[5]) > $Null
								[CheatTableGenerator]::Text.Append('<CheatEntries>') > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null

								if ($Float.Structure.Count -is [String])
								{
									[CheatTableGenerator]::BeginCheatEntryForLabel($Float.Structure.Count, 4, $False) > $Null
									[CheatTableGenerator]::EndCheatEntry(4)
								}

								for ($Index = 0; $Index -lt $Count; ++$Index)
								{
									[CheatTableGenerator]::BeginCheatEntryForLabel("$($Float.Name)[$Index]", 4, $True) > $Null
									[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[7]) > $Null
									[CheatTableGenerator]::Text.Append('<CheatEntries>') > $Null
									[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null

									$BaseName = "$($Float.Name)[$Index]"

									if ($Float.Name -eq 'MobPosition')
									{
										[CheatTableGenerator]::BeginCheatEntry("$($BaseName)_Index", ($Float.VirtualAddress + $Index * $Float.Structure.Size + 0xb3c), 'uint', 4, 6, $False) > $Null
										[CheatTableGenerator]::EndCheatEntry(6)
										[CheatTableGenerator]::BeginCheatEntry("$($BaseName)_Level", ($Float.VirtualAddress + $Index * $Float.Structure.Size + 0xae0), 'uint', 4, 6, $False) > $Null
										[CheatTableGenerator]::EndCheatEntry(6)
										[CheatTableGenerator]::BeginCheatEntry("$($BaseName)_MobType", ($Float.VirtualAddress + $Index * $Float.Structure.Size + 0x424), 'uint', 4, 6, $False) > $Null
										[CheatTableGenerator]::EndCheatEntry(6)
										[CheatTableGenerator]::BeginCheatEntry("$($BaseName)_Visibility", ($Float.VirtualAddress + $Index * $Float.Structure.Size + 0xAF4), 'uint', 4, 6, $False) > $Null
										[CheatTableGenerator]::EndCheatEntry(6)
									}

									foreach ($Offset in $Float.FloatOffsets)
									{
										$OffsetName = "$($BaseName)_$($Offset.Key)"

										[CheatTableGenerator]::BeginCheatEntryForLabel($Offset.Key, 6, $True) > $Null
										[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[9]) > $Null
										[CheatTableGenerator]::Text.Append('<CheatEntries>') > $Null
										[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
										[CheatTableGenerator]::BeginCheatEntry("$($OffsetName)_ActualValue", ($Float.VirtualAddress + $Index * $Float.Structure.Size + $Offset.Value), 'float', 4, 8, $False) > $Null
										[CheatTableGenerator]::EndCheatEntry(8)
										[CheatTableGenerator]::BeginCheatEntry("$($OffsetName)_HeldValue", ($InterpolatedFloatBaseAddress + $InterpolatedFloatHeldValueOffset), 'float', 4, 8, $False) > $Null
										[CheatTableGenerator]::EndCheatEntry(8)
										[CheatTableGenerator]::BeginCheatEntry("$($OffsetName)_Delta", ($InterpolatedFloatBaseAddress + $InterpolatedFloatDeltaOffset), 'float', 4, 8, $False) > $Null
										[CheatTableGenerator]::EndCheatEntry(8)
										[CheatTableGenerator]::BeginCheatEntry("$($OffsetName)_Target", ($InterpolatedFloatBaseAddress + $InterpolatedFloatTargetOffset), 'float', 4, 8, $False) > $Null
										[CheatTableGenerator]::EndCheatEntry(8)
										[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[9]) > $Null
										[CheatTableGenerator]::Text.Append('</CheatEntries>') > $Null
										[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
										[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[9]) > $Null
										[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
										[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
										[CheatTableGenerator]::EndCheatEntry(6)

										$InterpolatedFloatBaseAddress += $InterpolatedFloatEntrySize
									}

									[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[7]) > $Null
									[CheatTableGenerator]::Text.Append('</CheatEntries>') > $Null
									[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
									[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[7]) > $Null
									[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
									[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
									[CheatTableGenerator]::EndCheatEntry(4)
								}

								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[5]) > $Null
								[CheatTableGenerator]::Text.Append('</CheatEntries>') > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[5]) > $Null
								[CheatTableGenerator]::Text.Append($GroupHeader) > $Null
								[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
								[CheatTableGenerator]::EndCheatEntry(2)
							}
						}
					}

					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::IndentBy[3]) > $Null
					[CheatTableGenerator]::Text.Append('</CheatEntries>') > $Null
					[CheatTableGenerator]::Text.Append([CheatTableGenerator]::CRLF) > $Null
					[CheatTableGenerator]::EndCheatEntry(0)
					[CheatTableGenerator]::Text.Append("`t</CheatEntries>`r`n</CheatTable>") > $Null
				}


				function Copy-BackupOfRecettearExecutable
				{
					[CmdletBinding()] Param ($Language)

					if ($Null -eq $Script:BackupPath)
					{
						while (
							Test-Path -LiteralPath (
								$Script:BackupPath = (
									Join-Path `
										(Split-Path $RecettearExecutable.FullName) `
										"recettear.$Language.SansFancyScreenPatch.$([DateTime]::UtcNow.Ticks).exe"
								)
							) -PathType Leaf
						)
						{}
					}

					[IO.File]::Copy($RecettearExecutable.FullName, $Script:BackupPath)
				}


				Copy-BackupOfRecettearExecutable $GameVersionLanguage -ErrorAction Stop


				try
				{
					$File.Position = $PEOffset + 2
					$File.Write((LittleEndian $PatchedSectionCount), 0, 2)

					$File.Position = $OptionalHeaderOffset + 4
					$File.Write((LittleEndian $PatchedSizeOfCode), 0, 4)

					$File.Position = $OptionalHeaderOffset + 8
					$File.Write((LittleEndian $PatchedSizeOfInitialisedData), 0, 4)

					$File.Position = $OptionalHeaderOffset + 16
					$File.Write((LittleEndian ${&PatchEntryPoint}), 0, 4)

					$File.Position = $OptionalHeaderOffset + 56
					$File.Write((LittleEndian $PatchedSizeOfImage), 0, 4)

					$File.Position = $OptionalHeaderOffset + 60
					$File.Write((LittleEndian $PatchedSizeOfHeaders), 0, 4)

					$File.Position = $SectionTableOffset + 40 * $SectionCount
					$File.Write($PatchCodeSection, 0, $PatchCodeSection.Length)
					$File.Write($PatchDataSection, 0, $PatchDataSection.Length)

					$File.Position = $File.Length
					$File.Write([Byte[]]::new($FillerBytesNeededBeforeFirstPatchSectionCount), 0, $FillerBytesNeededBeforeFirstPatchSectionCount)
					$File.Write([Byte[]]::new($RawDataSizeOfPatchCode), 0, $RawDataSizeOfPatchCode)
					$File.Write([Byte[]]::new($RawDataSizeOfPatchData), 0, $RawDataSizeOfPatchData)

					foreach ($ID in $AssemblyIDs)
					{
						$Length = $Variables.GetValue("#$ID")

						if ($Length -eq 0)
						{
							continue
						}

						$File.Position = $Variables.GetValue("@$ID")
						$File.Write(($Variables.GetValue("*$ID")), 0, $Length)
					}

					$File.Position = $IncrementStateSharedBetweenGameFrameAndPresentationFrameCallOffset
					$File.Write(
						[Byte[]] @(
							0xE9, (LittleEndian (DisplacementFrom (${&IncrementStateSharedBetweenGameFrameAndPresentationFrameCall} + 5) -To ${&IncrementStateSharedThrottle})) <# jmp IncrementStateSharedThrottle #>
						).ForEach{$_},
						0,
						5
					)

					if ($PatchingFPSDisplay -and $Script:FramerateLimit -ge 100)
					{
						$File.Position = $FPSDisplayFunctionOffset + 375
						$File.Write((3), 0, 1)
					}
				}
				catch
				{
					Write-Error -ErrorAction Stop "The patching of `"$($RecettearExecutable.FullName)`" failed, please restore the backup.$([Environment]::Newline)Error: $_"

					throw
				}

				if ($Null -ne $Script:CheatEngineTablePath)
				{
					New-Item $Script:CheatEngineTablePath -Force -Value ([CheatTableGenerator]::Text.ToString() | Out-String) > $Null
					[CheatTableGenerator]::Text.Clear() > $Null
					[CheatTableGenerator]::Text.Capacity = 0 > $Null
				}
			}
		}


		function Test-Fingerprint ($Fingerprint)
		{
			     $RecettearExecutable.Length -eq $Fingerprint.FileSize `
			-and $Fingerprint.SHA256Hash -ceq $(
				if ($Null -eq $RecettearExecutableHash)
				{
					$Script:RecettearExecutableHash = (Get-FileHash -InputStream $RecettearFile -Algorithm SHA256 -ErrorAction Stop).Hash
				}

				$RecettearExecutableHash
			)
		}


		$PatchApplicationWillDefinitelyFail = $False


		if (Test-Fingerprint $KnownVersions.SteamEnglish.ExecutableFingerprint)
		{
			$DetectedKnownVersion = $KnownVersions.SteamEnglish
			$GameVersionLanguage = 'eng'
			$PatchApplicationWillDefinitelyFail = $True
		}
		elseif (Test-Fingerprint $KnownVersions.EnglishV1_108.ExecutableFingerprint)
		{
			$DetectedKnownVersion = $KnownVersions.EnglishV1_108
			$GameVersionLanguage = 'eng'
		}
		elseif (Test-Fingerprint $KnownVersions.SteamJapanese.ExecutableFingerprint)
		{
			$DetectedKnownVersion = $KnownVersions.SteamJapanese
			$GameVersionLanguage = 'jpn'
			$PatchApplicationWillDefinitelyFail = $True
		}
		elseif (Test-Fingerprint $KnownVersions.JapaneseV1_126.ExecutableFingerprint)
		{
			$DetectedKnownVersion = $KnownVersions.JapaneseV1_126
			$GameVersionLanguage = 'jpn'
		}
		else
		{
			if ($Null -ne $Script:GameLanguageOverride)
			{
				$GameVersionLanguage = $Script:GameLanguageOverride
			}
			elseif (
				$Null -eq (
					$GameVersionLanguage = $(
						if (-not [String]::IsNullOrWhiteSpace($RecettearExecutableVersionInfo.CompanyName))
						{
							if ($RecettearExecutableVersionInfo.CompanyName -match 'Carpe\s+Fulgur')
							{
								'eng'
							}
							else
							{
								'jpn'
							}
						}
						else
						{
							try
							{
								if (
									$Null -ne (
										Select-String -Pattern 'Carpe\s+Fulgur' -LiteralPath (
											Join-Path (Get-InstallationRootPathFromExecutablePath $RecettearExecutable.FullName) manual/manual.htm
										) -ErrorAction Stop
									)
								)
								{
									'eng'
								}
								else
								{
									'jpn'
								}
							}
							catch
							{}
						}
					)
				)
			)
			{
				if ($Script:NonInteractive)
				{
					throw [FancyScreenPatchForRecettearFailedToDetectLanguageException]::new(
						'The language of the Recettear installation could not be detected. Please try supplying a language via the `GameLanguageOverride` parameter.',
						[PSCustomObject] @{}
					)
				}
				else
				{
					$StopWatch.Stop()

					$GameVersionLanguage = ('eng', 'jpn')[
						$Host.UI.PromptForChoice(
							'The language of the Recettear installation could not be detected.',
							'Please select which language this installation is using:',
							('&English', '&Japanese'),
							@()
						)
					]

					$StopWatch.Start()
				}
			}
		}


		$LanguageCodeToName = @{eng = 'English'; jpn = 'Japanese'}


		$OfficalSupportedPatches = @{
			eng = [PSCustomObject] @{
				FileName = 'Recettear_patch_1108.zip'
				Fingerprint = [PSCustomObject] @{FileSize = 3310334; SHA256Hash = '4FECE744BAA609D10D7BCD2ECF374942B3A4EBD099182C7B50379BD1ED26F71E'}
				URLs = [String[]] @(
					'https://web.archive.org/web/20171106142803if_/http://www.carpefulgur.com/recettear/Recettear_patch_1108.zip'
				)
				RootPath = [RegEx]::new('^/?', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
			}

			jpn = [PSCustomObject] @{
				FileName = 'rece_update1126.zip'
				Fingerprint = [PSCustomObject] @{FileSize = 14031026; SHA256Hash = '9E139E361711F356A670CBBFD94BD385DE4BD1145049B2BA367989F870185E73'}
				URLs = [String[]] @(
					'https://egs-soft.info/product/recet/rece_update1126.zip'
					'https://web.archive.org/web/20160821161336/http://egs-soft.info/product/recet/rece_update1126.zip'
				)
				RootPath = [RegEx]::new('^/?rece_update1126/', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
			}
		}


		function Find-SupportedOfficialPatchArchive ($PatchArchive)
		{
			Find-FileFromInstallations $PatchArchive
		}


		function Test-ShouldApplyOfficalPatch
		{
			if ($Script:NonInteractive)
			{
				$Script:ApplySupportedPatchAutomatically
			}
			else
			{
				$Patch = $OfficalSupportedPatches[$GameVersionLanguage]
				$Script:OfficalPatchArchiveFile = Find-SupportedOfficialPatchArchive $Patch

				$Prompt = if ($Null -ne $DetectedKnownVersion)
				{
					"The $($DetectedKnownVersion.FriendlyName) of the game was detected. Only the latest, official, DRM-free version is supported."
				}
				else
				{
					'This version of the game is unknown by this script. Only the latest, official, DRM-free version is supported.'
				}

				$StopWatch.Stop()

				$Choice = $Host.UI.PromptForChoice(
					$Prompt,
					"The patch for the latest, official, DRM-free version of the $($LanguageCodeToName[$GameVersionLanguage]) version of the game can be found at $(if ($Patch.URLs.Count -eq 1) {'this URL'} else {'any of these URLs'}): $($Patch.URLs -join '; ')`nWould you like to?",
					(
						$(if ($Null -ne $OfficalPatchArchiveFile) {"Install the patch &automatically from $($OfficalPatchArchiveFile.FullName). (A backup of the original files will be made.)"} else {'&Download and install the patch automatically from one of those URLs'}),
						'&Continue without installing the patch.'
					),
					0
				)

				$StopWatch.Start()

				$Choice -eq 0
			}
		}


		function Install-OfficialPatch ($PatchArchiveFile, $Patch)
		{
			Install-FromZipArchive $PatchArchiveFile $Patch
		}


		function Invoke-InstallationOfOfficialPatch
		{
			Use-FileWhatIsDownloadedIfNecessary $OfficalPatchArchiveFile $OfficalSupportedPatches[$GameVersionLanguage] `
			{
				Param ($File, $FileDescription)

				$Script:OfficalPatchArchiveFile = $File

				Install-OfficialPatch $File $FileDescription
			}
		}


		function Find-SansFancyFancyScreenPatchBackup ($Language)
		{
			if ($Null -ne $Script:BackupPath)
			{
				Get-Item -LiteralPath $Script:BackupPath -ErrorAction Ignore
			}
			else
			{
				  $RecettearExecutable.Directory.EnumerateFiles("recettear.$Language.SansFancyScreenPatch.?*.exe", [IO.SearchOption]::TopDirectoryOnly) `
				| Select-ChosenOne $SelectGreater {Param ($A) [UInt64] ($A.Name -replace '^.*\.([0-9]+)\.exe$', '$1')}
			}
		}


		function Restore-SansFancyFancyScreenPatchBackup ($Backup)
		{
			if ($Null -eq $Script:ClobberedByRestoredBackupBackupPath)
			{
				while (
					Test-Path -LiteralPath (
						$Script:ClobberedByRestoredBackupBackupPath = (
							Join-Path `
								(Split-Path $RecettearExecutable.FullName) `
								"recettear.$GameVersionLanguage.ClobberedByRestoredFancyScreenPatchBackup.$([DateTime]::UtcNow.Ticks).exe"
						)
					) -PathType Leaf
				)
				{}
			}

			[IO.File]::Copy($RecettearExecutable.FullName, $Script:ClobberedByRestoredBackupBackupPath)

			Use-Disposable ([IO.File]::Open($Backup.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)) `
			{
				Param ($BackupFile)

				$RecettearFile.SetLength(0)
				$BackupFile.CopyTo($RecettearFile)
				$RecettearFile.Flush()
				$RecettearFile.Position = 0
			}

			Remove-Item -LiteralPath $Backup.FullName
		}


		function Test-ShouldRestoreBackup
		{
			if ($Null -eq ($Script:LastRecettearExecutableBackup = Find-SansFancyFancyScreenPatchBackup $GameVersionLanguage))
			{
				return $False
			}

			if ($Script:NonInteractive)
			{
				$Script:RestoreBackupAutomatically
			}
			else
			{
				$Prompt = if ($Null -ne $DetectedKnownVersion)
				{
					"The $($DetectedKnownVersion.FriendlyName) of the game was detected. Only the latest, official, DRM-free version is supported."
				}
				else
				{
					'This version of the game is unknown by this script. Only the latest, official, DRM-free version is supported.'
				}

				$StopWatch.Stop()

				$Choice = $Host.UI.PromptForChoice(
					$Prompt,
					"A backup made by a previous installation of the Fancy Screen Patch was found at: `"$($LastRecettearExecutableBackup.FullName)`"; would you like to?",
					('Restore the backup &automatically. (A backup of the current files will be made.)', '&Continue without restoring the backup.'),
					0
				)

				$StopWatch.Start()

				$Choice -eq 0
			}
		}


		$Script:TriedBackup = $False
		$Script:TriedOfficialPatch = $False


		function Invoke-DesperateAttemptToFixThings
		{
			if (-not $TriedBackup)
			{
				$Script:TriedBackup = $True

				if (Test-ShouldRestoreBackup)
				{
					Restore-SansFancyFancyScreenPatchBackup $LastRecettearExecutableBackup
				}

				$True
			}
			elseif (-not $TriedOfficialPatch)
			{
				$Script:TriedOfficialPatch = $True

				if (Test-ShouldApplyOfficalPatch)
				{
					Invoke-InstallationOfOfficialPatch
				}

				$True
			}
			else
			{
				$False
			}
		}


		if ($PatchApplicationWillDefinitelyFail)
		{
			Invoke-DesperateAttemptToFixThings > $Null
		}


		$VersionToPatchAs = if ($GameVersionLanguage -eq 'eng') {$KnownVersions.EnglishV1_108} elseif ($GameVersionLanguage -eq 'jpn') {$KnownVersions.JapaneseV1_126}


		for (;;)
		{
			try
			{
				Apply-Patch $RecettearFile $VersionToPatchAs
			}
			catch [FancyScreenPatchForRecettearPatchingException]
			{
				if (Invoke-DesperateAttemptToFixThings)
				{
					continue
				}
				else
				{
					throw
				}
			}

			break
		}


		$RecettearExecutable.Refresh()


		$ScriptResult.PatchedExecutable = $RecettearExecutable
		$ScriptResult.BackupOfPatchedExecutable = Get-Item -LiteralPath $Script:BackupPath
	}


	if (-not $Script:SkipPostPatchOperations)
	{
		$RootPath = Get-InstallationRootPathFromExecutablePath $RecettearExecutable.FullName


		$FileNameChanges = [Collections.Generic.List[ValueTuple[String, String]]]::new()


		$INIs = @(
			($GameINI = [PSCustomObject] @{FileName = 'recet.ini'; Path = $Null; Encoding = $ANSIEncoding; Lines = $Null; Values = $Null; Reset = $False; Changes = [Ordered] @{}; LinesBeforeReset = $Null})
			($DxWrapperINI = [PSCustomObject] @{FileName = 'dxwrapper.ini'; Path = $Null; Encoding = 'UTF8'; Lines = $Null; Values = $Null; Reset = $False; Changes = [Ordered] @{}; LinesBeforeReset = $Null})
			($SpecialKINI = [PSCustomObject] @{FileName = "$SpecialKWrapperName.ini"; Path = $Null; Encoding = 'UTF8'; Lines = $Null; Values = $Null; Reset = $False; Changes = [Ordered] @{}; LinesBeforeReset = $Null})
			($DgVoodoo2INI = [PSCustomObject] @{FileName = 'dgVoodoo.conf'; Path = $Null; Encoding = 'UTF8'; Lines = $Null; Values = $Null; Reset = $False; Changes = [Ordered] @{}; LinesBeforeReset = $Null})
		)


		foreach ($INI in $INIs)
		{
			$INI.Path = Join-Path $RootPath $INI.FileName
		}


		function Read-INI ($INI, [Switch] $Values)
		{
			if ($Null -eq $INI.Lines)
			{
				if (Test-Path -LiteralPath $INI.Path -PathType Leaf)
				{
					if ($Null -eq ($INI.Lines = Get-Content -LiteralPath $INI.Path -Encoding $INI.Encoding -ErrorAction Continue))
					{
						$INI.Lines = @()
					}

				}
				else
				{
					$INI.Lines = @()
				}

				$INI.Values = $Null
			}

			if ($Values -and $Null -eq $INI.Values)
			{
				$INI.Values = Get-ValuesFromINI $INI.Lines
			}
		}


		function Write-INI ($INI)
		{
			if ($INI.Changes.Count -ne 0)
			{
				Read-INI $INI

				$INIContent = Set-ValuesInINI $INI.Lines $INI.Changes

				if ('UTF8' -eq $INI.Encoding)
				{
					New-Item $INI.Path -Force -Value ($INIContent | Out-String) > $Null
				}
				else
				{
					$INIContent | Set-Content -LiteralPath $INI.Path -Encoding $INI.Encoding
				}
			}
		}


		function Get-INIValue ($INI, $Section, $Key)
		{
			if ($Null -ne ($SectionValues = $INI.Changes.$Section) -and $SectionValues.Contains($Key))
			{
				$SectionValues.$Key
			}
			else
			{
				$INI.Values.$Section.$Key
			}
		}


		function Set-INIValue ($INI, $Section, $Key, $Value)
		{
			if ($Null -eq ($SectionValues = $INI.Changes.$Section))
			{
				$SectionValues = ($INI.Changes.$Section = [Ordered] @{})
			}

			$SectionValues.$Key = $Value
		}


		function Get-DirectXVersionInUse ([Switch] $Actual)
		{
			Read-INI $DxWrapperINI -Values

			if (-not $Actual -and 'NoChange' -ne $Script:SetDirectXVersionToUse)
			{
				return $Script:SetDirectXVersionToUse
			}

			$DxWrapperD3D8To9 = Get-INIValue $DxWrapperINI Compatibility D3d8to9

			if ($Null -eq $DxWrapperD3D8To9 -or $DxWrapperD3D8To9 -eq '0')
			{
				8
			}
			else
			{
				Read-INI $DgVoodoo2INI -Values

				if ((Get-INIValue $DgVoodoo2INI DirectX DisableAndPassThru) -eq 'true')
				{
					9
				}
				else
				{
					$DgVoodoo2OutputAPI = Get-INIValue $DgVoodoo2INI  General OutputAPI

					if ($DgVoodoo2OutputAPI -match '^(?<D3D11>bestavailable)$|^d3d1(?:(?<D3D11>1)|(?<D3D12>2))')
					{
						if ($Null -ne $Matches.D3D12)
						{
							12
						}
						elseif ($Null -ne $Matches.D3D11)
						{
							11
						}
					}
					else
					{
						9
					}
				}
			}
		}


		$DirectXVersionInUse = Get-DirectXVersionInUse
		$ChangingDirectXVersion = 'NoChange' -ne $Script:SetDirectXVersionToUse -and $Script:SetDirectXVersionToUse -ne (Get-DirectXVersionInUse -Actual)


		if ('NoChange' -ne $Script:SetGameWindowMode)
		{
			$WindowModeValue = if ('Fullscreen' -eq $Script:SetGameWindowMode) {'0'} elseif ('Windowed' -eq $Script:SetGameWindowMode) {'1'} elseif ('BorderlessWindowed' -eq $Script:SetGameWindowMode) {'2'}

			Set-INIValue $GameINI setup winmode $WindowModeValue
		}


		if ('NoChange' -ne $Script:SetVerticalSyncEnabled -and $DirectXVersionInUse -eq 8)
		{
			Read-INI $GameINI -Values
			$GameWindowMode = Get-INIValue $GameINI setup winmode

			if ([String]::IsNullOrWhiteSpace($GameWindowMode) -or $Null -eq ($GameWindowMode = $GameWindowMode -as [Int32]))
			{
				$GameWindowMode = 1
			}

			$GameWindowMode = if ($Script:SetVerticalSyncEnabled)
			{
				$GameWindowMode -bor (1 -shl 16)
			}
			else
			{
				$GameWindowMode -band (-bnot (1 -shl 16))
			}

			Write-Host "GameWindowMode: $GameWindowMode"

			Set-INIValue $GameINI setup winmode $GameWindowMode
		}


		if ($Script:InstallDxWrapper)
		{
			$DxWrapperFileDescription = [PSCustomObject] @{
				FileName = 'dxwrapper_v1_0_6542_21.zip'
				Fingerprint = [PSCustomObject] @{FileSize = 5370660; SHA256Hash = '9C29693121B15B28C6E499A77AF23911011FA2D741316674DC98A4BD33542C9D'}
				URLs = [String[]] @(
					'https://github.com/elishacloud/dxwrapper/releases/download/v1.0.6542.21/dxwrapper.zip'
					'https://web.archive.org/web/20230712000800/https://objects.githubusercontent.com/github-production-release-asset-2e65be/81271358/d1b0dd80-c0a8-11eb-8ec1-61bfbc27c317?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20230712%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20230712T000800Z&X-Amz-Expires=300&X-Amz-Signature=2f4de384dee5ffbb625a083f22a721e64dbcbfc51f7964ee84c906ddc555cd89&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=81271358&response-content-disposition=attachment%3B%20filename%3Ddxwrapper.zip&response-content-type=application%2Foctet-stream'
				)
				RootPath = [RegEx]::new('^/?', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
			}

			if ($Null -ne ($FoundDxWrapper = Get-Item -LiteralPath (Join-Path $RootPath dxwrapper.zip) -ErrorAction Ignore))
			{
				$DxWrapperFileDescription.FileName = 'dxwrapper.zip'
			}
			else
			{
				$FoundDxWrapper = Find-FileFromInstallations $DxWrapperFileDescription
			}

			Use-FileWhatIsDownloadedIfNecessary $FoundDxWrapper $DxWrapperFileDescription `
			{
				Param ($File, $FileDescription)

				Install-FromZipArchive $File $FileDescription @{
					"Stub/$DxWrapperDLL" = $DxWrapperDLL
					'Stub/Stub.ini' = 'Stub.ini'
					'dxwrapper.dll' = 'dxwrapper.dll'
					'dxwrapper.ini' = 'dxwrapper.ini'
				}

				$Script:ConfigureDxWrapper = $True
			}
		}


		if ($Script:InstallDgVoodoo2)
		{
			$DgVoodoo2FileDescription = [PSCustomObject] @{
				FileName = 'dgVoodoo2_81_2.zip'
				Fingerprint = [PSCustomObject] @{FileSize = 5836398; SHA256Hash = '5D0407917DCAADEB9F8796355ABA10BC51A875812868F4549F624E7BBE0D8DBF'}
				URLs = [String[]] @(
					'http://dege.freeweb.hu/dgVoodoo2/bin/dgVoodoo2_81_2.zip'
					'https://web.archive.org/web/20230827194343/http://dege.freeweb.hu/dgVoodoo2/bin/dgVoodoo2_81_2.zip'
				)
				RootPath = [RegEx]::new('^/?', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
			}

			if ($Null -ne ($FoundDgVoodoo2 = Get-Item -LiteralPath (Join-Path $RootPath dgVoodoo2.zip) -ErrorAction Ignore))
			{
				$DgVoodoo2FileDescription.FileName = 'dgVoodoo2.zip'
			}
			else
			{
				$FoundDgVoodoo2 = Find-FileFromInstallations $DgVoodoo2FileDescription
			}

			Use-FileWhatIsDownloadedIfNecessary $FoundDgVoodoo2 $DgVoodoo2FileDescription `
			{
				Param ($File, $FileDescription)

				Install-FromZipArchive $File $FileDescription @{
					'MS/x86/D3D9.dll' = $DgVoodoo2DLL
					'dgVoodoo.conf' = 'dgVoodoo.conf'
					'dgVoodooCpl.exe' = 'dgVoodooCpl.exe'
					'QuickGuide.url' = 'dgVoodooQuickGuide.url'
				}

				$Script:ConfigureDgVoodoo2 = $True
			}
		}


		if ($Script:InstallSpecialK)
		{
			$SpecialKFileDescription = [PSCustomObject] @{
				FileName = 'SpecialK_23.8.17.zip'
				Fingerprint = [PSCustomObject] @{FileSize = 7351962; SHA256Hash = 'FD01D18106472E9B0F6C0FB89256A6928407EFD36A98FF2E1D451AA0E6021FBB'}
				URLs = [String[]] @(
					'https://nightly.link/SpecialKO/SpecialK/suites/15177810613/artifacts/867301204'
					'https://web.archive.org/web/20230817222304/https://pipelines.actions.githubusercontent.com/serviceHosts/8fb96cb4-27f5-4b0b-b1d1-89bc7687ccf5/_apis/pipelines/1/runs/487/signedartifactscontent?artifactName=SpecialK_23.8.17_ec35813d&urlExpires=2023-08-17T22%3A23%3A46.8004156Z&urlSigningMethod=HMACV2&urlSignature=9%2BR5hmMe1WrtTeCA4tnK13v3L6z%2BEPBZkjgR2VOL2ik%3D'
				)
				RootPath = [RegEx]::new('^/?', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
			}

			if ($Null -ne ($FoundSpecialK = Get-Item -LiteralPath (Join-Path $RootPath SpecialK.zip) -ErrorAction Ignore))
			{
				$SpecialKFileDescription.FileName = 'SpecialK.zip'
			}
			else
			{
				$FoundSpecialK = Find-FileFromInstallations $SpecialKFileDescription
			}

			Use-FileWhatIsDownloadedIfNecessary $FoundSpecialK $SpecialKFileDescription `
			{
				Param ($File, $FileDescription)

				Install-FromZipArchive $File $FileDescription @{
					'SpecialK32.dll' = $SpecialKDLL
				}

				$Script:ConfigureSpecialK = $True
			}
		}


		if ($Script:ResetDxWrapperConfiguration)
		{
			$Script:ConfigureDxWrapper = $True

			$DxWrapperINI.Reset = $True
			$DxWrapperINI.LinesBeforeReset = $DxWrapperINI.Lines
			$DxWrapperINI.Lines = @()
			$DxWrapperINI.Values = [Ordered] @{}
		}


		if ($ChangingDirectXVersion -or $Script:ConfigureDxWrapper -or $Script:CheckDxWrapperConfiguration)
		{
			if ($DirectXVersionInUse -eq 8)
			{
				$DxWrapperD3D8To9 = '0'
				$DxWrapperEnableVSync = $Null
			}
			else
			{
				$DxWrapperD3D8To9 = '1'
				$DxWrapperEnableVSync = if ($Script:SetVerticalSyncEnabled) {'1'} elseif ($Script:SetVerticalSyncEnabled -eq $False) {'0'}
			}
		}


		if ($ChangingDirectXVersion -or $Script:ConfigureDxWrapper)
		{
			Read-INI $DxWrapperINI -Values

			Set-INIValue $DxWrapperINI Compatibility D3d8to9 $DxWrapperD3D8To9
			Set-INIValue $DxWrapperINI Compatibility EnableD3d9Wrapper '0'

			if ($Null -ne $DxWrapperEnableVSync)
			{
				Set-INIValue $DxWrapperINI d3d9 EnableVSync $DxWrapperEnableVSync
			}
		}


		if ($Script:ResetDgVoodoo2Configuration)
		{
			$Script:ConfigureDgVoodoo2 = $True

			$DgVoodoo2INI.Reset = $True
			$DgVoodoo2INI.LinesBeforeReset = $DgVoodoo2INI.Lines
			$DgVoodoo2INI.Lines = @()
			$DgVoodoo2INI.Values = [Ordered] @{}
		}


		if ($ChangingDirectXVersion -or $Script:ConfigureDgVoodoo2 -or $Script:CheckDgVoodoo2Configuration)
		{
			$DgVoodoo2OutputAPI = if ($DirectXVersionInUse -eq 12) {'d3d12_fl12_0'} elseif ($DirectXVersionInUse -eq 11) {'d3d11_fl11_0'}
			$DgVoodoo2DirectXDisableAndPassthrough = if ($DirectXVersionInUse -ne 12 -and $DirectXVersionInUse -ne 11) {'true'} else {'false'}
		}


		if ($ChangingDirectXVersion -or $Script:ConfigureDgVoodoo2)
		{
			Read-INI $DgVoodoo2INI

			if ($Null -ne $DgVoodoo2OutputAPI)
			{
				Set-INIValue $DgVoodoo2INI General OutputAPI $DgVoodoo2OutputAPI
			}

			if ($Script:ConfigureDgVoodoo2)
			{
				Set-INIValue $DgVoodoo2INI GeneralExt PresentationModel 'flip_discard'
			}

			Set-INIValue $DgVoodoo2INI DirectX DisableAndPassThru $DgVoodoo2DirectXDisableAndPassthrough

			if ($Script:ConfigureDgVoodoo2)
			{
				Set-INIValue $DgVoodoo2INI DirectX VRAM '2048'
				Set-INIValue $DgVoodoo2INI DirectX AppControlledScreenMode 'true'
				Set-INIValue $DgVoodoo2INI DirectX DisableAltEnterToToggleScreenMode 'true'
				Set-INIValue $DgVoodoo2INI DirectX dgVoodooWatermark 'false'
			}
		}


		if ($Script:ResetSpecialKConfiguration)
		{
			$Script:ConfigureSpecialK = $True

			$SpecialKINI.Reset = $True
			$SpecialKINI.LinesBeforeReset = $SpecialKINI.Lines
			$SpecialKINI.Lines = @()
			$SpecialKINI.Values = [Ordered] @{}
		}


		if ($Script:ConfigureSpecialK)
		{
			Read-INI $SpecialKINI

			Set-INIValue $SpecialKINI Compatibility.General AutoLargeAddressPatch 'false'

			Set-INIValue $SpecialKINI Render.FrameRate PresentationInterval '-1'
			Set-INIValue $SpecialKINI Render.FrameRate UseAMDMWAITX 'false'

			Set-INIValue $SpecialKINI Render.D3D9 EnableTextureMods 'true'

			Set-INIValue $SpecialKINI Render.DXGI UseFlipDiscard 'true'
			Set-INIValue $SpecialKINI Render.DXGI DisableFlipModel 'false'
			Set-INIValue $SpecialKINI Render.DXGI AllowTearingInDWM 'true'

			Set-INIValue $SpecialKINI Scheduler.Boost MinimumRenderThreadPriority '2'

			Set-INIValue $SpecialKINI Window.System Borderless 'false'
			Set-INIValue $SpecialKINI Window.System Fullscreen 'false'

			Set-INIValue $SpecialKINI Display.Output ForceFullscreen 'false'
			Set-INIValue $SpecialKINI Display.Output ForceWindowed 'false'

			Set-INIValue $SpecialKINI Import.ReShade32 Architecture 'Win32'
			Set-INIValue $SpecialKINI Import.ReShade32 Filename 'ReShade32.dll'
			Set-INIValue $SpecialKINI Import.ReShade32 Role 'ThirdParty'
			Set-INIValue $SpecialKINI Import.ReShade32 When 'Early'
		}


		if ($DirectXVersionInUse -eq 12)
		{
			Read-INI $GameINI -Values

			$GameWindowMode = Get-INIValue $GameINI setup winmode

			$GameWindowMode = if ([String]::IsNullOrWhiteSpace($GameWindowMode) -or $Null -eq ($GameWindowMode = $GameWindowMode -as [Int32]))
			{
				1
			}
			else
			{
				$GameWindowMode -band (-bnot (1 -shl 16))
			}

			if ($GameWindowMode -eq 0)
			{
				if ($Script:NonInteractive)
				{
					Write-Warning 'The game''s window-mode is "FullScreen", but DirectX12 is to be used, so fullscreen mode may cause the game to fail to display an image. Borderless-windowed mode is recommended when using DirectX 12.'
				}
				else
				{
					$StopWatch.Stop()

					if (Read-YesOrNo 'The game''s window-mode is "FullScreen", but DirectX12 is to be used, so fullscreen mode may cause the game to fail to display an image. Would you like to use Borderless-windowed mode instead?')
					{
						Set-INIValue $GameINI setup winmode '2'
					}

					$StopWatch.Start()
				}
			}
		}


		if ($DgVoodoo2IsProbablyInstalled)
		{
			if ($DirectXVersionInUse -eq 12 -or $DirectXVersionInUse -eq 11)
			{
				if ($DgVoodoo2DLL -eq $DgVoodoo2DisabledDLL)
				{
					$FileNameChanges.Add([ValueTuple[String, String]]::new((Join-Path $RootPath $DgVoodoo2DisabledDLL), $DgVoodoo2EnabledDLL))
					$DgVoodoo2StateChange = $True
					$DgVoodoo2StateChangeDescription = 'enabled'
				}
			}
			else
			{
				if ($DgVoodoo2DLL -eq $DgVoodoo2EnabledDLL)
				{
					$FileNameChanges.Add([ValueTuple[String, String]]::new((Join-Path $RootPath $DgVoodoo2EnabledDLL), $DgVoodoo2DisabledDLL))
					$DgVoodoo2StateChange = $False
					$DgVoodoo2StateChangeDescription = 'disabled'
				}
			}
		}


		function Summarise-ConfigurationChangesForINI ($INI)
		{
			$Changes = $INI.Changes

			if ($Changes.Count -eq 0)
			{
				return
			}

			$Sections = $Changes.GetEnumerator() | ? {$_.Value.Count -gt 0}

			if ($Sections.Count -eq 0)
			{
				return
			}

			"`t$($INI.FileName):"

			foreach ($Section in $Changes.GetEnumerator())
			{
				if ($Section.Value.Count -eq 0)
				{
					continue
				}

				$OldSection = $INI.Values.($Section.Key)

				"`t`t[$($Section.Key)]"

				foreach ($Setting in $Section.Value.GetEnumerator())
				{

					$Old = $OldSection.($Setting.Key)
					$New = $Setting.Value

					if ($Old -ceq $New)
					{
						"`t`t$($Setting.Key)=$New"
					}
					else
					{
						"`t`t$($Setting.Key):"
						"`t`t`tOld: $($OldSection.($Setting.Key))"
						"`t`t`tNew: $($Setting.Value)"
					}
				}

				[String]::Empty
			}
		}


		function Summarise-ConfigurationChanges
		{
			if ($Null -ne $DgVoodoo2StateChangeDescription)
			{
				"`tdgVoodoo2 was $DgVoodoo2StateChangeDescription."
				[String]::Empty
			}

			$Resets = $INIs.ForEach{
				if ($_.Reset)
				{
					"`t$($_.FileName) was reset."
				}
			}

			if ($Resets.Count -gt 0)
			{
				$Resets
				[String]::Empty
			}

			$INIs.ForEach{
				Read-INI $_ -Values
				Summarise-ConfigurationChangesForINI $_
			}
		}


		$ConfigurationChanges = Summarise-ConfigurationChanges $_

		if ($ConfigurationChanges.Count -gt 0)
		{
			Write-Host "$([Environment]::NewLine)The following changes are being made to these configuration files:$([Environment]::NewLine)$($ConfigurationChanges -join [Environment]::NewLine)"
		}


		function Copy-Dictionary ($Dictionary, [Switch] $Recurse)
		{
			$Copy = $Dictionary.GetType()::new()

			foreach ($Entry in $Dictionary.GetEnumerator())
			{
				$CopiedValue = if ($Recurse -and $Entry.Value -is [Collections.IDictionary])
				{
					Copy-Dictionary $Entry.Value -Recurse
				}
				else
				{
					$Entry.Value
				}

				$Copy[$Entry.Key] = $CopiedValue
			}

			$Copy
		}


		$ScriptResult.ConfigurationChanges = [PSCustomObject] @{
			ByFile = $(
				$ByFile = [Ordered] @{}

				foreach ($INI in $INIs)
				{
					$ByFile.($INI.FileName) = [PSCustomObject] @{
						Reset = $(
							if ($INI.Reset)
							{
								[PSCustomObject] @{
									Before = [PSCustomObject] @{Lines = $INI.LinesBeforeReset}
									After = [PSCustomObject] @{Lines = $INI.Lines}
								}
							}
						)

						Changes = Copy-Dictionary $INI.Changes -Recurse
					}
				}

				$ByFile
			)

			DgVoodoo2EnabledStatusChange = $DgVoodoo2StateChange

			FileNameChanges = $FileNameChanges
		}


		foreach ($INI in $INIs)
		{
			Write-INI $INI
			$INI.Lines = $Null
		}


		foreach ($FileNameChange in $FileNameChanges)
		{
			Rename-Item -LiteralPath $FileNameChange.Item1 -NewName $FileNameChange.Item2 -ErrorAction Continue

			if (-not $?)
			{
				Write-Host "`"$($FileNameChange.Item1)`" could not be renamed to `"$($FileNameChange.Item2)`". See the error immediately above for why this is so.$([Environment]::NewLine)"
			}
		}


		$PostWriteConfigurationMessages = [Collections.Generic.List[String]]::new(8)


		function Summarise-ConfigurationCheck ($INI, $Check)
		{
			"`t$($INI.FileName):"

			foreach ($Section in $Check.GetEnumerator())
			{
				if ($Section.Value.Count -eq 0)
				{
					continue
				}

				"`t`t[$($Section.Key)]"

				foreach ($Setting in $Section.Value.GetEnumerator())
				{
					"`t`t$($Setting.Key):"
					"`t`t`tActual value: $($Setting.Value.ActualValue)"
					"`t`t`tExpected value: $($Setting.Value.ExpectedValue)"
				}

				[String]::Empty
			}
		}


		if ($Script:CheckDxWrapperConfiguration -or $Script:CheckDgVoodoo2Configuration -or $Script:CheckSpecialKConfiguration)
		{
			$PostWriteConfigurationMessages.Add('The following configuration files were checked:')
		}


		if ($Script:CheckDxWrapperConfiguration)
		{
			Read-INI $DxWrapperINI -Values

			$DxWrapperCheckedConfiguration = [Ordered] @{
				Compatibility = [Ordered] @{
					D3d8to9 = [PSCustomObject] @{ActualValue = Get-INIValue $DxWrapperINI Compatibility D3d8to9; ExpectedValue = $DxWrapperD3D8To9}
					EnableD3d9Wrapper = [PSCustomObject] @{ActualValue = Get-INIValue $DxWrapperINI Compatibility EnableD3d9Wrapper; ExpectedValue = '0'}
				}

				d3d9 = [Ordered] @{}
			}

			if ($Null -ne $DxWrapperEnableVSync)
			{
				$DxWrapperCheckedConfiguration.d3d9.EnableVSync = [PSCustomObject] @{ActualValue = Get-INIValue $DxWrapperINI d3d9 EnableVSync; ExpectedValue = $DxWrapperEnableVSync}
			}

			$ScriptResult.DxWrapperConfiguration = $DxWrapperCheckedConfiguration

			$PostWriteConfigurationMessages.Add(((Summarise-ConfigurationCheck $DxWrapperINI $ScriptResult.DxWrapperConfiguration) -join [Environment]::NewLine))
		}


		if ($Script:CheckDgVoodoo2Configuration)
		{
			Read-INI $DgVoodoo2INI -Values

			$DgVoodoo2CheckedConfiguration = [Ordered] @{
				General = [Ordered] @{}

				GeneralExt = [Ordered] @{
					PresentationModel = [PSCustomObject] @{ActualValue = Get-INIValue $DgVoodoo2INI GeneralExt PresentationModel; ExpectedValue = 'flip_discard'}
				}

				DirectX = [Ordered] @{
					DisableAndPassThru = [PSCustomObject] @{ActualValue = Get-INIValue $DgVoodoo2INI DirectX DisableAndPassThru; ExpectedValue = $DgVoodoo2DirectXDisableAndPassthrough}
					VRAM = [PSCustomObject] @{ActualValue = Get-INIValue $DgVoodoo2INI DirectX VRAM; ExpectedValue = '2048'}
					AppControlledScreenMode = [PSCustomObject] @{ActualValue = Get-INIValue $DgVoodoo2INI DirectX AppControlledScreenMode; ExpectedValue = 'true'}
					DisableAltEnterToToggleScreenMode = [PSCustomObject] @{ActualValue = Get-INIValue $DgVoodoo2INI DirectX DisableAltEnterToToggleScreenMode; ExpectedValue = 'true'}
					dgVoodooWatermark = [PSCustomObject] @{ActualValue = Get-INIValue $DgVoodoo2INI DirectX dgVoodooWatermark; ExpectedValue = 'false'}
				}
			}

			if ($Null -ne $DgVoodoo2OutputAPI)
			{
				$DgVoodoo2CheckedConfiguration.General.OutputAPI = [PSCustomObject] @{ActualValue = Get-INIValue $DgVoodoo2INI General OutputAPI; ExpectedValue = $DgVoodoo2OutputAPI}
			}

			$ScriptResult.DgVoodoo2Configuration = $DgVoodoo2CheckedConfiguration

			$PostWriteConfigurationMessages.Add(((Summarise-ConfigurationCheck $DgVoodoo2INI $ScriptResult.DgVoodoo2Configuration) -join [Environment]::NewLine))
		}


		if ($Script:CheckSpecialKConfiguration)
		{
			Read-INI $SpecialKINI -Values

			$ScriptResult.SpecialKConfiguration = [Ordered] @{
				'Compatibility.General' = [Ordered] @{
					AutoLargeAddressPatch = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Compatibility.General AutoLargeAddressPatch; ExpectedValue = 'false'}
				}

				'Render.FrameRate' = [Ordered] @{
					PresentationInterval = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Render.FrameRate PresentationInterval; ExpectedValue = '-1'}
					UseAMDMWAITX = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Render.FrameRate UseAMDMWAITX; ExpectedValue = 'false'}
				}

				'Render.D3D9' = [Ordered] @{
					EnableTextureMods = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Render.D3D9 EnableTextureMods; ExpectedValue = 'true'}
				}

				'Render.DXGI' = [Ordered] @{
					UseFlipDiscard = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Render.DXGI UseFlipDiscard; ExpectedValue = 'true'}
					DisableFlipModel = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Render.DXGI DisableFlipModel; ExpectedValue = 'false'}
					AllowTearingInDWM = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Render.DXGI AllowTearingInDWM; ExpectedValue = 'true'}
				}

				'Scheduler.Boost' = [Ordered] @{
					MinimumRenderThreadPriority = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Scheduler.Boost MinimumRenderThreadPriority; ExpectedValue = '2'}
				}

				'Window.System' = [Ordered] @{
					Borderless = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Window.System Borderless; ExpectedValue = 'false'}
					Fullscreen = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Window.System Fullscreen; ExpectedValue = 'false'}
				}

				'Display.Output' = [Ordered] @{
					ForceFullscreen = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Display.Output ForceFullscreen; ExpectedValue = 'false'}
					ForceWindowed = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Display.Output ForceWindowed; ExpectedValue = 'false'}
				}

				'Import.ReShade32' = [Ordered] @{
					Architecture = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Import.ReShade32 Architecture; ExpectedValue = 'Win32'}
					Filename = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Import.ReShade32 Filename; ExpectedValue = 'ReShade32.dll'}
					Role = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Import.ReShade32 Role; ExpectedValue = 'ThirdParty'}
					When = [PSCustomObject] @{ActualValue = Get-INIValue $SpecialKINI Import.ReShade32 When; ExpectedValue = 'Early'}
				}
			}

			$PostWriteConfigurationMessages.Add(((Summarise-ConfigurationCheck $SpecialKINI $ScriptResult.SpecialKConfiguration) -join [Environment]::NewLine))
		}


		if ($Script:GetGameWindowMode)
		{
			Read-INI $GameINI -Values

			$GameWindowMode = Get-INIValue $GameINI setup winmode

			$ScriptResult.GameWindowMode = if ([String]::IsNullOrWhiteSpace($GameWindowMode) -or $Null -eq ($GameWindowMode = $GameWindowMode -as [Int32]))
			{
				'Windowed'
			}
			else
			{
				$GameWindowMode = $GameWindowMode -band (-bnot (1 -shl 16))

				if ($GameWindowMode -eq 0) {'Fullscreen'} elseif ($GameWindowMode -eq 1) {'Windowed'} else {'BorderlessWindowed'}
			}

			$PostWriteConfigurationMessages.Add("The game's window-mode is: $($ScriptResult.GameWindowMode).$([Environment]::NewLine)")
		}


		if ($Script:GetDirectXVersionToUse -or $Script:GetVerticalSyncEnabled)
		{
			$DirectXVersionInUse = Get-DirectXVersionInUse
		}


		if ($Script:GetDirectXVersionToUse)
		{
			$ScriptResult.DirectXVersionToUse = $DirectXVersionInUse

			$PostWriteConfigurationMessages.Add("The version of DirectX in use is: $DirectXVersionInUse.$([Environment]::NewLine)")
		}


		if ($Script:GetVerticalSyncEnabled)
		{
			$ScriptResult.VerticalSyncEnabled = if ($DirectXVersionInUse -eq 8)
			{
				Read-INI $GameINI -Values

				$GameWindowMode = Get-INIValue $GameINI setup winmode

				if ([String]::IsNullOrWhiteSpace($GameWindowMode) -or $Null -eq ($GameWindowMode = $GameWindowMode -as [Int32]))
				{
					$False
				}
				else
				{
					($GameWindowMode -band (1 -shl 16)) -ne 0
				}
			}
			else
			{
				$DxWrapperEnableVSync = Get-INIValue $DxWrapperINI d3d9 EnableVSync

				$Null -ne $DxWrapperEnableVSync -and '0' -ne $DxWrapperEnableVSync
			}

			$PostWriteConfigurationMessages.Add("Vertical-sync is: $(if ($ScriptResult.VerticalSyncEnabled) {'enabled'} else {'disabled'}).$([Environment]::NewLine)")
		}


		if ($PostWriteConfigurationMessages.Count -gt 0)
		{
			Write-Host ($PostWriteConfigurationMessages -join [Environment]::NewLine)
		}
	}


	Write-Host "`"$($RecettearExecutable.FullName)`" was successfully patched, in $($StopWatch.Elapsed.TotalSeconds.ToString('F2'))-seconds."


	$StopWatch.Stop()


	$ScriptResult.TimeTaken = $StopWatch.Elapsed


	[PSCustomObject] $ScriptResult
}

