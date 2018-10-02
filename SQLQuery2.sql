USE CollectionDB;
GO

DECLARE	@server_id	UNIQUEIDENTIFIER;
DECLARE @Class_Id	UNIQUEIDENTIFIER;

SELECT	@Server_id = Id
FROM	data.AdminServers
WHERE	HostName = N'NB-LENOVO-I'
		AND ServerName = N'SQL_2017';

SELECT	@Class_Id = Id
FROM	system.Classes
WHERE	Name = N'DriveLatency';

IF CAST(SERVERPROPERTY('ProductVersion') AS CHAR(10)) <= '11'
BEGIN
RAISERROR ('SQL Server 2008', 0, 1) WITH NOWAIT;
INSERT INTO data.ClassValues
(Server_Id, Class_Id, PValue01, PValue02, PValue03, PValue04, PValue05, PValue06, PValue07)
EXEC	sp_executesql N'
WITH database_storage
AS
(
	SELECT	LEFT(MF.physical_name, 2)	AS Drive,
			SUM(num_of_reads)			AS num_of_reads,
			SUM(io_stall_read_ms)		AS io_stall_read_ms,
			SUM(num_of_writes)			AS num_of_writes,
			SUM(io_stall_write_ms)		AS io_stall_write_ms,
			SUM(num_of_bytes_read)		AS num_of_bytes_read,
			SUM(num_of_bytes_written)	AS num_of_bytes_written,
			SUM(io_stall)				AS io_stall
	FROM	sys.master_files AS MF
			INNER JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
			ON (
					MF.database_id = vfs.database_id AND
					MF.file_id = vfs.file_id
				)
	GROUP BY
			LEFT(MF.physical_name, 2)
)
SELECT	@Server_Id					AS Server_Id,
		@Class_Id					AS Class_Id,
		[Drive],
		CASE WHEN num_of_reads = 0
			THEN 0 
			ELSE io_stall_read_ms / num_of_reads 
		END AS [Read Latency],
		CASE 
			WHEN io_stall_write_ms = 0 THEN 0 
			ELSE (io_stall_write_ms/num_of_writes) 
		END AS [Write Latency],
		CASE 
			WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0 
			ELSE (io_stall/(num_of_reads + num_of_writes)) 
		END AS [Overall Latency],
		CASE 
			WHEN num_of_reads = 0 THEN 0 
			ELSE (num_of_bytes_read/num_of_reads) 
		END AS [Avg Bytes/Read],
		CASE 
			WHEN io_stall_write_ms = 0 THEN 0 
			ELSE (num_of_bytes_written/num_of_writes) 
		END AS [Avg Bytes/Write],
		CASE 
			WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0 
			ELSE ((num_of_bytes_read + num_of_bytes_written)/(num_of_reads + num_of_writes)) 
		END AS [Avg Bytes/Transfer]
FROM	database_storage
ORDER BY
		[Drive];',
		N'@Server_Id UNIQUEIDENTIFIER, @Class_Id UNIQUEIDENTIFIER',
		@Server_Id, @Class_Id;
END
ELSE
BEGIN
RAISERROR ('SQL Server 2012', 0, 1) WITH NOWAIT;
INSERT INTO data.ClassValues
(Server_Id, Class_Id, PValue01, PValue02, PValue03, PValue04, PValue05, PValue06, PValue07)
EXEC sp_executesql N'
WITH database_storage
AS
(
	SELECT	LEFT(MF.physical_name, 2)	AS Drive,
			SUM(num_of_reads)			AS num_of_reads,
			SUM(io_stall_read_ms)		AS io_stall_read_ms,
			SUM(num_of_writes)			AS num_of_writes,
			SUM(io_stall_write_ms)		AS io_stall_write_ms,
			SUM(num_of_bytes_read)		AS num_of_bytes_read,
			SUM(num_of_bytes_written)	AS num_of_bytes_written,
			SUM(io_stall)				AS io_stall
	FROM	sys.master_files AS MF
			CROSS APPLY sys.dm_io_virtual_file_stats(MF.database_id, MF.file_id) AS vfs
	GROUP BY
			LEFT(MF.physical_name, 2)
)
SELECT	@Server_Id					AS Server_Id,
		@Class_Id					AS Class_Id,
		[Drive],
		CASE WHEN num_of_reads = 0
			THEN 0 
			ELSE io_stall_read_ms / num_of_reads 
		END AS [Read Latency],
		CASE 
			WHEN io_stall_write_ms = 0 THEN 0 
			ELSE (io_stall_write_ms/num_of_writes) 
		END AS [Write Latency],
		CASE 
			WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0 
			ELSE (io_stall/(num_of_reads + num_of_writes)) 
		END AS [Overall Latency],
		CASE 
			WHEN num_of_reads = 0 THEN 0 
			ELSE (num_of_bytes_read/num_of_reads) 
		END AS [Avg Bytes/Read],
		CASE 
			WHEN io_stall_write_ms = 0 THEN 0 
			ELSE (num_of_bytes_written/num_of_writes) 
		END AS [Avg Bytes/Write],
		CASE 
			WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0 
			ELSE ((num_of_bytes_read + num_of_bytes_written)/(num_of_reads + num_of_writes)) 
		END AS [Avg Bytes/Transfer]
FROM	database_storage
ORDER BY
		[Drive];',
		N'@Server_Id UNIQUEIDENTIFIER, @Class_Id UNIQUEIDENTIFIER',
		@Server_Id, @Class_Id;
END
GO

CREATE OR ALTER VIEW data.DriveLatency
AS
	SELECT	Server_Id,
			CAST(PValue01 AS CHAR(2))	AS	Drive,
			CAST(PValue02 AS BIGINT)	AS	[Read Latency],
			CAST(PValue03 AS BIGINT)	AS	[Write Latency],
			CAST(PValue04 AS BIGINT)	AS	[Overall Latency],
			ValidFrom,
			ValidTo
	FROM	data.ClassValues
	WHERE	Class_Id = system.GetClass_Id('DriveLatency');
GO

SELECT * FROM data.DriveLatency
FOR SYSTEM_TIME ALL
WHERE	Drive = N'F:';
GO


UPDATE	data.ClassValues
SET		PValue02 = 10
WHERE	PValue01 = N'F:';
GO
