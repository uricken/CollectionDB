/*============================================================================
	File:		impl - create the publisher environment.sql

	Summary:	This script uses the collection database and checks for the name
				of the publishing server.
				Afterwards this script configures the affected server as a
				distribution server

	Date:		October 2018

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017

	Author:		Uwe Ricken, db Berater GmbH
============================================================================*/
:SETVAR	Distributor	NB-LENOVO-I\SQL_2017
:CONNECT NB-LENOVO-I\SQL_2017

USE master
EXEC	sp_adddistributor
		@distributor = N'$(Distributor)',
		@password = N''
GO

DECLARE	@DataPath	NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(256)) + N'CustomerOrders.mdf';
DECLARE @LogPath	NVARCHAR(256) = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS NVARCHAR(256)) + N'CustomerOrders.ldf';

EXEC	sp_adddistributiondb
		@database = N'distribution',
		@data_folder = @DataPath,
		@log_folder = @LogPath,
		@log_file_size = 2,
		@min_distretention = 0,
		@max_distretention = 72,
		@history_retention = 48,
		@deletebatchsize_xact = 5000,
		@deletebatchsize_cmd = 2000,
		@security_mode = 1
GO

USE [distribution] 
IF NOT EXISTS
(
	SELECT * from sysobjects
	WHERE	name = 'UIProperties'
			AND type = 'U '
) 
	CREATE TABLE UIProperties(id int);
GO

IF EXISTS
(
	SELECT * FROM ::fn_listextendedproperty
	(
		'SnapshotFolder',
		'user',
		'dbo',
		'table',
		'UIProperties',
		NULL,
		NULL
	)
)
	EXEC	sp_updateextendedproperty
			N'SnapshotFolder',
			N'F:\MSSQL14.SQL_2017\MSSQL\ReplData',
			'user',
			dbo,
			'table',
			'UIProperties' 
ELSE
	EXEC	sp_addextendedproperty
			N'SnapshotFolder', N'F:\MSSQL14.SQL_2017\MSSQL\ReplData', 'user', dbo, 'table', 'UIProperties'
GO

exec sp_adddistpublisher @publisher = N'NB-LENOVO-I\SQL_2017', @distribution_db = N'distribution', @security_mode = 1, @working_directory = N'F:\MSSQL14.SQL_2017\MSSQL\ReplData', @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
GO
