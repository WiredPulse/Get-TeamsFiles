<#
    .SYNOPSIS
        Script to download the files that you've uploaded to Microsoft Teams.
    
    .PARAMETER user
        Used to supply your user

    .PARAMETER url
        Used to supply the URL to your person OneDrive space in your Tenant's instance. By navigating to https://onedrive.live.com/about/en-us/signin and
        logging, in you can quickly retrieve the URL. 

    .PARAMETER destination
        Used to supply the destination to download the files to

    .EXAMPLE
        PS C:\> .\Get-TeamsFiles.ps1 -user "nandy.nan" -url "https://something-my.sharepoint.com/personal/" -destination "c:\downloadedFiles"

        Executes the script against "https://something-my.sharepoint.com/personal/" with the user "nandy-nan" and downloads the files to "c:\downloadedFiles" on the local machine
#>

[CmdletBinding()]
param(
       $user,
       $url,
       $destination
)

if(-not(get-module -Name PnP.PowerShell)){
    Install-Module -Name PnP.PowerShell
}
if(-not(get-module -Name PnP.PowerShell)){
    Write-Host -ForegroundColor red "Error: Can't install PnP module, check organization security policy or Internet connection"
    pause
    break
} 
$user = $user.Replace(".","_").Replace("@","_")
if($url[-1] -ne "\" -or $url[-1] -ne "/"){
    $url = $url + "\"
} 
$url = $url + $user
$listUrl = "Documents"
Connect-PnPOnline -url $url -UseWebLogin -ForceAuthentication -WarningAction SilentlyContinue
$web = Get-PnPWeb
$list = Get-PNPList -Identity $listUrl
 
function folder($folderUrl, $destinationFolder) {
    $folder = Get-PnPFolder -RelativeUrl $folderUrl
    $tempfiles = Get-PnPProperty -ClientObject $folder -Property Files
   
    if (!(Test-Path -path $destinationfolder)) {
        $dest = New-Item $destinationfolder -type directory 
    }
 
    $total = $folder.Files.Count
    Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Preparing to download contents of the " -NoNewline; Write-Host -ForegroundColor yellow "$($folder.name)" -NoNewline; write-host -ForegroundColor green " folder to" -NoNewline; Write-Host -ForegroundColor Yellow " $($destination)"
    Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Yellow "$($folder.name)" -NoNewline; Write-Host -ForegroundColor Green " directory contains " -NoNewline; Write-Host -ForegroundColor Yellow "$($total) " -NoNewline; Write-Host -ForegroundColor Green "files"
    Start-Sleep 2
    For ($i = 0; $i -lt $total; $i++) {
        $file = $folder.Files
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Downloading $($file.Name[$i])"
        Get-PnPFile -ServerRelativeUrl $file[$i].ServerRelativeUrl -Path $destinationfolder -FileName $file[$i].Name -AsFile
    }
}
 
function subfolders($folders, $currentPath) {
    foreach ($folder in $folders) {
        $tempurls = Get-PnPProperty -ClientObject $folder -Property ServerRelativeUrl    
        if ($folder.Name -ne "Forms") {
            $targetFolder = $currentPath + "\" + $folder.Name
            folder $folder.ServerRelativeUrl.Substring($web.ServerRelativeUrl.Length) $targetFolder 
            $tempfolders = Get-PnPProperty -ClientObject $folder -Property Folders
            # Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Processing folder: " $folder.Name " .. at " $currentPath
            subfolders $tempfolders $targetFolder
        }
    }
}
 
folder $listUrl $destination + "\" 
$tempfolders = Get-PnPProperty -ClientObject $list.RootFolder -Property Folders
subfolders $tempfolders $destination + "\"
