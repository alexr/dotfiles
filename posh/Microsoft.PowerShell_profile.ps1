# Load Convert-Size
. "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\Convert-Size.ps1"

# Load custom functions
. "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\functions.ps1"

# Load spark
. "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\spark.ps1"

# Load posz
New-Variable zscoreFile -Value "$(Split-Path -Parent $profile)\zscores.csv" -Force
. "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\posz\posz.ps1"


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
    } elseif (Test-Path Env:\BASEDIR) {
        # CoreXT env...
        Push-Location(Get-Content Env:\BASEDIR)
    } else {
        # Git env...
        $Location = Get-AncestorItem '.git' Container
        if($Location -ne $null) { Push-Location $Location }
    }
}

function Start-CBT {
    param ( [string]$Path )

    # Default path to current location
    if (-not $Path) {
        $Path = $Pwd.Path
    } else {
        $path2 = Resolve-Path $Path -ErrorAction SilentlyContinue
        if ($path2 -eq $null) {
            Write-Host "Error $Path is not valid!" -ForegroundColor Red
            return
        }
        $Path = $path2
    }

    # Find real root if any
    $Root = Get-AncestorItem -ItemName 'CBT' -ItemKind Container -SearchPath $Path
    if($Root -eq $null) {
        Write-Host "Error $Path is not CBT subtree!" -ForegroundColor Red
        return
    }

    # Save original path to switch to it if under current location
    $env:CbtStartupPath = $path
    Write-Host "Make sure personal startup.ps1 contains line 'if (`$env:CbtStartupPath) { Set-Location `$env:CbtStartupPath }'."

    $saved_CBT_SHELL = $null
    if (Test-Path Env:\CBT_SHELL) {
        $saved_CBT_SHELL = (Get-Item Env:\CBT_SHELL).Value
    }
    $x = New-Item Env:\CBT_SHELL -Value Powershell -Force

    Push-Location $Root
    & "_BuildCommon\Scripts\Startup.cmd"
    Pop-Location

    if ($env:CbtStartupPath -ne $null) {
        Remove-Item Env:\CbtStartupPath
    }

    if ($saved_CBT_SHELL -ne $null) {
        Set-Item Env:\CBT_SHELL $saved_CBT_SHELL
    } else {
        Remove-Item Env:\CBT_SHELL
    }
    Remove-Item Env:\saved_CBT_SHELL -ErrorAction Ignore

    "Exited CBT."
}

function Start-CoreXT {
    param ( [string]$Path )

    # Default path to current location
    if (-not $Path) {
        $Path = $Pwd.Path
    } else {
        $path2 = Resolve-Path $Path -ErrorAction SilentlyContinue
        if ($path2 -eq $null) {
            Write-Host "Error $Path is not valid!" -ForegroundColor Red
            return
        }
        $Path = $path2
    }

    # Find real root if any
    $Root = Get-AncestorItem -ItemName '.corext' -ItemKind Container -SearchPath $Path
    if($Root -eq $null) {
        Write-Host "Error $Path is not CoreXT subtree!" -ForegroundColor Red
        return
    }

    if($env:NugetMachineInstallRoot -eq $null) {
        Write-Host "Error `$env:NugetMachineInstallRoot is not set. It must be set as sustem variable!" -ForegroundColor Red
        return
    }

    Write-Host "Nuget location is set to $env:NugetMachineInstallRoot" -ForegroundColor Green
    Push-Location $Root

    sudo powershell -noexit tools\path1st\myenv.ps1 $Root 'cosmos'

    Pop-Location
    "Exited CoreXT."
}

# Figures out where SublimeText is installed and returns path to it
function Get-Sublime-Path {
    if (Test-Path (Join-Path $env:ProgramFiles '\Sublime Text 2')) {
        return $(Join-Path $env:ProgramFiles '\Sublime Text 2\sublime_text.exe')
    } elseif (Test-Path (Join-Path ${env:ProgramFiles(x86)} 'Sublime Text 2')) {
        return $(Join-Path ${env:ProgramFiles(x86)} '\Sublime Text 2\sublime_text.exe')
    } elseif (Test-Path (Join-Path $env:ProgramFiles '\Sublime Text 3')) {
        return $(Join-Path $env:ProgramFiles '\Sublime Text 3\sublime_text.exe')
    } elseif (Test-Path (Join-Path ${env:ProgramFiles(x86)} 'Sublime Text 3')) {
        return $(Join-Path ${env:ProgramFiles(x86)} '\Sublime Text 3\sublime_text.exe')
    } else {
        return $null
    }
}

# Figure out where Beyond Compare is installed and returns path to it
function Get-BeyondCompare-Path {
    if (Test-Path (Join-Path $env:ProgramFiles '\Beyond Compare 4')) {
        return $(Join-Path $env:ProgramFiles '\Beyond Compare 4\BCompare.exe')
    } elseif (Test-Path (Join-Path ${env:ProgramFiles(x86)} 'Beyond Compare 4')) {
        return $(Join-Path ${env:ProgramFiles(x86)} '\Beyond Compare 4\BCompare.exe')
    } elseif (Test-Path 'C:\Users\Bin\BC4') {
        return 'C:\Users\Bin\BC4\BCompare.exe'
    } else {
        return $null
    }
}

function tflog {
    param ( [int]$n = 20 )
    tf history .\* -r -format:brief -noprompt -stopafter:$n
}

function tfstat {
    param ( [switch]$a )

    if ($a) {
        $tfstat = tf status | Where-Object {$_ -and $_.Substring(0, 1) -ne "`$"}
    } else {
        $tfstat = tf status -r . | Where-Object {$_ -and $_.Substring(0, 1) -ne "`$"}
    }
    $col = $tfstat | Where-Object {$_ -and $_.Substring(0,1) -eq "-"} | Select-Object -First 1
    $col = if ($col) {$col.Split(" ")[0].Length + 1} else {0}
    $tfstat | Foreach-Object {if($_.Length -le $col) {$_} else {$_.Substring($col)}}
}

function tfdiff {
    param ( $itemspec = "" )

    $tempFile = [System.IO.Path]::GetTempFileName()
    Rename-Item "$tempFile" "$tempFile.diff"
    $tempFile = $tempFile + ".diff"
    $x = tf diff /noprompt > $tempFile

    & (Get-Sublime-Path) "$tempFile"
}

# Based on [this](http://stackoverflow.com/a/33013110) StackOverflow answer.
function Enable-FusionLog() {
    param ( $LogPath = "G:\FusionLog" )

    # These commands need to run as-admin, thus wrapping in sudo.
    sudo powershell -NoProfile -Command "& {
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name ForceLog         -Value 1        -Type DWord
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogFailures      -Value 1        -Type DWord
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogResourceBinds -Value 1        -Type DWord
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogPath          -Value $LogPath -Type String
    }"
}

function Disable-FusionLog() {

    # These commands need to run as-admin, thus wrapping into sudo.
    sudo powershell -NoProfile -Command "& {
        Remove-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name ForceLog
        Remove-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogFailures
        Remove-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogResourceBinds
        Remove-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogPath
    }"
}


#############################################################
# Aliases
Set-Alias l    Get-ChildItem
Set-Alias np   $(Join-Path $env:SystemRoot '\System32\notepad.exe')

if ((Get-Sublime-Path) -eq $null) {
    # TODO: find out how to hide this function from global scope.
    function sublime_not_installed() { Write-Host 'SublimeText2 is not installed :(' -ForegroundColor Red }
    Set-Alias subl sublime_not_installed
} else {
    Set-Alias subl $(Get-Sublime-Path)
}

Set-Alias sbl subl
Set-Alias sudo "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\sudo.ps1"

if ((Get-BeyondCompare-Path) -eq $null) {
    # TODO: find out how to hide this function from global scope.
    function beyondcompare_not_installed() { Write-Host 'Beyond Compare 4 is not installed :(' -ForegroundColor Red }
    Set-Alias bc2 beyondcompare_not_installed
} else {
    Set-Alias bc2 $(Get-BeyondCompare-Path)
}

Set-Alias bc3  bc2
Set-Alias bc4  bc2

# Have to use `pd` here to get these locations to flow through posz.
function Push-Parent { $location = Get-Parent; if ($location) { pd $location } }
function Push-GrandParent { $location = Get-GrandParent; if ($location) { pd $location } }
function Push-GreatGrandParent { $location = Get-GreatGrandParent; if ($location) { pd $location } }
Set-Alias ..   Push-Parent
Set-Alias ...  Push-GrandParent
Set-Alias .... Push-GreatGrandParent
Set-Alias title Set-WindowTitle

Set-Alias \\   Push-ContextRoot
Set-Alias whereis $(Join-Path $env:SystemRoot '\System32\where.exe')

function f($search, $path) { findstr /snip $search $path }
function fs($search, $path) { findstr /snip /c:$search $path }
function cmdvs32 { Start-VisualStudioEnvironment x86 }
function cmdvs64 { Start-VisualStudioEnvironment x64 }
Set-Alias du2 directory-summary
function rcopy($from, $to) { robocopy $from $to /S /MT /Z }

#############################################################
# Ensure needed path's are indeed part of the path variable
#$pth = $(type Env:\path).Split(';') | Group-Object | Select-Object Name
#if ($pth -ncontains '') ???? how to add proper paths reliably across environments and machines ???
#Set-Item Env:\Path "$([string]::Join(';', $x.Name))"

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
#    . (Resolve-Path "$env:github_posh_git\profile.example.ps1")
    Push-Location (Resolve-Path "$env:github_posh_git")
    Import-Module .\posh-git

    Set-Location "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\posh-tf"
    Import-Module .\posh-tf
    # source CheckVersion.ps1 to create tf alias, since aliases don't export from ps modules
    . (".\CheckVersion.ps1")

    Pop-Location
} else {
    Import-Module posh-git
}

if (git --version) {
    # Modify prompt and git colors to fit more the zenburn scheme.
    # as described in http://sedodream.com/2012/05/05/GitCustomizingColorsForWindowsIncludingPoshgit.aspx
    $global:GitPromptSettings.WorkingForegroundColor=[ConsoleColor]::Blue
#    $global:GitPromptSettings.BranchAheadForegroundColor=[ConsoleColor]::Cyan
#    $global:GitPromptSettings.BeforeIndexForegroundColor=[ConsoleColor]::Green
    $global:GitPromptSettings.IndexForegroundColor=[ConsoleColor]::Green
    git config --global color.status.untracked "blue normal dim"
    git config --global color.status.changed "blue normal bold"
    git config --global color.status.added "green normal bold"
    git config --global color.diff.new "green bold"
    git config --global color.diff.old "red bold"
    git config --global color.diff.frag "cyan bold"
    git config --global color.diff.whitespace "yellow reverse"
    git config --global color.branch.remote "blue bold"
    git config --global color.branch.upstream "white bold"

    # Graphical history aliases
    git config --global alias.l "log --pretty='%C(black bold)%h%Creset -%C(yellow dim reverse)%d%Creset %s %C(cyan bold)[%an]%Creset %C(green bold)(%cr)%Creset'"
    git config --global alias.lg "log --graph --pretty='%C(black bold)%h%Creset -%C(yellow dim reverse)%d%Creset %s %C(cyan bold)[%an]%Creset %C(green bold)(%cr)%Creset' --abbrev-commit --date=relative"
    git config --global alias.lga "!git lg --all"
    git config --global core.editor ("`"'" + (Get-Sublime-Path) + "' -w $*`"")
    git config --global diff.tool "bc3"
    git config --global merge.tool "bc3"

    # Prevent Git from leaving around *.orig files after merges
    git config --global mergetool.keepBackup false

#    $global:TFPromptSettings.ChangesForegroundColor=[ConsoleColor]::Green
#    $global:TFPromptSettings.DetectedForegroundColor=[ConsoleColor]::Blue
}

# Modifying prompt function to include CBT and CodeBox
# prompt function content from $env:github_posh_git\profile.example.ps1
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    Write-Host $(Get-Date -Format "hh:mm:ss ") -ForegroundColor Cyan -nonewline

    Write-Host($pwd.ProviderPath) -nonewline

    # If CBT_VERSION is set then we are in the CBT env...
    if(Test-Path 'Env:\CBT_VERSION') {
        #Write-Host("$([char]0x205E)CBT$([char]0x205E)")  -ForegroundColor DarkGray -nonewline
        #Write-Host("$([char]0x27E8)CBT$([char]0x27E9) ")  -ForegroundColor DarkGray -nonewline
        #Write-Host("$([char]0x2506)CBT$([char]0x2506) ")  -ForegroundColor DarkGray -nonewline
        Write-Host("�CBT� ") -ForegroundColor DarkGray -nonewline
    }

    # If CODEBOXPROJECT is set then we are in the Codebox env...
    if (Test-Path Env:\CODEBOXPROJECT) {
        Write-Host("�CodeBox� ") -ForegroundColor DarkGray -nonewline
    }

    # If BASEDIR is set then we are in the CoreXT env...
    if(Test-Path 'Env:\BASEDIR') {
        Write-Host("�CrXT� ") -ForegroundColor DarkGray -nonewline
    }

    Write-VcsStatus

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}
