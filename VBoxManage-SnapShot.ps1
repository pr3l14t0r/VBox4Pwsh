<# Contains interactions with 'VBoxManage snapshot' command #>
function Get-VBoxVMSnapshot
{
<#
    .SYNOPSIS
        Gets the snapshots of a VBox VM.

    .DESCRIPTION
        TODO:

    .PARAMETER VMIdentifier
        Specifiy either the Name or the Universally Unique Identifier (UUID) of the VM that you want to start.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $VMIdentifier,

    [switch] $PrintHirarchy
)

    # for the logging function
    $Component = "Get-VBoxVMSnapshot"

    if([string]::IsNullOrWhiteSpace($VMIdentifier))
    {
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
    }

    $Arguments = [string[]]("snapshot",$VMIdentifier,"list","--details","--machinereadable")

    Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Listing the snapshots of VM <"+$VMIdentifier+"> now.") -Level Verbose
    $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

    if($ret.ExitCode -eq 0)
    {
        if($PrintHirarchy)
        {
            # just print out the hierarchy gotten from raw STDout.
            # [OPTIONAL]ToDo: Maybe return a PSCustomObject that reflects the hierarchy. Like:
            <#
                Name = SnapShotName
                UUID = SnapShotUUID
                HasParent = [bool] -> TRUE if the snapshot has a parent
                IsParent or HasChildren = [bool] -> TRUE if the snapshot is a parent one or has a childSnashot (multiple Children are possible...)
                IsCurrent = [bool] -> TRUE if the snapshot is the current one
            #>
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout
            return $null
        }
        else
        {
            # Split output lines
            $NonCurrentSnapshots = @($ret.stdout.Split([System.Environment]::NewLine)) | Where-Object {(-not [string]::IsNullOrEmpty($_)) -and (($_.split('='))[0] -notmatch "Current")}
            $CurrentSnapshot = @($ret.stdout.Split([System.Environment]::NewLine)) | Where-Object {($_.split('='))[0] -match "Current"}

            # return all snapshots as a PSCustomObject. That will loose the hierarchy but makes them usable for Pipes etc.            
            $out = @()
            $i=0;
            while ($i -lt $NonCurrentSnapshots.Count) {

            #Fetch and format the Name of the snapshot
            $SnapshotName = $NonCurrentSnapshots[$i] -split ('=',2) | Select-Object -Last 1
            $SnapshotName = $SnapshotName.Substring(1,($SnapshotName.Length-2))

            # check if this is the current snapshot
            if(($CurrentSnapshot[0] -split ('=',2))[1] -eq ('"'+$SnapshotName+'"')){$IsCurrent = $true}
            else{$IsCurrent = $false}

            #Fetch now the UUID of the snapshot
            $SnapshotUUID = $NonCurrentSnapshots[$i+1] -split ('=',2) | Select-Object -Last 1
            $SnapshotUUID = $SnapshotUUID.Substring(1,($SnapshotUUID.Length-2))

            # Now check if there is a third line that contains a description. If so, fetch it. If not, leave it empty.
            # Explanation: "if the part in front of '=' from the current line matches 'Description', then..."
            if((-not [string]::IsNullOrEmpty($NonCurrentSnapshots[$i+2])) -and (($NonCurrentSnapshots[$i+2].split('"'))[0] -match "Description"))
            {
                # line contains description of the snapshot. Will add it.
                $Description = $NonCurrentSnapshots[$i+2] -split ('=',2) | Select-Object -Last 1
                $Description = $Description.Substring(1,($Description.Length-2))
                
                #Now set the counter to the correct position
                $i += 3
            }
            else
            {
                $Description = ""
                $i += 2
            }

            $out += [PSCustomObject]@{
                "Name" = $SnapshotName
                "UUID" = $SnapshotUUID
                "Description" = $Description
                "isCurrent" = $IsCurrent
            }

            }# end while

           return $out
        }
    }
    elseif(($ret.ExitCode -eq 1) -and ($ret.stdout -like "*no*snapshots*"))
    {
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ($ret.stdout) -Level Verbose
        return $null
    }
    else
    {
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to list snapshots!") -Level Warning
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout
        throw $ret.stderr
    }
}

function New-VBoxVMSnapshot
{
<#
    .SYNOPSIS
        Creates a snapshot of a VBox VM.

    .DESCRIPTION
        TODO:

    .PARAMETER VMIdentifier
        Specifiy either the Name or the Universally Unique Identifier (UUID) of the VM that you want to start.

    .PARAMETER SnapshotName
        Specify the name of the snapshot to take. Default will be the current UTC timestamp as string!
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $VMIdentifier,

    [string] $SnapshotName
)

    # for the logging function
    $Component = "New-VBoxVMSnapshot"

    if([string]::IsNullOrWhiteSpace($VMIdentifier))
    {
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
    }
    else
    {
        $Arguments = [string[]]("snapshot",$VMIdentifier,"take")
    }

    #If the snaphotname has not been specified, name it after "nows" timestamp.
    if([string]::IsNullOrEmpty($SnapshotName))
    {
        $SnapshotName = [DateTime]::Now.ToUniversalTime().ToString("s")
    }
    
    $Arguments += $SnapshotName

    Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Taking a snaphsot of VM <"+$VMIdentifier+"> now. SnapshotName: <"+$SnapshotName+">") -Level Verbose
    $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

    if($ret.ExitCode -eq 0)
    {
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Sucessfully took the snapshot <"+$SnapshotName+"> for VM <"+$VMIdentifier+">") -Level Verbose
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout -Level Verbose
    }
    else
    {
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to create a snapshot!") -Level Warning
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stderr -Level Error
    }
}

function Remove-VBoxVMSnapshot
{
<#
    .SYNOPSIS
        Removes a snapshot from a VBox VM.

    .DESCRIPTION
        TODO:

    .PARAMETER VMIdentifier
        Specifiy either the Name or the Universally Unique Identifier (UUID) of the VM

    .PARAMETER SnapshotName
        Specify the name of the snapshot that you want to remove. If left blank, the current snapshot will be taken!
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","VMName","UUID")]
    [string] $VMIdentifier,

    [Parameter()]
    [AllowNull()]
    [string] $SnapshotName
)
    Begin 
    {
        # for the logging function
        $Component = "Remove-VBoxVMSnapshot"
    }

    Process
    {
        if([string]::IsNullOrWhiteSpace($VMIdentifier))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
            break
        }
        if([string]::IsNullOrEmpty($SnapshotName))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'SnaphotName' has not been specified! Will remove the current one.") -Level Verbose
            $SnapshotName = Get-VBoxVMSnapshot -VMIdentifier $VMIdentifier | Where-Object {$_.isCurrent} | Select-Object -ExpandProperty Name
        }

        $Arguments = [string[]]("snapshot",$VMIdentifier,"delete",$SnapshotName)

        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Removing snapshot <"+$SnapshotName+"> now from VM <"+$VMIdentifier+">!") -Level Verbose
        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

        if($ret.ExitCode -eq 0)
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Sucessfully removed snapshot <"+$SnapshotName+"> from VM <"+$VMIdentifier+">!") -Level Verbose
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout -Level Verbose
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to remove the snapshot!") -Level Warning
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout
            throw $ret.stderr
        }
    }
}

function Restore-VBoxVMSnapshot
{
<#
    .SYNOPSIS
        Restores a snapshot of a VBox VM.

    .DESCRIPTION
        TODO:

    .PARAMETER VMIdentifier
        Specifiy either the Name or the Universally Unique Identifier (UUID) of the VM that you want to start.

    .PARAMETER SnapshotName
        Specify the name of the snapshot that you want to restore.
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","VMName","UUID")]
    [string] $VMIdentifier,

    [Parameter()]
    [string] $SnapshotName
)

    Begin 
    {
        # for the logging function
        $Component = "Restore-VBoxVMSnapshot"
    }
    Process
    {
        if([string]::IsNullOrWhiteSpace($VMIdentifier))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
            break
        }
        if([string]::IsNullOrEmpty($SnapshotName))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'SnaphotName' has not been specified! Will use the most current one.") -Level Verbose
            $Arguments = [string[]]("snapshot",$VMIdentifier,"restorecurrent")
        }
        else
        {
            $Arguments = [string[]]("snapshot",$VMIdentifier,"restore",$SnapshotName)
        }

        if((Get-VBoxVMInformation -VMIdentifier $VMIdentifier).VMState -eq "running")
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("The VM <"+$VMIdentifier+"> is currently running! Saving it first") -Level Verbose
            Save-VBoxVMState -VMIdentifier $VMIdentifier
        }
        
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Restoring VM <"+$VMIdentifier+"> to snaphsot <"+$SnapshotName+"> now.") -Level Verbose
        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

        if($ret.ExitCode -eq 0)
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Sucessfully restored machine <"+$VMIdentifier+"> to snapshot <"+$SnapshotName+">!") -Level Verbose
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout -Level Verbose
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to restore the snapshot!") -Level Warning
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout
            throw $ret.stderr
        }
    }
}