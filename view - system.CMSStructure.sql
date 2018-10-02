/*============================================================================
	File:		view - system.CMSStructure.sql

	Summary:	This script creates a system view for the structure of
				the folders / servers in the local CMS (Central Management Server)

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

IF OBJECT_ID(N'system.CMSStructure', N'V') IS NOT NULL
	DROP VIEW system.CMSStructure;
	GO

CREATE VIEW system.CMSStructure
AS
	-- Root-Knoten
	SELECT	DISTINCT
			1				AS	Level,
			CASE [type]
				WHEN N'S'	THEN N'Single Servers'
				WHEN N'CI'	THEN N'Clustered Instances'
				ELSE NULL
			END				AS	name,
			CASE [type]
				WHEN N'S'	THEN N'Installed single server instances'
				WHEN N'CI'	THEN N'Installed cluster instances'
				ELSE NULL
			END				AS	description,
			CAST(0 AS INT)	AS	server_type,
			N'GROUP'		AS	[type],
			CAST(NULL AS NVARCHAR(64))	AS predecessor
	FROM	data.SQLServers

	UNION

	-- Clusterknoten
	SELECT	DISTINCT
			2					AS	Level,
			hostname			AS	name,
			N'Clusterresource'	AS	description,
			CAST(0 AS INT)	AS	server_type,
			N'GROUP'			AS	[type],
			N'Clustered Instances'	AS predecessor
	FROM	data.SQLServers
	WHERE	[type] = N'CI'
			AND deleted IS NULL
			AND archived IS NULL

	UNION

	-- Instances in Clusters
	SELECT	DISTINCT
			3					AS	Level,
			hostname + ISNULL(N'\' + Instance, '')			AS	name,
			NULL				AS	description,
			CAST(0 AS INT)	AS	server_type,
			N'SERVER'			AS	[type],
			hostname			AS predecessor
	FROM	data.SQLServers
	WHERE	[type] = N'CI'
			AND deleted IS NULL
			AND archived IS NULL

	UNION

	-- single instances without high availability
	SELECT	DISTINCT
			4					AS	Level,
			hostname + ISNULL(N'\' + Instance, '')			AS	name,
			NULL				AS	description,
			CAST(0 AS INT)	AS	server_type,
			N'SERVER'			AS	[type],
			N'Single Servers'	AS predecessor
	FROM	data.SQLServers
	WHERE	[type] != N'CI'
			AND deleted IS NULL
			AND archived IS NULL;
GO

-- Test
SELECT * FROM system.CMSStructure
ORDER BY
	Level,
	name;
GO
