USE [FLDataMart]
GO

IF OBJECT_ID(N'dbo.FusionLiveProjectMapping_test', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.FusionLiveProjectMapping_test
    (
        WorkSpaceId INT NOT NULL,
        FolderPattern VARCHAR(500) NOT NULL,
        ProjectNumber VARCHAR(100) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_FusionLiveProjectMapping_test_IsActive DEFAULT (1),
        CreatedDate DATETIME2(0) NOT NULL CONSTRAINT DF_FusionLiveProjectMapping_test_CreatedDate DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_FusionLiveProjectMapping_test PRIMARY KEY (WorkSpaceId, FolderPattern)
    );
END
GO

-- New mappings can use the project number as the match text:
-- INSERT INTO dbo.FusionLiveProjectMapping_test (WorkSpaceId, FolderPattern, ProjectNumber)
-- VALUES (12345, '%10715.500%', '10715.500');
GO

