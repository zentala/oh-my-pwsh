BeforeAll {
    . $PSScriptRoot/../../settings/icons.ps1
    . $PSScriptRoot/../../modules/status-output.ps1
    . $PSScriptRoot/../../modules/logger.ps1
    . $PSScriptRoot/../../modules/functions.ps1
}

Describe "Test-ProfileDoctorPath" {
    It "Reports missing paths as not writable" {
        $result = Test-ProfileDoctorPath -Path (Join-Path $TestDrive "missing-dir")

        $result.Exists | Should -BeFalse
        $result.Writable | Should -BeFalse
        $result.Error | Should -Be "missing"
    }

    It "Reports writable directories correctly" {
        $path = Join-Path $TestDrive "doctor-ok"
        New-Item -ItemType Directory -Path $path | Out-Null

        $result = Test-ProfileDoctorPath -Path $path

        $result.Exists | Should -BeTrue
        $result.Writable | Should -BeTrue
        $result.Error | Should -BeNullOrEmpty
    }
}

Describe "Get-ProfileDoctorChecks" {
    BeforeEach {
        Mock Get-CimInstance { [pscustomobject]@{ Name = "Windows" } }
        Mock Get-Command {
            param($Name)
            [pscustomobject]@{ Name = $Name }
        }
        Mock Get-Module {
            param($ListAvailable, $Name)
            [pscustomobject]@{ Name = $Name }
        }
        Mock Test-ProfileDoctorPath {
            param($Path)
            [pscustomobject]@{ Path = $Path; Exists = $true; Writable = $true; Error = $null }
        }
    }

    It "Returns command availability and path checks" {
        $report = Get-ProfileDoctorChecks

        $report.Commands.Fnm | Should -BeTrue
        $report.Commands.OhMyPosh | Should -BeTrue
        $report.Commands.Zoxide | Should -BeTrue
        $report.Modules.TerminalIcons | Should -BeTrue
        $report.Paths.Count | Should -Be 3
    }
}
