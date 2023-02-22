echo ^
@"
echo off
cls
type "%0" > "%temp%\%~n0.ps1"
set no-output=2^>nul ^>NUL

::if +%1+==++ goto :ERR
set no-output=2^>nul ^>NUL

conhost --headless  PowerShell.exe   -ExecutionPolicy Bypass -File %temp%\%~n0.ps1   -Verb runAs   
goto :end
:ERR
echo.
echo ERRORE: parametri non sei admin!
echo riesegui il programma come amministratore 
echo.
pause
exit /b
goto :end 

"@


    cls
     #Self-elevate the script if required
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
     if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
      $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
      Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
      Exit
     }
    }	
	
# La Directory da cui viene lanciato lo script
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition


function Set-ConsoleWindow
{
    param(
        [int]$Width,
        [int]$Height
    )


    $pshost = get-host
    $pswindow = $pshost.ui.rawui
    $pswindow.windowtitle = "My PowerShell Session"
    $pswindow.foregroundcolor = "Yellow"
    $pswindow.backgroundcolor = "Black"
    $newsize = $pswindow.windowsize
    $newsize.height = $Height
    $newsize.width = $Width
    $pswindow.windowsize = $newsize

    # da verificare -----------------------------------------------------------------
    $WindowSize = $Host.UI.RawUI.WindowSize
    $WindowSize.Width  = [Math]::Min($Width, $Host.UI.RawUI.BufferSize.Width)
    $WindowSize.Height = $Height

    try{
        $Host.UI.RawUI.WindowSize = $WindowSize
    }
    catch [System.Management.Automation.SetValueInvocationException] {
        $Maxvalue = ($_.Exception.Message |Select-String "\d+").Matches[0].Value
        $WindowSize.Height = $Maxvalue
        $Host.UI.RawUI.WindowSize = $WindowSize
    }
}

Function Get-infoPC {
	$bio = Get-WmiObject Win32_Bios            | Select-Object -ExcludeProperty __*  -Property name,description,manufacturer,serialnumber,version
	$cpu = Get-WmiObject Win32_Processor       | Select-Object -ExcludeProperty __*  -Property name,manufacturer,numberofcores,numberoflogicalprocessors,processorID,SocketDesignation,MaxClockSpeed,caption
	$pc  = Get-WmiObject Win32_ComputerSystem  | Select-Object -ExcludeProperty __*  -Property name,description,dnshostname,domain,workgroup,model,manufacturer,systemtype,numberofprocessors,numberoflogicalprocessors,TotalPhysicalMemory
	$os  = Get-WmiObject Win32_OperatingSystem | Select-Object -ExcludeProperty __*  -Property bootDevice,BuildNumber,Caption,CSDversion,istalldate,locale,osarchitecture,oslanguage,version,windowsdirectory
    $props = @{ 
                nome 		    =$pc.name	  			
                Tipo    	 	=$pc.description 
                DNShostname 	=$PC.DNShostname      
                Modello		    =$PC.Model     			
                Produttore 	    =$PC.manufacturer
                numCpu		    =$PC.manufacturer
                numCpuLogiche   =$PC.manufacturer
                Dominio 		=$PC.domain  			
                Workgroup		=$PC.workgroup
                BootDevice 	    =$os.bootDevice
                OS	 		    =$os.Caption
                architettura	=$os.osarchitecture
                OSver	 		=$os.Version
                windir 		    =$os.windowsdirectory
                ServicePack	    =$os.CSDversion
                OSbuild	 	    =$os.BuildNumber
                CPUname	 	    =$cpu.name
                CPUid		 	=$cpu.processorID
                CpuSocket	 	=$cpu.SocketDesignation
                CPUProduttore	=$cpu.manufacturer
                CPUclock		=$cpu.MaxClockSpeed
                BiosProduttore  =$bio.manufacturer
                BiosNumber	    =$bio.serialnumber
                BiosVer		    =$bio.version
                BiosName		=$bio.Name
               }
	$InfoPC = new-object psobject -Property $props
	return $infoPC
}
Function Get-Folder($initialDirectory, $Description) {
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowserDialog.RootFolder = 'MyComputer'
	$FolderBrowserDialog.Description = $Description
	
    if ($initialDirectory) { $FolderBrowserDialog.SelectedPath = $initialDirectory }
    $dr=$FolderBrowserDialog.ShowDialog()
	if ($dr -eq 'Cancel') {exit}
    return $FolderBrowserDialog.SelectedPath
	
}
function Info-form {
 param(
        $Caption,
        $DefaultDest
    )

Add-Type -AssemblyName System.Windows.Forms
$Form = New-Object system.Windows.Forms.Form
$Form.Text = $Caption
$Form.AutoSize = $True
$Form.AutoSizeMode = "GrowAndShrink"
# or GrowOnly
$Form.BackColor = "Lime"
# color names are static properties of System.Drawing.Color
# you can also use ARGB values, such as "#FFFFEBCD"
$Font = New-Object System.Drawing.Font("Courier new",12,[System.Drawing.FontStyle]::Italic)
# Font styles are: Regular, Bold, Italic, Underline, Strikeout
$Form.Font = $Font
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Folder destination: $DefaultDest"

$Label.Text = $Label.Text  + (((Get-infoPC).psobject.properties|select name,value) |out-string)
$Label.AutoSize = $True
$Form.Controls.Add($Label)
$Form.Show()
}

$separaXtipo='si'
Set-ConsoleWindow -Width 30 -Height 30
$infoPC= Get-infoPC
#visualizza le info pc
#$infopc
((Get-infoPC).psobject.properties|select name,value) | Format-wide -AutoSize



# genera id del pc
$IDdriversDelPC=("$($infoPC.Produttore)_$($infoPC.Modello)") -replace (' ','_')

#visualizza l'id generato
$IDdriversDelPC
$DestinationDriversPath= "c:\temp\$IDdriversDelPC"

#invoke-command  -Command {Info-form -Caption $IDdriversDelPC -defaultDest $DestinationDriversPath }


 
$DestinationDriversPath = (Get-Folder  -Description "Seleziona il Folder di destinazione`n ID modello PC: $IDdriversDelPC")+"\$IDdriversDelPC"

if (-not (Test-Path $DestinationDriversPath)) {mkdir $DestinationDriversPath }
echo "Destination Driver path: $DestinationDriversPath"

#con win 11 il comando ha smesso di funzionare !!
#export-WindowsDriver -Online -Destination $DestinationDriversPath
# rimane dism ...
dism /online /export-driver /destination:$DestinationDriversPath
"attendere prego. divido i drivers per tipologia"
$DD=Get-WindowsDriver -online|select OriginalFileName,Driver,classname, providername,catalogfile, classdescription,version
#|Export-Csv -Delimiter ';'-NoTypeInformation "$DestinationDriversPath\infodriver.txt" 
#Get-WindowsDriver -online|select *|Export-Csv -NoTypeInformation "$DestinationDriversPath\infodrivers.txt" -s
$DD |
   select OriginalFileName,Driver,classname, providername,catalogfile, classdescription,version |
        Export-Csv -NoTypeInformation "$DestinationDriversPath\infodriver.txt" -Delimiter ';'
# Separa per tipologia di driver
if ($separaXtipo -eq 'si') {
    $DD|%  { 
                if (! ( Test-Path "$DestinationDriversPath\$($_.className)"))  { mkdir "$DestinationDriversPath\$($_.className)"}
                $oName=$_.OriginalFileName  -split '\\'
                $SourceFolder="$DestinationDriversPath\$($oName[-2])"
                $finalDestination="$DestinationDriversPath\$($_.className)"
                echo "$SourceFolder $finalDestination"
                move "$SourceFolder"  "$finalDestination" -force
            }
}



start $DestinationDriversPath
#cmd.exe /c pause
echo `
:end
