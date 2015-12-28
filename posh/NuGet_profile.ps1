# Taken from [this](https://gist.github.com/davidfowl/984358) gist.
# as described in @Haacked [blog post](http://haacked.com/archive/2011/05/22/an-obsessive-compulsive-guide-to-source-code-formatting.aspx/).
function Recurse-Project {
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$ProjectName,
        [parameter(Mandatory = $true)]$Action
    )
    Process {
        # Convert project item guid into friendly name
        function Get-Type($kind) {
            switch($kind) {
                '{6BB5F8EE-4483-11D3-8BCF-00C04F8EC28C}' { 'File' }
                '{6BB5F8EF-4483-11D3-8BCF-00C04F8EC28C}' { 'Folder' }
                default { $kind }
            }
        }

        # Convert language guid to friendly name
        function Get-Language($item) {
            if(!$item.FileCodeModel) {
                return $null
            }

            $kind = $item.FileCodeModel.Language
            switch($kind) {
                '{B5E9BD34-6D3E-4B5D-925E-8A43B79820B4}' { 'C#' }
                '{B5E9BD33-6D3E-4B5D-925E-8A43B79820B4}' { 'VB' }
                default { $kind }
            }
        }

        # Walk over all project items running the action on each
        function Recurse-ProjectItems($projectItems, $action) {
            $projectItems | %{
                $obj = New-Object PSObject -Property @{
                    ProjectItem = $_
                    Type = Get-Type $_.Kind
                    Language = Get-Language $_
                }

                & $action $obj

                if($_.ProjectItems) {
                    Recurse-ProjectItems $_.ProjectItems $action
                }
            }
        }

        if($ProjectName) {
            $p = Get-Project $ProjectName
        }
        else {
            $p = Get-Project
        }

        $p | %{ Recurse-ProjectItems $_.ProjectItems $Action }
    }
}

# Statement completion for project names
Register-TabExpansion 'Recurse-Project' @{
    ProjectName = { Get-Project -All | Select -ExpandProperty Name }
}


# Example to print all project items
function Get-Project-Items {
    Recurse-Project -Action {param($item) "`"$($item.ProjectItem.Name)`" is a $($item.Type)" }
}

# Function to format all documents based on https://gist.github.com/984353
function Format-Document {
    param(
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$ProjectName
    )
    Process {
        $ProjectName | %{
                        Recurse-Project -ProjectName $_ -Action { param($item)
                        if($item.Type -eq 'Folder' -or !$item.Language) {
                            return
                        }

                        $window = $item.ProjectItem.Open('{7651A701-06E5-11D1-8EBD-00A0C90F26EA}')
                        if ($window) {
                            Write-Host "Processing `"$($item.ProjectItem.Name)`""
                            [System.Threading.Thread]::Sleep(100)
                            $window.Activate()
                            $Item.ProjectItem.Document.DTE.ExecuteCommand('Edit.FormatDocument')
                            $Item.ProjectItem.Document.DTE.ExecuteCommand('Edit.RemoveAndSort')
                            $window.Close(1)
                        }
                    }
        }
    }
}
