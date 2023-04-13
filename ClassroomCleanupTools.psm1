function Remove-BrowserCache {
  <#
  .SYNOPSIS
    This will remove internet browers' cached user data
  .DESCRIPTION
    This script removes all of the user data stored by the browser/s, It first needs
    to stop all of the current browser processes before it can remove the user data.
    It will then attempt to remove all of the user data from the chosen browser/s.
    This script will choose all four browsers if none are chosen from the BrowserType
    parameter.
  .Parameter BrowserType
    This parameter has four options Chrome, Firefox, Edge and IExplore. These can be entered
    as an array seperated by commas as per the examples in this help.
  .EXAMPLE
    Remove-BrowserCache
    Deletes the user data from Chrome, Firefox, Edge and IE (the default targets all four browsers)
  .EXAMPLE
    Remove-BrowserCache -BrowserType IExplore,Chrome
    Deletes the user data from Chrome and IE only
  .EXAMPLE
    Remove-BrowserCache -BrowserType Chrome
    Deletes the user data from Chrome only
  .EXAMPLE
    Remove-BrowserCache -BrowserType MsEdge
    Deletes the user data from Edge only    
  .NOTES
    General notes
    Created by: Brent Denny
    Created on: 9 Aug 2019
    Updated on: 13 Apr 2023

    Version:
    0.0.1 - 9 Aug 2019 - Initial version for trail
    1.0.0 - 13 Apr 2023 - Version that also incorporates Edge 
  #>
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
  Param(
    [ValidateSet('Chrome','FireFox','IExplore','MSEdge')]
    [string[]]$BrowserType = @('Chrome','FireFox','IExplore','MSEdge')
  )
  if ($PSCmdlet.ShouldProcess(($BrowserType -join ' and '), "Terminating processes")) {
    Write-Verbose 'Killing all current brower sessions, hopefully?'
    Get-Process | Where-Object {$_.ProcessName -in $BrowserType} | Stop-Process -Force
    $Counter = 0
    do {
      Start-Sleep -Seconds 1
      $Counter++
      $BrowserProcs = Get-Process | Where-Object {$_.ProcessName -in $BrowserType}
    } until ($BrowserProcs.Count -eq 0 -or $Counter -eq 20)
    if ($BrowserProcs.Count -ne 0) {
      Write-Warning "The selected browsers did not terminate in a timely fashion, `nplease close the browsers manually and re-run the script"
      break
    }
  }
  switch ($BrowserType) {
    {$_ -contains 'Chrome'} {
      if ($PSCmdlet.ShouldProcess('Chrome', "Delete User Data")) {
        $ChromePath = $env:LOCALAPPDATA + "\Google\Chrome\User Data\*"
        if (Test-Path ($env:LOCALAPPDATA + "\Google\Chrome\User Data")) {
          try {
            Write-Verbose 'Attempting to clear user data from Chrome'
            Remove-Item -Path $ChromePath -Recurse -Force -ErrorAction stop
          }
          catch {Write-Warning 'Cannot delete the Chrome user data'}
        }
        else {Write-Verbose 'No user data exists for the Chrome browser'}
      }
    }
    {$_ -contains 'Firefox'}  {
      if ($PSCmdlet.ShouldProcess('Firefox', "Delete User Data")) {
        if (Test-Path $env:APPDATA\Mozilla\Firefox\Profiles) {
          $FirefoxProfileFolders = (Get-ChildItem $env:APPDATA\Mozilla\Firefox\Profiles\ -Directory).FullName
          Try {
            Write-Verbose 'Attempting to clear user data from Chrome Firefox'
            foreach ($ProfDir in $FirefoxProfileFolders) {
              Remove-Item -Recurse -Force -Path $ProfDir\* -ErrorAction stop
            }
          }
          Catch {Write-Warning 'Cannot delete the Firefox user data'}
        }
        else {Write-Verbose 'No user data exists for the Firefox browser'}    
      }
    }
    {$_ -contains 'IExplore'} {
      if ($PSCmdlet.ShouldProcess('Internet Explorer', "Delete User Data")) {
        Write-Verbose 'Attempting to clear user data from Internet Explorer'
        invoke-command -ScriptBlock {RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 255}
      }
    }
    {$_ -contains 'MSEdge'} {
      if ($PSCmdlet.ShouldProcess('Edge', "Delete User Data")) {
        Write-Verbose 'Attempting to clear user data from Edge'
        try {
          if (Test-Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default") {
            Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" -Recurse -Force -ErrorAction Stop
          }
        }
        catch {Write-Warning 'Cannot delete the Edge user data'}
      }
    }    
    Default {Write-Warning 'Failed to clear user data, can only clear user data from Chrome, Firefox, Edge and Internet Explorer'}
  }
}
