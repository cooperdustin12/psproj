from SwisClient import SwisClient

swis = SwisClient('localhost', 'admin', '')
config = swis.invoke('Orion.Discovery', 'CreateCorePluginConfiguration',
	{
		'BulkList': [{'Address':'10.199.10.12'}],
		#'IpRanges': [],	# Optional
		#'Subnets': None,	# Optional
		'Credentials': [
			{'CredentialID':1, 'Order':1},
			{'CredentialID':2, 'Order':2},
		],
		'WmiRetriesCount': 1,
		'WmiRetryIntervalMiliseconds': 1000
	})

disco = swis.invoke('Orion.Discovery', 'StartDiscovery',
	{
		'Name': 'SDKDiscovery',
		'EngineId': 1,
		'JobTimeoutSeconds': 3600,
		'SearchTimeoutMiliseconds': 2000,
		'SnmpTimeoutMiliseconds': 2000,
		'SnmpRetries': 4,
		'RepeatIntervalMiliseconds': 1800,
		'SnmpPort': 161,
		'HopCount': 0,
		'PreferredSnmpVersion': 'SNMP2c',
		'DisableIcmp': False,
		'AllowDuplicateNodes': False,
		'IsAutoImport': True,
		'IsHidden': True,
		'PluginConfigurations': [
			{'PluginConfigurationItem': config}
		]
	})
