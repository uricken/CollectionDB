USE CollectionDB;
GO

;WITH cms_nodes
AS
(
	-- Root-Knoten
	SELECT	CASE
				WHEN [type] = 'S'	THEN N'Single Server'
				WHEN [type] = 'CI'	THEN N'Clustered Instances'
				ELSE N'undefinied'
			END						AS [name],
			CASE
				WHEN [type] = 'S'	THEN N'Microsoft SQL Server single instance systeme'
				WHEN [type] = 'CI'	THEN N'Microsoft SQL Server clustered instance systeme'
				ELSE N'undefinierte Spezifikation'
			END						AS [description],
			0						AS [server_type],
			rn.server_group_id		AS [parent_id],
			0						AS [is_system_object]
	FROM	data.SQLServers
			CROSS APPLY
			(
				SELECT	server_group_id
				FROM	msdb.dbo.sysmanagement_shared_server_groups_internal
				WHERE	parent_id = 1
						AND [name] = system.GetParameterValue(N'cms_root_node')
			) AS rn
	WHERE	AdminServer IN
			(
				SELECT	Id
				FROM	data.AdminServers
				WHERE	hostname = HOST_NAME()
						AND ServerName = N'SQL_2017'
			)
)
MERGE msdb.dbo.sysmanagement_shared_server_groups_internal AS target
USING (SELECT DISTINCT * FROM cms_nodes) AS source
ON
(
	target.name = source.name
	AND target.parent_id = source.parent_id
)
WHEN NOT MATCHED BY TARGET
THEN
	INSERT (name, description, server_type, parent_id, is_system_object)
	VALUES (source.name, source.description, source.server_type, source.parent_id, source.is_system_object);
GO

--SELECT * FROM data.SQLServers;
--GO
