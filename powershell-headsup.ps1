######################
# powershell-headsup #
# author: psFifteen  #
# version: 0.1       #
######################

# Settings
$Script:BackgroundColor = "Black"
$Script:BiggestWidth = 36
$Script:BiggestHeight = 18
$Script:DirectoryWatch = "C:\Users\XXX\Downloads"
$Script:DirectoryWatchName = "New Downloads"
$Script:DirectoryWatchMinutes = 15
$Script:FileLocation = ".\read_me.txt"
$Script:FrameColour = "Magenta"
$Script:FrameCorner = "+"
$Script:FrameHorizontal = "-"
$Script:FrameVertical = "|"
$Script:PercentCritical = 10
$Script:PercentWarning = 30
$Script:PercentColourCritical = "Red"
$Script:PercentColourWarning = "Yellow"
$Script:PercentColourOK = "Green"
$Script:RefreshRate = 15
$Script:TaskPath = "\"
$Script:TextColour = "White"
$Script:Title = "Heads Up"
$Script:Username = $env:USERNAME

# Disable Quick Edit mode on window (Select)
$QuickEditCodeSnippet = @" 
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
public static class DisableConsoleQuickEdit {
    const uint ENABLE_QUICK_EDIT = 0x0040;
    // STD_INPUT_HANDLE (DWORD): -10 is the standard input device.
    const int STD_INPUT_HANDLE = -10;
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll")]
    static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll")]
    static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
    public static bool SetQuickEdit(bool SetEnabled) {
        IntPtr consoleHandle = GetStdHandle(STD_INPUT_HANDLE);
        // get current console mode
        uint consoleMode;
        if (!GetConsoleMode(consoleHandle, out consoleMode)) {
            // ERROR: Unable to get console mode.
            return false;
        }
        // Clear the quick edit bit in the mode flags
        if (SetEnabled) {
            consoleMode &= ~ENABLE_QUICK_EDIT;
        } else {
            consoleMode |= ENABLE_QUICK_EDIT;
        }
        // set the new mode
        if (!SetConsoleMode(consoleHandle, consoleMode)) {
            // ERROR: Unable to set console mode
            return false;
        }
        return true;
    }
}
"@

Add-Type -TypeDefinition $QuickEditCodeSnippet -Language CSharp | Out-Null

Function Set-QuickEdit() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="This switch will disable Console QuickEdit option")]
        [switch]$DisableQuickEdit=$false
    )
    if ([DisableConsoleQuickEdit]::SetQuickEdit($DisableQuickEdit)) {
        # Write-Host "QuickEdit settings has been updated." -ForegroundColor Cyan
    } else {
        # Write-Host "Something went wrong with QuickEdit." -ForegroundColor Red
    }
}

# Clear host and read the file per line
Function Read-WindowFile($Path = $FileLocation, $ExitFile, $MyPID) {
    # Read file
    $FileContents = Get-Content -Path $Path
    $NewFileContents = @()
    foreach ($Line in $FileContents) {
        # Check for Exit Code and Exit
        if ($Line -eq "XX_Get_me_out_of_here!_XX") {
            Write-Host "Exit Code Found... Exiting..." -ForegroundColor Green
            Start-Sleep 2
            Stop-Process -Id $MyPID -Force -Confirm:$false
        }
        # Elipsis or Pad
        if ($($Line.Length) -gt $BiggestWidth) {
            $NewFileContents = $NewFileContents + "$(($Line).SubString(0,$($BiggestWidth - 3)))..."
        } else {
            $Excess = $BiggestWidth - $($Line.Length)
            for ($i = 0;$i -lt $Excess;$i++) {
                $Padding = $Padding + " "
            }
            $NewFileContents = $NewFileContents + "$($Line)$($Padding)"
        }
        # Tidy up
        Remove-Variable Padding -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
    # Set window size and clear
    Clear-Host
    $PSHost = Get-Host
    $PSWindow = $PSHost.UI.RawUI
    $PSWindow.BackgroundColor = $BackgroundColor
    $NewWinSize = $PSWindow.WindowSize
    $NewBufSize = $PSWindow.BufferSize
    $NewWinSize.Height = $BiggestHeight
    $NewBufSize.Height = $BiggestHeight
    $NewWinSize.Width = $BiggestWidth + 4
    $NewBufSize.Width = $BiggestWidth + 4
    $PSWindow.WindowSize = $NewWinSize
    $PSWindow.BufferSize = $NewBufSize
    # Frame Maker
    for ($i = 0;$i -lt $BiggestWidth;$i++) {
        $Frame = $Frame + $FrameHorizontal
        $Blank = $Blank + " "
    }
    Write-Host "$FrameCorner$FrameHorizontal$Frame$FrameHorizontal$FrameCorner" -ForegroundColor $FrameColour
    Write-Host "$FrameVertical " -ForegroundColor $FrameColour -NoNewline
    Write-Host "$Blank" -NoNewline
    Write-Host " $FrameVertical" -ForegroundColor $FrameColour
    # Write Output
    foreach ($Line in $NewFileContents) {
        Write-Host "$FrameVertical " -ForegroundColor $FrameColour -NoNewline
        if ($Line -match "Machine Status:") {
            Write-Host "Machine Status: " -ForegroundColor $TextColour -NoNewline
            if ($(($Line -split "Machine Status: ")[1]) -match "OK") {
                Write-Host "$(($Line -split "Machine Status: ")[1]) " -ForegroundColor $PercentColourOK -NoNewline
            } else {
                Write-Host "$(($Line -split "Machine Status: ")[1]) " -ForegroundColor $PercentColourCritical -NoNewline
            }
        } else {
            foreach ($LineItem in ($Line -split " ")) {
                if ($LineItem -match "%") {
                    if ([int]$LineItem.Replace("%","") -lt ($PercentCritical + 1)) {
                        Write-Host "$LineItem " -ForegroundColor $PercentColourCritical -NoNewline
                    } elseif ([int]$LineItem.Replace("%","") -lt ($PercentWarning + 1)) {
                        Write-Host "$LineItem " -ForegroundColor $PercentColourWarning -NoNewline
                    } elseif ([int]$LineItem.Replace("%","") -gt $PercentWarning) {
                        Write-Host "$LineItem " -ForegroundColor $PercentColourOK -NoNewline
                    }
                } else {
                    Write-Host "$LineItem " -ForegroundColor $TextColour -NoNewline
                }
            }
        }
        Write-Host "$FrameVertical" -ForegroundColor $FrameColour
    }
    # End of Frame
    Write-Host "$FrameVertical " -ForegroundColor $FrameColour -NoNewline
    Write-Host "$Blank" -NoNewline
    Write-Host " $FrameVertical" -ForegroundColor $FrameColour
    Write-Host "$FrameCorner$FrameHorizontal$Frame$FrameHorizontal$FrameCorner" -ForegroundColor $FrameColour
    # Tidy up
    Remove-Variable Frame -Force -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Variable Blank -Force -Confirm:$false -ErrorAction SilentlyContinue
}

Function Set-WindowLine($Path = $FileLocation, $Line, $Value) {
    $i = 1
    $FileContents = Get-Content -Path $Path | ForEach-Object {
        if ($i -eq $Line) {
            $Value
        } else {
            $_
        }
        $i++
    }
    Set-Content -Path $Path -Value $FileContents
}

Function Get-FifteenGreeting() {
    # Create Greeting
    $Username = $Username
    $AMPM = Get-Date -Format "tt"
    $TimeHH = Get-Date -Format "HH"
    if ($AMPM -eq 'AM' -and $TimeHH -lt '04') {
        $Greeting = "$Username! GO TO BED!"
    } elseif ($AMPM -eq 'AM') {
        $Greeting = "Good Morning, $Username."
    } elseif ($AMPM -eq 'PM' -and $TimeHH -lt '18') {
        $Greeting = "Good Afternoon, $Username."
    } elseif ($AMPM -eq 'PM' -and $TimeHH -gt '17') {
        $Greeting = "Good Evening, $Username."
    } else {
        $Greeting = "Hello, $Username."
    }
    Return $Greeting
}

Function Get-IPtoINT64() {
    param ($ip)
    $octets = $ip.split(".")
    return [int64]([int64]$octets[0] * 16777216 + [int64]$octets[1] * 65536 + [int64]$octets[2] * 256 + [int64]$octets[3])
}

Function Get-INT64toIP() {
    param ([int64]$int)
    return (([math]::truncate($int / 16777216)).tostring() + "." + ([math]::truncate(($int % 16777216) / 65536)).tostring() + "." + ([math]::truncate(($int % 65536) / 256)).tostring() + "." + ([math]::truncate($int % 256)).tostring() )
}

Function Get-FifteenNetworkDetails {
    # Get my IP address(es)
    $MyNetworks = Get-NetIPAddress | Where-Object { $_.IPv4Address -ne "127.0.0.1" -and $_.AddressFamily -ne "IPv6" -and $_.AddressState -eq "Preferred" }
    foreach ($MyNetwork in $MyNetworks) {
        # If DHCP
        if ($MyNetwork.PrefixOrigin -eq "Dhcp" -and $MyNetwork.SuffixOrigin -eq "Dhcp") {
            $IsDHCP = " (DHCP)"
        }
        Return "IP: $([Net.IPAddress]::Parse($($MyNetwork.IPAddress)).IPAddressToString) /$([int]$MyNetwork.PrefixLength)$IsDHCP"
    }
}

Function Get-FifteenComputerCPU {
    # Get details
    $AllProcessor = Get-CimInstance -ClassName Win32_Processor | Select-Object NumberOfCores, Status
    if ($($AllProcessor.Count) -eq 1) {
        $LineCPU = "CPU: 1 Socket - $($AllProcessor.NumberOfCores) Cores - $($AllProcessor.Status)"
    } else {
        $CPUNumber = 0
        foreach ($Processor in $AllProcessor) {
            $CPUNumber++
        }
        $LineCPU = "CPU: $($CPUNumber) Sockets"
    }
    Return $LineCPU
}

Function Get-FifteenComputerMEM {
    # Get details
    $AllMemory = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object Capacity
    if ($AllMemory.Count -eq 1) {
        $LineMEM = "Memory: $($AllMemory.Capacity / 1GB)GB"
    } elseif ($AllMemory.Count -gt 1) {
        $TotalMemoryCapacity = 0
        foreach ($Memory in $AllMemory) {
            $MemoryCapacity = ($Memory.Capacity / 1GB)
            if ($TotalMemoryCapacity -eq 0) {
                $MemoryCapacityDisplay = "$($MemoryCapacity)GB"
            } else {
                $MemoryCapacityDisplay = "$MemoryCapacityDisplay + $($MemoryCapacity)GB"
            }
            $TotalMemoryCapacity = $TotalMemoryCapacity + $MemoryCapacity
        }
        $LineMEM = "Memory: $($TotalMemoryCapacity)GB ($MemoryCapacityDisplay)"
    }
    Return $LineMEM
}

Function Get-FifteenComputerMachine {
    # Get details
    $Machine = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Domain, Name
    Return "Machine: $($Machine.Domain)\$($Machine.Name)"
}

Function Get-FifteenComputerStatus {
    # Get details
    $Machine = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Status
    Return "Machine Status: $($Machine.Status)"
}

Function Get-FifteenComputerOS {
    # Get details
    $OSDetails = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object LastBootUpTime
    Return "Last Boot Time: $($OSDetails.LastBootUpTime)"
}

Function Get-FifteenDirectoryWatch {
    # Get details
    $NewDownloadsCount = (Get-ChildItem -Path $DirectoryWatch | Where-Object {(Get-Date -Date $_.LastWriteTime) -gt (Get-Date).AddMinutes(-$DirectoryWatchMinutes)}).Count
    Return "$($DirectoryWatchName): $NewDownloadsCount"
}

Function Get-FifteenComputerDisks {
    # Get details
    $AllDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | Select-Object FreeSpace, Size
    $LineDisks = "Disks: $($AllDisks.Count) -"
    foreach ($Disk in $AllDisks) {
        $DiskSize = [int][Math]::Round($Disk.Size / 1GB)
        $DiskFreeSpace = [int][Math]::Round($Disk.FreeSpace / 1GB)
        $DiskPercentRemaining = [int][Math]::Round(($DiskFreeSpace / $DiskSize) * 100)
        $LineDisks = $LineDisks + " $($DiskPercentRemaining)%"
    }
    Return $LineDisks
}

Function Get-FifteenScheduledTasks($State = $false) {
    if (!$State) {
        $AllTasks = Get-ScheduledTask | Select-Object TaskName, State | Where-Object {$_.State -ne "Ready" -and $_.State -ne "Disabled"}
        $SchState = "Scheduled Tasks"
    } else {
        $AllTasks = Get-ScheduledTask | Select-Object TaskName, State | Where-Object {$_.State -eq $State}
        $SchState = "$State Tasks"
    }
    Return "$($SchState): $($AllTasks.Count)"
}

# Do the things
Try {
    # Clear and set window colour
    Clear-Host
    (Get-Host).UI.RawUI.BackgroundColor = $BackgroundColor
    Write-Host "Loading..." -ForegroundColor $TextColour
    Set-QuickEdit -DisableQuickEdit
    Do {
        Set-WindowLine -Line 1 -Value (Get-FifteenGreeting)
        Set-WindowLine -Line 2 -Value "02"
        Set-WindowLine -Line 3 -Value "03"
        Set-WindowLine -Line 4 -Value (Get-FifteenComputerCPU)
        Set-WindowLine -Line 5 -Value (Get-FifteenComputerMEM)
        Set-WindowLine -Line 6 -Value (Get-FifteenComputerMachine)
        Set-WindowLine -Line 7 -Value (Get-FifteenComputerStatus)
        Set-WindowLine -Line 8 -Value (Get-FifteenComputerOS)
        Set-WindowLine -Line 9 -Value (Get-FifteenComputerDisks)
        Set-WindowLine -Line 10 -Value (Get-FifteenNetworkDetails)
        Set-WindowLine -Line 11 -Value (Get-FifteenScheduledTasks -State "Running")
        Set-WindowLine -Line 12 -Value (Get-FifteenScheduledTasks -State "Disabled")
        Set-WindowLine -Line 13 -Value (Get-FifteenDirectoryWatch)
        Read-WindowFile -ExitFile $ExitFile -MyPID $PID
        $host.UI.RawUI.WindowTitle = "$Title - $(Get-Date -Format "dddd dd MMMM yyyy")"
        Start-Sleep -Seconds $RefreshRate
    } While ($true)
}
Catch {
    Clear-Host
    Write-Host "Error with Read / Watch" -ForegroundColor Red
    Write-Host $Error[0] -ForegroundColor Black -BackgroundColor Red
    Start-Sleep 10
}
Finally {
    Clear-Host
    Write-Host "Exiting..." -ForegroundColor $TextColour
    Start-Sleep 2
    Exit
}
