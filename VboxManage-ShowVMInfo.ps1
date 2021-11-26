<# Contains interactions with 'VBoxManage showvminfo' command #>

function Get-VBoxVMInformation
{
<#
    .SYNOPSIS
        Retrieves information about a VM and returns a readable list.

    .DESCRIPTION
        TODO:

    .PARAMETER VMIdentifier
        Specifiy either the Name or the Universally Unique Identifier (UUID) of the VM that you want to start.
#>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $VMIdentifier
    )

    # for the logging function
    $Component = "Get-VBoxVMInformation"

    if([string]::IsNullOrWhiteSpace($VMIdentifier))
    {
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
    }
    else
    {
        $Arguments = [string[]]("showvminfo",$VMIdentifier,"--details","--machinereadable")

        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Getting information about VM <"+$VMIdentifier+">") -Level Verbose
        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

        if($ret.ExitCode -eq 0)
        {
            # Build a PSCustomObject out of the returned list
            $PSObjectArgs=@{}
            foreach($line in @($ret.stdout.Split([System.Environment]::NewLine)))
            {
                if(-not ([string]::IsNullOrEmpty($line)))
                {
                    $PSObjectArgs.Add((($line.Split('='))[0]).replace('"',''), (($line.Split('='))[1]).replace('"',""))
                }
            }

            # do several stuff here
            # parse the forwarded ports 
            $forwards = $PSObjectArgs.GetEnumerator() | Where-Object {$_.Name -like "*forward*"}
            if($null -ne $forwards)
            {
                # initalize placeholder array
                $forwardedPorts = @()
                
                # create an array and parse the ports from the list
                foreach($entry in ($forwards))
                {
                    # remove the object from the propertylist (because we add the array afterwards)
                    $PSObjectArgs.Remove($entry.Key)

                    # And now create a nice looking PSCustomObject
                    $entry = $entry.Value.Split(",")
                    $forwardedPorts += [PSCustomObject]@{
                        "Name" = $entry[0]
                        "Protocol" = $entry[1]
                        "HostIP" = $entry[2]
                        "HostPort" = $entry[3]
                        "GuestIP" = $entry[4]
                        "GuestPort" = $entry[5]
                    }
                }
            }

            # Create a generic PSCustomObject out of the received key-value pairs
            $retObject = (New-Object -TypeName PSCustomObject -Property $PSObjectArgs)

            # Add now the forwarded ports, if any. 
            if($forwardedPorts){$retObject | Add-Member -MemberType NoteProperty -Name "PortForwarding" -Value $forwardedPorts}
    
            return ($retObject)
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Something went wrong while retrieving the information from VM.") -Level Warning
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stderr -Level Error
            return $null
        }
    }
}