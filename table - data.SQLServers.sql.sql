/*============================================================================
	File:		table - data.SQLServers.sql

	Summary:	This script creates a central management table which stores
				all SQL Servers and additional properties.
				This table will be used to distribute the data to the different
				collection servers!

	Date:		June 2018

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017

	Author:		Uwe Ricken, db Berater GmbH
============================================================================*/
USE master;
GO

IF DB_ID(N'CollectionDB') IS NULL
BEGIN
	RAISERROR (N'The database [%s] does not exist. Schemas cannot be created', 16, 1, N'CollectionDB') WITH NOWAIT;
	RETURN;
END
GO

USE [CollectionDB];
GO

IF OBJECT_ID(N'data.SQLServers', N'U') IS NOT NULL
	DROP TABLE data.SQLServers;
	GO

CREATE TABLE [data].[SQLServers]
(
	[sid]							UNIQUEIDENTIFIER NOT NULL ROWGUIDCOL DEFAULT (NEWSEQUENTIALID()),
	[hostname]						[NVARCHAR](255) NOT NULL, 
	[instance]						[NVARCHAR](15) NULL, 
	[systemtyp]						[NVARCHAR](1) NOT NULL, 
	[type]							[NVARCHAR](2) NOT NULL, 
	[alias]							[NVARCHAR](50) NULL, 
	[description]					[NVARCHAR](255) NULL, 
	[application]					[NVARCHAR](255) NULL, 
	[application_contact]			[NVARCHAR](255) NULL, 
	[application_contact_manual]	[NVARCHAR](255) NULL, 
	[created]						[SMALLDATETIME] NULL, 
	[deleted]						[SMALLDATETIME] NULL, 
	[archived]						[SMALLDATETIME] NULL, 
	[connected]						[BIT] NULL, 
	[TS_create]						[SMALLDATETIME] NULL, 
	[TS_modify]						[SMALLDATETIME] NULL, 
	[Ticket]						[NCHAR](255) NULL, 
	[nagiosstate]					[NVARCHAR](15) NULL, 
	[nagioslinkname]				[NVARCHAR](32) NULL,
	[AdminServer]					UNIQUEIDENTIFIER NULL
);
GO

ALTER TABLE data.SQLServers ADD CONSTRAINT pk_SQLServers_SId
PRIMARY KEY CLUSTERED (sid);
GO

CREATE NONCLUSTERED INDEX nix_SQLServers_Type
ON data.SQLServers
(
	type,
	deleted,
	archived
)
INCLUDE
(
	hostname,
	instance
);
GO

CREATE STATISTICS stats_SQLServers_HostInstance
ON data.SQLServers (hostname, instance);
GO

--ALTER TABLE data.SQLServers ADD CONSTRAINT fk_SQLServers_AdminServer FOREIGN KEY (AdminServer)
--REFERENCES data.AdminServers (Id)
--ON DELETE CASCADE;

CREATE NONCLUSTERED INDEX nix_SQLServers_ActiveServers ON data.SQLServers
(
	deleted,
	archived
)
WHERE	deleted IS NULL
		AND archived IS NULL;
GO

SELECT	*
FROM	data.SQLServers
WHERE	deleted IS NULL
		AND archived IS NULL;
GO