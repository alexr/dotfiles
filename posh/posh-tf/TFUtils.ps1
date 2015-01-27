function Get-TFStatus($tfDir = (Get-LocalOrParentPath '$tf')) {
    $settings = $Global:TFPromptSettings
    $enabled = (-not $settings) -or $settings.EnablePromptStatus
    if ($enabled -and $tfDir)
    {
        if($settings.Debug) {
            $sw = [Diagnostics.Stopwatch]::StartNew(); Write-Host ''
        } else {
            $sw = $null
        }

        if($settings.EnableFileStatus) {
            dbg 'Getting status' $sw
            try {
                # Unfortunately when TFS server is not available or you are offline,
                # "tf status" can hang for untolarable time and requires ^C to get your prompt back.
                # Here is quick and dirty solution to run "tf status" as timed process with 500ms timeout.
                # More than 500ms to get an answer and it's killed.
                $status = ([RunHelperClass]::RunTimed("tf", "status", $pwd.path, 900)).Split("`r`n")
            } catch {
                $status = @()
            }
        } else {
            $status = @()
        }

        $rolledBack = 0
        $changesAdded = 0
        $changesModified = 0
        $changesDeleted = 0
        $detectedAdded = 0
        $detectedModified = 0
        $detectedDeleted = 0
        $inChanges = $true
        $error = $false

        dbg 'Parsing status' $sw
        $status | ForEach-Object {
            dbg "Status: $_" $sw
            if($_) {
                switch -regex ($_) {
		    # [RunHelperClass]::RunTimed returns 'FAILED' when process is killed.
                    'FAILED' {
                        $error = $true
                    }
                    '.* edit,* .*' {
                        if ($inChanges) { $changesModified += 1 } else { $detectedModified += 1 }
                    }

                    '.* add,* .*' {
                        if ($inChanges) { $changesAdded += 1 } else { $detectedAdded += 1 }
                    }

                    '.* delete,* .*' {
                        if ($inChanges) { $changesDeleted += 1 } else { $detectedDeleted += 1 }
                    }

                    '.* rollback .*' { $rolledBack += 1 }

                    '^Detected Changes:' { $inChanges = $false }
                }
            }
        }

        dbg 'Building status object' $sw
        if ($changesAdded + $changesModified + $changesDeleted -gt 0) {
            $changes = New-Object PSObject |
                Add-Member -PassThru NoteProperty Added      $changesAdded |
                Add-Member -PassThru NoteProperty Modified   $changesModified |
                Add-Member -PassThru NoteProperty Deleted    $changesDeleted |
                Add-Member -PassThru NoteProperty Rollbacked $rolledBack
        }
        if ($detectedAdded + $detectedModified + $detectedDeleted -gt 0) {
            $detected = New-Object PSObject |
                Add-Member -PassThru NoteProperty Added    $detectedAdded |
                Add-Member -PassThru NoteProperty Modified $detectedModified |
                Add-Member -PassThru NoteProperty Deleted  $detectedDeleted
        }

        $result = New-Object PSObject -Property @{
            HasChanges      = [bool]$changes
            Changes         = $changes
            HasDetected     = [bool]$detected
            Detected        = $detected
            HasError        = $error
        }

        dbg 'Finished' $sw
        if($sw) { $sw.Stop() }
        return $result
    }
}
