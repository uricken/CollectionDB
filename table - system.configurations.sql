/*============================================================================
	File:		table - system.configurations.sql

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

IF OBJECT_ID(N'system.Configurations', N'U') IS NOT NULL
	DROP TABLE system.Configurations;
	GO

CREATE TABLE system.Configurations
(
	configuration_id		UNIQUEIDENTIFIER	NOT NULL	DEFAULT (NEWSEQUENTIALID()),
	configuration_name		VARCHAR(255)		NOT NULL,
	configuration_desc		VARCHAR(512)		NOT NULL,
	configuration_value		SQL_VARIANT			NOT NULL,
	AdminServer				UNIQUEIDENTIFIER	NULL
);
GO

CREATE UNIQUE CLUSTERED INDEX cuix_configurations_configuration_id
ON system.Configurations(configuration_id);
GO

CREATE UNIQUE NONCLUSTERED INDEX uix_configurations_configuration_name
ON system.Configurations
(
	configuration_name,
	AdminServer
);
GO