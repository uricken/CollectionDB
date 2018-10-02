/*============================================================================
	File:		table - data.ActivityLog.sql

	Summary:	This script creates a system table which stores the activity
				which will be recorded by the stored procedures for system
				activity and collection activity

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

IF OBJECT_ID(N'data.ActivityLog', N'U') IS NOT NULL
	DROP TABLE data.ActivityLog;
	GO

CREATE TABLE data.ActivityLog
(
	EntryId			UNIQUEIDENTIFIER	NOT NULL	ROWGUIDCOL DEFAULT (NEWID()),
	server_name		SYSNAME				NOT NULL	DEFAULT (@@SERVERNAME),
	proc_name		SYSNAME				NOT NULL,
	start_time		DATETIME2(4)		NOT NULL	DEFAULT	(GETDATE()),
	end_time		DATETIME2(4)		NULL,
	process_step	NVARCHAR(2048)		NULL,
	ErrorMessage	NVARCHAR(2048)		NULL,
	ErrorNumber		INT					NOT NULL	DEFAULT (0)
);
GO

ALTER TABLE data.ActivityLog ADD CONSTRAINT pk_ActivityLog
PRIMARY KEY CLUSTERED (EntryId);
GO