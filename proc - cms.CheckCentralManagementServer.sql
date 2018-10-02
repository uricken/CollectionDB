/*============================================================================
	File:		proc - cms.CheckCentralManagementServer.sql

	Summary:	This script creates a stored procedure which checks whether the
				unerlying Microsoft SQL Server is prepared as a CMS
				(Central Management Server).

				More details about CMS can be found here:
				https://docs.microsoft.com/de-de/sql/ssms/register-servers/create-a-central-management-server-and-server-group?view=sql-server-2017

	Date:		June 2018

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017

	Author:		Uwe Ricken, db Berater GmbH
============================================================================*/
USE CollectionDB;
GO

IF OBJECT_ID(N'cms.CheckCentralManagementServer', N'P') IS NOT NULL
	DROP PROC cms.CheckCentralManagementServer;
	GO

CREATE PROC cms.CheckCentralManagementServer
AS
BEGIN
	SET NOCOUNT ON;

	/* general variables for tracing and error handling */
	DECLARE	@proc_name		SYSNAME	=	OBJECT_NAME(@@PROCID);
	DECLARE	@activitylog_id	UNIQUEIDENTIFIER;
	DECLARE	@error_num		INT;
	DECLARE	@error_msg		NVARCHAR(2048);

	DECLARE	@server_name		SYSNAME	=	HOST_NAME();
	DECLARE	@instance_name		SYSNAME;
	DECLARE	@product_version	INT;
	DECLARE	@node_id			INT;
	DECLARE	@return_code		INT = 0;

	-- extract server and instance name from the @@servername variable!
	IF CHARINDEX(N'\', @@SERVERNAME) > 0
	BEGIN
		SET	@instance_name = REPLACE(@@SERVERNAME, HOST_NAME(), N'');
		SET	@instance_name = REPLACE(@instance_name, N'\', N'');
	END
	ELSE
		SET	@instance_name = N'MSSQLSERVER';

	-- If the actual server is not configured as an ADMIN server we exit the procedure
	IF NOT EXISTS
	(
		SELECT	*
		FROM	data.AdminServers
		WHERE	HostName = HOST_NAME()
				AND ISNULL(ServerName, N'MSSQLSERVER') = @instance_name
	)
	BEGIN
		SET	@error_msg = N'Server ' + CAST(@@SERVERNAME AS NVARCHAR(2048)) + N' is not configured in data.AdminServers';

		EXEC system.WriteActivityLog
			@EntryId = NULL,
			@proc_name = @proc_name,
			@process_step = N'check for role as admin server',
			@error_message = @error_msg,
			@error_number = NULL,
			@ReturnValue = @activitylog_id OUTPUT

		RETURN @return_code;
	END

	-- If the current version of Microsoft SQL Server is prior to 2008
	-- we raise an error
	SET		@product_version = 
			CAST
			(
				LEFT
				(
					CAST(SERVERPROPERTY(N'ProductVersion') AS VARCHAR(3)),
					CHARINDEX
					(
						'.',
						CAST(SERVERPROPERTY(N'ProductVersion') AS VARCHAR(3))
					) - 1
				) AS INT
			);

	IF @product_version < 10
	BEGIN
		SET	@error_msg = N'Versions of SQL Server that are earlier than SQL Server 2008 cannot be designated as a central management server.'

		EXEC system.WriteActivityLog
			@EntryId = NULL,
			@proc_name = @proc_name,
			@process_step = N'check the version of Microsoft SQL Server',
			@error_message = @error_msg,
			@error_number = NULL,
			@ReturnValue = @activitylog_id OUTPUT

		RETURN @return_code;
	END

	-- Both system tables have to be in msdb; otherwise we return an error
	IF NOT EXISTS
	(
		SELECT	object_id
		FROM	msdb.sys.all_objects
		WHERE	name IN
				(
					N'sysmanagement_shared_server_groups_internal',
					N'sysmanagement_shared_registered_servers_internal'
				)
				AND type = 'U'
	)
	BEGIN
		SET	@error_msg = N'The actual server is not ready as role for a Central Management Server! Please configure CMS manually.';

		EXEC system.WriteActivityLog
			@EntryId = NULL,
			@proc_name = @proc_name,
			@process_step = N'check the infrastructure for CMS',
			@error_message = @error_msg,
			@error_number = NULL,
			@ReturnValue = @activitylog_id OUTPUT

		RETURN @return_code;
	END

	-- First we need the name of the root folder where all objects must be created
	DECLARE	@root_node	NVARCHAR(256) = CAST(system.GetParameterValue(N'cms_root_node') AS NVARCHAR(256));

	-- if no root_node has been configured we exit with an error message
	IF @root_node IS NULL
	BEGIN
		SET	@error_msg = N'There is no configuration item for the root node of the CMS';

		EXEC system.WriteActivityLog
			@EntryId = NULL,
			@proc_name = @proc_name,
			@process_step = N'check the root node configuration',
			@error_message = @error_msg,
			@error_number = NULL,
			@ReturnValue = @activitylog_id OUTPUT

		RETURN @return_code;
	END

	-- when a root node is available we check whether it exists.
	-- if not than we create a dedicated root node for the storage
	-- of all collectable servers
	SELECT	@node_id = server_group_id
	FROM	msdb.dbo.sysmanagement_shared_server_groups_internal
			WHERE	name = @root_node
					AND parent_id = 1;

	IF @node_id IS NULL
	BEGIN
		INSERT INTO msdb.dbo.sysmanagement_shared_server_groups_internal
		(name, description, server_type, parent_id, is_system_object)
		VALUES
		(
			@root_node,
		    N'this is the folder for all servers for the data collection operations',
		    0,
		    1,
		    0
		);

		SET @node_id = SCOPE_IDENTITY();
	END

	-- When the root-node is implemented we implement the second layer which determines
	-- whether it is a clustered instance or a single server
	;WITH cms_nodes
	AS
	(
		-- Root-Knoten
		SELECT	CASE
					WHEN S.[type] = 'S'	THEN N'Single Server'
					WHEN S.[type] = 'CI'	THEN N'Clustered Instances'
					ELSE N'undefinied'
				END						AS [name],
				CASE
					WHEN S.[type] = 'S'	THEN N'Microsoft SQL Server single instance systeme'
					WHEN S.[type] = 'CI'	THEN N'Microsoft SQL Server clustered instance systeme'
					ELSE N'undefinierte Spezifikation'
				END						AS [description],
				0						AS [server_type],
				rn.server_group_id		AS [parent_id],
				0						AS [is_system_object]
		FROM	data.SQLServers AS S
				CROSS APPLY
				(
					SELECT	server_group_id
					FROM	msdb.dbo.sysmanagement_shared_server_groups_internal
					WHERE	parent_id = 1
							AND [name] = @root_node
				) AS rn
		WHERE	S.AdminServer IN
				(
					SELECT	Id
					FROM	data.AdminServers
					WHERE	hostname = @server_name
							AND ServerName = @instance_name
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

	-- if the folder exists we now have to make sure that we build a list of all
	-- servers from data.SQLServers to build the folder structure with all affected
	-- servers
	SELECT * FROM msdb.dbo.sysmanagement_shared_server_groups_internal
	SELECT * FROM system.CMSStructure;


	RETURN 1;
	SET NOCOUNT OFF;
END
GO

EXEC cms.CheckCentralManagementServer;
GO

SELECT * FROM data.ActivityLog;
GO

TRUNCATE TABLE data.ActivityLog;

SELECT * FROM data.AdminServers;
GO


--UPDATE	data.SQLServers
--SET		AdminServer = N'4D154F12-3880-E811-A660-3052CBE86F06';
--GO