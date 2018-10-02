USE CollectionDB;
GO

IF OBJECT_ID(N'system.Classes', N'U') IS NOT NULL
	DROP TABLE system.Classes;
	GO

CREATE TABLE system.Classes
(
	Id		UNIQUEIDENTIFIER	NOT NULL	DEFAULT (NEWID()) ROWGUIDCOL,
	name	VARCHAR(64)			NOT NULL,
	sp_name	NVARCHAR(128)		NULL,

	CONSTRAINT pk_Classes PRIMARY KEY CLUSTERED
	(Id)
);
GO

INSERT INTO system.classes (name, sp_name)
VALUES
('ServerProperties', 'collector.sp_ServerProperties'),
('DriveLatency', 'collector.sp_DriveLatency');
GO

SELECT * FROM system.Classes;
GO

CREATE OR ALTER FUNCTION system.GetClass_Id(@Name VARCHAR(64))
RETURNS UNIQUEIDENTIFIER
AS
BEGIN
	DECLARE @RetValue UNIQUEIDENTIFIER;
	SELECT	@RetValue = ID
	FROM	system.Classes
	WHERE	name = @Name;

	RETURN	@RetValue;
END
GO

