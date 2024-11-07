$ClusterResources = Get-ClusterGroup
$ClusterGroup = $ClusterResources | Where-Object {$_.Name -eq 'Cluster Group'}
$HostedGroup = $ClusterResources | Where-Object {$_.Name -ne 'Cluster Group' -and $_.Name -ne 'Available Storage'}
If($HostedGroup.OwnerNode -ne $ClusterGroup.OwnerNode)
{
    Move-ClusterGroup -Name $ClusterGroup.Name -Node $HostedGroup.OwnerNode -ErrorAction Stop
}