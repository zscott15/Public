<#
.Synopsis
   Remotely Configures winhttp and inet proxy machine-wide
.DESCRIPTION
   Adds registry keys to set the winhttp and inet proxy machine-wide to sailbearer.
.EXAMPLE
   Set-MachineWideProxy -ComputerName ServerFQDN -Credential (get-admincred)
#>
function Set-MachineWideProxy
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Computer FQDN
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$ComputerFQDN,
        
        # Proxy Address
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$ProxyAddress,

        # Proxy Address
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$BypassList,

        # Credential Used to connect to server.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [pscredential]$Credential
    )
    Process
    {
        Try
        {
            $Session = New-PSSession -ComputerName $ComputerFQDN -Credential $Credential
            $Script = 
            {
                #Set winhttp sailbearer config
                netsh winhttp set proxy $ProxyAddress $BypassList

                $PPURegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings'
                $PPUName = 'ProxySettingsPerUser'
                $PPUValue = '0'
                # Create the key if it does not exist
                If (-NOT (Test-Path $RegistryPath))
                {
                    New-Item -Path $PPURegPath -Force | Out-Null
                }
                New-ItemProperty -Path $PPURegPath -Name $PPUName -PropertyType DWord -Value $PPUValue  
                
                $Proxy64RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings'
                $Proxy32RegPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Internet Settings'
                $EName = 'ProxyEnable'
                $EValue = '1'
                $SName = 'ProxyServer'
                $OName = 'ProxyOverride'
                # Create the key if it does not exist
                If (-NOT (Test-Path $Proxy64RegPath))
                {
                    New-Item -Path $Proxy64RegPath -Force | Out-Null
                }
                New-ItemProperty -Path $Proxy64RegPath -Name $EName -PropertyType DWORD -Value $EValue
                New-ItemProperty -Path $Proxy64RegPath -Name $SName -PropertyType String -Value $ProxyAddress
                New-ItemProperty -Path $Proxy64RegPath -Name $OName -PropertyType String -Value $BypassList
                # Create the key if it does not exist
                If (-NOT (Test-Path $Proxy32RegPath))
                {
                    New-Item -Path $Proxy32RegPath -Force | Out-Null
                }
                New-ItemProperty -Path $Proxy32RegPath -Name $EName -PropertyType DWORD -Value $EValue
                New-ItemProperty -Path $Proxy32RegPath -Name $SName -PropertyType String -Value $ProxyAddress
                New-ItemProperty -Path $Proxy32RegPath -Name $OName -PropertyType String -Value $BypassList
            }
            Invoke-Command -Session $Session -ScriptBlock $Script
        }
        Catch
        {
            Write-Error -Message $_.Exception.Message
        }
    }
    End
    {
    }
}
