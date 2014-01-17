#############################################################
# Aliases
Set-Alias -Name l   -Value Get-ChildItem
Set-Alias -Name np  -Value $env:SystemRoot\System32\notepad.exe
Set-Alias -Name sbl -Value 'C:\Program Files\Sublime Text 2\sublime_text.exe'
Set-Alias -Name pd  -Value Pop-Location

function DPMain2 {
    Set-Location g:\VSTS\DPMain2
    & _BuildCommon\Scripts\Startup.cmd
}

function DPMain {
    Set-Location g:\VSTS\DPMain
    & _BuildCommon\Scripts\Startup.cmd
}

function f($search, $path) { findstr /snip $search $path }
function fs($search, $path) { findstr /snip /c:$search $path }
function ..   { Push-Location .. }
function ...  { Push-Location ..\.. }
function .... { Push-Location ..\..\.. }

function Test-Colors {
    $colors = @('Black       ', 'DarkBlue    ', 'DarkGreen   ', 'DarkCyan    ',
                'DarkRed     ', 'DarkMagenta ', 'DarkYellow  ', 'Gray        ',
                'DarkGray    ', 'Blue        ', 'Green       ', 'Cyan        ',
                'Red         ', 'Magenta     ', 'Yellow      ', 'White       ')

    for($i=0; $i -lt $colors.Length; $i++) {
        Write-Host -BackgroundColor $colors[$i].Trim() "   " -NoNewline
        Write-Host " " $colors[$i] -NoNewline
        if($i%4 -eq 3) { Write-Host }
    }
}

# Modified from http://stackingcode.com/blog/2011/11/14/zenburn-powershell
function New-ZenburnPowerShell {
    param ( [string]$Name = $(throw "Name required.") )
    $shortcutPath = Join-Path $home "Desktop\$Name.lnk"
    $registryItemPath = Join-Path HKCU:\Console $Name

    if (Test-Path $shortcutPath) {
        throw "$shortcutPath already exists!"
    }

    # Remove existing registry item.
    if (Test-Path $registryItemPath) {
        Remove-Item $registryItemPath
    }

    # Create new shortcut item.
    $ws = New-Object -ComObject wscript.shell
    $shortcut = $ws.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $Env:windir System32\WindowsPowerShell\v1.0\powershell.exe
    $shortcut.WorkingDirectory = "%HOMEDRIVE%%HOMEPATH%"
    $shortcut.Save()
    "Created `"$shortcutPath`""

    # Create new registry item.
    $x = New-Item $registryItemPath
    # http://twinside.free.fr/dotProject/?p=125
    $colors = @(
        0x003f3f3f, 0x00af6464, 0x00008000, 0x00808000,
        0x00232333, 0x00aa50aa, 0x0000dcdc, 0x00ccdcdc,
        0x008080c0, 0x00ffafaf, 0x007f9f7f, 0x00d3d08c,
        0x007071e3, 0x00c880c8, 0x00afdff0, 0x00ffffff
    )
    for ($i = 0; $i -lt $colors.Length; $i++) {
        $x = New-ItemProperty $registryItemPath -Name ("ColorTable" + $i.ToString("00")) -PropertyType DWORD -Value $colors[$i]
    }
    $x = New-ItemProperty $registryItemPath -Name "FaceName" -PropertyType STRING -Value "ProgCleanCo"
    $x = New-ItemProperty $registryItemPath -Name "FontSize" -PropertyType DWORD -Value 0x000D0007 # 13x7
    $x = New-ItemProperty $registryItemPath -Name "FontFamily" -PropertyType DWORD -Value 0x00000030
    $x = New-ItemProperty $registryItemPath -Name "FontWeight" -PropertyType DWORD -Value 0x00000190
    $x = New-ItemProperty $registryItemPath -Name "ScreenBufferSize" -PropertyType DWORD -Value 0x232800A5 # 9000x165
    $x = New-ItemProperty $registryItemPath -Name "QuickEdit" -PropertyType DWORD -Value 0x00000001
    $x = New-ItemProperty $registryItemPath -Name "WindowSize" -PropertyType DWORD -Value 0x001900A5
    "Created `"$registryItemPath`""
}



#############################################################
# Setup java
# as described in http://cs.markusweimer.com/2013/08/02/how-to-setup-powershell-for-github-maven-and-java-development/
if(Test-Path $env:JAVA_HOME) {
    Set-Alias javac $env:JAVA_HOME\bin\javac.exe
    Set-Alias java $env:JAVA_HOME\bin\java.exe
    Set-Alias jar $env:JAVA_HOME\bin\jar.exe
}
# Setup maven
if(Test-Path $env:M2_HOME) {
    function mvn-mt{
            $cmd = "$env:M2_HOME\bin\mvn.bat -TC1 $args"
            Invoke-Expression($cmd)        
    }
    function mvn {
            $cmd = "$env:M2_HOME\bin\mvn.bat $args"
            Invoke-Expression($cmd)        
    }
} else {
    function mvn {
        echo "Could not find a maven install. is M2_HOME set?"
    }
}

#############################################################
# Setup git
if(Test-Path ~\AppData\Local\GitHub) {
    . (Resolve-Path "$env:LOCALAPPDATA\GitHub\shell.ps1")
    . (Resolve-Path "$env:github_posh_git\profile.example.ps1")

    # Modify prompt and git colors to fit more the zenburn scheme.
    # as described in http://sedodream.com/2012/05/05/GitCustomizingColorsForWindowsIncludingPoshgit.aspx
    $global:GitPromptSettings.WorkingForegroundColor=[ConsoleColor]::Green
    git config --global color.status.untracked "blue normal dim"
    git config --global color.status.changed "blue normal bold"
}
