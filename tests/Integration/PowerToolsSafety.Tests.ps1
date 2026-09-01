#Requires -Modules Pester

BeforeAll {
    $script:powerToolsPath = (Resolve-Path "$PSScriptRoot/../../modules/power-tools.ps1").Path
}

Describe 'Power tools clean-process safety' -Tag @('Integration', 'PowerTools') {
    It 'fails closed before a native process can run' {
        $childScript = {
            param([string]$ModulePath)

            . $ModulePath
            function Test-GsudoAvailable { $false }
            function Invoke-PowerProcess {
                throw 'Blocked external process: the test must never reach a native executable'
            }

            try {
                Invoke-WithElevation -Command 'shutdown.exe /h'
                exit 2
            } catch {
                if ($_.Exception.Message -notlike 'Blocked external process:*') {
                    exit 3
                }
                exit 0
            }
        }

        $output = & pwsh -NoProfile -NonInteractive -Command $childScript -Args $script:powerToolsPath 2>&1

        $LASTEXITCODE | Should -Be 0 -Because ($output -join [Environment]::NewLine)
        $output -join [Environment]::NewLine | Should -Not -Match 'Access is denied|shutdown was initiated'
    }
}
