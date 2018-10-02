/*============================================================================
	File:		0020 - required schemas in CollectionDB.sql

	Summary:	This script creates different schemas for the storage of objects
				like tables, views, functions, procs, etc.

	Date:		June 2018

	SQL Server Version: 2008 / 2012 / 2014 / 2016

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

IF SCHEMA_ID(N'data') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [data] AUTHORIZATION dbo;';
	GO

IF SCHEMA_ID(N'system') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [system] AUTHORIZATION dbo;';
	GO

IF SCHEMA_ID(N'cms') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [cms] AUTHORIZATION dbo;';
	GO

IF SCHEMA_ID(N'log') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [log] AUTHORIZATION dbo;';