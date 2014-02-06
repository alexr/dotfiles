#############################################################
# New functions
function Push-Parent {
    $Location = Split-Path $pwd
    if($Location.Length -ne 0) { Push-Location $Location }
}

function Push-GrandParent {
    $Location1 = Split-Path $pwd
    if($Location1.Length -ne 0) {
        $Location2 = Split-Path $Location1
        if($Location2.Length -ne 0) { Push-Location $Location2 }
        else                        { Push-Location $Location1 }
    }
}

function Push-GreatGrandParent {
    $Location1 = Split-Path $pwd
    if($Location1.Length -ne 0) {
        $Location2 = Split-Path $Location1
        if($Location2.Length -ne 0) {
            $Location3 = Split-Path $Location2
            if($Location3.Length -ne 0) { Push-Location $Location3 }
            else                        { Push-Location $Location2 }
        } else                          { Push-Location $Location1 }
    }
}

# Looks upwards in the current path ($pwd) to find item named $ItemName,
# which can be Leaf, Container, or either of them, which is the default.
# Returns closest path to the $ItemName or $null if not found.
function Get-AncestorItem {
    param ( [Parameter(Mandatory)][string]$ItemName,
            [ValidateSet('Leaf', 'Container', 'Any')]$ItemKind = 'Any')

    $cur = $pwd.Path
    while($cur.Length -ne 0) {
        if(Test-Path $cur\$ItemName -PathType $ItemKind) {
            return $cur
        }
        $cur = Split-Path $cur
    }
    return $null
}

# Quickly get to the root of current enlistment/branch in CBT and Git
function Push-ContextRoot {
# Razzle environment doesn't support PowerShell :(
#    # are we in Razzle environment
#    if(Test-Path Env:\_RazzleArguments) {
#        Push-Location(Get-Content Env:\BaseDir) # can also use SDXROOT
#    } else {

    if(Test-Path Env:\CBT_PS_ARGS) {
        # CBT env...
        Push-Location(Get-Content Env:\ENLISTMENT_ROOT)
    } else {
        # Git env...
        $Location = Get-AncestorItem '.git' Container
        if($Location -ne $null) { Push-Location $Location }
    }
}

function Start-CBT {
    param ( [Parameter(Mandatory)][string]$Root )

    $saved_CBT_SHELL = $null
    if(Test-Path Env:\CBT_SHELL) {
        $saved_CBT_SHELL = (Get-Item Env:\CBT_SHELL).Value
        Remove-Item Env:\CBT_SHELL
    }
    $x = New-Item Env:\CBT_SHELL -Value Powershell
    Push-Location $Root
    & "_BuildCommon\Scripts\Startup.cmd"
    Pop-Location
    if($saved_CBT_SHELL -ne $null) {
        Set-Item Env:\CBT_SHELL $saved_CBT_SHELL
    } else {
        Remove-Item Env:\CBT_SHELL
    }
    "Exited CBT."
}
function DPMain  { Start-CBT g:\VSTS\DPMain  }
function DPMain2 { Start-CBT g:\VSTS\DPMain2 }

#############################################################
# Aliases
Set-Alias l   Get-ChildItem
Set-Alias np  $(Join-Path $env:SystemRoot '\System32\notepad.exe')
Set-Alias sbl $(Join-Path $env:ProgramFiles '\Sublime Text 2\sublime_text.exe')
Set-Alias pd  Pop-Location
Set-Alias .. Push-Parent
Set-Alias ... Push-GrandParent
Set-Alias .... Push-GreatGrandParent
Set-Alias \\ Push-ContextRoot

#function DPMain2 {
#    New-Item Env:\CBT_SHELL -Value Powershell
#    Set-Location g:\VSTS\DPMain2
#    & _BuildCommon\Scripts\Startup.cmd
#}


function f($search, $path) { findstr /snip $search $path }
function fs($search, $path) { findstr /snip /c:$search $path }


function Test-Colors {
    $colors = @('Black       ', 'DarkBlue    ', 'DarkGreen   ', 'DarkCyan    ',
                'DarkRed     ', 'DarkMagenta ', 'DarkYellow  ', 'Gray        ',
                'DarkGray    ', 'Blue        ', 'Green       ', 'Cyan        ',
                'Red         ', 'Magenta     ', 'Yellow      ', 'White       ')

    for($i=0; $i -lt $colors.Length; $i++) {
        Write-Host -BackgroundColor $colors[$i].Trim() '   ' -NoNewline
        Write-Host ' ' $colors[$i] -NoNewline
        if($i%4 -eq 3) { Write-Host }
    }
}

# Modified from http://stackingcode.com/blog/2011/11/14/zenburn-powershell
function New-ZenburnPowerShell {
    param ( [Parameter(mandatory)][string]$Name )

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
        $x = New-ItemProperty $registryItemPath -Name "ColorTable$($i.ToString('00'))" -PropertyType DWORD -Value $colors[$i]
    }
    $x = New-ItemProperty $registryItemPath -Name "FaceName" -PropertyType STRING -Value "DejaVu Sans Mono"
#    $x = New-ItemProperty $registryItemPath -Name "FaceName" -PropertyType STRING -Value "ProggyClean"
#    $x = New-ItemProperty $registryItemPath -Name "FontSize" -PropertyType DWORD -Value 0x000D0007 # 13x7
    $x = New-ItemProperty $registryItemPath -Name "FontSize" -PropertyType DWORD -Value 0x00120000 # 18
    $x = New-ItemProperty $registryItemPath -Name "FontFamily" -PropertyType DWORD -Value 0x00000036
    $x = New-ItemProperty $registryItemPath -Name "FontWeight" -PropertyType DWORD -Value 0x00000190 # 400
    $x = New-ItemProperty $registryItemPath -Name "ScreenBufferSize" -PropertyType DWORD -Value 0x232800A5 # 9000x165
    $x = New-ItemProperty $registryItemPath -Name "QuickEdit" -PropertyType DWORD -Value 0x00000001
    $x = New-ItemProperty $registryItemPath -Name "WindowSize" -PropertyType DWORD -Value 0x001900A5
    "Created `"$registryItemPath`""
}

function Enable-Console-Dejavu {
    $FontName = "DejaVu Sans Mono"
    $RegistryItemPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont"
    $PropertyName = '0'
    $AlreadyInstalled = $false
    while($PropertyName.Length -lt 8) {
        $x =  (Get-ItemProperty -Name '0*' -path $RegistryItemPath).$PropertyName
        if($x -eq $null) {
            break
        }
        Write-Host "At [$PropertyName] = $x"
        if($x -eq $FontName) {
            $AlreadyInstalled = $true
            break
        }
        $PropertyName = $PropertyName + "0"
    }
    if($AlreadyInstalled) {
        Write-Host "$FontName already enabled." -ForegroundColor Yellow
    } else {
        try {
            $x = New-ItemProperty $RegistryItemPath -Name $PropertyName -PropertyType String -Value $FontName -ErrorAction Stop
            Write-Host "$FontName has been enabled." -ForegroundColor Green
        } catch [System.Security.SecurityException] {
            Write-Host "Oops. Permission denied." -ForegroundColor Red
            Write-Host "This function modifies registry. Run from admin posh or permanently enable with 'Set-ExecutionPolicy unrestricted' from admin posh." -ForegroundColor Red
        }
    }
}



#############################################################
# Setup java
# as described in http://cs.markusweimer.com/2013/08/02/how-to-setup-powershell-for-github-maven-and-java-development/
if(Test-Path Env:\JAVA_HOME) {
    Set-Alias javac $env:JAVA_HOME\bin\javac.exe
    Set-Alias java $env:JAVA_HOME\bin\java.exe
    Set-Alias jar $env:JAVA_HOME\bin\jar.exe
}
# Setup maven
if(Test-Path Env:\M2_HOME) {
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
    $global:GitPromptSettings.WorkingForegroundColor=[ConsoleColor]::Blue
    $global:GitPromptSettings.BranchAheadForegroundColor=[ConsoleColor]::Cyan
    $global:GitPromptSettings.BeforeIndexForegroundColor=[ConsoleColor]::Green
    $global:GitPromptSettings.IndexForegroundColor=[ConsoleColor]::Green
    git config --global color.status.untracked "blue normal dim"
    git config --global color.status.changed "blue normal bold"
    git config --global color.status.added "green normal bold"
}

# Modify prompt function to include CBT
# prompt function content from $env:github_posh_git\profile.example.ps1
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

    Write-Host($pwd.ProviderPath) -nonewline

    # If CBT_VERSION is set then we are in the CBT env...
    if(Test-Path 'Env:\CBT_VERSION') {
        #Write-Host("$([char]0x205E)CBT$([char]0x205E)")  -ForegroundColor DarkGray -nonewline
        #Write-Host("$([char]0x27E8)CBT$([char]0x27E9) ")  -ForegroundColor DarkGray -nonewline
        #Write-Host("$([char]0x2506)CBT$([char]0x2506) ")  -ForegroundColor DarkGray -nonewline
        Write-Host("¦CBT¦ ")  -ForegroundColor DarkGray -nonewline
    }
    
    Write-VcsStatus

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}

. "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\posz.ps1"

