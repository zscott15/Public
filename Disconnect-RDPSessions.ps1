Function Disconnect-RDPSessions
{
    [CmdletBinding()]
    [Alias()]
    [OutputType()]
    Param
    (
        # Computer FQDN
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [string]$ComputerFQDN,

        # Credential Used to connect to server.
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [pscredential]$Credential
    )
    $Session = New-PSSession -ComputerName $ComputerFQDN -Credential $Credential
    $Script = 
    {
        #Get all RDP Sessions
        $Query = qwinsta /server:localhost
        $IDs = ForEach ($Session in $Query)
        {
            #Pull IDs of Active and Disconnected Sessions
            $Session = $Session.Replace(' ','')
            If ($Session -like '*Active*')
            {
                $Session = $Session.Replace(' ','').TrimEnd('Active')
                $Session.Remove(0,$Session.length-1)
            }
            ElseIf ($Session -like '*Disc*' -and $Session -notlike '*services*')
            {
                $Session = $Session.Replace(' ','').TrimEnd('Disc')
                $Session.Remove(0,$Session.length-1)
            }   
        }
        #Kill all RDP sessions
        ForEach ($ID in $IDs)
        {
            rwinsta $ID /server:localhost
        }
    }
    Invoke-Command -Session $Session -ScriptBlock $Script
}