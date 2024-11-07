Param(
    [String]$CommonName,
    [String]$CertThumbprint
)

function Install-SSRSCertificate
{
    [CmdletBinding()]
    Param
    (
        #Certificate CommonName 
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0)]
        [String]
        $CommonName,

        #Certificate Thumbprint 
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1)]
        [String]
        $CertThumbprint
    )

    Process
    {   
        #Directories
        $SSRSConfigFile = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\rsreportserver.config'
        $StorePath = "C:\Program Files\win-acme\Certificates\Temp"
        $Date = Get-Date -Format "MMyyyy"
        
        #Backup old SSRS Config File
        Copy-Item -LiteralPath $SSRSConfigFile -Destination "$StorePath\rsreportserver-$Date.config" -Recurse -Force -ErrorAction Stop
        Write-Host "Successfully backed up old SSRS config file."

        #Update rsreportserver.config file        
        $SSRSConfig = [XML](Get-Content -LiteralPath $SSRSConfigFile)
        $OldBindings = $SSRSConfig.Configuration.SSLCertificateConfiguration.Bindings.Binding
        ForEach($Binding in $OldBindings)
        {
            $Binding.CertificateHash = $CertThumbprint    
        }
        #$SSRSConfig.Save($SSRSConfigFile)


        #Removes Old Cert Binding
        netsh http delete sslcert ipport=0.0.0.0:443
        netsh http delete sslcert ipport=[::]:443

        #Adds New Cert Binding
        netsh http add sslcert ipport=0.0.0.0:443 certhash=$CertThumbprint appid='{1d40ebc7-1983-4ac5-82aa-1e17a7ae9a0e}'
        netsh http add sslcert ipport=[::]:443 certhash=$CertThumbprint appid='{1d40ebc7-1983-4ac5-82aa-1e17a7ae9a0e}'

        #Restart SSRS
        Write-Host "Restarting SSRS..."
        $Service = Get-Service -Name SQLServerReportingServices -ErrorAction Stop
        Stop-Service $Service
        Start-Service $Service
        $Service = Get-Service -Name SQLServerReportingServices -ErrorAction Stop
        Write-Host "SSRS is now $($Service.Status)"
    }
}
Install-SplunkAcmeCertificate -CommonName $CommonName -CertPassword $CertPassword -CertThumbprint $CertThumbprint