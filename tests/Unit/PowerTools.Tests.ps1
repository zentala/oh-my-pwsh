#Requires -Modules Pester

BeforeAll {
    . "$PSScriptRoot/../../settings/icons.ps1"
    . "$PSScriptRoot/../../modules/status-output.ps1"
    . "$PSScriptRoot/../../modules/power-tools.ps1"
    . "$PSScriptRoot/../Helpers/PowerToolsTestHelpers.ps1"

    function global:Read-SpectreSelection {
        param([string]$Title, [string[]]$Choices)
    }

    function global:Read-SpectreText {
        param([string]$Prompt, [string]$DefaultAnswer)
    }
}

Describe 'Power tools helper functions' {
    Context 'Resolve-PowerAction' {
        It 'maps every supported action alias to its canonical action' {
            $cases = @{
                hibernate = @('hibernate', 'hibe', 'hib', 'h')
                sleep     = @('sleep', 'slp', 's', 'nap')
                shutdown  = @('shutdown', 'off', 'shut', 'down')
                restart   = @('restart', 'reboot', 'rb', 'r')
                cancel    = @('cancel', 'unpower', 'clear', 'abort', 'c')
                status    = @('status', 'list', 'ls')
                help      = @('help', '--help', '-h', '?')
                menu      = @('menu')
            }

            foreach ($expected in $cases.Keys) {
                foreach ($alias in $cases[$expected]) {
                    Resolve-PowerAction -Token $alias | Should -Be $expected
                    Resolve-PowerAction -Token $alias.ToUpperInvariant() | Should -Be $expected
                }
            }
        }

        It 'returns null for empty and unknown tokens' {
            Resolve-PowerAction -Token $null | Should -BeNullOrEmpty
            Resolve-PowerAction -Token '' | Should -BeNullOrEmpty
            Resolve-PowerAction -Token 'hibernate-now' | Should -BeNullOrEmpty
        }
    }

    Context 'ConvertTo-PowerMinutes' {
        It 'parses numeric, minute, hour, and compound durations' {
            @{
                '0'       = 0
                '60'      = 60
                '90m'     = 90
                '2h'      = 120
                '2h30m'   = 150
                ' 1H30M ' = 90
            }.GetEnumerator() | ForEach-Object {
                ConvertTo-PowerMinutes -Token $_.Key | Should -Be $_.Value
            }
        }

        It 'parses now as zero and rejects invalid values' {
            ConvertTo-PowerMinutes -Token 'now' | Should -Be 0
            foreach ($token in @($null, '', 'abc', '1hour', '1h2', '2m3h', '-5', '1:60', '24:00')) {
                ConvertTo-PowerMinutes -Token $token | Should -BeNullOrEmpty
            }
        }

        It 'calculates absolute times from a stable current time' {
            $fixedNow = [datetime]'2026-09-02T12:00:00'
            Mock Get-Date { $fixedNow }

            ConvertTo-PowerMinutes -Token '23:30' | Should -Be 690
            ConvertTo-PowerMinutes -Token '11:59' | Should -Be 1439
        }
    }

    Context 'Get-PowerCommand' {
        It 'returns the exact native command for each action' {
            Get-PowerCommand -Action hibernate | Should -Be 'shutdown.exe /h'
            Get-PowerCommand -Action sleep | Should -Be 'rundll32.exe powrprof.dll,SetSuspendState 0,1,0'
            Get-PowerCommand -Action shutdown | Should -Be 'shutdown.exe /s /t 0'
            Get-PowerCommand -Action restart | Should -Be 'shutdown.exe /r /t 0'
        }
    }

    Context 'Format-PowerDuration' {
        It 'formats minute and hour boundaries' {
            Format-PowerDuration 0 | Should -Be '0 min'
            Format-PowerDuration 59 | Should -Be '59 min'
            Format-PowerDuration 60 | Should -Be '1h'
            Format-PowerDuration 90 | Should -Be '1h 30m'
            Format-PowerDuration 120 | Should -Be '2h'
        }
    }
}

Describe 'Power tools external safety boundary' {
    BeforeEach {
        Mock Test-GsudoAvailable { $false }
    }

    It 'blocks every native power/scheduler command before execution' {
        foreach ($command in @(
                'shutdown.exe /h',
                'rundll32.exe powrprof.dll,SetSuspendState 0,1,0',
                'schtasks /delete /tn "OhMyPwsh-Power-sleep-test" /f'
            )) {
            $recorder = Initialize-PowerExternalSafetyDouble

            { Invoke-WithElevation -Command $command } | Should -Throw 'Blocked external process in test*'
            Should -Invoke Invoke-PowerProcess -Times 1 -ParameterFilter {
                $FilePath -eq 'cmd.exe' -and $ArgumentList[0] -eq '/c' -and $ArgumentList[1] -eq $command
            }
        }
    }

    It 'does not use gsudo unless the first process fails and gsudo is available' {
        Mock Test-GsudoAvailable { $true }
        $recorder = [System.Collections.Generic.List[string]]::new()
        Mock Invoke-PowerProcess {
            param([string]$FilePath, [string[]]$ArgumentList)
            $recorder.Add("$FilePath $($ArgumentList -join ' ')")
            if ($FilePath -eq 'cmd.exe') { return 1 }
            return 0
        }

        Invoke-WithElevation -Command 'schtasks /delete /tn "safe" /f' | Should -BeTrue
        $recorder | Should -HaveCount 2
        $recorder[1] | Should -BeLike 'gsudo cmd.exe /c *'
    }
}

Describe 'Get-PowerSchedule' {
    BeforeEach {
        $script:powerNow = [datetime]'2026-09-02T12:00:00'
        Mock Get-Date { $script:powerNow }
        Mock Invoke-WithElevation { $script:deletedPowerCommands += $Command; $true }
        $script:deletedPowerCommands = [System.Collections.Generic.List[string]]::new()
    }

    It 'filters, sorts, assigns stable IDs, and rounds minutes up' {
        $tasks = @(
            (New-PowerTaskDouble 'Unrelated-task'),
            (New-PowerTaskDouble 'OhMyPwsh-Power-restart-b'),
            (New-PowerTaskDouble 'OhMyPwsh-Power-sleep-a')
        )
        $infos = @{
            'Unrelated-task' = New-PowerTaskInfoDouble $powerNow.AddMinutes(1)
            'OhMyPwsh-Power-restart-b' = New-PowerTaskInfoDouble $powerNow.AddMinutes(45.1)
            'OhMyPwsh-Power-sleep-a' = New-PowerTaskInfoDouble $powerNow.AddMinutes(10.01)
        }
        Mock Get-ScheduledTask { $tasks }
        Mock Get-ScheduledTaskInfo { param([string]$TaskName) $infos[$TaskName] }

        $result = @(Get-PowerSchedule)

        $result | Should -HaveCount 2
        $result[0].Id | Should -Be 1
        $result[0].Action | Should -Be 'sleep'
        $result[0].MinutesLeft | Should -Be 11
        $result[1].Id | Should -Be 2
        $result[1].Action | Should -Be 'restart'
        $result[1].MinutesLeft | Should -Be 46
        Should -Invoke Get-ScheduledTask -ParameterFilter { $TaskName -eq 'OhMyPwsh-Power-*' }
    }

    It 'deletes stale and missing-next-run tasks and excludes them' {
        $tasks = @(
            (New-PowerTaskDouble 'OhMyPwsh-Power-sleep-stale'),
            (New-PowerTaskDouble 'OhMyPwsh-Power-hibernate-missing'),
            (New-PowerTaskDouble 'OhMyPwsh-Power-shutdown-live')
        )
        $infos = @{
            'OhMyPwsh-Power-sleep-stale' = New-PowerTaskInfoDouble $powerNow.AddMinutes(-1)
            'OhMyPwsh-Power-hibernate-missing' = New-PowerTaskInfoDouble $null
            'OhMyPwsh-Power-shutdown-live' = New-PowerTaskInfoDouble $powerNow.AddMinutes(5)
        }
        Mock Get-ScheduledTask { $tasks }
        Mock Get-ScheduledTaskInfo { param([string]$TaskName) $infos[$TaskName] }

        $result = @(Get-PowerSchedule)

        $result | Should -HaveCount 1
        $result[0].Action | Should -Be 'shutdown'
        $script:deletedPowerCommands | Should -HaveCount 2
        $script:deletedPowerCommands | Should -Contain 'schtasks /delete /tn "OhMyPwsh-Power-sleep-stale" /f'
        $script:deletedPowerCommands | Should -Contain 'schtasks /delete /tn "OhMyPwsh-Power-hibernate-missing" /f'
    }

    It 'returns an empty collection for no tasks and scheduler failures' {
        Mock Get-ScheduledTask { $null }
        @(Get-PowerSchedule) | Should -HaveCount 0

        Mock Get-ScheduledTask { Write-Error 'scheduler unavailable' }
        @(Get-PowerSchedule) | Should -HaveCount 0
    }

    It 'builds a safe scheduled-task command and handles immediate/invalid durations' {
        Mock Invoke-WithElevation { $script:deletedPowerCommands.Add($Command); $true }
        Mock Write-StatusMessage {}

        New-PowerSchedule -Action 'sleep' -Minutes 10

        $script:deletedPowerCommands | Should -HaveCount 1
        $script:deletedPowerCommands[0] | Should -Match '^schtasks /create /sc once /st 12:10\s+/tn "OhMyPwsh-Power-sleep-[a-f0-9]{8}" /tr "rundll32\.exe powrprof\.dll,SetSuspendState 0,1,0" /f$'

        Mock Invoke-PowerNow {}
        New-PowerSchedule -Action 'hibernate' -Minutes 0
        Should -Invoke Invoke-PowerNow -ParameterFilter { $Action -eq 'hibernate' }

        New-PowerSchedule -Action 'restart' -Minutes -1
        Should -Invoke Invoke-WithElevation -Times 1
        Should -Invoke Write-StatusMessage -ParameterFilter { $Message -eq 'Time must be >= 0' }
    }
}

Describe 'Remove-PowerSchedule' {
    BeforeEach {
        $script:powerSchedule = @(
            (New-PowerScheduleDouble 1 'OhMyPwsh-Power-hibernate-a' 'hibernate' ([datetime]'2026-09-02T13:00:00')),
            (New-PowerScheduleDouble 2 'OhMyPwsh-Power-sleep-b' 'sleep' ([datetime]'2026-09-02T14:00:00')),
            (New-PowerScheduleDouble 3 'OhMyPwsh-Power-shutdown-c' 'shutdown' ([datetime]'2026-09-02T15:00:00')),
            (New-PowerScheduleDouble 4 'OhMyPwsh-Power-restart-d' 'restart' ([datetime]'2026-09-02T16:00:00'))
        )
        $script:deletedPowerCommands = [System.Collections.Generic.List[string]]::new()
        Mock Get-PowerSchedule { $script:powerSchedule }
        Mock Invoke-WithElevation { $script:deletedPowerCommands.Add($Command); $true }
        Mock Confirm-PowerAction { $true }
        Mock Write-StatusMessage {}
    }

    It 'cancels by numeric ID only' {
        Remove-PowerSchedule -Target '2'
        $script:deletedPowerCommands | Should -HaveCount 1
        $script:deletedPowerCommands[0] | Should -Be 'schtasks /delete /tn "OhMyPwsh-Power-sleep-b" /f'
    }

    It 'cancels canonical actions and every supported alias' {
        foreach ($case in @(
                @{ Target = 'hibernate'; Name = 'OhMyPwsh-Power-hibernate-a' }
                @{ Target = 'h'; Name = 'OhMyPwsh-Power-hibernate-a' }
                @{ Target = 'sleep'; Name = 'OhMyPwsh-Power-sleep-b' }
                @{ Target = 's'; Name = 'OhMyPwsh-Power-sleep-b' }
                @{ Target = 'shutdown'; Name = 'OhMyPwsh-Power-shutdown-c' }
                @{ Target = 'off'; Name = 'OhMyPwsh-Power-shutdown-c' }
                @{ Target = 'restart'; Name = 'OhMyPwsh-Power-restart-d' }
                @{ Target = 'r'; Name = 'OhMyPwsh-Power-restart-d' }
            )) {
            $script:deletedPowerCommands.Clear()
            Remove-PowerSchedule -Target $case.Target
            $script:deletedPowerCommands | Should -HaveCount 1
            $script:deletedPowerCommands[0] | Should -Be "schtasks /delete /tn `"$($case.Name)`" /f"
        }
    }

    It 'cancels all with confirmation and leaves tasks untouched when declined' {
        Remove-PowerSchedule -Target 'all'
        $script:deletedPowerCommands | Should -HaveCount 4
        Should -Invoke Confirm-PowerAction -ParameterFilter { $Message -like 'Cancel all 4 scheduled actions?*' }

        $script:deletedPowerCommands.Clear()
        Mock Confirm-PowerAction { $false }
        Remove-PowerSchedule -Target 'all'
        $script:deletedPowerCommands | Should -HaveCount 0
    }

    It 'confirms before removing multiple matches for an action' {
        $script:powerSchedule = @(
            (New-PowerScheduleDouble 1 'OhMyPwsh-Power-hibernate-a' 'hibernate' ([datetime]'2026-09-02T13:00:00')),
            (New-PowerScheduleDouble 2 'OhMyPwsh-Power-hibernate-b' 'hibernate' ([datetime]'2026-09-02T14:00:00'))
        )
        Mock Confirm-PowerAction { $false }

        Remove-PowerSchedule -Target 'hibernate'

        $script:deletedPowerCommands | Should -HaveCount 0
        Should -Invoke Confirm-PowerAction -ParameterFilter { $Message -like 'Cancel all 2 scheduled hibernate actions?*' }
    }

    It 'reports missing and empty targets without deleting' {
        Remove-PowerSchedule -Target '99'
        Remove-PowerSchedule -Target 'not-a-task'
        $script:deletedPowerCommands | Should -HaveCount 0

        Mock Get-PowerSchedule { @() }
        Remove-PowerSchedule -Target 'hibernate'
        $script:deletedPowerCommands | Should -HaveCount 0
        Should -Invoke Write-StatusMessage -Times 3
    }
}

Describe 'Power command dispatcher' {
    BeforeEach {
        Mock Show-PowerMenu {}
        Mock Show-PowerStatus {}
        Mock Show-PowerHelp {}
        Mock New-PowerSchedule {}
        Mock Remove-PowerSchedule {}
        Mock Invoke-PowerNow {}
        Mock Write-StatusMessage {}
    }

    It 'routes empty input and status/help/menu/cancel commands' {
        Invoke-Power
        Should -Invoke Show-PowerMenu -Times 1

        foreach ($token in @('status', 'help', 'menu', 'cancel')) {
            Invoke-Power $token
        }
        Should -Invoke Show-PowerStatus -Times 1
        Should -Invoke Show-PowerHelp -Times 1
        Should -Invoke Show-PowerMenu -Times 2
        Should -Invoke Remove-PowerSchedule -Times 1 -ParameterFilter { $null -eq $Target }
    }

    It 'routes cancellation by ID, action, and short alias' {
        Invoke-Power cancel 1
        Invoke-Power cancel hibernate
        Invoke-Power c h

        Should -Invoke Remove-PowerSchedule -Times 1 -ParameterFilter { $Target -eq '1' }
        Should -Invoke Remove-PowerSchedule -Times 1 -ParameterFilter { $Target -eq 'hibernate' }
        Should -Invoke Remove-PowerSchedule -Times 1 -ParameterFilter { $Target -eq 'h' }
    }

    It 'routes both action/time orders and now to the scheduler boundary' {
        Invoke-Power hibernate 60
        Invoke-Power 90 sleep
        Invoke-Power restart now

        Should -Invoke New-PowerSchedule -Times 1 -ParameterFilter { $Action -eq 'hibernate' -and $Minutes -eq 60 }
        Should -Invoke New-PowerSchedule -Times 1 -ParameterFilter { $Action -eq 'sleep' -and $Minutes -eq 90 }
        Should -Invoke New-PowerSchedule -Times 1 -ParameterFilter { $Action -eq 'restart' -and $Minutes -eq 0 }
    }

    It 'reports unknown, invalid, and too-many arguments without side effects' {
        Invoke-Power unknown
        Invoke-Power hibernate invalid
        Invoke-Power hibernate 1 2

        Should -Invoke New-PowerSchedule -Times 0
        Should -Invoke Remove-PowerSchedule -Times 0
        Should -Invoke Invoke-PowerNow -Times 0
        Should -Invoke Write-StatusMessage -Times 3
    }
}

Describe 'Power tools menu' {
    BeforeEach {
        $script:menuSchedule = @(
            (New-PowerScheduleDouble 1 'OhMyPwsh-Power-hibernate-a' 'hibernate' ([datetime]'2026-09-02T13:00:00')),
            (New-PowerScheduleDouble 2 'OhMyPwsh-Power-sleep-b' 'sleep' ([datetime]'2026-09-02T14:00:00'))
        )
        $script:menuScheduled = [System.Collections.Generic.List[string]]::new()
        $script:menuRemoved = [System.Collections.Generic.List[string]]::new()
        $script:menuHelpShown = 0
        Mock Show-PowerStatus {}
        Mock Get-PowerSchedule { $script:menuSchedule }
        Mock New-PowerSchedule { $script:menuScheduled.Add("$Action/$Minutes") }
        Mock Remove-PowerSchedule { $script:menuRemoved.Add([string]$Target) }
        Mock Show-PowerHelp { $script:menuHelpShown++ }
        Mock Write-StatusMessage {}
        Mock Test-SpectreAvailable { $false }
    }

    It 'routes all eight fallback choices and exits safely' {
        $cases = @(
            @{ Choice = '1'; Responses = @('1', '45'); Expected = 'hibernate/45' }
            @{ Choice = '2'; Responses = @('2', '1h'); Expected = 'sleep/60' }
            @{ Choice = '3'; Responses = @('3', '90m'); Expected = 'shutdown/90' }
            @{ Choice = '4'; Responses = @('4', 'now'); Expected = 'restart/0' }
            @{ Choice = '5'; Responses = @('5', '2'); Expected = 'remove/2' }
            @{ Choice = '6'; Responses = @('6'); Expected = 'remove/all' }
            @{ Choice = '7'; Responses = @('7'); Expected = 'help' }
            @{ Choice = '8'; Responses = @('8'); Expected = 'exit' }
        )

        foreach ($case in $cases) {
            $script:menuResponses = [System.Collections.Generic.Queue[string]]::new()
            foreach ($response in $case.Responses) { $menuResponses.Enqueue($response) }
            Mock Read-Host { $script:menuResponses.Dequeue() }
            Show-PowerMenu

            switch -Regex ($case.Expected) {
                '^hibernate|^sleep|^shutdown|^restart' { $script:menuScheduled | Should -Contain $case.Expected }
                '^remove/' { $script:menuRemoved | Should -Contain ($case.Expected -replace '^remove/', '') }
                '^help$' { $script:menuHelpShown | Should -Be 1 }
                '^exit$' { $script:menuScheduled | Should -HaveCount 0; $script:menuRemoved | Should -HaveCount 0 }
            }
            $script:menuScheduled.Clear()
            $script:menuRemoved.Clear()
        }
    }

    It 'does not prompt for an item when the fallback schedule is empty' {
        Mock Get-PowerSchedule { @() }
        $script:menuResponses = [System.Collections.Generic.Queue[string]]::new()
        $menuResponses.Enqueue('5')
        Mock Read-Host { $script:menuResponses.Dequeue() }

        Show-PowerMenu

        $script:menuRemoved | Should -HaveCount 0
        Should -Invoke Read-Host -Times 1
        Should -Invoke Write-StatusMessage -ParameterFilter { $Message -eq 'Nothing to cancel' }
    }

    It 'treats invalid fallback input as exit without side effects' {
        $script:menuResponses = [System.Collections.Generic.Queue[string]]::new()
        $menuResponses.Enqueue('not-a-choice')
        Mock Read-Host { $script:menuResponses.Dequeue() }

        Show-PowerMenu

        $script:menuScheduled | Should -HaveCount 0
        $script:menuRemoved | Should -HaveCount 0
        $script:menuHelpShown | Should -Be 0
    }

    It 'keeps Spectre selection and text routing equivalent' {
        Mock Test-SpectreAvailable { $true }
        $script:spectreChoice = 'Schedule shutdown'
        Mock Read-SpectreSelection {
            param([string]$Title, [string[]]$Choices)
            if ($Title -eq 'What do you want to do?') { return $script:spectreChoice }
            return '[2] sleep at 14:00'
        }
        Mock Read-SpectreText { param([string]$Prompt, [string]$DefaultAnswer) '30' }

        Show-PowerMenu

        $script:menuScheduled | Should -Contain 'shutdown/30'
        Should -Invoke Read-SpectreSelection -Times 1
        Should -Invoke Read-SpectreText -Times 1

        $script:menuScheduled.Clear()
        $script:menuRemoved.Clear()
        $script:spectreChoice = 'Cancel a scheduled action'
        Show-PowerMenu
        $script:menuRemoved | Should -Contain '2'
    }
}
