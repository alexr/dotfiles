#############################################################
# New functions

# Pushes parent location (i.e. '..') if exists
function Push-Parent {
    $Location = Split-Path $pwd
    if($Location.Length -ne 0) { Push-Location $Location }
}

# Pushes grandparent location (i.e. '../..') or,
# if not exists then the parent if exists
function Push-GrandParent {
    $Location1 = Split-Path $pwd
    if($Location1.Length -ne 0) {
        $Location2 = Split-Path $Location1
        if($Location2.Length -ne 0) { Push-Location $Location2 }
        else                        { Push-Location $Location1 }
    }
}

# Pushes greatgrandparent, if not exists then grandparent, and
# finaly parent, whichever exists 
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

