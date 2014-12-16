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

# Helper to run a process with timeout. After timeout process is killed.
# Some processes need to be killed repeatedly for some reason, otherwice they become ghosts. :)
if (-not ([System.Management.Automation.PSTypeName]'RunHelperClass').Type)
{
    $null = Add-Type 'using System;
    using System.Diagnostics;
    public class RunHelperClass {
        public static string RunTimed(string exe, string args, string cwd, int timeout)
        {
            var p = new Process();
            p.StartInfo.FileName = exe;
            p.StartInfo.Arguments = args;
            p.StartInfo.CreateNoWindow = false;
            p.StartInfo.UseShellExecute = false;
            p.StartInfo.WorkingDirectory = cwd;
            p.StartInfo.RedirectStandardOutput = true;
            p.StartInfo.RedirectStandardError = true;
            p.Start();
            if (!p.WaitForExit(timeout))
            {
                try { p.Kill(); }
                catch (Exception)
                {
                    try { p.Kill(); }
                    catch (Exception)
                    { p.Kill(); }
                }
                return "FAILED";
            }
            return p.StandardOutput.ReadToEnd() + p.StandardError.ReadToEnd();
        }
    }' -PassThru
}
