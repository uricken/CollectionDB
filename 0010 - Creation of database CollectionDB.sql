/*============================================================================
	File:		0010 - Creation of database CollectionDB.sql

	Summary:	This script creates the central management database for
				all management tasks around management and collection
				of server informations

	Date:		June 20189

	SQL Server Version: 2008 / 2012 / 2014 / 2016

	Author:		Uwe Ricken, db Berater GmbH
============================================================================*/
USE master;
GO

-- A database will only be created if no db exists!
IF DB_ID(N'CollectionDB') IS NULL
BEGIN
	CREATE DATABASE [CollectionDB];

	ALTER DATABASE [CollectionDB]
	MODIFY FILE
	(
		NAME = N'CollectionDB',
		SIZE = 1024MB,
		FILEGROWTH = 1024MB
	);

	ALTER DATABASE [CollectionDB]
	MODIFY FILE
	(
		NAME = N'CollectionDB_Log',
		SIZE = 1024MB,
		FILEGROWTH = 1024MB
	);

	ALTER DATABASE [CollectionDB] SET RECOVERY FULL;
	ALTER AUTHORIZATION ON DATABASE::[CollectionDB] TO sa;
END
GO