<# Contains interactions with 'VBoxManage guestcontrol' command #>
function Copy-FileToVBoxVM
{
<#
    .SYNOPSIS
        Copies a file from local source to VBoxVM

    .DESCRIPTION
        Copies files from the host to the guest file system. Only available with Guest Additions 4.0 or later installed. 

    .PARAMETER Source
        Specifiy the full qualified path of your file that you want to copy to the machine. Can be multiple, full qualified paths.

    .PARAMETER Destination
        Specifies the absolute path of the guest file system destination directory. Mandatory. For example: C:\Temp. 

    .Parameter Follow
        Enables symlink following on the host file system. Optional. 
    
    .Parameter Recursive
        Enables recursive copying of files and directories from the specified host file system directory. Optional. 
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","VMName","UUID")]
    [string] $VMIdentifier,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]] $Source,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Destination,

    [Parameter()]
    [AllowNull()]
    [switch] $Follow,

    [Parameter()]
    [AllowNull()]
    [switch] $Recursive,

    [Parameter()]
    [string] $UserName,

    [Parameter()]
    [string] $Password
)

    Begin 
    {
        # for the logging function
        $Component = "Copy-FileToVBoxVM"
    }
    Process
    {
        if([string]::IsNullOrWhiteSpace($VMIdentifier))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
            break
        }

        $Arguments = [string[]]("guestcontrol",$VMIdentifier,'--verbose')

        # common params
        if(-not [string]::IsNullOrEmpty($UserName)){$Arguments += @("--username",$UserName)}
        if(-not [string]::IsNullOrEmpty($Password)){$Arguments += @("--password",$Password)}

        # add main keyword
        $Arguments += "copyto"

        # Additional params
        if($Follow){$Arguments += "--follow"}
        if($Recursive){$Arguments += "--recursive"}
        
        #Add target directory
        $Arguments += [string[]]("--target-directory",$Destination)

        #Add host file(s)
        $Arguments += $Source


        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Copying files now to VM <"+$VMIdentifier+">!") -Level Verbose
        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

        if($ret.ExitCode -eq 0)
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Sucessfully copied the files to VM <"+$VMIdentifier+">!") -Level Verbose
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Received from STDOut: `n"+$ret.stdout) -Level Verbose -Indent 4
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Received from STDErr: `n"+$ret.stderr) -Level Verbose -Indent 4
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to copy the files!") -Level Warning
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout -Indent 4
            throw $ret.stderr
        }
    }
}

function Copy-FileFromVBoxVM
{
<#
    .SYNOPSIS
        Copies a file from a VBoxVM to the local machine

    .DESCRIPTION
        Copies files from the guest to the host file system. Only available with Guest Additions 4.0 or later installed. 

    .PARAMETER Source
        Specifies the absolute paths of guest file system files to be copied. Mandatory. For example: C:\Windows\System32\calc.exe. Wildcards can be used in the expressions. For example: C:\Windows\System*\*.dll. 

    .PARAMETER Destination
        Specifies the absolute path of the host file system destination directory. Mandatory. For example: C:\Temp.

    .Parameter Follow
        Enables symlink following on the host file system. Optional. 
    
    .Parameter Recursive
        Enables recursive copying of files and directories from the specified host file system directory. Optional. 
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","VMName","UUID")]
    [string] $VMIdentifier,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]] $Source,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Destination,

    [Parameter()]
    [AllowNull()]
    [switch] $Follow,

    [Parameter()]
    [AllowNull()]
    [switch] $Recursive,

    [Parameter()]
    [string] $UserName,

    [Parameter()]
    [string] $Password
)

    Begin 
    {
        # for the logging function
        $Component = "Copy-FileFromVBoxVM"

        #Check first if the specified output directory exists
        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Check if the directory <"+$Destination+"> exists. If not, it will get created!") -Level Verbose
        if(-not (Test-Path -Path $Destination -PathType Container))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("The path does not exist yet!") -Level Verbose
            $null = New-Item -Path $Destination -ItemType Directory -Force -Confirm:$false -ErrorAction Stop
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Succesfully created the directory <"+$Destination+">!") -Level Verbose
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Path exists.") -Level Verbose
        }
    }
    Process
    {
        if([string]::IsNullOrWhiteSpace($VMIdentifier))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
            break
        }

        $Arguments = [string[]]("guestcontrol",$VMIdentifier,'--verbose')

        # common params
        if(-not [string]::IsNullOrEmpty($UserName)){$Arguments += @("--username",$UserName)}
        if(-not [string]::IsNullOrEmpty($Password)){$Arguments += @("--password",$Password)}

        # add main keyword
        $Arguments += "copyfrom"

        # Additional params
        if($Follow){$Arguments += "--follow"}
        if($Recursive){$Arguments += "--recursive"}
        
        #Add target host directory
        $Arguments += [string[]]("--target-directory",$Destination)

        #Add guest file(s)/directory/ies
        $Arguments += $Source


        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Copying files now from VM <"+$VMIdentifier+">!") -Level Verbose
        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

        if($ret.ExitCode -eq 0)
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Sucessfully copied the files from VM <"+$VMIdentifier+">!") -Level Verbose
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Received from STDOut: `n"+$ret.stdout) -Level Verbose -Indent 4
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to copy the files!") -Level Warning
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message $ret.stdout -Indent 4
            throw $ret.stderr
        }
    }
}

function Invoke-VboxVMProcess
{
<#
    .SYNOPSIS
        Runs a programm on the VM.

    .DESCRIPTION
        Executes a guest program, forwarding stdout, stderr, and stdin to and from the host until it completes. 

    .PARAMETER FilePath
        Specifies the absolute path of the executable on the guest OS file system. Mandatory. For example: C:\Windows\System32\calc.exe. 
        On Unix-Hosts, Double-Backslashes are needed: "c:\\windows\\system32\\ipconfig.exe"

    .PARAMETER Params
        Specifies the program name, followed by one or more arguments to pass to the program. Optional.  

    .Parameter TimeOut
        Specifies the maximum time, in microseconds, that the executable can run, during which VBoxManage receives its output. Optional.
        If unspecified, VBoxManage waits indefinitely for the process to end, or an error occurs. 
    
    .Parameter EnvironmentVariables
        Sets, modifies, and unsets environment variables in the environment in which the program will run. Optional.
        Provide a hashlist consting out of key-value pairs

    .Parameter UnquotedArgs
        Disables escaped double quoting, such as \"fred\", on arguments passed to the executed program. Optional. 

    .Parameter WaitSTDOut
        Does not wait or waits until the guest process ends and receives its exit code and reason/flags.
        In the case of TRUE, VBoxManage receives its stdout while the process runs. Optional.

    .Parameter WaitSTDErr
        Does not wait or waits until the guest process ends and receives its exit code and reason/flags.
        In the case of TRUE, VBoxManage receives its stdout while the process runs. Optional.

    .Parameter dos2unix
        Converts output from DOS/Windows guests to UNIX/Linux-compatible line endings, CR + LF to LF. Not yet implemented. Optional. 

    .Parameter unix2dos
        Converts output from a UNIX/Linux guests to DOS/Windows-compatible line endings, LF to CR + LF. Not yet implemented. Optional. 

    .Parameter UserName
        Provide the UserName of the user in whichs context the program shall run. Optional.

    .Parameter Password
        Provide the password of a user. Optional. 
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","VMName","UUID")]
    [string] $VMIdentifier,

    [Parameter()]
    [AllowNull()]
    [string] $FilePath,

    [Parameter()]
    [AllowNull()]
    [string[]] $Params,

    [Parameter()]
    [AllowNull()]
    [int] $TimeOut,

    [Parameter()]
    [AllowNull()]
    [Hashtable] $EnvironmentVariables,

    [Parameter()]
    [AllowNull()]
    [switch] $UnquotedArgs,

    [Parameter()]
    [switch] $WaitSTDOut,

    [Parameter()]
    [switch] $WaitSTDErr,

    [Parameter()]
    [AllowNull()]
    [switch] $dos2unix,

    [Parameter()]
    [AllowNull()]
    [switch] $unix2dos,

    [Parameter()]
    [AllowNull()]
    [switch] $PassThru,

    [Parameter()]
    [string] $UserName,

    [Parameter()]
    [string] $Password
)

    Begin 
    {
        # for the logging function
        $Component = "Invoke-VboxVMProcess"
    }

    Process
    {
        if([string]::IsNullOrWhiteSpace($VMIdentifier))
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Parameter 'VMIdentifier' is not specified or empty! Please provide the parameter 'VMIDentifier' by either providing the VMs Name or UUID!") -Level Error
            break
        }

        $Arguments = [string[]]("guestcontrol",$VMIdentifier)

        # Add COMMON params
        if(-not [string]::IsNullOrEmpty($UserName)){$Arguments += @("--username",$UserName)}
        if(-not [string]::IsNullOrEmpty($Password)){$Arguments += @("--password",$Password)}

        # Add the main keyword
        $Arguments += "run"

        # Add Additional params
        if($FilePath){$Arguments += [string[]]("--exe",$FilePath)}
        if($TimeOut){$Arguments += [string[]]("--timeout",$TimeOut)}
        if($EnvironmentVariables)
        {
            foreach($entry in $EnvironmentVariables.GetEnumerator())
            {
                $Arguments += [string[]]("--putenv",([string]::Concat($entry.Key,'=',$entry.Value)))
            }
        }
        if($UnquotedArgs){$Arguments += "--unquoted-args"}
        if($WaitSTDOut){$Arguments += "--wait-stdout"}else{$Arguments += "--no-wait-stdout"}
        if($WaitSTDErr){$Arguments += "--wait-stderr"}else{$Arguments += "--no-wait-stderr"}
        if($dos2unix){$Arguments += "--dos2unix"}
        if($unix2dos){$Arguments += "--unix2dos"}
        
        # Add the arguments, if any
        if($Params){$Arguments += "--",$Params}

        Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Executing a program now on VM <"+$VMIdentifier+">") -Level Verbose
        $ret = Invoke-Process -FilePath $script:VBOXManage -ProcessArguments $Arguments

        if($ret.ExitCode -eq 0)
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Sucessfully ran a program on <"+$VMIdentifier+">!") -Level Verbose
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ([string]::Concat("Received from STDOut: ",[Environment]::NewLine,$ret.stdout)) -Level Verbose -Indent 4
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ([string]::Concat("Received from STDErr: ",[Environment]::NewLine,$ret.stderr)) -Level Verbose -Indent 4
            if($PassThru){return $ret}
        }
        else
        {
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ("Unable to run or finish the program on <"+$VMIdentifier+">!") -Level Warning
            Write-VBox4PwshLog -VM $VMIdentifier -Component $Component -Message ([string]::Concat("Received from STDOut: ",[Environment]::NewLine,$ret.stdout)) -Level Verbose -Indent 4
            throw $ret.stderr
        }
    }
}
