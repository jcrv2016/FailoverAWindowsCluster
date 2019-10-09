#Get parameters. They are mandatory! Put in the two nodes in the cluster (order doesn't matter), and then the cluster name.

param (
    [Parameter(Mandatory=$true)][string]$server1,
    [Parameter(Mandatory=$true)][string]$server2,
    [Parameter(Mandatory=$true)][string]$ClusterName
 )

Write-Output "`n########`n"


$OriginalOwnerNode = get-clustergroup | Where {$_ -match $ClusterName} | Select 'OwnerNode' -expandproperty 'OwnerNode' 
$OriginalOwnerNode = $OriginalOwnerNode.Name
Write-Output "Active cluster node for $ClusterName is:" $OriginalOwnerNode `n

if ($OriginalOwnerNode -eq $server1)
{
$NodeToFailoverTo = $server2
}
else
{
$NodeToFailoverTo = $server1
}

#See if anyone is logged in
$userIDRegex = '(?<=\s+)\d+(?=\s+[a-z])'
$loggedOnUsers = quser /server:$OriginalOwnerNode | select-string -allmatches $userIDRegex

#If people are logged in, then log them all out
if ($loggedOnUsers)
{
	Write-Output "RDP Users are logged onto $OriginalOwnerNode"
	ForEach ($user in $loggedOnUsers)
	{
		$userName = $user.tostring().split("")[1]
		Write-Output "Logging off $userName" 
		logoff /server:$OriginalOwnerNode $user.matches.value
	}
}
else
{
Write-Output "No RDP Users are logged onto $OriginalOwnerNode"
}

#Start Failover Process
Write-Output "`nMoving active node to:" $NodeToFailOverTo `n

#Record the prooess start time
$StartTime = Get-Date -Format G
Write-Output "Failover started at: " $StartTime `n

#Execute command to move
move-clustergroup $ClusterName -node $NodeToFailOverTo  >$null

#Time completion
$EndTime = Get-Date -Format G
Write-Output "`nFailover Completed at: " $EndTime `n

#Confirm results of move
$CurrentOwnerNode = get-clustergroup | Where {$_ -match $ClusterName} | Select 'OwnerNode' -expandproperty 'OwnerNode' 
Write-Output "Active cluster node for $ClusterName is now: " $CurrentOwnerNode.Name

Write-Output "`n########`n"
Get-PSSession | Remove-PSSession
