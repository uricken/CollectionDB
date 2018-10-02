USE CollectionDB;
GO

IF OBJECT_ID(N'system.GetClassId', N'FN') IS NOT NULL
	DROP FUNCTION system.GetClassId;
	GO

CREATE FUNCTION system.GetClassId(@ClassName VARCHAR(64))
RETURNS UNIQUEIDENTIFIER
AS
BEGIN
	RETURN
	(
		SELECT	Id
		FROM	system.Classes
		WHERE	name = @ClassName
	);
END
GO

SELECT	system.GetClassId(N'ServerProperties');
GO
