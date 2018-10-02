/*============================================================================
	File:		proc - system.WriteActivityLog.sql

	Summary:	This script creates a stored procedure which writes into
				the activity log. The returnvalue is the id (uniqueidentifier)
				which can be used to update the entry

	Date:		July 2018

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

IF OBJECT_ID(N'system.WriteActivityLog', N'P') IS NOT NULL
	DROP PROC system.WriteActivityLog;
	GO

CREATE PROCEDURE system.WriteActivityLog
	@EntryId		UNIQUEIDENTIFIER	NULL,
	@proc_name		sysname				NULL,
	@process_step	NVARCHAR(2048)		NULL,
	@error_message	NVARCHAR(2048)		NULL,
	@error_number	INT					NULL,
	@ReturnValue	UNIQUEIDENTIFIER	OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	IF CAST(system.GetParameterValue(N'activate_activity_log') AS INT) = 0
		RETURN;

	DECLARE	@ReturnTable TABLE (EntryId UNIQUEIDENTIFIER);

	IF @EntryId IS NULL
	BEGIN
		INSERT INTO data.ActivityLog
		(server_name, proc_name, process_step, ErrorMessage, ErrorNumber)
		OUTPUT inserted.EntryId INTO @ReturnTable
		VALUES
		(@@SERVERNAME, @proc_name, @process_step, @error_message, ISNULL(@error_number, 0))

		SELECT	@ReturnValue = EntryId FROM @ReturnTable;
	END

	ELSE
		UPDATE	data.ActivityLog
		SET		end_time = GETDATE(),
				ErrorMessage = @error_message,
				ErrorNumber = ISNULL(@error_number, 0)
		WHERE	EntryId = @EntryId;

	SET NOCOUNT OFF
END
GO

TRUNCATE TABLE data.ActivityLog;
GO

-- Testentry
DECLARE @ReturnValue UNIQUEIDENTIFIER;
EXEC system.WriteActivityLog
	@EntryId = NULL ,                  --uniqueidentifier
    @proc_name = 'Test',               --sysname
    @process_step = N'Test' ,          --nvarchar(2048)
    @error_message = NULL ,            --nvarchar(2048)
    @error_number = NULL,              --int
    @ReturnValue = @ReturnValue OUTPUT --uniqueidentifier

WAITFOR DELAY '00:00:05.000';

EXEC system.WriteActivityLog
	@EntryId = @ReturnValue,
	@proc_name = NULL,
	@process_step = NULL,
	@error_message = N'Das ist ein Fehler' ,             -- nvarchar(2048)
    @error_number = 3103,
	@ReturnValue = @ReturnValue OUTPUT;

SELECT * FROM data.ActivityLog;
GO
