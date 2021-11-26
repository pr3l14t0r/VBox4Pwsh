<# Contains interactions with 'VBoxManage startvm' command #>
function Start-VBoxVM
{
<#
    .SYNOPSIS
        Starts a VBox VM if it is in a stopped state.

    .DESCRIPTION
        TODO:

    .PARAMETER VMIdentifier
        Specifiy either the Name or the Universally Unique Identifier (UUID) of the VM that you want to start.

    .PARAMETER StartType
        Specify the start type of VM. Valid Arguments: gui, sdl, headless, separate. Defaults to headless.
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","VMName","UUID")]
    [string] $VMIdentifier,

    [Parameter()]
    [ValidateSet(
        "gui",
        "sdl",
        "headless",
        "separate"
    )]
    [string] $StartType
)

    Begin 
    {
        # for the logging function
        $Component = "Start-VBoxVM"
    }
    Process
    {
        if([string]::IsNullOrWhiteSpace($VMIdentifier))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
            break;
        }
        else
        {
            $Arguments = [string[]]("startvm",$VMIdentifier)
        }
    
        if([string]::IsNullOrEmpty($StartType)){$Arguments+= [string[]]("--type","headless")}
        else{$Arguments+= [string[]]("--type",$StartType)}
    
    
        # Check if the VM isn't in a paused state. If so, just resume it instead of start.
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Checking the VMs state to decide the operation to take") -Level Verbose
        $VMInfo = Get-VBoxVMInformation -VMIdentifier $VMIdentifier
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("The VMs state is <"+$VMInfo.VMState+">.") -Level Verbose
        if(($VMInfo.VMState -eq "paused"))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Resuming the VM instead of starting it (Which means 'Resume-VBoxVM' will be called)") -Level Verbose
            Resume-VBoxVM -VMIdentifier $VMIdentifier
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Starting the VM now with normal start procedure") -Level Verbose
            $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments
    
            if($ret.ExitCode -ne 0)
            {
                Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to start the VM!") -Level Warning
                Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout
                throw $ret.stderr
            }
        }
    }
}
