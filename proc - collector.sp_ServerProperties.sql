USE CollectionDB;
GO

IF SCHEMA_ID(N'collector') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA collector AUTHORIZATION dbo;';
	GO

IF SCHEMA_ID(N'collector') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA collector AUTHORIZATION dbo;';
	GO

IF OBJECT_ID(N'collector.sp_ServerProperties', N'P') IS NOT NULL
	DROP PROCEDURE collector.sp_ServerProperties;
	GO

CREATE PROCEDURE collector.sp_ServerProperties
	@ServerName		NVARCHAR(64),
	@InstanceName	NVARCHAR(64)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@provider	NVARCHAR(4000) = N'PROVIDER=SQLOLEDB;SERVER=$ServerName';
	DECLARE	@Server_Id	UNIQUEIDENTIFIER;
	DECLARE	@Class_Id	UNIQUEIDENTIFIER = system.GetClass_Id(N'ServerProperties');

	IF
	(
		@InstanceName = N'MSSQLSERVER'
		OR @InstanceName IS NULL
		OR @InstanceName = N''
	)
		SET	@provider = REPLACE(@provider, N'$ServerName', @ServerName);
	ELSE
		SET @provider = REPLACE(@provider, N'$ServerName', @ServerName + N'\' + @InstanceName);

	-- Evaluierung der Server_Id für die Eintragungen der Daten
	SELECT	@Server_Id = sid
	FROM	data.SQLServers
			WHERE	hostname = @ServerName
					AND instance = @InstanceName;

	BEGIN
		EXEC master.dbo.sp_addlinkedserver
			@server		=	N'Collector',
			@srvproduct	=	N'MSSQL',
			@provider	=	N'SQLNCLI',
			@provstr	=	@provider;

		EXEC master.dbo.sp_addlinkedsrvlogin
			@rmtsrvname=N'Collector',
			@useself=N'True',
			@locallogin=NULL,@rmtuser=NULL,
			@rmtpassword=NULL;

		EXEC master.dbo.sp_serveroption @server=N'Collector', @optname=N'rpc out', @optvalue=N'true';
	END

	-- first we collect all required information before we
	-- merge them into the data.ClassValues!
	CREATE TABLE #Collector
	(
		PValue01	SQL_VARIANT			NULL,
		PValue02	SQL_VARIANT			NULL,
		PValue03	SQL_VARIANT			NULL,
		PValue04	SQL_VARIANT			NULL,
		PValue05	SQL_VARIANT			NULL,
		PValue06	SQL_VARIANT			NULL,
		PValue07	SQL_VARIANT			NULL,
		PValue08	SQL_VARIANT			NULL,
		PValue09	SQL_VARIANT			NULL
	);

	INSERT INTO #Collector
	    (
	        PValue01,
	        PValue02,
	        PValue03,
	        PValue04,
	        PValue05,
	        PValue06,
	        PValue07,
	        PValue08,
	        PValue09
	    )
	EXEC
	(
		';WITH SP
		AS
		(
			SELECT	SERVERPROPERTY(''MachineName'')					AS MachineName,
					SERVERPROPERTY(''ServerName'')					AS ServerName,
					SERVERPROPERTY(''Edition'')						AS Edition,
					SERVERPROPERTY(''ProductVersion'')				AS ProductVersion,
					SERVERPROPERTY(''BuildClrVersion'')				AS BuildClrVersion,
					SERVERPROPERTY(''ComputerNamePhysicalNetBIOS'')	AS ComputerNamePhysicalNetBIOS,
					SERVERPROPERTY(''IsClustered'')					AS IsClustered,
					SERVERPROPERTY(''ResourceLastUpdateDateTime'')	AS ResourceLastUpdateDateTime,
					SERVERPROPERTY(''Collation'')						AS Collation
		)
		SELECT * FROM SP;'
	) AT Collector;

	EXEC master.dbo.sp_dropserver
		@server = N'Collector',
		@droplogins = 'droplogins';

	-- Jetzt werden die Daten in data.ClassValues importiert
	;WITH T
	AS
	(
		SELECT	Server_Id,
				Class_Id,
				PValue01,
				PValue02,
				PValue03,
				PValue04,
				PValue05,
				PValue06,
				PValue07,
				PValue08,
				PValue09
		FROM	data.ClassValues
	)
	MERGE T AS target
	USING
	(
		SELECT	@Server_Id	AS Server_Id,
				@Class_Id	AS Class_Id,
				PValue01,
                PValue02,
                PValue03,
                PValue04,
                PValue05,
                PValue06,
                PValue07,
                PValue08,
                PValue09
		FROM	#Collector
	) AS source
	ON
	(
		target.Server_Id = source.Server_Id
		AND target.Class_Id = source.Class_Id
	)
	WHEN NOT MATCHED BY TARGET
	THEN
		INSERT VALUES
		(
			source.Server_Id,
			source.Class_Id,
			source.PValue01,
			source.PValue02,
			source.PValue03,
			source.PValue04,
			source.PValue05,
			source.PValue06,
			source.PValue07,
			source.PValue08,
			source.PValue09
		)
		WHEN MATCHED
		AND
		(
			target.PValue01 <> source.PValue01
			OR target.PValue02 <> source.PValue02
			OR target.PValue03 <> source.PValue03
			OR target.PValue04 <> source.PValue04
			OR target.PValue05 <> source.PValue05
			OR target.PValue06 <> source.PValue06
			OR target.PValue07 <> source.PValue07
			OR target.PValue08 <> source.PValue08
			OR target.PValue09 <> source.PValue09
		)
		THEN
			UPDATE
			SET	target.PValue01 = source.PValue01,
				target.PValue02 = source.PValue02,
				target.PValue03 = source.PValue03,
				target.PValue04 = source.PValue04,
				target.PValue05 = source.PValue05,
				target.PValue06 = source.PValue06,
				target.PValue07 = source.PValue07,
				target.PValue08 = source.PValue08,
				target.PValue09 = source.PValue09;
	
	SET NOCOUNT OFF;
END
GO

EXEC collector.sp_ServerProperties
	@ServerName = N'NB-LENOVO-I',
	@InstanceName = N'SQL_2016';
GO

SELECT * FROM data.ClassValues;
GO

--DELETE data.ClassValues WHERE Class_Id = N'2A7E49E3-EF54-4C41-ADDE-BD3128EE63DB';
--GO
