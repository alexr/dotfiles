#############################################################
# New functions

# Returns parent location (i.e. '..') if exists
function Get-Parent {
    $Location = Split-Path $pwd
    if($Location.Length -ne 0) { return $Location }
    else { return $null }
}

# Returns grandparent location (i.e. '../..') or,
# if not exists then the parent if exists
function Get-GrandParent {
    $Location1 = Split-Path $pwd
    if($Location1.Length -ne 0) {
        $Location2 = Split-Path $Location1
        if($Location2.Length -ne 0) { return $Location2 }
        else                        { return $Location1 }
    } else { return $null }
}

# Returns greatgrandparent, if not exists then grandparent, and
# finaly parent, whichever exists 
function Get-GreatGrandParent {
    $Location1 = Split-Path $pwd
    if($Location1.Length -ne 0) {
        $Location2 = Split-Path $Location1
        if($Location2.Length -ne 0) {
            $Location3 = Split-Path $Location2
            if($Location3.Length -ne 0) { return $Location3 }
            else                        { return $Location2 }
        } else                          { return $Location1 }
    } else { return $null }
}

# Looks upwards in the current path ($pwd) to find item named $ItemName,
# which can be Leaf, Container, or either of them, which is the default.
# Returns closest path to the $ItemName or $null if not found.
function Get-AncestorItem {
    param ( [Parameter(Mandatory)][string]$ItemName,
            [ValidateSet('Leaf', 'Container', 'Any')]$ItemKind = 'Any',
            [string]$SearchPath = $pwd.Path)

    $cur = (Resolve-Path $SearchPath).Path

    while($cur.Length -ne 0) {
        if(Test-Path $cur\$ItemName -PathType $ItemKind) {
            return $cur
        }
        $cur = Split-Path $cur
    }
    return $null
}

# Looks up Visual Stdio instalation path.
# Backward compatible up to VS 10.0 and future proof till VS 14.0.
# Returns an object with `path` containing VS installation root
# and `version` - latest installed VS version.
function Get-LatestVisualStudio-InstallationPath {
    $regPath = "HKLM:SOFTWARE$(if([Environment]::Is64BitOperatingSystem) { '\Wow6432Node' })\Microsoft\VisualStudio\1*.0"
    $reg = Get-ChildItem $regPath | Sort-Object Name -desc | Select-Object -First 1

    if ($reg) {
        $res = New-Object psobject
        $res | Add-Member -Name version -Type NoteProperty -Value $reg.PSChildName
        $res | Add-Member -Name path -Type NoteProperty -Value ($reg | Get-ItemProperty | Select-Object -Exp "InstallDir")
        return $res
    } else {
        return $null
    }
}

function Start-VisualStudioEnvironment {
    param ( [string]$platform )
    $vsinfo = Get-LatestVisualStudio-InstallationPath
    if ($vsinfo) {
        Write-Host "Starting $platform comand prompt for VS $($vsinfo.version)..."

        $saved_VS_ENV_TITLE = $Host.UI.RawUI.WindowTitle
        $Host.UI.RawUI.WindowTitle = "Visual Studio Cmd - $platform"

        & cmd /k "`"$($vsinfo.path)..\..\VC\vcvarsall.bat`" $platform"

        $Host.UI.RawUI.WindowTitle = $saved_VS_ENV_TITLE
    } else {
        Write-Host "No Visual Studio version installed."
    }
}

# Basic du -s, slightly fixed, based on:
#     http://stackoverflow.com/questions/868264/du-in-powershell
# TODO:
# - Add (-c) produce grand total
# - Add (-s) display only a total for each argument
# - Add (-h) print sizes in human readable format (e.g., 1K 234M 2G 5T)
# - Add (#), where # is a number of levels to descend to compute sizes
function directory-summary {
    param ( [string]$dir = "." )
    Get-ChildItem $dir -ErrorAction SilentlyContinue |
        % { $f = $_ ;
            Get-ChildItem -r $_.FullName -ErrorAction SilentlyContinue |
            Where-Object -Property Length |
            Measure-Object -Property Length -Sum |
            Select-Object @{Name="Name";Expression={$f}}, Sum }
}


# A hack to monitor and kill bitlocker popup };^)
function Block-Bitlocker {
  while ($true)
  {
    $x = Get-Process -Name MBAMClientUI -ErrorAction SilentlyContinue | `
           Select-Object -ExpandProperty Id -ErrorAction SilentlyContinue
    if ($x) {
      Stop-process -Id $x -ErrorAction SilentlyContinue
      Write-Host X -NoNewLine -ForegroundColor Red
      Start-Sleep -Milliseconds 100
    } else {
      Write-Host . -NoNewLine -ForegroundColor Green
      Start-Sleep 10
    }
  }
}

# http://stackoverflow.com/questions/63805/equivalent-of-nix-which-command-in-powershell
function which([string]$name)
{
    if($name) {
        Get-Command $name -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Definition
    }
}


# Print all the console colors with names.
function Test-Colors {
    $colors = @('Black       ', 'DarkBlue    ', 'DarkGreen   ', 'DarkCyan    ',
                'DarkRed     ', 'DarkMagenta ', 'DarkYellow  ', 'Gray        ',
                'DarkGray    ', 'Blue        ', 'Green       ', 'Cyan        ',
                'Red         ', 'Magenta     ', 'Yellow      ', 'White       ')

    for ($i=0; $i -lt $colors.Length; $i++) {
        Write-Host -BackgroundColor $colors[$i].Trim() '   ' -NoNewline
        Write-Host -ForegroundColor $colors[$i].Trim() 'Col' -NoNewline
        Write-Host ' ' $colors[$i] -NoNewline
        if ($i%4 -eq 3) { Write-Host }
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
        0x00232347, 0x00aa50aa, 0x0000dcdc, 0x00ccdcdc,
        0x00808085, 0x00ffafaf, 0x007f9f7f, 0x00d3d08c,
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

