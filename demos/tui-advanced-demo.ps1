#Requires -Modules PwshSpectreConsole

<#
.SYNOPSIS
    Advanced TUI demo showcasing charts, trees, calendars, and live updates

.DESCRIPTION
    Demonstrates advanced PwshSpectreConsole features:
    - Bar charts and breakdown charts
    - Tree structures
    - Calendar views
    - Live updating data
    - Color schemes
    - JSON formatting

.EXAMPLE
    .\demos\tui-advanced-demo.ps1
#>

# Suppress encoding warning
$env:IgnoreSpectreEncoding = $true

# Check if PwshSpectreConsole is installed
if (-not (Get-Module -ListAvailable -Name PwshSpectreConsole)) {
    Write-Host "⚠️  PwshSpectreConsole not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name PwshSpectreConsole -Scope CurrentUser -Force
}

Import-Module PwshSpectreConsole

# Title
Write-Host ""
Write-SpectreFigletText -Text "System Monitor"
Write-SpectreRule "Advanced TUI Features Demo"
Write-Host ""

# Demo 1: Bar Chart - Disk Usage
Write-SpectreRule "Bar Chart - Disk Usage"
$diskData = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | Select-Object -First 5

$chartItems = $diskData | ForEach-Object {
    $usedGB = [math]::Round($_.Used / 1GB, 1)
    New-SpectreChartItem -Label "$($_.Name): $($usedGB)GB" -Value $usedGB -Color ([Spectre.Console.Color]::Blue)
}

$chartItems | Format-SpectreBarChart -Width 60 | Out-SpectreHost
Write-Host ""

# Demo 2: Breakdown Chart - Memory Usage
Write-SpectreRule "Breakdown Chart - Memory Distribution"

# Simulate memory data
$memoryData = @(
    New-SpectreChartItem -Label "Applications" -Value 45 -Color ([Spectre.Console.Color]::Green)
    New-SpectreChartItem -Label "System" -Value 25 -Color ([Spectre.Console.Color]::Blue)
    New-SpectreChartItem -Label "Cached" -Value 20 -Color ([Spectre.Console.Color]::Yellow)
    New-SpectreChartItem -Label "Free" -Value 10 -Color ([Spectre.Console.Color]::Grey)
)

$memoryData | Format-SpectreBreakdownChart -Width 60 | Out-SpectreHost
Write-Host ""

# Demo 3: Tree Structure - Process Hierarchy
Write-SpectreRule "Tree - Process Hierarchy"

# Get some processes and create a tree
$tree = @{
    Label = "System Processes"
    Children = @(
        @{
            Label = "PowerShell ($$)"
            Children = @(
                @{ Label = "WorkingSet: $([math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 1))MB" }
                @{ Label = "Threads: $((Get-Process -Id $PID).Threads.Count)" }
                @{ Label = "Handles: $((Get-Process -Id $PID).HandleCount)" }
            )
        }
        @{
            Label = "Top CPU Processes"
            Children = (Get-Process | Sort-Object CPU -Descending | Select-Object -First 3 | ForEach-Object {
                @{ Label = "$($_.Name) - CPU: $([math]::Round($_.CPU, 2))s" }
            })
        }
    )
}

Format-SpectreTree -Data $tree | Out-SpectreHost
Write-Host ""

# Demo 4: Calendar
Write-SpectreRule "Calendar - Current Month"
Write-SpectreCalendar -Date (Get-Date) | Out-SpectreHost
Write-Host ""

# Demo 5: JSON Formatting
Write-SpectreRule "JSON - System Info"

$systemInfo = @{
    Hostname = $env:COMPUTERNAME
    User = $env:USERNAME
    OS = (Get-CimInstance Win32_OperatingSystem).Caption
    PowerShell = $PSVersionTable.PSVersion.ToString()
    Uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    Processors = (Get-CimInstance Win32_Processor).Count
}

$systemInfo | ConvertTo-Json | Format-SpectreJson | Out-SpectreHost
Write-Host ""

# Demo 6: Progress with Multiple Tasks
Write-SpectreRule "Progress - Multi-task Simulation"

$tasks = @(
    @{ Name = "Scanning files..."; Duration = 1 }
    @{ Name = "Processing data..."; Duration = 1 }
    @{ Name = "Generating report..."; Duration = 1 }
)

foreach ($task in $tasks) {
    Invoke-SpectreCommandWithStatus -Spinner "Dots" -Title $task.Name -ScriptBlock {
        Start-Sleep -Seconds 1
    }
}

Write-Host "✓ All tasks completed" -ForegroundColor Green
Write-Host ""

# Demo 7: Color Palette
Write-SpectreRule "Color Palette"
Write-Host "Available color schemes:" -ForegroundColor Cyan
Get-SpectreDemoColors
Write-Host ""

# Demo 8: Multi-column Layout with Panels
Write-SpectreRule "Panel Layout - Side by Side"

# Display panels using Format-SpectreColumns
@(
    (Format-SpectrePanel -Title "CPU" -Data "Usage: 45%`nThreads: 12")
    (Format-SpectrePanel -Title "Memory" -Data "Used: 8.2GB`nFree: 7.8GB")
    (Format-SpectrePanel -Title "Disk" -Data "Read: 120MB/s`nWrite: 85MB/s")
) | Format-SpectreColumns | Out-SpectreHost
Write-Host ""

# Demo 9: Emojis & Markup
Write-SpectreRule "Emojis & Rich Markup"

Write-SpectreHost "💻 [bold cyan]System Status:[/] [green]Online[/]"
Write-SpectreHost "🔥 [bold yellow]Performance:[/] [red]High Load![/]"
Write-SpectreHost "📊 [bold blue]Analytics:[/] [dim]Processing data...[/]"
Write-SpectreHost "✅ [bold green]Security:[/] [underline]All systems protected[/]"
Write-Host ""

# Demo 10: Live Display - Real-time Updates
Write-SpectreRule "Live Display - Real-time Updates"

# Create live updating panel
$data = @()
Invoke-SpectreLive -Data (Format-SpectrePanel -Title "System Monitor" -Data "Initializing...") -ScriptBlock {
    param($Context)

    for ($i = 1; $i -le 5; $i++) {
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        $cpuPercent = Get-Random -Minimum 10 -Maximum 95
        $memPercent = Get-Random -Minimum 30 -Maximum 85
        $status = if ($cpuPercent -lt 50) { "[green]Normal[/]" }
                  elseif ($cpuPercent -lt 80) { "[yellow]Warning[/]" }
                  else { "[red]Critical[/]" }

        $content = @"
[bold]Time:[/] $timestamp
[bold]Status:[/] $status
[bold]CPU:[/] ${cpuPercent}%
[bold]Memory:[/] ${memPercent}%
[bold]Updates:[/] $i/5
"@
        $panel = Format-SpectrePanel -Title "System Monitor" -Data $content
        $Context.UpdateTarget($panel)
        Start-Sleep -Milliseconds 600
    }
}
Write-Host "✓ Live display complete" -ForegroundColor Green
Write-Host ""

# Demo 11: Multi Progress Bars
Write-SpectreRule "Multi Progress - Parallel Tasks"

Invoke-SpectreCommandWithProgress -ScriptBlock {
    param($Context)

    $tasks = @(
        @{ Name = "Downloading files"; Total = 100 }
        @{ Name = "Processing data"; Total = 80 }
        @{ Name = "Generating reports"; Total = 50 }
    )

    $progressTasks = @()
    foreach ($taskInfo in $tasks) {
        $progressTasks += $Context.AddTask($taskInfo.Name, $true, $taskInfo.Total)
    }

    # Simulate progress
    $completed = @(0, 0, 0)
    while ($completed[0] -lt 100 -or $completed[1] -lt 80 -or $completed[2] -lt 50) {
        for ($i = 0; $i -lt $progressTasks.Count; $i++) {
            if ($completed[$i] -lt $tasks[$i].Total) {
                $increment = Get-Random -Minimum 5 -Maximum 15
                $completed[$i] = [Math]::Min($completed[$i] + $increment, $tasks[$i].Total)
                $progressTasks[$i].Value = $completed[$i]
            }
        }
        Start-Sleep -Milliseconds 100
    }
}
Write-Host "✓ All parallel tasks completed" -ForegroundColor Green
Write-Host ""

# Final message
Format-SpectrePanel -Title "✓ Advanced Demo Complete!" -Data @"
Features demonstrated:
• Bar charts (disk usage visualization)
• Breakdown charts (memory distribution)
• Tree structures (process hierarchy)
• Calendar display (current month)
• JSON formatting (system info)
• Progress indicators (multi-task simulation)
• Color palettes (full Spectre.Console colors)
• Multi-column layouts (panels side by side)
• Emojis & rich markup (bold, colors, underline)
• Live display (real-time table updates)
• Multi progress bars (parallel task tracking)

PwshSpectreConsole: https://github.com/ShaunLawrie/PwshSpectreConsole
"@ | Out-SpectreHost

Write-Host ""
Write-Host "Explore more: Get-Command -Module PwshSpectreConsole" -ForegroundColor Cyan
