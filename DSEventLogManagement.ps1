function Get-DSEventlogConfiguration {
    <#
   .Synopsis
    Gets the EventLogConfiguration the specified EventLog in XML
   .Example
    Get-DSEventLogConfiguration -EventLogName ForwardedEvents
    Gets the XML Configuration from the ForwardedEvents Log
   .Parameter EventLogName
    The name of the EventLog
   .Notes
    Name:       Get-DSEventLogConfiguration
    Author:     Tom Stryhn (@dotStryhn)
   .Link 
    https://github.com/dotStryhn/DSEventLogManagement
    http://dotstryhn.dk
    #> 

    [CmdletBinding()]
    [OutputType([XML])]
    param(
        [Parameter(Mandatory = $true, Position = 0)][string]$EventLogName
    )

    "Trying to retrieve System Configuration" | Write-Verbose
    #Creating a Process to get information from the execution
    $GetLogConfProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $GetLogConfProcessInfo.FileName = "wevtutil.exe"
    $GetLogConfProcessInfo.RedirectStandardError = $true
    $GetLogConfProcessInfo.RedirectStandardOutput = $true
    $GetLogConfProcessInfo.UseShellExecute = $false
    $GetLogConfProcessInfo.Arguments = "gl $($EventLogName) /f:xml"
    $TryProcess = New-Object System.Diagnostics.Process
    $TryProcess.StartInfo = $GetLogConfProcessInfo
    $TryProcess.Start() | Out-Null
    $TryProcess.WaitForExit()

    # Using Exitcodes for "Errorhandling"
    if ($TryProcess.ExitCode -eq 0) {
        # Ran without Errors
        [XML]$EventLogConfiguration = $TryProcess.StandardOutput.ReadToEnd()
        "EventLog: [$EventLogName] Exists" | Write-Verbose
        "System Configuration retrieved`n" | Write-Verbose
        $EventLogConfiguration
    }
    elseif ($TryProcess.ExitCode -eq 5) {
        # EventLog: Access Denied
        "EventLog: [$EventLogName] Access Denied`n" | Write-Verbose
        "Nothing returned`n" | Write-Verbose
    }
    elseif ($TryProcess.ExitCode -eq 15007) {
        # EventLog: Not Found
        "EventLog: [$EventLogName] Not Found`n" | Write-Verbose
        "Nothing returned`n" | Write-Verbose
    }
    else {
        # Unhandled Exitcodes
        $TryProcess.StandardError.ReadToEnd() | Write-Verbose
        Throw 'Error getting Configuration'
    }
}

function Test-DSEventlogConfiguration {
    <#
   .Synopsis
    Tests a given EventLogConfiguration from a Pipeline, XML or Parameter
   .Example
    C:\Configs\Application-Std-Cfg.xml | Test-DSEventlogConfiguration
    Tests the Configuration against the saved XML-configuration in the Application-Std-Cfg.xml
   .Example
    Test-DSEventlogConfiguration -EventLogName ForwardedEvents -AutoBackup $true -Retention $false
    Tests the Forwarded EventLogConfiguration against the given arguments
   .Parameter XMLPath
    The XML-file path
   .Parameter EventLogName
    Name of the EventLog
   .Parameter EventLogPath
    The path to the EventLogFile (.evtx)
   .Parameter AutoBackup
    AutoBackup? $True or $False
   .Parameter Retention
    Retention? $True or $False
   .Parameter MaxLogSize
    The MaxLogFile size, ie. 10485760 or 10mb
   .Parameter EventLogEnabled
    EventLogEnabled? $True or $False
   .Notes
    Name:       Get-DSEventlogConfigurationToXML
    Author:     Tom Stryhn (@dotStryhn)
   .Link 
    https://github.com/dotStryhn/DSEventLogManagement
    http://dotstryhn.dk
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline', DontShow)][XML]$XMLInput,
        [ValidateScript( {Test-path -Path $_ -PathType Leaf})]
        [Parameter(Position = 0, ParameterSetName = 'FromXML')][String]$XMLPath,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'FromARG')][String]$EventLogName,
        [Parameter(ParameterSetName = 'FromARG')][string]$EventLogPath = "",
        [Parameter(ParameterSetName = 'FromARG')][bool]$AutoBackup = $false,
        [Parameter(ParameterSetName = 'FromARG')][bool]$Retention = $false,
        [Parameter(ParameterSetName = 'FromARG')][int]$MaxLogSize,
        [Parameter(ParameterSetName = 'FromARG')][bool]$EventLogEnabled = $true
    )

    switch ($PSCmdlet.ParameterSetName) {
        "FromXML" {
            "Running with XML Parameterset`n" | Write-Verbose
            try {
                "Loading Desired Configuration '$XMLPath'" | Write-Verbose
                [XML]$XMLInput = Get-Content $XMLPath
            }
            catch {
                throw "Error loading file as XML"
            }
            "Desired Configuration Loaded`n" | Write-Verbose
        }
        "FromARG" {
            "Running with Arguments Parameterset`n" | Write-Verbose
            # Checks for Arguments used in the Commandline and setting them to comparable values
            if ($PSBoundParameters.ContainsKey('AutoBackup')) { if ($AutoBackup -eq $true ) { $AutoBackupCheck = "true" } else { $AutoBackupCheck = 'false' } }
            if ($PSBoundParameters.ContainsKey('Retention')) { if ($Retention -eq $true) { $RetentionCheck = "true" } else { $RetentionCheck = 'false' } }
            if ($PSBoundParameters.ContainsKey('EventLogEnabled')) { if ($EventLogEnabled -eq $true) { $EnabledCheck = "true" } else { $EnabledCheck = 'false' } }
        }
    }

    # Gets the values from XML-file
    if ($XMLInput) {
        $EventLogName = $XMLInput.channel.name
        $EventLogPath = $XMLInput.channel.logging.logFileName
        $AutoBackupCheck = $XMLInput.channel.logging.autoBackup
        $RetentionCheck = $XMLInput.channel.logging.retention
        $MaxLogSize = $XMLInput.channel.logging.maxSize
        $EnabledCheck = $XMLInput.channel.enabled
    }

    # Setting Controlvalues
    $Found = $true
    $Access = $true
    $Compliance = $true

    "Trying to retrieve System Configuration" | Write-Verbose
    # Creating a Process to get information from the execution
    $GetLogConfProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $GetLogConfProcessInfo.FileName = "wevtutil.exe"
    $GetLogConfProcessInfo.RedirectStandardError = $true
    $GetLogConfProcessInfo.RedirectStandardOutput = $true
    $GetLogConfProcessInfo.UseShellExecute = $false
    $GetLogConfProcessInfo.Arguments = "gl $($EventLogName) /f:xml"
    $TryProcess = New-Object System.Diagnostics.Process
    $TryProcess.StartInfo = $GetLogConfProcessInfo
    $TryProcess.Start() | Out-Null
    $TryProcess.WaitForExit()

    # Using Exitcodes for "Errorhandling"
    if ($TryProcess.ExitCode -eq 0) {
        # Ran without Errors
        [XML]$CurrentConfiguration = $TryProcess.StandardOutput.ReadToEnd()
        "EventLog: [$EventLogName] Exists" | Write-Verbose
        "System Configuration retrieved`n" | Write-Verbose
    }
    elseif ($TryProcess.ExitCode -eq 5) {
        # EventLog: Access Denied
        "EventLog: [$EventLogName] Access Denied`n" | Write-Verbose
        $Found = $true
        $Access = $false
    }
    elseif ($TryProcess.ExitCode -eq 15007) {
        # EventLog: Not Found
        "EventLog: [$EventLogName] Not Found`n" | Write-Verbose
        $Access = $false
        $Found = $false
        $Compliance = $Compliance -and $false
    }
    else {
        # Unhandled Exitcodes
        $TryProcess.StandardError.ReadToEnd() | Write-Verbose
        Throw 'Error getting Configuration'
    }

    if (($MaxLogSize -eq "") -and ($EventLogPath -eq "") -and (-not($RetentionCheck)) -and (-not($AutoBackupCheck)) -and (-not($EnabledCheck)) -and ($Found -eq $true) -and ($Access -eq $false)) {
        "Nothing to Validate - Confirming Existence`n" | Write-Verbose
    }
    else {
        if (($Found -eq $true) -and ($Access -eq $true)) {
            "Validation  Setting" | Write-Verbose
            if ($EnabledCheck) {
                if ((-not($AutoBackupCheck)) -and (-not($RetentionCheck)) -and ($EventLogPath -eq "") -and ($MaxLogSize -eq "")) {
                    $LastLine = "`n"
                }
                else {
                    $LastLine = ""
                }

                if ($EnabledCheck -eq $CurrentConfiguration.channel.enabled) {
                    $Compliance = $Compliance -and $true
                    "    OK      Enabled    | System: $($CurrentConfiguration.channel.enabled)$LastLine" | Write-Verbose
                }
                else {
                    $Compliance = $Compliance -and $false
                    $Spacing = ""
                    $i = 0
                    "[MISMATCH]  Enabled    | System: $($CurrentConfiguration.channel.enabled)$(while($i -le (($CurrentConfiguration.channel.logging.logFileName).Length - $($CurrentConfiguration.channel.enabled).Length)) { $Spacing += " "; $i++ })$Spacing| Desired: $EnabledCheck$LastLine" | Write-Verbose
                }
            }
        
            if ($AutoBackupCheck) {
                if (($MaxLogSize -eq "") -and ($EventLogPath -eq "") -and (-not($RetentionCheck))) {
                    $LastLine = "`n"
                }
                else {
                    $LastLine = ""
                }

                if ($AutoBackupCheck -eq $CurrentConfiguration.channel.logging.autoBackup) {
                    $Compliance = $Compliance -and $true
                    "    OK      AutoBackup | System: $AutoBackupCheck$LastLine" | Write-Verbose
                }
                else {
                    $Compliance = $Compliance -and $false
                    $Spacing = ""
                    $i = 0
                    "[MISMATCH]  AutoBackup | System: $($CurrentConfiguration.channel.logging.autoBackup)$(while($i -le (($CurrentConfiguration.channel.logging.logFileName).Length - $($CurrentConfiguration.channel.logging.autoBackup).Length)) { $Spacing += " "; $i++ })$Spacing| Desired: $AutoBackupCheck$LastLine" | Write-Verbose
                }
            }
            
            if ($RetentionCheck) {
                if (($MaxLogSize -eq "") -and ($EventLogPath -eq "")) {
                    $LastLine = "`n"
                }
                else {
                    $LastLine = ""
                }

                if ($RetentionCheck -eq $CurrentConfiguration.channel.logging.retention) {
                    $Compliance = $Compliance -and $true
                    "    OK      Retention  | System: $RetentionCheck$LastLine" | Write-Verbose
                }
                else {
                    $Compliance = $Compliance -and $false
                    $Spacing = ""
                    $i = 0
                    "[MISMATCH]  Retention  | System: $($CurrentConfiguration.channel.logging.retention)$(while($i -le (($CurrentConfiguration.channel.logging.logFileName).Length - $($CurrentConfiguration.channel.logging.retention).Length)) { $Spacing += " "; $i++ })$Spacing| Desired: $RetentionCheck$LastLine" | Write-Verbose
                }
            }
        
            if ($EventLogPath -ne "") {
                if ($MaxLogSize -eq "") {
                    $LastLine = "`n"
                }
                else {
                    $LastLine = ""
                }

                if ($EventLogPath -eq $CurrentConfiguration.channel.logging.logFileName) {
                    $Compliance = $Compliance -and $true
                    "    OK      LogPath    | System: $EventLogPath$LastLine" | Write-Verbose
                }
                else {
                    $Compliance = $Compliance -and $false
                    "[MISMATCH]  LogPath    | System: $($CurrentConfiguration.channel.logging.logFileName) | Desired: $EventLogPath$LastLine" | Write-Verbose
                }
            }
            
            if ($MaxLogSize -ne "") {
                if ($MaxLogSize -eq $CurrentConfiguration.channel.logging.maxSize) {
                    $Compliance = $Compliance -and $true
                    "    OK      MaxLogSize | System: $MaxLogSize`n" | Write-Verbose
                }
                else {
                    $Compliance = $Compliance -and $false
                    $Spacing = ""
                    $i = 0
                    "[MISMATCH]  MaxLogSize | System: $($CurrentConfiguration.channel.logging.maxSize)$(while($i -le (($CurrentConfiguration.channel.logging.logFileName).Length - $($CurrentConfiguration.channel.logging.maxSize).Length)) { $Spacing += " "; $i++ })$Spacing| Desired: $MaxLogSize`n" | Write-Verbose
                }
            }
        }
        elseif (($Access -eq $false) -and ($Found -eq $true)) {
            "[ERROR] Unable to Validate without Access" | Write-Verbose
            $Compliance = $Compliance -and $false
        }
    }
    "Validation Returning: $Compliance" | Write-Verbose
    $Compliance
}

function Save-DSEventlogConfigurationToXML {
    <#
   .Synopsis
    Saves the EventLogConfiguration XML from pipeline to a specified file
   .Example
    Get-DSEventLogConfiguration -EventLogName ForwardedEvents | Save-DSEventLogConfigurationToXML -Path C:\Temp\ForwardedEvents.xml
    Saves the EventLogConfiguration from the Get-DSEventLogConfiguration function
   .Parameter Path
    The path to save the XML-file
   .Notes
    Name:       Get-DSEventlogConfigurationToXML
    Author:     Tom Stryhn (@dotStryhn)
   .Link 
    https://github.com/dotStryhn/DSEventLogManagement
    http://dotstryhn.dk
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true, DontShow)][XML]$EventlogConfiguration,
        [Parameter(Mandatory = $true, Position = 0)][string]$Path
    )
    
    # Checks for publishingchannel and removes it, since it will generate an error when importing
    if ($EventlogConfiguration.channel.publishing) {
        $EventlogConfiguration.channel.RemoveChild($EventlogConfiguration.channel.publishing) | Out-Null
    }

    $EventlogConfiguration.Save($Path)
}