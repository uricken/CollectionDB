/*============================================================================
	File:		function - system.GetParameterValue.sql

	Summary:	This script creates a system function which returns the
				configuration_value from system.configurations

	Date:		June 2018

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017

	Author:		Uwe Ricken, db Berater GmbH
============================================================================*/
IF DB_ID(N'CollectionDB') IS NULL
BEGIN
	RAISERROR (N'The database [%s] does not exist. Schemas cannot be created', 16, 1, N'CollectionDB') WITH NOWAIT;
	RETURN;
END
GO

USE [CollectionDB];
GO

ALTER FUNCTION system.GetParameterValue (@configuration_name AS VARCHAR(255))
RETURNS SQL_VARIANT
--WITH SCHEMABINDING
AS
BEGIN
	DECLARE	@ReturnValue SQL_VARIANT;

	;WITH r
	AS
	(
			SELECT	C.configuration_value,
					C.AdminServer
			FROM	system.configurations AS C
					INNER JOIN data.AdminServers AS Adm
					ON
					(
						C.AdminServer = Adm.Id
						AND Adm.HostName + N'\' + Adm.ServerName = @@SERVERNAME
					)
			WHERE	C.configuration_name = @configuration_name
		
			UNION ALL
		
			SELECT	C.configuration_value,
					C.AdminServer
			FROM	system.configurations AS C
			WHERE	C.AdminServer IS NULL
					AND C.configuration_name = @configuration_name
	)
	SELECT TOP (1) @ReturnValue = r.configuration_value
	FROM	r
	ORDER BY
			AdminServer DESC;

	RETURN @ReturnValue;
END
GO

-- Test!
SELECT	CAST(system.GetParameterValue(N'linked_server_name') AS VARCHAR(255));
GO
