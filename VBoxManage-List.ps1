<# Contains interactions with 'VBoxManage list' command #>
function Get-VboxHDDs
{
<#
    .SYNOPSIS
        Retrieves all media declared as HDD from VirtualBox.

    .DESCRIPTION
        TODO:
#>

    $Arguments = [string[]]("list","--long","--sorted","hdds")
    $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

    $outObject=@()
    if($ret.ExitCode -eq 0)
    {
        $props=@{}
        foreach($line in @($ret.stdout.Split([System.Environment]::NewLine)))
        {
            if([string]::IsNullOrEmpty($line))
            {
                $outObject += (New-Object -TypeName PSCustomObject -Property $props)
                $props = @{}
            }
            else
            {
                $key = ($line.Split(":",2)[0] -Replace(":","") -Replace(" ","") -replace ("-",""))
                $value = ($line.Split(":",2)[-1]).TrimEnd()
                # TODO: Chech the types of the values. Right now, everything is a string.
                #   Suggestions:
                #       Encryption    : disabled --> could be boolean instead
                #       Sizeondisk    : 18721 MBytes --> could be Integer of Bytes
                while([string]::IsNullOrWhiteSpace($value[0])){$value = $value.Remove(0,1)}
                $props.Add($key,$value)
            }

        }
        return $outObject
    }
    #TODO: Build a powershell view table so that the PSCustomObject will get displayed in a standardized layout.
}

function Get-VboxVMs
{
<#
    .SYNOPSIS
        List all VMs configured in Virtualbox.

    .DESCRIPTION
        TODO:
    
    .PARAMETER Long
        Prints all information about a VM.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [switch] $Long
)

    # for the logging function
    $Component = "Get-VboxVMs"

    if($Long)
    {
        #$Arguments = [string[]]("list","--long","--sorted","vms")
        Write-VBox4PwshLog -Component $Component -Message ("Sorry, but 'vboxmange list --long --sorted vms' isn't implemented yet!") -Level Warning
        #ToDo: Implement the 'list --long --sorted vms' call. Problem: The output is not machine-readable...
    }
    else
    {
        # just get the basic overview
        $Arguments = [string[]]("list","vms")
    }
    $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

    $outObject=@()
    if($ret.ExitCode -eq 0)
    {
        if($Long)
        {
            #ToDo: If '--long --sorted' was used, format the output here
        }
        else
        {
            foreach($line in $ret.stdout.Split([System.Environment]::NewLine))
            {
                $outObject += [PSCustomObject]@{
                    Name = $line -replace '"','' -split " " | Select-Object -First 1
                    UUID = $line -replace '"','' -split " " | Select-Object -Last 1
                }
            }
        }
        return ($outObject | Sort-Object -Property Name )
    }
}
