function Get-LocalOrParentPath($path) {
    $checkIn = Get-Item -Force .
    while ($checkIn -ne $null) {
        $pathToTest = [System.IO.Path]::Combine($checkIn.fullname, $path)
        if (Test-Path $pathToTest) {
            return $pathToTest
        } else {
            $checkIn = $checkIn.parent
        }
    }
    return $null
}

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose # -ForegroundColor Yellow
    }
}
