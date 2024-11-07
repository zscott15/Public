Param(
    [String]$CommonName,
    [String]$Thumbprint
)

function Install-IISAcmeCertificate
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

        #Certificate CommonName 
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1)]
        [String]
        $Thumbprint
    )

    Process
    {
        If ((Get-Module -ListAvailable -Name IISAdministration) -eq $null)
        {
            Install-Module -Name IISAdministration -Force -Scope CurrentUser
        }
        Else
        {
            Import-Module IISAdministration -ErrorAction SilentlyContinue
            Import-Module WebAdministration -ErrorAction SilentlyContinue
        }

        #Get Binding Information Relevant to Primary CommonName
        $Binding = Get-WebBinding | Where-Object {$_.protocol -eq 'https'}
        $BindInfo = $Binding.bindingInformation

        $BD = ForEach($Bind in $BindInfo)
        {
            #Object to store Bindings info
            class BindingInfo
            {
                [String]$SiteName
                [String]$IPAddress
                [Int]$Port
                [String]$Header
                [String]$Bind
            }    
            $sobj = [BindingInfo]::new()
            $sobj.IPAddress,$sobj.Port,$sobj.Header = $Bind.Split(':')
            $sobj.Bind = $Bind
            $sobj.SiteName = (Get-IISSite | Where-Object {$_.bindings.bindingInformation -eq $Bind}).Name

            #Added to provide SAN cert functionality. SAN Request format is comma separated. "<CommonName>, <CommonName>"
            If($CommonName -contains ',')
            {
                $CommonNames = ($CommonName.Split(',')).trim()
            }
            else
            {
                $CommonNames = $CommonName
            }

            ForEach ($CommonName in $CommonNames)
            {
                if ($sobj.header -eq $CommonName)
                {
                    $sobj
                }
            }
        }

        #Installs Certificate to relevant bindings
        $BD.ForEach(
        {
            (Get-WebBinding -Name $_.SiteName -port $_.Port).AddSSLCertificate("$Thumbprint","my")
        })
    }
}
Install-IISAcmeCertificate -CommonName $CommonName -Thumbprint $ThumbPrint