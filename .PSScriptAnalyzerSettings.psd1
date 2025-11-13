@{
    # Severity levels: Error, Warning, Information
    Severity = @('Error', 'Warning')

    # Include default rules
    IncludeDefaultRules = $true

    # Exclude specific rules
    ExcludeRules = @(
        # Allow Write-Host for user-facing output (not library code)
        'PSAvoidUsingWriteHost',

        # Allow aliases in profile (user convenience)
        'PSAvoidUsingCmdletAliases',

        # Allow positional parameters in interactive scripts
        'PSAvoidUsingPositionalParameters',

        # Allow global variables in profile (profile uses them intentionally)
        'PSAvoidGlobalVars',

        # Allow Invoke-Expression for Oh My Posh, zoxide, and similar tools
        'PSAvoidUsingInvokeExpression',

        # BOM encoding not critical for PowerShell 7+
        'PSUseBOMForUnicodeEncodedFile',

        # Allow $args assignment in fallback functions
        'PSAvoidAssignmentToAutomaticVariable',

        # Empty catch blocks acceptable for optional features
        'PSAvoidUsingEmptyCatchBlock',

        # Plural nouns acceptable for some function names
        'PSUseSingularNouns',

        # ShouldProcess not needed for profile functions
        'PSUseShouldProcessForStateChangingFunctions'
    )

    # Custom rules
    Rules = @{
        PSUseCompatibleSyntax = @{
            Enable         = $false  # Disabled - requires compatibility profile files
            TargetVersions = @('7.0', '7.2', '7.4')
        }

        PSUseCompatibleCommands = @{
            Enable         = $false  # Disabled - requires compatibility profile files
            TargetProfiles = @(
                'win-8_x64_10.0.17763.0_7.0.0_x64_4.0.30319.42000_core',
                'win-8_x64_10.0.17763.0_7.2.0_x64_4.0.30319.42000_core'
            )
        }

        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable             = $true
            NoEmptyLineBefore  = $false
            IgnoreOneLineBlock = $true
            NewLineAfter       = $false
        }

        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind            = 'space'
        }

        PSUseConsistentWhitespace = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator                  = $true
            CheckParameter                  = $false
        }

        PSAlignAssignmentStatement = @{
            Enable         = $false  # Can be too strict for varied code
            CheckHashtable = $false
        }

        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $false  # Allow double quotes by default
        }
    }
}
