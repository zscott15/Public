## MODIFY VARIABLE ##
$SQLNode = 'SERVERFQDN'
## MODIFY VARIABLE ##

$Session = New-PSSession -ComputerName $SQLNode -Credential (get-t1creds)
$Script = {
    $Task = Get-ScheduledTask -TaskName MoveClusterCoreResources
    $Trigger = $Task.Triggers
    $Action = $Task.Actions
    Register-ClusteredScheduledTask -TaskName MoveClusterCoreResources -TaskType AnyNode -Trigger $Trigger -Action $Action
}
Invoke-Command -Session $Session -ScriptBlock $Script