<#

	These are all the functions for tab completion (auto-population of params)
	To use, place this after params in a function
	
	DynamicParam { if ($source) { return (Get-ParamSqlXyz -SqlServer $Source -SqlCredential $SourceSqlCredential) } }

#>
Function Get-ParamSqlServerConfigs
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Server Configs from specified SQL Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$configlist = @()
	$server.Configuration.ShowAdvancedOptions.ConfigValue = $true
	$null = $server.ConnectionContext.ExecuteNonQuery("RECONFIGURE WITH OVERRIDE")
	$configlist = $server.Configuration.PsObject.Properties.Name | Where-Object { $_ -notin "Parent", "Properties" }
	$server.Configuration.ShowAdvancedOptions.ConfigValue = $false
	$null = $server.ConnectionContext.ExecuteNonQuery("RECONFIGURE WITH OVERRIDE")
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($configlist) { $validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $configlist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($configlist) { $attributeCollection.Add($validationset) }
	$Configs = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Configs", [String[]], $attributeCollection)
	
	$newparams.Add("Configs", $Configs)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlDatabases
{
<# 
.SYNOPSIS 
Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
filled with database list from specified SQL Server server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	$SupportDbs = "ReportServer", "ReportServerTempDb", "distribution"
	
	# Populate arrays
	$databaselist = @()
	foreach ($database in $server.databases)
	{
		if ((!$database.IsSystemObject) -and $SupportDbs -notcontains $database.name)
		{
			$databaselist += $database.name
		}
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	# Provide backwards compatability for improperly named parameter
	# Scratch that. I'm going with plural. Sorry, Snoves!
	$alias = New-Object System.Management.Automation.AliasAttribute "Database"
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($databaselist) { $dbvalidationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $databaselist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($databaselist) { $attributeCollection.Add($dbvalidationset) }
	$attributeCollection.Add($alias)
	$Databases = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Databases", [String[]], $attributeCollection)
	
	$dbexcludeattributes = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$dbexcludeattributes.Add($attributes)
	if ($databaselist) { $dbexcludeattributes.Add($dbvalidationset) }
	$Exclude = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Exclude", [String[]], $dbexcludeattributes)
	
	$newparams.Add("Databases", $Databases)
	$newparams.Add("Exclude", $Exclude)
	
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlLogins
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with login list from specified SQL Server server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	$loginlist = @()
	
	foreach ($login in $server.logins)
	{
		if (!$login.name.StartsWith("##") -and $login.name -ne 'sa')
		{
			$loginlist += $login.name
		}
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	# Provide backwards compatability for improperly named parameter
	# Scratch that. I'm going with plural. Sorry, Snoves!
	$alias = New-Object System.Management.Automation.AliasAttribute "Login"
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Login list parameter setup
	if ($loginlist) { $loginvalidationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $loginlist }
	
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($loginlist) { $attributeCollection.Add($loginvalidationset) }
	
	$attributeCollection.Add($alias)
	$Logins = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Logins", [String[]], $attributeCollection)
	
	$excludeattributes = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$excludeattributes.Add($attributes)
	if ($loginlist) { $excludeattributes.Add($loginvalidationset) }
	$Exclude = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Exclude", [String[]], $excludeattributes)
	
	$newparams.Add("Logins", $Logins)
	$newparams.Add("Exclude", $Exclude)
	
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlServerRoles
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Server Roles from specified SQL Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$rolelist = @()
	$roles = $server.roles | Where-Object { $_.IsFixedRole -eq $false -and $_.Name -ne 'public' }
	foreach ($role in $roles)
	{
		$rolelist += $role.name
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($rolelist) { $validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $rolelist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($rolelist) { $attributeCollection.Add($validationset) }
	$roles = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Roles", [String[]], $attributeCollection)
	
	$newparams.Add("Roles", $roles)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlCredentials
{
<# 
.SYNOPSIS 
Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
filled with SQL Credentials from specified SQL Server server name.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$credentiallist = @()
	foreach ($credential in $server.credentials)
	{
		$credentiallist += $credential.name
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($credentiallist) { $dbvalidationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $credentiallist }
	$lsattributes = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$lsattributes.Add($attributes)
	if ($credentiallist) { $lsattributes.Add($dbvalidationset) }
	$Credentials = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Credentials", [String[]], $lsattributes)
	
	$newparams.Add("Credentials", $Credentials)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlServerAudits
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Server Audits from specified SQL Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$auditlist = @()
	foreach ($audit in $server.audits)
	{
		$auditlist += $audit.name
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($auditlist) { $validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $auditlist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($auditlist) { $attributeCollection.Add($validationset) }
	$audits = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Audits", [String[]], $attributeCollection)
	
	$newparams.Add("Audits", $audits)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlServerServerAuditSpecifications
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Server ServerAuditSpecifications from specified SQL Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$auditspeclist = @()
	foreach ($auditspec in $server.ServerAuditSpecifications)
	{
		$auditspeclist += $auditspec.name
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($auditspeclist) { $validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $auditspeclist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($auditspeclist) { $attributeCollection.Add($validationset) }
	$serverAuditSpecifications = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("ServerAuditSpecifications", [String[]], $attributeCollection)
	
	$newparams.Add("ServerAuditSpecifications", $serverAuditSpecifications)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlBackupDevices
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Backup Devices from specified SQL Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$backupdevicelist = @()
	foreach ($backupdevice in $server.BackupDevices)
	{
		$backupdevicelist += $backupdevice.name
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($backupdevicelist) { $validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $backupdevicelist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($backupdevicelist) { $attributeCollection.Add($validationset) }
	$backupdevices = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("BackupDevices", [String[]], $attributeCollection)
	
	$newparams.Add("BackupDevices", $backupdevices)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlServerEndpoints
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Server Endpoints from specified SQL Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$endpointlist = @()
	$usernedponit = $server.Endpoints | Where-Object { $_.IsSystemObject -eq $false }
	foreach ($endpoint in $server.Endpoints)
	{
		$endpointlist += $endpoint.name
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($endpointlist) { $validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $endpointlist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($endpointlist) { $attributeCollection.Add($validationset) }
	$Endpoints = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Endpoints", [String[]], $attributeCollection)
	
	$newparams.Add("Endpoints", $Endpoints)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlLinkedServers
{
<# 
.SYNOPSIS 
Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
filled with Linked Servers from specified server name.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$linkedserverlist = @()
	foreach ($linkedserver in $server.LinkedServers)
	{
		# skip the replication linked server
		if ($linkedserver.name -ne 'repl_distributor')
		{
			$linkedserverlist += $linkedserver.name
		}
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($linkedserverlist) { $dbvalidationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $linkedserverlist }
	$lsattributes = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$lsattributes.Add($attributes)
	if ($linkedserverlist) { $lsattributes.Add($dbvalidationset) }
	$LinkedServers = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("LinkedServers", [String[]], $lsattributes)
	
	$newparams.Add("LinkedServers", $LinkedServers)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlPolicyManagement
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Sql Policy Management objects from specified SQL Server server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	$sqlconn = $server.ConnectionContext.SqlConnectionObject
	$sqlStoreConnection = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SqlStoreConnection $sqlconn
	
	# DMF is the Declarative Management Framework, Policy Based Management's old name
	$store = New-Object Microsoft.SqlServer.Management.DMF.PolicyStore $sqlStoreConnection
	
	$objects = "Policies", "Conditions" # Maybe other stuff later? I don't know PBM well enough yet to know.
	
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	foreach ($name in $objects)
	{
		$items = $store.$name.Name
		if ($items.count -gt 0)
		{
			$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
			$attributeCollection.Add($attributes)
			$attributeCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $items))
		}
		
		$newparams.Add($name, (New-Object -Type System.Management.Automation.RuntimeDefinedParameter($name, [String[]], $attributeCollection)))
	}
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlResourceGovernor
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Resource Governor objects from specified SQL Server server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	$pools = $server.ResourceGovernor.ResourcePools | Where-Object { $_.Name -notin "internal", "default" }
	
	if ($pools.count -gt 0)
	{
		$attributes = New-Object System.Management.Automation.ParameterAttribute
		$attributes.ParameterSetName = "__AllParameterSets"
		$attributes.Mandatory = $false
		$attributes.Position = 3
		
		$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
		$attributeCollection.Add($attributes)
		$attributeCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $pools.Name))
		
		$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		$newparams.Add("ResourcePools", (New-Object -Type System.Management.Automation.RuntimeDefinedParameter("ResourcePools", [String[]], $attributeCollection)))
	}
	$server.ConnectionContext.Disconnect()
	return $newparams
}

Function Get-ParamSqlExtendedEvents
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Extended Event objects from specified SQL Server server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	$sqlconn = $server.ConnectionContext.SqlConnectionObject
	$sqlStoreConnection = New-Object Microsoft.SqlServer.Management.Sdk.Sfc.SqlStoreConnection $sqlconn
	
	$store = New-Object  Microsoft.SqlServer.Management.XEvent.XEStore $sqlStoreConnection
	
	$objects = "Sessions" # Maybe packages later? I don't understand xEvents well enough yet to know.
	
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	foreach ($name in $objects)
	{
		$items = $store.$name.Name
		if ($items.count -gt 0)
		{
			$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
			$attributeCollection.Add($attributes)
			$attributeCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $items))
		}
		
		$newparams.Add($name, (New-Object -Type System.Management.Automation.RuntimeDefinedParameter($name, [String[]], $attributeCollection)))
	}
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlDatabaseMail
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Database Mail server objects from specified SQL Server server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	$objects = "ConfigurationValues", "Profiles", "Accounts", "MailServers"
	
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	foreach ($name in $objects)
	{
		if ($name -eq "MailServers") { $items = $server.Mail.Accounts.$name.Name }
		else { $items = $server.Mail.$name.Name }
		if ($items.count -gt 0)
		{
			$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
			$attributeCollection.Add($attributes)
			$attributeCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $items))
		}
		
		$newparams.Add($name, (New-Object -Type System.Management.Automation.RuntimeDefinedParameter($name, [String[]], $attributeCollection)))
	}
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlJobServer
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with job server objects from specified SQL Server server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	$jobobjects = "ProxyAccounts", "JobSchedule", "SharedSchedules", "AlertSystem", "JobCategories", "OperatorCategories"
	$jobobjects += "AlertCategories", "Alerts", "TargetServerGroups", "TargetServers", "Operators", "Jobs", "Mail"
	
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	foreach ($name in $jobobjects)
	{
		$items = $server.JobServer.$name.Name
		if ($items.count -gt 0)
		{
			$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
			$attributeCollection.Add($attributes)
			$attributeCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $items))
		}
		
		$newparams.Add($name, (New-Object -Type System.Management.Automation.RuntimeDefinedParameter($name, [String[]], $attributeCollection)))
	}
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlCmsGroups
{
<# 
.SYNOPSIS 
Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
filled with server groups from specified SQL Server Central Management server name.

#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
		
	)
	
	try { $SqlCms = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	$sqlconnection = $SqlCms.ConnectionContext.SqlConnectionObject
	
	try { $cmstore = New-Object Microsoft.SqlServer.Management.RegisteredServers.RegisteredServersStore($sqlconnection) }
	catch { return }
	
	if ($cmstore -eq $null) { return }
	
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$paramattributes = New-Object System.Management.Automation.ParameterAttribute
	$paramattributes.ParameterSetName = "__AllParameterSets"
	$paramattributes.Mandatory = $false
	$paramattributes.Position = 3
	
	$argumentlist = $cmstore.DatabaseEngineServerGroup.ServerGroups.name
	
	if ($argumentlist -ne $null)
	{
		$validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $argumentlist
		
		$combinedattributes = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
		$combinedattributes.Add($paramattributes)
		$combinedattributes.Add($validationset)
		
		$SqlCmsGroups = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("SqlCmsGroups", [String[]], $combinedattributes)
		$newparams.Add("SqlCmsGroups", $SqlCmsGroups)
		
		return $newparams
	}
	else { return }
}

Function Get-ParamSqlServerTriggers
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with Server Triggers from specified SQL Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$triggerlist = @()
	foreach ($trigger in $server.Triggers)
	{
		$triggerlist += $trigger.name
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($triggerlist) { $validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $triggerlist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($triggerlist) { $attributeCollection.Add($validationset) }
	$Triggers = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Triggers", [String[]], $attributeCollection)
	
	$newparams.Add("Triggers", $Triggers)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}


Function Get-ParamSqlCustomErrors
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with ID of Server Custom Errors/User Defined Messages from specified SQL Server.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	# Populate arrays
	$messagelist = @()
	$uniquemessageid = $server.UserDefinedMessages | Select ID | Sort-Object | Get-Unique
	foreach ($message in $uniquemessageid)
	{
		$messagelist += $message.ID
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($messagelist) { $validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $messagelist }
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($messagelist) { $attributeCollection.Add($validationset) }
	$CustomErrors = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("CustomErrors", [String[]], $attributeCollection)
	
	$newparams.Add("CustomErrors", $CustomErrors)
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}

Function Get-ParamSqlDatabaseAssemblies
{
<# 
 .SYNOPSIS 
 Internal function. Returns System.Management.Automation.RuntimeDefinedParameterDictionary 
 filled with assemblies from specified SQL Server.
	
 Assembly name is in database.assemblyname format.
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object]$SqlServer,
		[System.Management.Automation.PSCredential]$SqlCredential
	)
	
	try { $server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential -ParameterConnection }
	catch { return }
	
	######### Assemblies
	$list = @()
	
	foreach ($database in $server.Databases)
	{
		try
		{
			# a bug here requires a try/catch
			$userAssemblies = $($database.assemblies | Where-Object { $_.isSystemObject -eq $false })
			foreach ($assembly in $userAssemblies)
			{
				$name = "$($database.name).$($assembly.name)"
				$list += $name
			}
		}
		catch { }
	}
	
	# Reusable parameter setup
	$newparams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributes = New-Object System.Management.Automation.ParameterAttribute
	
	$attributes.ParameterSetName = "__AllParameterSets"
	$attributes.Mandatory = $false
	$attributes.Position = 3
	
	# Database list parameter setup
	if ($list)
	{
		$validationset = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $list
	}
	$attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
	$attributeCollection.Add($attributes)
	if ($list) { $attributeCollection.Add($validationset) }
	$Assemblies = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Assemblies", [String[]], $attributeCollection)
	
	$newparams.Add("Assemblies", $Assemblies)
	
	$server.ConnectionContext.Disconnect()
	
	return $newparams
}
