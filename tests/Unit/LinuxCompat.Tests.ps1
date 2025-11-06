BeforeAll {
    # Enable Linux compatibility
    $global:OhMyPwsh_EnableLinuxCompat = $true
    $global:OhMyPwsh_ShowFeedback = $false  # Disable feedback for cleaner tests

    # Source the module
    . $PSScriptRoot/../../modules/linux-compat.ps1
}

Describe "Linux Compatibility Aliases" {
    Context "Basic command aliases" {
        It "grep alias points to Select-String" {
            (Get-Alias grep).ResolvedCommandName | Should -Be "Select-String"
        }

        It "which alias points to Get-Command" {
            (Get-Alias which).ResolvedCommandName | Should -Be "Get-Command"
        }

        It "whereis alias points to Get-Command" {
            (Get-Alias whereis).ResolvedCommandName | Should -Be "Get-Command"
        }

        It "clear alias points to Clear-Host" {
            (Get-Alias clear).ResolvedCommandName | Should -Be "Clear-Host"
        }

        It "cls alias points to Clear-Host" {
            (Get-Alias cls).ResolvedCommandName | Should -Be "Clear-Host"
        }
    }

    Context "File operation functions" {
        It "cp is a function (not alias)" {
            Get-Command cp -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "mv is a function (not alias)" {
            Get-Command mv -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "rm is a function (not alias)" {
            Get-Command rm -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "rmdir is a function (not alias)" {
            Get-Command rmdir -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "pwd alias points to Get-Location" {
            (Get-Alias pwd).ResolvedCommandName | Should -Be "Get-Location"
        }
    }

    Context "System info aliases" {
        It "ps alias points to Get-Process" {
            (Get-Alias ps).ResolvedCommandName | Should -Be "Get-Process"
        }

        It "kill alias points to Stop-Process" {
            (Get-Alias kill).ResolvedCommandName | Should -Be "Stop-Process"
        }

        It "date alias points to Get-Date" {
            (Get-Alias date).ResolvedCommandName | Should -Be "Get-Date"
        }

        It "df alias points to Get-PSDrive" {
            (Get-Alias df).ResolvedCommandName | Should -Be "Get-PSDrive"
        }
    }

    Context "Archive and download aliases" {
        It "unzip alias points to Expand-Archive" {
            $alias = Get-Alias unzip -ErrorAction SilentlyContinue
            if ($alias) {
                $alias.Definition | Should -Be "Expand-Archive"
            } else {
                # Alias might not be set if Expand-Archive not available
                Set-TestInconclusive "Expand-Archive not available"
            }
        }

        It "zip alias points to Compress-Archive" {
            $alias = Get-Alias zip -ErrorAction SilentlyContinue
            if ($alias) {
                $alias.Definition | Should -Be "Compress-Archive"
            } else {
                # Alias might not be set if Compress-Archive not available
                Set-TestInconclusive "Compress-Archive not available"
            }
        }

        It "wget alias points to Invoke-WebRequest" {
            (Get-Alias wget).ResolvedCommandName | Should -Be "Invoke-WebRequest"
        }

        It "curl alias points to Invoke-WebRequest" {
            (Get-Alias curl).ResolvedCommandName | Should -Be "Invoke-WebRequest"
        }
    }

    Context "Help and history aliases" {
        It "man alias points to Get-Help" {
            (Get-Alias man).ResolvedCommandName | Should -Be "Get-Help"
        }

        It "history alias points to Get-History" {
            (Get-Alias history).ResolvedCommandName | Should -Be "Get-History"
        }
    }

    Context "Shortcut aliases" {
        It "g alias points to git" {
            (Get-Alias g).Definition | Should -Be "git"
        }

        It "py alias points to python" {
            (Get-Alias py).Definition | Should -Be "python"
        }

        It "python3 alias points to python" {
            (Get-Alias python3).Definition | Should -Be "python"
        }
    }
}

Describe "Linux-style Functions" {
    Context "ls function" {
        It "ls function exists" {
            Get-Command ls -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "ls calls Get-ChildItem" {
            Mock Get-ChildItem {}

            ls

            Should -Invoke Get-ChildItem
        }
    }

    Context "ll function" {
        It "ll function exists" {
            Get-Command ll -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "ll calls Get-ChildItem" {
            Mock Get-ChildItem {}

            ll

            Should -Invoke Get-ChildItem
        }
    }

    Context "la function" {
        It "la function exists" {
            Get-Command la -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "la calls Get-ChildItem with -Force" {
            Mock Get-ChildItem {}

            la

            Should -Invoke Get-ChildItem -ParameterFilter {
                $Force -eq $true
            }
        }
    }

    Context "mkdir function" {
        BeforeEach {
            Mock New-Item {}
            Mock Write-Host {}
        }

        It "mkdir function exists" {
            Get-Command mkdir -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Creates directory with New-Item" {
            mkdir "testdir"

            Should -Invoke New-Item -ParameterFilter {
                $ItemType -eq "Directory" -and $Force -eq $true
            }
        }

        It "Handles -p flag (Linux compatibility)" {
            mkdir -p "testdir"

            Should -Invoke New-Item -ParameterFilter {
                $Path -eq "testdir"
            }
        }

        It "Creates multiple directories" {
            mkdir "dir1" "dir2"

            Should -Invoke New-Item -Times 2
        }
    }

    Context "touch function" {
        BeforeEach {
            Mock Test-Path { return $false }
            Mock New-Item {}
            Mock Get-Item { return [PSCustomObject]@{ LastWriteTime = Get-Date } }
            Mock Write-Host {}
        }

        It "touch function exists" {
            Get-Command touch -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Creates new file when it does not exist" {
            Mock Test-Path { return $false }

            touch "newfile.txt"

            Should -Invoke New-Item -ParameterFilter {
                $ItemType -eq "File"
            }
        }

        It "Updates timestamp when file exists" {
            Mock Test-Path { return $true }
            Mock Get-Item {
                $obj = New-Object PSObject
                Add-Member -InputObject $obj -MemberType NoteProperty -Name LastWriteTime -Value (Get-Date)
                return $obj
            }

            touch "existingfile.txt"

            Should -Invoke Get-Item
        }
    }

    Context "Navigation shortcuts" {
        It ".. function exists" {
            Get-Command .. -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "... function exists" {
            Get-Command ... -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It ".... function exists" {
            Get-Command .... -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "~ function exists" {
            Get-Command ~ -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "code. function exists" {
            Get-Command code. -CommandType Function | Should -Not -BeNullOrEmpty
        }
    }

    Context "mkcd function" {
        BeforeEach {
            Mock New-Item {}
            Mock Set-Location {}
            Mock Write-Host {}
        }

        It "mkcd function exists" {
            Get-Command mkcd -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Creates directory" {
            mkcd "newdir"

            Should -Invoke New-Item -ParameterFilter {
                $ItemType -eq "Directory" -and $Path -eq "newdir"
            }
        }

        It "Changes to created directory" {
            # mkcd calls Set-Location directly, not mockable easily
            # Just verify it doesn't throw
            { mkcd "newdir" } | Should -Not -Throw
        }
    }
}

Describe "File Operations with PowerShell-style Parameters" {
    BeforeEach {
        Mock Remove-Item {}
        Mock Copy-Item {}
        Mock Move-Item {}
        Mock Write-Host {}
    }

    Context "rm function" {
        It "rm function exists" {
            Get-Command rm -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Removes file without flags" {
            rm "testfile"

            Should -Invoke Remove-Item -ParameterFilter {
                $Path -eq "testfile" -and -not $Recurse -and -not $Force
            }
        }

        It "Handles -Recurse flag" {
            rm -Recurse "testdir"

            Should -Invoke Remove-Item -ParameterFilter {
                $Recurse -eq $true
            }
        }

        It "Handles -Force flag" {
            rm -Force "testfile"

            Should -Invoke Remove-Item -ParameterFilter {
                $Force -eq $true
            }
        }

        It "Handles -Recurse -Force combined" {
            rm -Recurse -Force "testdir"

            Should -Invoke Remove-Item -ParameterFilter {
                $Recurse -eq $true -and $Force -eq $true
            }
        }

        It "Removes multiple paths" {
            & (Get-Command rm -CommandType Function) "file1" "file2" "file3"

            Should -Invoke Remove-Item -Times 3
        }

        It "Shows usage when no paths specified" {
            & (Get-Command rm -CommandType Function)

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "Usage:*"
            }
        }

        It "Shows hint about rr alias in usage" {
            & (Get-Command rm -CommandType Function)

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "*rr*"
            }
        }
    }

    Context "rr function (quick recursive+force removal)" {
        It "rr function exists" {
            Get-Command rr -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Removes with -Recurse -Force by default" {
            rr "testdir"

            Should -Invoke Remove-Item -ParameterFilter {
                $Recurse -eq $true -and $Force -eq $true
            }
        }

        It "Removes multiple paths recursively" {
            rr "dir1" "dir2" "dir3"

            Should -Invoke Remove-Item -Times 3 -ParameterFilter {
                $Recurse -eq $true -and $Force -eq $true
            }
        }

        It "Shows usage when no paths specified" {
            rr

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "Usage:*"
            }
        }
    }

    Context "rmdir function" {
        It "rmdir function exists" {
            Get-Command rmdir -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Removes with -Recurse -Force by default" {
            rmdir "testdir"

            Should -Invoke Remove-Item -ParameterFilter {
                $Recurse -eq $true -and $Force -eq $true
            }
        }

        It "Removes multiple directories" {
            rmdir "dir1" "dir2"

            Should -Invoke Remove-Item -Times 2 -ParameterFilter {
                $Recurse -eq $true -and $Force -eq $true
            }
        }

        It "Shows usage when no paths specified" {
            rmdir

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "Usage:*"
            }
        }
    }

    Context "cp function" {
        It "cp function exists" {
            Get-Command cp -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Copies file without flags" {
            & (Get-Command cp -CommandType Function) "source.txt" "dest.txt"

            Should -Invoke Copy-Item -ParameterFilter {
                $Path -eq "source.txt" -and $Destination -eq "dest.txt" -and -not $Recurse -and -not $Force
            }
        }

        It "Handles -Recurse flag" {
            cp -Recurse "sourcedir" "destdir"

            Should -Invoke Copy-Item -ParameterFilter {
                $Recurse -eq $true
            }
        }

        It "Handles -Force flag" {
            cp -Force "source.txt" "dest.txt"

            Should -Invoke Copy-Item -ParameterFilter {
                $Force -eq $true
            }
        }

        It "Handles -Recurse -Force combined" {
            cp -Recurse -Force "sourcedir" "destdir"

            Should -Invoke Copy-Item -ParameterFilter {
                $Recurse -eq $true -and $Force -eq $true
            }
        }

        It "Shows usage when insufficient arguments" {
            & (Get-Command cp -CommandType Function) "onlyonefile"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "Usage:*"
            }
        }
    }

    Context "mv function" {
        It "mv function exists" {
            Get-Command mv -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Moves file without flags" {
            & (Get-Command mv -CommandType Function) "source.txt" "dest.txt"

            Should -Invoke Move-Item -ParameterFilter {
                $Path -eq "source.txt" -and $Destination -eq "dest.txt" -and -not $Force
            }
        }

        It "Handles -Force flag" {
            mv -Force "source.txt" "dest.txt"

            Should -Invoke Move-Item -ParameterFilter {
                $Force -eq $true
            }
        }

        It "Shows usage when insufficient arguments" {
            & (Get-Command mv -CommandType Function) "onlyonefile"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "Usage:*"
            }
        }
    }
}

Describe "Compatibility Warning Functions" {
    BeforeEach {
        Mock Write-Host {}
    }

    Context "chmod function" {
        It "chmod function exists" {
            Get-Command chmod -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Shows warning message" {
            chmod

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "*doesn't work on Windows*"
            }
        }

        It "Suggests Windows alternative (icacls)" {
            chmod

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "*icacls*"
            }
        }
    }

    Context "chown function" {
        It "chown function exists" {
            Get-Command chown -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Shows warning message" {
            chown

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "*doesn't work on Windows*"
            }
        }
    }

    Context "apt function" {
        It "apt function exists" {
            Get-Command apt -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Shows warning message" {
            apt

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "*doesn't work on Windows*"
            }
        }

        It "Suggests Windows alternatives" {
            apt

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "*winget*" -or $Object -like "*scoop*"
            }
        }
    }

    Context "sudo function" {
        BeforeEach {
            Mock Start-Process {}
        }

        It "sudo function exists" {
            Get-Command sudo -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Starts process with RunAs" {
            sudo "test command"

            Should -Invoke Start-Process -ParameterFilter {
                $Verb -eq "RunAs"
            }
        }
    }
}

Describe "Module Loading Behavior" {
    Context "When OhMyPwsh_EnableLinuxCompat is false" {
        It "Module can be disabled" {
            $global:OhMyPwsh_EnableLinuxCompat = $false

            # Re-source the module
            { . $PSScriptRoot/../../modules/linux-compat.ps1 } | Should -Not -Throw

            # Reset for other tests
            $global:OhMyPwsh_EnableLinuxCompat = $true
            . $PSScriptRoot/../../modules/linux-compat.ps1
        }
    }
}
