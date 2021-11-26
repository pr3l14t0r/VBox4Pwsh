function Copy-VBoxDiskMedium
{
<#
    .SYNOPSIS
        Clones a VBox disk medium from source to Target.

    .DESCRIPTION
        This command duplicates a virtual disk, DVD, or floppy medium to a new medium, usually an image file, with a new unique identifier (UUID).
        The new image can be transferred to another host system or reimported into Oracle VM VirtualBox using the Virtual Media Manager.
        See 'https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-clonemedium.html' for more information.

    .PARAMETER Source
        Either specify the UUID of a VM, Disk-Medium or a VMs Snapshot, or specify a filepath.

    .PARAMETER Target
        Either specify the UUID of a VM, Disk-Medium or a VMs Snapshot, or specify a filepath.

    .PARAMETER Format
        Set a file format for the output file different from the file format of the input file

    .PARAMETER Variant
        Set a file format variant for the output file.

    .PARAMETER Existing
        Perform the clone operation to an already existing destination medium. Only the portion of the source medium which fits into the destination medium is copied. This means if the destination medium is smaller than the source only a part of it is copied, and if the destination medium is larger than the source the remaining part of the destination medium is unchanged.
#>
[CmdletBinding()]
[Alias('Clone-VBoxDiskMedium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Source,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Target,

    [Parameter()]
    [ValidateSet(
        "VDI",
        "VMDK",
        "VHD",
        "RAW"
    )]
    [string] $Format,

    [Parameter()]
    [AllowNull()]
    [ValidateSet(
        "Standard",
        "Fixed",
        "Split2G",
        "Stream",
        "ESX"
    )]
    [string] $Variant,

    [Parameter()]
    [switch] $Existing
)

    # for the logging function
    $Component = "Copy-VBoxDiskMedium"

    $Arguments = [string[]]("clonemedium","disk",$Source,$Target,"--format")

    if([string]::IsNullOrEmpty($Format))
    {
        $Arguments += "RAW"
    }
    else
    {
        $Arguments += $Format
    }

    if(-not [string]::IsNullOrEmpty($Variant)){$Arguments += ("--variant",$Variant)}

    if($Existing){$Arguments+="--existing"}

    $StartTime = [System.DateTime]::now
    $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments
    $EndTime = [System.DateTime]::now

    if($ret.ExitCode -eq 0)
    {
        Write-VBox4PwshLog -Component $Component -Message $ret.stdout -Level Verbose -Indent 4
        Write-VBox4PwshLog -Component $Component -Message ("Succesfully Cloned the medium <"+$Source+"> to <"+$Target+">!") -Level Verbose
        Write-VBox4PwshLog -Component $Component -Message ("Time taken: "+($EndTime-$StartTime).ToString("G")) -Level Verbose
    }
    else
    {
        Write-VBox4PwshLog -Component $Component -Message ("Unable to clone medium!") -Level Warning
        Write-VBox4PwshLog -Component $Component -Message $ret.stdout -Indent 4
        Write-VBox4PwshLog -Component $Component -Message $ret.stderr -Level Error -Indent 4
    }

    # This is called because most often after a "clonemedium" call follows a "closemedium" call.
    # There should be at least one second between those calls, otherwise you'll get a 'is locked for reading by another task' error
    Start-Sleep -Seconds 2
}

function Close-VBoxDiskMedium
{
<#
    .SYNOPSIS
        Closes a disk medium in VBox.

    .DESCRIPTION
        This command removes a hard disk, DVD, or floppy image from a Oracle VM VirtualBox media registry.
        See 'https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-closemedium.html' for more information.

    .PARAMETER Medium
        Either specify the UUID of a VM, Disk-Medium or specify a filepath.

    .PARAMETER Delete
        Specify this switch in order to also delete the file behind the medium.
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("FullName","UUID")]
    [string] $Medium,

    [switch] $Delete
)

    Begin
    {
        # for the logging function
        $Component = "Close-VBoxDiskMedium"
    }

    Process
    {
        $Arguments = [string[]]("closemedium","disk",$Medium)

        if($Delete){$Arguments+="--delete"}

        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

        if($ret.ExitCode -eq 0)
        {
            Write-VBox4PwshLog -Component $Component -Message $ret.stdout -Level Verbose -Indent 4
            Write-VBox4PwshLog -Component $Component -Message ("Succesfully closed the medium <"+$Medium+">!") -Level Verbose
        }
        else
        {
            Write-VBox4PwshLog -Component $Component -Message ("Unable to close medium!") -Level Warning
            Write-VBox4PwshLog -Component $Component -Message $ret.stdout -Indent 4
            Write-VBox4PwshLog -Component $Component -Message $ret.stderr -Level Error -Indent 4
        }
    }
}