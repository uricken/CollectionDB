/*============================================================================
	File:		table - data.AdminServers.sql

	Summary:	This script creates a table for the storage of all admin servers
				(subscribers) and its depending domain name.
				The domain name is required as translation to data.SQLServers.

				In data.SQLServers is a new attribute [AdminServer] which uses
				an UDF to get the name of the AdminServer based on the FQDN.

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

IF OBJECT_ID(N'data.AdminServers', N'U') IS NOT NULL
	DROP TABLE data.AdminServers;
	GO

CREATE TABLE data.AdminServers
(
	Id				UNIQUEIDENTIFIER	NOT NULL	ROWGUIDCOL	DEFAULT (NEWSEQUENTIALID()),
	HostName		SYSNAME				NOT NULL,
	ServerName		SYSNAME				NOT NULL,
	DomainName		SYSNAME				NOT NULL,
	is_publisher	BIT					NOT NULL	DEFAULT (0)
);
GO

ALTER TABLE data.AdminServers ADD CONSTRAINT pk_AdminServers
PRIMARY KEY CLUSTERED (Id);
GO

CREATE UNIQUE NONCLUSTERED INDEX nix_AdminServers_HostServer
ON data.AdminServers
(
	HostName,
	ServerName
);

-- You can fill demo data from the script [0030 - DemoData for Tests.sql]