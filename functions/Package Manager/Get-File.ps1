<#
$Metadata = @{
	Title = "Get File"
	Filename = "Get-File.ps1"
	Description = ""
	Tags = ""
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "http://janikvonrotz.ch"
	CreateDate = "2014-02-05"
	LastEditDate = "2014-02-05"
	Url = ""
	Version = "0.0.0"
	License = @'
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Switzerland License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ch/ or 
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}
#>

function Get-File{

<#
.SYNOPSIS
    Download file from url.

.DESCRIPTION
	Download file from url.

.PARAMETER Url
	Source url of the file.

.PARAMETER Path
	Local file path to save the file. Default is source file and and current location.

.EXAMPLE
	PS C:\> Get-File -Url "http://www.domain.com/download/file.exe" -Path "file.exe"
#>

    [CmdletBinding()]
    param(

		[Parameter( Mandatory=$true)]
		[String]
		$Url,

		[Parameter( Mandatory=$false)]
		[String]
		$Path,
        
        [Switch]
        $Force
	)
    
    #--------------------------------------------------#
    # main
    #--------------------------------------------------#
 
    begin {
    
        $WebClient = New-Object System.Net.WebClient
        $Global:DownloadComplete = $false
     
        $eventDataComplete = Register-ObjectEvent $WebClient DownloadFileCompleted `
            -SourceIdentifier WebClient.DownloadFileComplete `
            -Action {$Global:DownloadComplete = $true}
            
        $eventDataProgress = Register-ObjectEvent $WebClient DownloadProgressChanged `
            -SourceIdentifier WebClient.DownloadProgressChanged `
            -Action { $Global:DPCEventArgs = $EventArgs }    
    } 
       
    process{
    
        $PathAndFilename = Get-PathAndFilename $Path
    
        if(-not $PathAndFilename.Filename){$PathAndFilename.Filename = (Split-Path ([uri]$Url).LocalPath -Leaf)}
        if(-not $PathAndFilename.Path){$PathAndFilename.Path = (Get-Location).Path}
        if(-not (Test-Path $PathAndFilename.Path)){New-Item -Path $PathAndFilename.Path -ItemType Directory}
        $Path = Join-Path $PathAndFilename.Path ($PathAndFilename.Filename)
        
        Write-Progress -Activity "Downloading file" -Status $Url
        
        $WebClient.DownloadFileAsync($Url, $Path)
       
        while (!($Global:DownloadComplete)) {                
            $ProgressPercentage = $Global:DPCEventArgs.ProgressPercentage
            if ($ProgressPercentage -ne $null) {
                Write-Progress -Activity "Downloading file" -Status $Url -PercentComplete $ProgressPercentage
            }
        }
       
        Write-Progress -Activity "Downloading file" -Status $Url -Complete
        
        $PathAndFilename
    }   
      
    end{
    
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete
        $WebClient.Dispose()
        $Global:DownloadComplete = $null
        $Global:DPCEventArgs = $null
        Remove-Variable WebClient
        Remove-Variable eventDataComplete
        Remove-Variable eventDataProgress
        [GC]::Collect()    
    }  
}  