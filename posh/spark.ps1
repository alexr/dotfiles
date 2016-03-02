# Displays array of numbers as a simple 9-level CLI chart.
# Inspired by https://github.com/holman/spark.
#
# Usage:
#     spark @(...) [-z] [-s]
#   or via pipe
#     @(...) | spark [-z] [-s]
#
#   Positive numbers result in green bars, negative in red.
#   When array has all positive or all negative numbers, it is bein scaled
#   to display only [min-max] range, i.e. min value displayed as " ", and max value as "█".
#   Specifying "-z" one can set " " to mean 0.0 instead.
#   When both positive and negative numbers present, " " is always mean 0.0,
#   and "█" represents max(abs(min), abs(max)).
#   When visualizing numbers smaller than [-9..9] it may be usefult to specify "-s"
#   to allow one tick to represent fractional step. E.g.
#   > spark @(0, .1, .2, .3, .4, .5, .6, .7, .8)
#   >       ▁▁▁
#   > spark @(0, .1, .2, .3, .4, .5, .6, .7, .8) -s
#   >  ▁▂▃▄▅▆▇█
#
# Example:
#
# > git shortlog -s | cut -f1  | spark
# > ▂▁ ▁▁█▂▄▁▇
# > 
function spark () {
    param ( [Parameter(ValueFromPipeline=$True)] [double[]] $val,
                                                 [switch]   $z,
                                                 [switch]   $s,
                                                 [switch]   $test)

    $ticks = " ▁▂▃▄▅▆▇█"
    $colorPositive = 'green'
    $colorNegative = 'red'

    # limit minimum scale to 1.0, unless "-s" is specified,
    # in which case minimum scale is not limited.
    $minScale = if ($s) { 0.0 } else { 1.0 }

    if($input) {
        $arr = @($input)
    } else {
        $arr = $val
    }

    function data2ticks($arr) {
        $x = $arr | Measure-Object -Maximum -Minimum

        # Values appear on each side of 0. Choose scale $f based on which side is further from 0.
        # Limit scale to $minScale.
        if ($x.Minimum -lt 0.0 -and $x.Maximum -gt 0.0) {
            $f = [Math]::Max(-$x.Minimum, $x.Maximum)/($ticks.Length-1)
            $min = 0.0
        } else {
            if ($z) {
                $min = 0.0
                $f = [Math]::Max([Math]::Abs($x.Minimum), [Math]::Abs($x.Maximum))/($ticks.Length-1)
            } else {
                $f = ($x.Maximum-$x.Minimum)/($ticks.Length-1)
                # $min is distance closest to 0, i.e. value represented by " " tick. 
                $min = if ($x.Maximum -gt 0.0) { $x.Minimum } else { $x.Maximum }
            }
        }

        if ($z) { $min = 0.0 }
        $f = [Math]::Max($f, $minScale)

        $res = $arr | ForEach-Object { [Math]::Round(($_ - $min)/$f) }
        return $res
    }

    if (-not $test) {
        data2ticks $arr | ForEach-Object {
            Write-Host -NoNewline $ticks[[Math]::Abs($_)] -ForegroundColor ($colorPositive, $colorNegative)[$_ -lt 0]
        }
        Write-Host
    }
    else {
        return data2ticks $arr
    }
}

function __testspark__() {

    $testData = @{
       # Simple
       @(0,1,2,3,4,5,6,7,8)               = @(0,1,2,3,4,5,6,7,8)
       # Exponential
       @(0,2,4,8,16,32,64,128,256)        = @(0,0,0,0,0,1,2,4,8)
       # Scale
       @(2,4,6,8,10,12,14,16,18)          = @(0,1,2,3,4,5,6,7,8)
       # Negative Exponential
       @(0,-2,-4,-8,-16,-32,-64,-128,-256)  = @(0,0,0,0,0,-1,-2,-4,-8)
       # Negative Scale
       @(-2,-4,-6,-8,-10,-12,-14,-16,-18) = @(0,-1,-2,-3,-4,-5,-6,-7,-8)
       # Positive and Negative
       @(0,-1,1,-2,2,-3,3,-4,4,-5,5,-6,6,-7,7,-8,8) = @(0,-1,1,-2,2,-3,3,-4,4,-5,5,-6,6,-7,7,-8,8)
       # Positive and Negative w/ Scale
       @(-2,2,-4,4,-6,6,-8,8,-10,10,-12,12,-14,14,-16,16) = @(-1,1,-2,2,-3,3,-4,4,-5,5,-6,6,-7,7,-8,8)
       # Positive and Negative w/ Stretch
       @(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,
-1,0) =  @(0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,-8,-8,-7,-7,-6,-6,-5,-5,-4,-4,-3,-3,-2,-2,-1,-1,0,0)
    }

    function test($data, $expected) {
        Write-Host "- - - - - - - - - - - - -"
        spark $data
        Write-Host -BackgroundColor Gray -ForegroundColor Black "@(" $data ")"
        $res = Compare-Object (spark $data -test) $expected
        if ($res -eq $null) {
            Write-Host -ForegroundColor Green "PASS"
        } else {
            Write-Host -ForegroundColor Red "FAIL"
            Write-Host $res
        }
    }

    $testData.Keys | ForEach-Object { test $_ $testData.Get_Item($_) }
}
