# Resolve the path to VBOXManage Executable
[string] $script:VBOXManage = $(
    if($IsWindows)
    {
        $WindowsBase = [System.IO.Path]::Combine("Oracle","VirtualBox","VBoxManage.exe")
        #Check Programfiles Directory
        if([System.IO.File]::Exists([System.IO.Path]::Combine($env:ProgramFiles,$WindowsBase))){[System.IO.Path]::Combine($env:ProgramFiles,$WindowsBase)}
        # if not exists, try Programfiles X86
        elseif([System.IO.File]::Exists([System.IO.Path]::Combine(${env:ProgramFiles(x86)},$WindowsBase))){[System.IO.Path]::Combine(${env:ProgramFiles(x86)},$WindowsBase)}
        # if not exists, try ProgramData
        elseif([System.IO.File]::Exists([System.IO.Path]::Combine($env:ProgramData,$WindowsBase))){[System.IO.Path]::Combine($env:ProgramData,$WindowsBase)}
        # if not exists, check the LOCALAPPDATA folder of the user
        elseif([System.IO.File]::Exists([System.IO.Path]::Combine($env:LOCALAPPDATA,$WindowsBase))){[System.IO.Path]::Combine($env:LOCALAPPDATA,$WindowsBase)}
        # if not exists, check TEMP folder of user
        elseif([System.IO.File]::Exists([System.IO.Path]::Combine($env:TEMP,$WindowsBase))){[System.IO.Path]::Combine($env:LOCALAPPDATA,$WindowsBase)}
        # Could not find something.. This needs to break!
        else{[string]::Empty}
    }
    elseif ($IsLinux)
    {
        # Check if 'vboxmanage' is already in path
        try
        {
            $test = Start-Process -FilePath "vboxmanage" -ArgumentList "--version" -Wait -PassThru -RedirectStandardOutput "/dev/null"
            if($test.ExitCode -eq 0)
            {
                # 'vboxmanage' has been succesfully invoked and can be used!
                "vboxmanage"
            }
        }
        catch
        {
            Write-Warning ("Unable to find 'vboxmanage' on this System! Please make sure that it is part of 'PATH'!")
        }

    }
)
if([string]::IsNullOrEmpty($script:VBOXManage))
{
    Write-Warning ("Unable to find 'vboxmanage' on this System! Please make sure that it is part of 'PATH'!")
    Write-Error ("Without 'vboxmange' this module makes no sense! Stopping here.")
    break
}

function Invoke-Process
{
<#
    .SYNOPSIS
        Helper function to create and run processes. Also fetches STDOut and STDErr in a convenient way.

    .DESCRIPTION

    .EXAMPLE
#>
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $FilePath,

    [Parameter()]
    [string[]]
    $ProcessArguments
)

    # Temporarely set ErrorActionPreference to STOP
    $ErrPref = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    # for the logging function
    $Component = "Invoke-Process"

    Write-VBox4PwshLog -Component $Component -Message ("Path: <"+$FilePath+">") -Level Verbose
    Write-VBox4PwshLog -Component $Component -Message ("Arguments <"+$ProcessArguments+">") -Level Verbose

    $stdout=@()
    $stderr=@()

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $FilePath
    $pinfo.CreateNoWindow = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $ProcessArguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo

    try
    { 
        $starttime = [datetime]::Now
        $null = $p.Start()

        #$p.WaitForExit()
        while (-not $p.HasExited) {
            if(-not $p.StandardOutput.EndOfStream){$stdout += $p.StandardOutput.ReadLine()}
        }

        $stdout += $p.StandardOutput.ReadToEnd()
        $stderr += $p.StandardError.ReadToEnd()

        $ret = [pscustomobject]@{
            stdout = $stdout -join [System.Environment]::NewLine
            stderr = $stderr -join [System.Environment]::NewLine
            ExitCode = $p.ExitCode
            Runtime = ([datetime]::Now - $starttime).ToString("G")
        }

        # Just in case there are leftovers, kill em all!
        $null = Stop-Process -Id $p.Id -Force -ErrorAction Ignore
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        Write-VBox4PwshLog -Component $Component -Message ("Unable to start the Process!") -Level Warning
        Write-VBox4PwshLog -Component $Component -Message ([String]::Concat("Errormessage: ",$Error[0].Exception.Message,[Environment]::NewLine,"Errortype: ",$_.Exception.GetType().FullName)) -Level Error -Indent 4
        $ret = $null
    }
    catch 
    {
        Write-VBox4PwshLog -Component $Component -Message ("Unable to start the Process!") -Level Warning
        Write-VBox4PwshLog -Component $Component -Message ([String]::Concat("Errormessage: ",$Error[0].Exception.Message,[Environment]::NewLine,"Errortype: ",$_.Exception.GetType().FullName)) -Level Error -Indent 4
        $ret = $null
    }

    # Reset ErroractionPreference
    $ErrorActionPreference = $ErrPref
    
    return $ret
}

function Write-VBox4PwshLog
{
<#
    # This function includes code taken from the function "Write-Log" from Github Repo: https://github.com/microsoft/PowerShellForGitHub
    # Permalink to function: https://github.com/microsoft/PowerShellForGitHub/blob/f7efc4a03640cf292b0e6a256d6713a6f15145b2/Helpers.ps1#L41
    .SYNOPSIS
        Writes logging information to screen and log file simultaneously.
    .DESCRIPTION
        Writes logging information to screen and log file simultaneously.
    .PARAMETER Message
        The message(s) to be logged. Each element of the array will be written to a separate line.
        This parameter supports pipelining but there are no
        performance benefits to doing so. For more information, see the .NOTES for this
        cmdlet.
    .PARAMETER Level
        The type of message to be logged.
    .PARAMETER Indent
        The number of spaces to indent the line in the log file.
    .PARAMETER Path
        The log file path.
        Defaults to $env:USERPROFILE\Documents\PowerShellForGitHub.log
    .PARAMETER Exception
        If present, the exception information will be logged after the messages provided.
        The actual string that is logged is obtained by passing this object to Out-String.
    .EXAMPLE
        Write-Log -Message "Everything worked." -Path C:\Debug.log
        Writes the message "Everything worked." to the screen as well as to a log file at "c:\Debug.log",
        with the caller's username and a date/time stamp prepended to the message.
    .EXAMPLE
        Write-Log -Message ("Everything worked.", "No cause for alarm.") -Path C:\Debug.log
        Writes the following message to the screen as well as to a log file at "c:\Debug.log",
        with the caller's username and a date/time stamp prepended to the message:
        Everything worked.
        No cause for alarm.
    .EXAMPLE
        Write-Log -Message "There may be a problem..." -Level Warning -Indent 2
        Writes the message "There may be a problem..." to the warning pipeline indented two spaces,
        as well as to the default log file with the caller's username and a date/time stamp
        prepended to the message.
    .EXAMPLE
        try { $null.Do() }
        catch { Write-Log -Message ("There was a problem.", "Here is the exception information:") -Exception $_ -Level Error }
        Logs the message:
        Write-Log : 2018-01-23 12:57:37 : dabelc : There was a problem.
        Here is the exception information:
        You cannot call a method on a null-valued expression.
        At line:1 char:7
        + try { $null.Do() } catch { Write-Log -Message ("There was a problem." ...
        +       ~~~~~~~~~~
            + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
            + FullyQualifiedErrorId : InvokeMethodOnNull
    .INPUTS
        System.String
    .NOTES
        The "LogPath" configuration value indicates where the log file will be created.
        The "" determines if log entries will be made to the log file.
           If $false, log entries will ONLY go to the relevant output pipeline.
        Note that, although this function supports pipeline input to the -Message parameter,
        there is NO performance benefit to using the pipeline. This is because the pipeline
        input is simply accumulated and not acted upon until all input has been received.
        This behavior is intentional, in order for a statement like:
            "Multiple", "messages" | Write-Log -Exception $ex -Level Error
        to make sense.  In this case, the cmdlet should accumulate the messages and, at the end,
        include the exception information.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Justification="We need to be able to access the PID for logging purposes, and it is accessed via a global variable.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidOverwritingBuiltInCmdlets", "", Justification="Write-Log is an internal function being incorrectly exported by PSDesiredStateConfiguration.  See PowerShell/PowerShell#7209")]
    param(
        [Parameter(ValueFromPipeline)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]] $Message = @(),

        [ValidateSet('Error', 'Warning', 'Informational', 'Verbose', 'Debug')]
        [string] $Level = 'Informational',

        [string] $Component,

        [string] $VM,

        [ValidateRange(1, 30)]
        [Int16] $Indent = 0,

        [System.Management.Automation.ErrorRecord] $Exception
    )

    begin
    {
        # If no path has been specified through ENV var, use the %temp% directory
        # On Linux: /tmp
        # On windows: C:\users\$USER$\appdata\local\temp
        if($null -eq $env:VBOX4PWSHLogfilePath){$env:VBOX4PWSHLogfilePath = [System.IO.Path]::Combine(([System.IO.Path]::GetTempPath()),"VBox4Pwsh.log")}

        # [OPTIONAL TODO]: i do not care whether a Directory or file has been provided. If the provided path is "C:\Mydir" or "/tmp/log", the resulting filenames will be "Mydir" or "log"
        #   At this moment there is no "cool way" to check the path before it has actually been created 
        #   "Test-Path -Path "/blah" -PathType Container -IsValid is not implemented correctly. Refer to: https://github.com/PowerShell/PowerShell/issues/8607
        
        # Now check if the path is existing. If not, create it!
        if(-not (Test-Path -Path $env:VBOX4PWSHLogfilePath -PathType Leaf)){$null = New-Item -Path $env:VBOX4PWSHLogfilePath -ItemType File -Force}
        
        # Accumulate the list of Messages, whether by pipeline or parameter.
        $messages = @()
    }

    process
    {
        foreach ($m in $Message)
        {
            $messages += $m
        }
    }

    end
    {
        if ($null -ne $Exception)
        {
            # If we have an exception, add it after the accumulated messages.
            $messages += Out-String -InputObject $Exception
        }
        elseif ($messages.Count -eq 0)
        {
            # If no exception and no messages, we should early return.
            return
        }

        # Finalize the string to be logged.
        $finalMessage = $messages -join [Environment]::NewLine

        # Build the console and log-specific messages. Always LocalTime
        $dateString = ([DateTime]::Now).ToString("yyyy-MM-dd HH:mm:ssZ")

        $consoleMessage = '{0}{1}' -f
            (" " * $Indent),
            $finalMessage

        $logFileMessage = '{0}{1} : {2} : {3} : {4} : {5}' -f
        (" " * $Indent),
        $dateString,
        $Component,
        $VM,
        $Level.ToUpper(),
        $finalMessage

        # Write the message to screen/log.
        # Note that the below logic could easily be moved to a separate helper function, but a conscious
        # decision was made to leave it here. When this cmdlet is called with -Level Error, Write-Error
        # will generate a WriteErrorException with the origin being Write-Log. If this call is moved to
        # a helper function, the origin of the WriteErrorException will be the helper function, which
        # could confuse an end user.
        switch ($Level)
        {
            # Need to explicitly say SilentlyContinue here so that we continue on, given that
            # we've assigned a script-level ErrorActionPreference of "Stop" for the module.
            'Error'   { Write-Error $consoleMessage -ErrorAction SilentlyContinue }
            'Warning' { Write-Warning $consoleMessage }
            'Verbose' { Write-Verbose $consoleMessage }
            'Debug'   { Write-Debug $consoleMessage }
            'Informational'    {
                # We'd prefer to use Write-Information to enable users to redirect that pipe if
                # they want, unfortunately it's only available on v5 and above.  We'll fallback to
                # using Write-Host for earlier versions (since we still need to support v4).
                if ($PSVersionTable.PSVersion.Major -ge 5)
                {
                    Write-Information $consoleMessage -InformationAction Continue
                }
                else
                {
                    Write-InteractiveHost $consoleMessage
                }
            }
        }

        try
        {
            if ([String]::IsNullOrWhiteSpace($env:VBOX4PWSHLogfilePath))
            {
                Write-Warning 'The log-path has not been specified!'
            }
            else
            {
                $logFileMessage | Out-File -FilePath $env:VBOX4PWSHLogfilePath -Append -WhatIf:$false -Confirm:$false
            }
        }
        catch
        {
            $output = @()
            $output += "Failed to add log entry to [$env:VBOX4PWSHLogfilePath]. The error was:"
            $output += Out-String -InputObject $_

            if (Test-Path -Path $env:VBOX4PWSHLogfilePath -PathType Leaf)
            {
                # The file exists, but likely is being held open by another process.
                # Let's do best effort here and if we can't log something, just report
                # it and move on.
                $output += "This is non-fatal, and your command will continue.  Your log file will be missing this entry:"
                $output += $consoleMessage
                Write-Warning ($output -join [Environment]::NewLine)
            }
            else
            {
                # If the file doesn't exist and couldn't be created, it likely will never
                # be valid.  In that instance, let's stop everything so that the user can
                # fix the problem, since they have indicated that they want this logging to
                # occur.
                throw ($output -join [Environment]::NewLine)
            }
        }
    }
}