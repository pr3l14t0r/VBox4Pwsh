function Resume-VBoxVM
{
<#
    .SYNOPSIS
        Starts a VBox VM that is in a saved state

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
    $Component = "Resume-VBoxVM"

    if([string]::IsNullOrWhiteSpace($VMIdentifier))
    {
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
    }
    else
    {
        $Arguments = [string[]]("controlvm",$VMIdentifier,"resume")

        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

        if($ret.ExitCode -ne 0)
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to resume the VM!") -Level Warning
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stderr -Level Error
        }
    }
}

function Save-VBoxVMState
{
<#
    .SYNOPSIS
        Saves the state of a running VM.

    .DESCRIPTION
        TODO:

    .PARAMETER VMIdentifier
        Specifiy either the Name or the Universally Unique Identifier (UUID) of the VM that you want to start.
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","VMName","UUID")]
    [string] $VMIdentifier
)

    Begin 
    {
        # for the logging function
        $Component = "Save-VBoxVMState"
    }
    Process
    {
        if([string]::IsNullOrWhiteSpace($VMIdentifier))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
            break
        }
        else
        {
            $Arguments = [string[]]("controlvm",$VMIdentifier,"savestate")
        }
    
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Saving the state of VM <"+$VMIdentifier+"> now..") -Level Verbose
        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments
    
        if($ret.ExitCode -ne 0)
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to save the state of VM!") -Level Warning
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout
            throw $ret.stderr
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Succesfully saved the state of VM <"+$VMIdentifier+">") -Level Verbose
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout -Level Verbose
        }
    }
}