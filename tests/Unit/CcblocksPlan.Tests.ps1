BeforeAll {
    # Source the modules under test (ccblocks first, then plan)
    . $PSScriptRoot/../../modules/ccblocks.ps1
    . $PSScriptRoot/../../modules/ccblocks-plan.ps1

    # Override config paths to use TestDrive
    $script:CcblocksConfigDir = Join-Path $TestDrive 'ccblocks'
    $script:CcblocksPlansDir  = Join-Path $TestDrive 'ccblocks' 'plans'
    $script:CcblocksPlanTaskPrefix = 'ccblocks-plan-'
    $script:CcblocksPlanDaemonScript = Join-Path $PSScriptRoot '../../scripts/ccblocks-plan-daemon.ps1'

    New-Item -ItemType Directory -Path $script:CcblocksPlansDir -Force | Out-Null

    # Mock the plan registration function to avoid Task Scheduler dependency
    Mock _cc_plan_register_task { }
    Mock Get-ScheduledTask { $null }
    Mock Unregister-ScheduledTask { }
    Mock Stop-ScheduledTask { }

    # Mock Write-Host to capture output
    Mock Write-Host {}
}

# ── ID Generation ────────────────────────────────────────────────────────────

Describe "_cc_plan_generate_id" {
    Context "When no existing plans" {
        It "Returns timestamp-based ID" {
            $date = [datetime]::new(2026, 4, 14, 1, 0, 0)
            $id = _cc_plan_generate_id -ScheduledAt $date
            $id | Should -Be '20260414-0100'
        }
    }

    Context "When plan with same time exists" {
        BeforeAll {
            $date = [datetime]::new(2026, 4, 14, 2, 0, 0)
            # Create existing plan file
            $existingFile = Join-Path $script:CcblocksPlansDir 'plan-20260414-0200.json'
            '{}' | Set-Content $existingFile
        }

        It "Returns ID with suffix -2" {
            $date = [datetime]::new(2026, 4, 14, 2, 0, 0)
            $id = _cc_plan_generate_id -ScheduledAt $date
            $id | Should -Be '20260414-0200-2'
        }

        AfterAll {
            Remove-Item (Join-Path $script:CcblocksPlansDir 'plan-20260414-0200.json') -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Auto Scheduling ──────────────────────────────────────────────────────────

Describe "_cc_plan_auto_time" {
    Context "When ccusage is not available" {
        BeforeAll {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'ccusage' }
        }

        It "Returns a future time" {
            $time = _cc_plan_auto_time
            $time | Should -BeOfType [datetime]
            $time | Should -BeGreaterThan (Get-Date)
        }

        It "Returns time at least 10 minutes from now" {
            $time = _cc_plan_auto_time
            ($time - (Get-Date)).TotalMinutes | Should -BeGreaterOrEqual 9.5
        }
    }

    Context "When ccusage reports active block" {
        BeforeAll {
            # Create a mock function for ccusage so Pester can mock it
            function ccusage { '3h 45m remaining' }

            Mock Get-Command {
                [PSCustomObject]@{ Name = 'ccusage'; Source = 'C:\mock\ccusage.exe'; CommandType = 'Application' }
            } -ParameterFilter { $Name -eq 'ccusage' }

            Mock ccusage { '3h 45m remaining' }
        }

        It "Schedules based on block expiry + 5 minutes" {
            $before = (Get-Date).AddHours(3).AddMinutes(49)
            $time = _cc_plan_auto_time
            $after = (Get-Date).AddHours(3).AddMinutes(51)

            $time | Should -BeGreaterOrEqual $before
            $time | Should -BeLessOrEqual $after
        }
    }
}

# ── Plan JSON Read/Write ─────────────────────────────────────────────────────

Describe "_cc_plan_read_all" {
    Context "When plans directory is empty" {
        It "Returns empty array" {
            $plans = _cc_plan_read_all
            $plans.Count | Should -Be 0
        }
    }

    Context "When plans exist" {
        BeforeAll {
            $plan1 = @{
                id = 'test-001'; prompt = 'test prompt 1'; status = 'pending'
                workingDirectory = 'C:\test'; scheduledAt = '2026-04-14T01:00:00'
                createdAt = '2026-04-13T22:00:00'; autoEdit = $false
                resumeSession = $null; timeoutMinutes = 60
                taskName = 'ccblocks-plan-test-001'; completedAt = $null
                exitCode = $null; logFile = 'plan-test-001.log'
                outputFile = 'plan-test-001.output.md'
            }
            $plan1 | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:CcblocksPlansDir 'plan-test-001.json')

            $plan2 = @{
                id = 'test-002'; prompt = 'test prompt 2'; status = 'completed'
                workingDirectory = 'C:\test'; scheduledAt = '2026-04-14T02:00:00'
                createdAt = '2026-04-13T22:00:00'; autoEdit = $true
                resumeSession = 'abc123'; timeoutMinutes = 120
                taskName = 'ccblocks-plan-test-002'; completedAt = '2026-04-14T02:30:00'
                exitCode = 0; logFile = 'plan-test-002.log'
                outputFile = 'plan-test-002.output.md'
            }
            $plan2 | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:CcblocksPlansDir 'plan-test-002.json')
        }

        It "Returns all plans" {
            $plans = _cc_plan_read_all
            $plans.Count | Should -Be 2
        }

        It "Preserves plan fields" {
            $plans = _cc_plan_read_all
            $pending = $plans | Where-Object { $_.id -eq 'test-001' }
            $pending.prompt | Should -Be 'test prompt 1'
            $pending.status | Should -Be 'pending'
            $pending.autoEdit | Should -Be $false
        }

        It "Preserves resume session" {
            $plans = _cc_plan_read_all
            $completed = $plans | Where-Object { $_.id -eq 'test-002' }
            $completed.resumeSession | Should -Be 'abc123'
            $completed.autoEdit | Should -Be $true
        }

        AfterAll {
            Remove-Item (Join-Path $script:CcblocksPlansDir 'plan-test-001.json') -Force -ErrorAction SilentlyContinue
            Remove-Item (Join-Path $script:CcblocksPlansDir 'plan-test-002.json') -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Plan Create ──────────────────────────────────────────────────────────────

Describe "_ccblocks_plan_create" {
    BeforeAll {
        # Mock claude as available
        Mock Get-Command {
            [PSCustomObject]@{ Name = 'claude'; Source = 'C:\mock\claude.exe'; CommandType = 'Application' }
        } -ParameterFilter { $Name -eq 'claude' }
    }

    Context "When creating with --at flag" {
        It "Creates plan JSON file" {
            # Schedule for a future time
            $futureHour = ((Get-Date).Hour + 2) % 24
            $atTime = '{0:D2}:00' -f $futureHour

            _ccblocks_plan_create -SubArgs @('test plan prompt', '--at', $atTime)

            $planFiles = Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*.json'
            $planFiles.Count | Should -BeGreaterOrEqual 1
        }

        It "Stores correct prompt in JSON" {
            $planFiles = Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*.json' | Sort-Object LastWriteTime -Descending
            $plan = Get-Content $planFiles[0].FullName -Raw | ConvertFrom-Json
            $plan.prompt | Should -Be 'test plan prompt'
        }

        It "Stores current directory as workingDirectory" {
            $planFiles = Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*.json' | Sort-Object LastWriteTime -Descending
            $plan = Get-Content $planFiles[0].FullName -Raw | ConvertFrom-Json
            $plan.workingDirectory | Should -Be (Get-Location).Path
        }

        It "Sets status to pending" {
            $planFiles = Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*.json' | Sort-Object LastWriteTime -Descending
            $plan = Get-Content $planFiles[0].FullName -Raw | ConvertFrom-Json
            $plan.status | Should -Be 'pending'
        }
    }

    Context "When creating with --auto-edit" {
        It "Sets autoEdit to true" {
            $futureHour = ((Get-Date).Hour + 3) % 24
            $atTime = '{0:D2}:30' -f $futureHour

            _ccblocks_plan_create -SubArgs @('edit plan', '--at', $atTime, '--auto-edit')

            $planFiles = Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*.json' | Sort-Object LastWriteTime -Descending
            $plan = Get-Content $planFiles[0].FullName -Raw | ConvertFrom-Json
            $plan.autoEdit | Should -Be $true
        }
    }

    Context "When creating with --resume" {
        It "Stores resume session ID" {
            $futureHour = ((Get-Date).Hour + 4) % 24
            $atTime = '{0:D2}:15' -f $futureHour

            _ccblocks_plan_create -SubArgs @('resume msg', '--at', $atTime, '--resume', 'session-xyz')

            $planFiles = Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*.json' | Sort-Object LastWriteTime -Descending
            $plan = Get-Content $planFiles[0].FullName -Raw | ConvertFrom-Json
            $plan.resumeSession | Should -Be 'session-xyz'
        }
    }

    Context "When creating with --timeout" {
        It "Stores custom timeout" {
            $futureHour = ((Get-Date).Hour + 5) % 24
            $atTime = '{0:D2}:45' -f $futureHour

            _ccblocks_plan_create -SubArgs @('long task', '--at', $atTime, '--timeout', '120')

            $planFiles = Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*.json' | Sort-Object LastWriteTime -Descending
            $plan = Get-Content $planFiles[0].FullName -Raw | ConvertFrom-Json
            $plan.timeoutMinutes | Should -Be 120
        }
    }

    Context "When claude is not installed" {
        BeforeAll {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'claude' }
        }

        It "Shows error and does not create plan" {
            $beforeCount = (Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*noclaude*.json' -ErrorAction SilentlyContinue).Count
            _ccblocks_plan_create -SubArgs @('noclaude plan', '--at', '23:59')
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Claude CLI not found*' }
        }
    }

    Context "When prompt is empty" {
        It "Shows usage error" {
            _ccblocks_plan_create -SubArgs @('')
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Usage:*' }
        }
    }

    Context "When --at time format is invalid" {
        BeforeAll {
            Mock Get-Command {
                [PSCustomObject]@{ Name = 'claude'; Source = 'C:\mock\claude.exe'; CommandType = 'Application' }
            } -ParameterFilter { $Name -eq 'claude' }
        }

        It "Shows error for bad format" {
            _ccblocks_plan_create -SubArgs @('bad time', '--at', 'abc')
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Invalid time format*' }
        }
    }

    AfterAll {
        # Clean up all test plans
        Get-ChildItem -Path $script:CcblocksPlansDir -Filter 'plan-*.json' -ErrorAction SilentlyContinue |
            Remove-Item -Force
    }
}

# ── Plan List ────────────────────────────────────────────────────────────────

Describe "_ccblocks_plan_list" {
    Context "When no plans exist" {
        It "Shows info message" {
            _ccblocks_plan_list
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*No plans scheduled*' }
        }
    }

    Context "When plans exist" {
        BeforeAll {
            @{
                id = 'list-test'; prompt = 'list test prompt'; status = 'pending'
                workingDirectory = 'C:\test'; scheduledAt = '2026-04-14T01:00:00'
                createdAt = '2026-04-13T22:00:00'; autoEdit = $false
                resumeSession = $null; timeoutMinutes = 60
                taskName = 'ccblocks-plan-list-test'; completedAt = $null
                exitCode = $null; logFile = 'plan-list-test.log'
                outputFile = 'plan-list-test.output.md'
            } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:CcblocksPlansDir 'plan-list-test.json')
        }

        It "Displays plan info" {
            _ccblocks_plan_list
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*pending*' }
        }

        AfterAll {
            Remove-Item (Join-Path $script:CcblocksPlansDir 'plan-list-test.json') -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Plan Show ────────────────────────────────────────────────────────────────

Describe "_ccblocks_plan_show" {
    Context "When plan exists" {
        BeforeAll {
            @{
                id = 'show-test'; prompt = 'show me details'; status = 'completed'
                workingDirectory = 'C:\test\project'; scheduledAt = '2026-04-14T01:00:00'
                createdAt = '2026-04-13T22:00:00'; autoEdit = $true
                resumeSession = 'sess-abc'; timeoutMinutes = 90
                taskName = 'ccblocks-plan-show-test'
                completedAt = '2026-04-14T01:45:00'; exitCode = 0
                logFile = 'plan-show-test.log'; outputFile = 'plan-show-test.output.md'
            } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:CcblocksPlansDir 'plan-show-test.json')
        }

        It "Displays plan details" {
            _ccblocks_plan_show -Id 'show-test'
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*show me details*' }
        }

        It "Shows resume session" {
            _ccblocks_plan_show -Id 'show-test'
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*sess-abc*' }
        }

        It "Shows completion info" {
            _ccblocks_plan_show -Id 'show-test'
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Exit code: 0*' }
        }

        AfterAll {
            Remove-Item (Join-Path $script:CcblocksPlansDir 'plan-show-test.json') -Force -ErrorAction SilentlyContinue
        }
    }

    Context "When plan does not exist" {
        It "Shows error" {
            _ccblocks_plan_show -Id 'nonexistent'
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Plan not found*' }
        }
    }

    Context "When no ID provided" {
        It "Shows usage error" {
            _ccblocks_plan_show -Id ''
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Usage:*' }
        }
    }
}

# ── Plan Cancel ──────────────────────────────────────────────────────────────

Describe "_ccblocks_plan_cancel" {
    Context "When cancelling a pending plan" {
        BeforeAll {
            @{
                id = 'cancel-test'; prompt = 'cancel me'; status = 'pending'
                workingDirectory = 'C:\test'; scheduledAt = '2026-04-14T05:00:00'
                createdAt = '2026-04-13T22:00:00'; autoEdit = $false
                resumeSession = $null; timeoutMinutes = 60
                taskName = 'ccblocks-plan-cancel-test'; completedAt = $null
                exitCode = $null; logFile = 'plan-cancel-test.log'
                outputFile = 'plan-cancel-test.output.md'
            } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:CcblocksPlansDir 'plan-cancel-test.json')
        }

        It "Updates status to cancelled" {
            _ccblocks_plan_cancel -Id 'cancel-test'

            $plan = Get-Content (Join-Path $script:CcblocksPlansDir 'plan-cancel-test.json') -Raw | ConvertFrom-Json
            $plan.status | Should -Be 'cancelled'
        }

        It "Sets completedAt timestamp" {
            $plan = Get-Content (Join-Path $script:CcblocksPlansDir 'plan-cancel-test.json') -Raw | ConvertFrom-Json
            $plan.completedAt | Should -Not -BeNullOrEmpty
        }

        AfterAll {
            Remove-Item (Join-Path $script:CcblocksPlansDir 'plan-cancel-test.json') -Force -ErrorAction SilentlyContinue
        }
    }

    Context "When plan is already completed" {
        BeforeAll {
            @{
                id = 'done-test'; prompt = 'already done'; status = 'completed'
                workingDirectory = 'C:\test'; scheduledAt = '2026-04-14T01:00:00'
                createdAt = '2026-04-13T22:00:00'; autoEdit = $false
                resumeSession = $null; timeoutMinutes = 60
                taskName = 'ccblocks-plan-done-test'
                completedAt = '2026-04-14T01:30:00'; exitCode = 0
                logFile = 'plan-done-test.log'; outputFile = 'plan-done-test.output.md'
            } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:CcblocksPlansDir 'plan-done-test.json')
        }

        It "Shows warning instead of cancelling" {
            _ccblocks_plan_cancel -Id 'done-test'
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*already completed*' }
        }

        AfterAll {
            Remove-Item (Join-Path $script:CcblocksPlansDir 'plan-done-test.json') -Force -ErrorAction SilentlyContinue
        }
    }

    Context "When plan does not exist" {
        It "Shows error" {
            _ccblocks_plan_cancel -Id 'ghost'
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Plan not found*' }
        }
    }
}

# ── Plan Clean ───────────────────────────────────────────────────────────────

Describe "_ccblocks_plan_clean" {
    Context "When old completed plans exist" {
        BeforeAll {
            # Old completed plan (>7 days)
            @{
                id = 'old-plan'; prompt = 'old'; status = 'completed'
                workingDirectory = 'C:\test'; scheduledAt = '2026-04-01T01:00:00'
                createdAt = '2026-04-01T00:00:00'; autoEdit = $false
                resumeSession = $null; timeoutMinutes = 60
                taskName = 'ccblocks-plan-old-plan'
                completedAt = '2026-04-01T01:30:00'; exitCode = 0
                logFile = 'plan-old-plan.log'; outputFile = 'plan-old-plan.output.md'
            } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:CcblocksPlansDir 'plan-old-plan.json')

            # Recent pending plan (should NOT be cleaned)
            @{
                id = 'recent-plan'; prompt = 'recent'; status = 'pending'
                workingDirectory = 'C:\test'; scheduledAt = (Get-Date).AddHours(1).ToString('o')
                createdAt = (Get-Date).ToString('o'); autoEdit = $false
                resumeSession = $null; timeoutMinutes = 60
                taskName = 'ccblocks-plan-recent-plan'; completedAt = $null
                exitCode = $null; logFile = 'plan-recent-plan.log'
                outputFile = 'plan-recent-plan.output.md'
            } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:CcblocksPlansDir 'plan-recent-plan.json')
        }

        It "Removes old completed plan" {
            _ccblocks_plan_clean
            Test-Path (Join-Path $script:CcblocksPlansDir 'plan-old-plan.json') | Should -Be $false
        }

        It "Keeps recent pending plan" {
            Test-Path (Join-Path $script:CcblocksPlansDir 'plan-recent-plan.json') | Should -Be $true
        }

        AfterAll {
            Remove-Item (Join-Path $script:CcblocksPlansDir 'plan-recent-plan.json') -Force -ErrorAction SilentlyContinue
        }
    }

    Context "When no old plans exist" {
        It "Shows info message" {
            _ccblocks_plan_clean
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*No old plans to clean*' }
        }
    }
}

# ── Plan Dispatcher ──────────────────────────────────────────────────────────

Describe "_ccblocks_plan" {
    Context "When called with no args" {
        It "Shows help" {
            _ccblocks_plan -SubArgs @()
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*ccblocks plan*schedule Claude*' }
        }
    }

    Context "When called with 'help'" {
        It "Shows help" {
            _ccblocks_plan -SubArgs @('help')
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*ccblocks plan*schedule Claude*' }
        }
    }

    Context "When called with 'list'" {
        It "Does not throw" {
            { _ccblocks_plan -SubArgs @('list') } | Should -Not -Throw
        }
    }
}

# ── Daemon Script Syntax ─────────────────────────────────────────────────────

Describe "ccblocks-plan-daemon.ps1" {
    It "Has valid PowerShell syntax" {
        $daemonPath = Join-Path $PSScriptRoot '../../scripts/ccblocks-plan-daemon.ps1'
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            (Resolve-Path $daemonPath).Path, [ref]$null, [ref]$errors
        )
        $errors.Count | Should -Be 0
    }
}
