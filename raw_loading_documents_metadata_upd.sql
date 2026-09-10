USE [FLDataMart]
GO

/****** Object:  StoredProcedure [dbo].[raw_loading_documents_metadata_upd]    Script Date: 9/10/2026 9:06:54 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[raw_loading_documents_metadata_upd] (@WorkSpaceId INT, @FilePath VARCHAR (200))
AS

/************************************************************************************************************ 
	Stored Procedure Name:	raw_loading_documents_metadata_upd
	
	CREATED by:		sliu on 09/14/2023
	
	EXEC dbo.raw_loading_documents_metadata_upd 16232, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16232.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16263, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16263HESSBALDPATE.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16338, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16338MITSUBISHI.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16354, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16354ENTERPRISE.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16392, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16392HESSOPS.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16394, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16394CLEANPLANET.txt'

	EXEC dbo.raw_loading_documents_metadata_upd 16472, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16472JERAPMO.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16474, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16474SINAGTALA.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16539, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16539EDGCORPORATE.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16548, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16548CBHGROUP.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16585, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16585MWCCMCVA.txt'
	EXEC dbo.raw_loading_documents_metadata_upd 16585, '\\IMSQL19.EDG.NET\SourceData\FusionLive\16585MWCCMCVA.txt'

	EXEC IMDataHub.dbo.rpt_fl_vendor_data_weekly_detail_upd 16338
	EXEC IMDataHub.dbo.rpt_fl_vendor_data_project_weekly_detail_upd '10416'
**************************************************************************************************************/
SET QUOTED_IDENTIFIER OFF;
SET NOCOUNT ON;

DECLARE @BulkInsert VARCHAR(200), @Last_Updated DATETIME;

SELECT @Last_Updated = ISNULL(MAX(ISNULL(last_updated_time, uploaded)), '01/01/2020')
FROM dbo.raw_fusionLive_documents_metadata
WHERE WorkSpaceId = @WorkSpaceId;

TRUNCATE TABLE dbo.fl_raw_export_emp;
SELECT @BulkInsert = 'BULK INSERT dbo.v_fl_raw_export_emp FROM "' + @FilePath + '"';

--SELECT @BulkInsert AS BulkInsert;
--BULK INSERT dbo.fl_raw_export_emp FROM '\\IMSQL19.EDG.NET\SourceData\FusionLive\SearchResult.txt'

EXEC(@BulkInsert);
--SELECT * FROM dbo.fl_raw_export_emp

TRUNCATE TABLE dbo.fl_raw_export_table;
INSERT INTO dbo.fl_raw_export_table (TransId, LineText)
SELECT TransId, LineText FROM dbo.fl_raw_export_emp
WHERE LineText NOT LIKE '<?xml%'
AND LineText NOT LIKE '<status%' AND LineText NOT LIKE '</status%'
AND LineText NOT LIKE '<workspace%'
AND LineText NOT LIKE '<documents%' AND LineText NOT LIKE '</documents%'
AND LineText NOT IN ('<attributes>', '</attributes>')
ORDER BY 1;

--UPDATE dbo.fl_raw_export_table SET LineText = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(LineText,'</',''),'/>',''),'<',''),'>','')));
/*
UPDATE dbo.fl_raw_export_table SET LineText = LTRIM(RTRIM(LineText));
UPDATE dbo.fl_raw_export_table SET LineText = RIGHT(LineText, LEN(LineText) - 2) WHERE LEFT(LineText, 2) = '</';
UPDATE dbo.fl_raw_export_table SET LineText = LEFT(LineText, LEN(LineText) - 2) WHERE RIGHT(LineText, 2) = '/>';
UPDATE dbo.fl_raw_export_table SET LineText = RIGHT(LineText, LEN(LineText) - 1) WHERE LEFT(LineText, 1) = '<';
UPDATE dbo.fl_raw_export_table SET LineText = LEFT(LineText, LEN(LineText) - 1) WHERE RIGHT(LineText, 1) = '>';
UPDATE dbo.fl_raw_export_table SET LineText = LTRIM(RTRIM(LineText));
*/
UPDATE dbo.fl_raw_export_table
SET FLID = CAST(LEFT(REPLACE(LineText,'<document id="',''), CHARINDEX('"', REPLACE(LineText,'<document id="','')) - 1) AS BIGINT),
	LineText = RIGHT(LineText, LEN(LineText) - CHARINDEX('reference=', LineText, 1) + 1) 
WHERE LineText LIKE '<document id="%'

UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, 'reference="', 'reference=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" title="', '| title=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" revision="', '| revision=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" status="', '| status=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" version="', '| version=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" islatest="', '| islatest=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" hascontent="', '| hascontent=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" haslink="', '| haslink=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" islink="', '| islink=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" islocked="', '| islocked=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" ischeckout="', '| ischeckout=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" lockedbyid="', '| lockedbyid=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" lockedbyname="', '| lockedbyname=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" hasattachment="', '| hasattachment=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" isattachment="', '| isattachment=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" hasmarkup="', '| hasmarkup=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" companyname="', '| companyname=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" externalurl="', '| externalurl=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" uploaded="', '| uploaded=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" size="', '| size=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" uptodate="', '| uptodate=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" revisioncount="', '| revisioncount=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" last_updated_time="', '| last_updated_time=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" last_updated_by="', '| last_updated_by=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" uri="', '| uri=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" hasprojectfiles="', '| hasprojectfiles=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" hasrendition="', '| hasrendition=|') WHERE LineText LIKE 'reference=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '">', '|>') WHERE LineText LIKE 'reference=%' AND LineText LIKE '%">';

--Remove specail characters in Vendor Reference Number column
DECLARE @ParentId INT, @ChildId INT, @ParentIdText VARCHAR(800), @ChildText VARCHAR(800)

DECLARE c_VendorReferenceNumber INSENSITIVE CURSOR FOR
SELECT b.TransId ParentId, REPLACE(REPLACE(REPLACE(b.LineText,CHAR(10),''),CHAR(13),''),CHAR(160),'') ParentText,
		a.TransId ChildId, a.LineText ChildText
FROM dbo.fl_raw_export_table a
INNER JOIN dbo.fl_raw_export_table b ON a.TransId -1 = b.TransId
WHERE a.LineText NOT LIKE '<%'
AND b.LineText LIKE '<attribute name="Vendor Reference Number"%';

OPEN c_VendorReferenceNumber;
FETCH NEXT FROM c_VendorReferenceNumber INTO @ParentId, @ParentIdText, @ChildId, @ChildText
WHILE (@@FETCH_STATUS = 0)
	BEGIN
		UPDATE dbo.fl_raw_export_table
		SET LineText = @ParentIdText + @ChildText
		WHERE TransId = @ParentId;

		DELETE FROM dbo.fl_raw_export_table WHERE TransId = @ChildId;

		FETCH NEXT FROM c_VendorReferenceNumber INTO @ParentId, @ParentIdText, @ChildId, @ChildText
	END
CLOSE c_VendorReferenceNumber;
DEALLOCATE c_VendorReferenceNumber;

--Process FusionLive record ID
DECLARE @TransId INT, @LineText VARCHAR(8000), @FLID BIGINT, @max_TransId INT;

DECLARE c_update_flid INSENSITIVE CURSOR FOR
SELECT TransId, FLID
FROM dbo.fl_raw_export_table
WHERE FLID IS NOT NULL;

OPEN c_update_flid;
FETCH NEXT FROM c_update_flid INTO @TransId, @FLID;

WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @max_TransId = NULL;

		SELECT @max_TransId = MIN(TransId)
		FROM dbo.fl_raw_export_table
		WHERE TransId > @TransId
		AND LineText = '</document>';

		IF @max_TransId IS NOT NULL
			BEGIN
				UPDATE dbo.fl_raw_export_table
				SET FLID = @FLID
				WHERE TransId > @TransId AND TransId <= @max_TransId;
			END

		FETCH NEXT FROM c_update_flid INTO @TransId, @FLID;
	END
CLOSE c_update_flid;
DEALLOCATE c_update_flid;

DECLARE
			@reference VARCHAR(100),
			@title VARCHAR(255),
			@revision VARCHAR(20),
			@status VARCHAR(100),
			@version VARCHAR(20),
			@islatest BIT,
			@hascontent BIT,
			@haslink BIT,
			@islink BIT,
			@islocked BIT,
			@ischeckout BIT,
			@lockedbyid  VARCHAR(20),
			@lockedbyname VARCHAR(100),
			@hasattachment BIT,
			@isattachment BIT,
			@hasmarkup BIT,
			@companyname VARCHAR(100),
			@externalurl VARCHAR(200),
			@uploaded DATETIME,
			@size VARCHAR(50),
			@uptodate BIT,
			@revisioncount TINYINT,
			@last_updated_time DATETIME,
			@last_updated_by VARCHAR(50),
			@uri VARCHAR(255),
			@hasprojectfile BIT,
			@hasrendition BIT

--Process FusionLive main elements
TRUNCATE TABLE dbo.raw_fusionLive_documents_metadata_temp;

DECLARE c_parse_element CURSOR FOR
SELECT TransId, LineText, FLID
FROM dbo.fl_raw_export_table
WHERE LineText LIKE 'reference=|%';

OPEN c_parse_element;
FETCH NEXT FROM c_parse_element INTO @TransId, @LineText, @FLID;

WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT
			@reference = NULL,
			@title = NULL,
			@revision = NULL,
			@status = NULL,
			@version = NULL,
			@islatest = NULL,
			@hascontent = NULL,
			@haslink = NULL,
			@islink = NULL,
			@islocked = NULL,
			@ischeckout = NULL,
			@lockedbyid = NULL,
			@lockedbyname = NULL,
			@hasattachment = NULL,
			@isattachment = NULL,
			@hasmarkup = NULL,
			@companyname = NULL,
			@externalurl = NULL,
			@uploaded = NULL,
			@size = NULL,
			@uptodate = NULL,
			@revisioncount = NULL,
			@last_updated_time = NULL,
			@last_updated_by = NULL,
			@uri = NULL,
			@hasprojectfile = NULL,
			@hasrendition = NULL

		SELECT @reference = SUBSTRING(@LineText, 12, CHARINDEX('| title=|', @LineText, 1) - 12);
		SELECT @title = SUBSTRING(@LineText, (CHARINDEX('| title=|', @LineText, 1) + LEN('| title=|')), 
						CHARINDEX('| revision=|', @LineText, 1) - (CHARINDEX('| title=|', @LineText, 1) + LEN('| title=|')));
		SELECT @revision = SUBSTRING(@LineText, (CHARINDEX('| revision=|', @LineText, 1) + LEN('| revision=|')), 
						CHARINDEX('| status=|', @LineText, 1) - (CHARINDEX('| revision=|', @LineText, 1) + LEN('| revision=|')));
		SELECT @status = SUBSTRING(@LineText, (CHARINDEX('| status=|', @LineText, 1) + LEN('| status=|')), 
						CHARINDEX('| version=|', @LineText, 1) - (CHARINDEX('| status=|', @LineText, 1) + LEN('| status=|')));
		SELECT @version = SUBSTRING(@LineText, (CHARINDEX('| version=|', @LineText, 1) + LEN('| version=|')), 
						CHARINDEX('| islatest=|', @LineText, 1) - (CHARINDEX('| version=|', @LineText, 1) + LEN('| version=|')));
		SELECT @islatest = SUBSTRING(@LineText, (CHARINDEX('| islatest=|', @LineText, 1) + LEN('| islatest=|')), 
						CHARINDEX('| hascontent=|', @LineText, 1) - (CHARINDEX('| islatest=|', @LineText, 1) + LEN('| islatest=|')));
		SELECT @hascontent = SUBSTRING(@LineText, (CHARINDEX('| hascontent=|', @LineText, 1) + LEN('| hascontent=|')), 
						CHARINDEX('| haslink=|', @LineText, 1) - (CHARINDEX('| hascontent=|', @LineText, 1) + LEN('| hascontent=|')));
		SELECT @haslink = SUBSTRING(@LineText, (CHARINDEX('| haslink=|', @LineText, 1) + LEN('| haslink=|')), 
						CHARINDEX('| islink=|', @LineText, 1) - (CHARINDEX('| haslink=|', @LineText, 1) + LEN('| haslink=|')));
		SELECT @islink = SUBSTRING(@LineText, (CHARINDEX('| islink=|', @LineText, 1) + LEN('| islink=|')), 
						CHARINDEX('| islocked=|', @LineText, 1) - (CHARINDEX('| islink=|', @LineText, 1) + LEN('| islink=|')));
		SELECT @islocked = SUBSTRING(@LineText, (CHARINDEX('| islocked=|', @LineText, 1) + LEN('| islocked=|')), 
						CHARINDEX('| ischeckout=|', @LineText, 1) - (CHARINDEX('| islocked=|', @LineText, 1) + LEN('| islocked=|')));
		SELECT @ischeckout = SUBSTRING(@LineText, (CHARINDEX('| ischeckout=|', @LineText, 1) + LEN('| ischeckout=|')), 
				CHARINDEX('|', @LineText, (CHARINDEX('| ischeckout=|', @LineText, 1) + LEN('| ischeckout=|') + 1)) - (CHARINDEX('| ischeckout=|', @LineText, 1) + LEN('| ischeckout=|')));
		SELECT @lockedbyid = CASE WHEN CHARINDEX('| lockedbyid=|', @LineText, 1) > 0 THEN
				SUBSTRING(@LineText, (CHARINDEX('| lockedbyid=|', @LineText, 1) + LEN('| lockedbyid=|')), 
				CHARINDEX('|', @LineText, (CHARINDEX('| lockedbyid=|', @LineText, 1) + LEN('| lockedbyid=|') + 1)) - (CHARINDEX('| lockedbyid=|', @LineText, 1) + LEN('| lockedbyid=|')))
				ELSE NULL END;
		SELECT @lockedbyname = CASE WHEN CHARINDEX('| lockedbyname=|', @LineText, 1) > 0 THEN
				SUBSTRING(@LineText, (CHARINDEX('| lockedbyname=|', @LineText, 1) + LEN('| lockedbyname=|')), 
				CHARINDEX('|', @LineText, (CHARINDEX('| lockedbyname=|', @LineText, 1) + LEN('| lockedbyname=|') + 1)) - (CHARINDEX('| lockedbyname=|', @LineText, 1) + LEN('| lockedbyname=|')))
				ELSE NULL END;
		SELECT @hasattachment = SUBSTRING(@LineText, (CHARINDEX('| hasattachment=|', @LineText, 1) + LEN('| hasattachment=|')), 
						CHARINDEX('| isattachment=|', @LineText, 1) - (CHARINDEX('| hasattachment=|', @LineText, 1) + LEN('| hasattachment=|')));
		SELECT @isattachment = SUBSTRING(@LineText, (CHARINDEX('| isattachment=|', @LineText, 1) + LEN('| isattachment=|')), 
						CHARINDEX('| hasmarkup=|', @LineText, 1) - (CHARINDEX('| isattachment=|', @LineText, 1) + LEN('| isattachment=|')));
		SELECT @hasmarkup = SUBSTRING(@LineText, (CHARINDEX('| hasmarkup=|', @LineText, 1) + LEN('| hasmarkup=|')), 
						CHARINDEX('| companyname=|', @LineText, 1) - (CHARINDEX('| hasmarkup=|', @LineText, 1) + LEN('| hasmarkup=|')));
		SELECT @companyname = SUBSTRING(@LineText, (CHARINDEX('| companyname=|', @LineText, 1) + LEN('| companyname=|')), 
						CHARINDEX('| externalurl=|', @LineText, 1) - (CHARINDEX('| companyname=|', @LineText, 1) + LEN('| companyname=|')));
		SELECT @externalurl = SUBSTRING(@LineText, (CHARINDEX('| externalurl=|', @LineText, 1) + LEN('| externalurl=|')), 
						CHARINDEX('| uploaded=|', @LineText, 1) - (CHARINDEX('| externalurl=|', @LineText, 1) + LEN('| externalurl=|')));
		SELECT @uploaded = SUBSTRING(@LineText, (CHARINDEX('| uploaded=|', @LineText, 1) + LEN('| uploaded=|')), 
						CHARINDEX('| size=|', @LineText, 1) - (CHARINDEX('| uploaded=|', @LineText, 1) + LEN('| uploaded=|')));
		SELECT @size = SUBSTRING(@LineText, (CHARINDEX('| size=|', @LineText, 1) + LEN('| size=|')), 
						CHARINDEX('| uptodate=|', @LineText, 1) - (CHARINDEX('| size=|', @LineText, 1) + LEN('| size=|')));
		SELECT @uptodate = SUBSTRING(@LineText, (CHARINDEX('| uptodate=|', @LineText, 1) + LEN('| uptodate=|')), 
						CHARINDEX('| revisioncount=|', @LineText, 1) - (CHARINDEX('| uptodate=|', @LineText, 1) + LEN('| uptodate=|')));
		SELECT @revisioncount = SUBSTRING(@LineText, (CHARINDEX('| revisioncount=|', @LineText, 1) + LEN('| revisioncount=|')), 
						CHARINDEX('| last_updated_time=|', @LineText, 1) - (CHARINDEX('| revisioncount=|', @LineText, 1) + LEN('| revisioncount=|')));
		SELECT @last_updated_time = SUBSTRING(@LineText, (CHARINDEX('| last_updated_time=|', @LineText, 1) + LEN('| last_updated_time=|')), 
						CHARINDEX('| last_updated_by=|', @LineText, 1) - (CHARINDEX('| last_updated_time=|', @LineText, 1) + LEN('| last_updated_time=|')));
		SELECT @last_updated_by = SUBSTRING(@LineText, (CHARINDEX('| last_updated_by=|', @LineText, 1) + LEN('| last_updated_by=|')), 
						CHARINDEX('| uri=|', @LineText, 1) - (CHARINDEX('| last_updated_by=|', @LineText, 1) + LEN('| last_updated_by=|')));
		SELECT @uri = SUBSTRING(@LineText, (CHARINDEX('| uri=|', @LineText, 1) + LEN('| uri=|')), 
						CHARINDEX('| hasprojectfiles=|', @LineText, 1) - (CHARINDEX('| uri=|', @LineText, 1) + LEN('| uri=|')));
		SELECT @hasprojectfile = SUBSTRING(@LineText, (CHARINDEX('| hasprojectfiles=|', @LineText, 1) + LEN('| hasprojectfiles=|')), 
						CHARINDEX('| hasrendition=|', @LineText, 1) - (CHARINDEX('| hasprojectfiles=|', @LineText, 1) + LEN('| hasprojectfiles=|')));
		SELECT @hasrendition = CASE WHEN CHARINDEX('| hasrendition=|', @LineText, 1) > 0 THEN
				SUBSTRING(@LineText, (CHARINDEX('| hasrendition=|', @LineText, 1) + LEN('| hasrendition=|')), 
				CHARINDEX('|', @LineText, (CHARINDEX('| hasrendition=|', @LineText, 1) + LEN('| hasrendition=|') + 1)) - (CHARINDEX('| hasrendition=|', @LineText, 1) + LEN('| hasrendition=|')))
				ELSE NULL END;

		--SELECT @FLID AS FLID, @reference AS reference, @title AS title, @lockedbyid AS lockedbyid, @lockedbyname AS lockedbyname, @LineText AS LineText;

		INSERT INTO dbo.raw_fusionLive_documents_metadata_temp (
								WorkSpaceId,
								[id],
								reference,
								title,
								revision,
								Docstatus,
								[version],
								--isDeleted,
								islatest,
								hascontent,
								haslink,
								islink,
								islocked,
								ischeckout,
								lockedbyid,
								lockedbyname,
								hasattachment,
								isattachment,
								hasmarkup,
								companyname,
								externalurl,
								uploaded,
								size,
								uptodate,
								revisioncount,
								last_updated_time,
								last_updated_by,
								uri,
								hasprojectfile,
								hasrendition
						)
		VALUES (@WorkSpaceId,@FLID,@reference,@title,
								REPLACE(@revision,' ',''),
								@status,@version,@islatest,
								@hascontent,
								@haslink,
								@islink,
								@islocked,
								@ischeckout,
								@lockedbyid,
								@lockedbyname,
								@hasattachment,
								@isattachment,
								@hasmarkup,
								@companyname,
								CASE @externalurl WHEN '' THEN NULL ELSE @externalurl END,
								CASE @uploaded WHEN '1900-01-01 00:00:00.000' THEN NULL ELSE @uploaded END,
								CAST(@size AS BIGINT),
								@uptodate,
								@revisioncount,
								CASE @last_updated_time WHEN '1900-01-01 00:00:00.000' THEN NULL ELSE @last_updated_time END,
								CASE @last_updated_by WHEN '' THEN NULL ELSE @last_updated_by END,
								@uri,
								@hasprojectfile,
								@hasrendition
				);

		FETCH NEXT FROM c_parse_element INTO @TransId, @LineText, @FLID;
	END
CLOSE c_parse_element;
DEALLOCATE c_parse_element;

--Process FusionLive folder elements
DECLARE @FolderID BIGINT, @FolderName VARCHAR(1000);

DECLARE c_update_folderid INSENSITIVE CURSOR FOR
SELECT TransId, LineText, FLID
FROM dbo.fl_raw_export_table
WHERE LineText LIKE '<folder id%';

OPEN c_update_folderid;
FETCH NEXT FROM c_update_folderid INTO @TransId, @LineText, @FLID;

WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @FolderID = NULL;
		SELECT @FolderName = NULL;

		SELECT @FolderID = SUBSTRING(@LineText, 13, CHARINDEX('" name="', @LineText, 1) - 13);
		SELECT @FolderName = SUBSTRING(@LineText, (CHARINDEX('" name="', @LineText, 1) + LEN('" name="')), 
						CHARINDEX('" />', @LineText, 1) - (CHARINDEX('" name="', @LineText, 1) + LEN('" name="')));

		IF @FolderID IS NOT NULL
			BEGIN
				UPDATE dbo.raw_fusionLive_documents_metadata_temp
				SET FolderID = @FolderID, FolderName = @FolderName
				WHERE id = @FLID;
			END

		FETCH NEXT FROM c_update_folderid INTO @TransId, @LineText, @FLID;
	END
CLOSE c_update_folderid;
DEALLOCATE c_update_folderid;

--Process FusionLive category elements
DECLARE @category_id BIGINT, @category_name VARCHAR(100);

DECLARE c_update_category INSENSITIVE CURSOR FOR
SELECT TransId, LineText, FLID
FROM dbo.fl_raw_export_table
WHERE LineText LIKE '<category id%';

OPEN c_update_category;
FETCH NEXT FROM c_update_category INTO @TransId, @LineText, @FLID;

WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @category_id = NULL;
		SELECT @category_name = NULL;

		SELECT @category_id = SUBSTRING(@LineText, 15, CHARINDEX('" name="', @LineText, 1) - 15);
		SELECT @category_name = SUBSTRING(@LineText, (CHARINDEX('" name="', @LineText, 1) + LEN('" name="')), 
						CHARINDEX('" />', @LineText, 1) - (CHARINDEX('" name="', @LineText, 1) + LEN('" name="')));

		IF @FolderID IS NOT NULL
			BEGIN
				UPDATE dbo.raw_fusionLive_documents_metadata_temp
				SET category_id = @category_id, category_name = @category_name
				WHERE id = @FLID;
			END

		FETCH NEXT FROM c_update_category INTO @TransId, @LineText, @FLID;
	END
CLOSE c_update_category;
DEALLOCATE c_update_category;

--Process FusionLive file type elements
DECLARE @file_type VARCHAR(100), @file_mimetype VARCHAR(255), @file_name NVARCHAR(100), @file_size VARCHAR(50), @file_contentformatcode VARCHAR(50);

UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, 'file type="', 'file type=|') WHERE LineText LIKE '<file type=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" mimetype="', '| mimetype=|') WHERE LineText LIKE '<file type=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" name="', '| name=|') WHERE LineText LIKE '<file type=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" size="', '| size=|') WHERE LineText LIKE '<file type=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" contentformatcode="', '| contentformatcode=|') WHERE LineText LIKE '<file type=%';
UPDATE dbo.fl_raw_export_table SET LineText = REPLACE(LineText, '" />', '| />') WHERE LineText LIKE '<file type=%' AND LineText LIKE '%" />';

DECLARE c_update_category INSENSITIVE CURSOR FOR
SELECT TransId, LineText, FLID
FROM dbo.fl_raw_export_table
WHERE LineText LIKE '<file type=%';

OPEN c_update_category;
FETCH NEXT FROM c_update_category INTO @TransId, @LineText, @FLID;

WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @file_type = NULL;
		SELECT @file_mimetype = NULL;
		SELECT @file_name = NULL;
		SELECT @file_size = NULL;
		SELECT @file_contentformatcode = NULL;

		SELECT @file_type = CASE WHEN @LineText LIKE '%file type=%' THEN
								SUBSTRING(@LineText, 13, CHARINDEX('| mimetype=|', @LineText, 1) - 13)
							ELSE NULL END;
		SELECT @file_mimetype = CASE WHEN CHARINDEX('| mimetype=|', @LineText, 1) > 0 THEN
						SUBSTRING(@LineText, (CHARINDEX('| mimetype=|', @LineText, 1) + LEN('| mimetype=|')), 
						CHARINDEX('|', @LineText, (CHARINDEX('| mimetype=|', @LineText, 1) + LEN('| mimetype=|') + 1)) - (CHARINDEX('| mimetype=|', @LineText, 1) + LEN('| mimetype=|')))
						ELSE NULL END;
		SELECT @file_name = CASE WHEN CHARINDEX('| name=|', @LineText, 1) > 0 THEN
						SUBSTRING(@LineText, (CHARINDEX('| name=|', @LineText, 1) + LEN('| name=|')), 
						CHARINDEX('|', @LineText, (CHARINDEX('| name=|', @LineText, 1) + LEN('| name=|') + 1)) - (CHARINDEX('| name=|', @LineText, 1) + LEN('| name=|')))
						ELSE NULL END;

		SELECT @file_size = CASE WHEN CHARINDEX('| size=|', @LineText, 1) > 0 THEN
						SUBSTRING(@LineText, (CHARINDEX('| size=|', @LineText, 1) + LEN('| size=|')), 
						CHARINDEX('|', @LineText, (CHARINDEX('| size=|', @LineText, 1) + LEN('| size=|') + 1)) - (CHARINDEX('| size=|', @LineText, 1) + LEN('| size=|')))
						ELSE NULL END;
		SELECT @file_contentformatcode = CASE WHEN CHARINDEX('| contentformatcode=|', @LineText, 1) > 0 THEN
						SUBSTRING(@LineText, (CHARINDEX('| contentformatcode=|', @LineText, 1) + LEN('| contentformatcode=|')), 
						CHARINDEX('|', @LineText, (CHARINDEX('| contentformatcode=|', @LineText, 1) + LEN('| contentformatcode=|') + 1)) - (CHARINDEX('| contentformatcode=|', @LineText, 1) + LEN('| contentformatcode=|')))
						ELSE NULL END;

		IF @FolderID IS NOT NULL
			BEGIN
				UPDATE dbo.raw_fusionLive_documents_metadata_temp
				SET 
					file_type = @file_type,
					file_mimetype = @file_mimetype,
					[file_name] = @file_name,
					file_size = CAST(@file_size AS BIGINT),
					file_contentformatcode = CASE @file_contentformatcode
													WHEN 'text' THEN 'txt' WHEN 'excel8book' THEN 'xls' ELSE @file_contentformatcode END
				WHERE id = @FLID;
			END

		FETCH NEXT FROM c_update_category INTO @TransId, @LineText, @FLID;
	END
CLOSE c_update_category;
DEALLOCATE c_update_category;

--Set isDeleted flag
UPDATE dbo.raw_fusionLive_documents_metadata_temp SET isDeleted = 1 WHERE FolderName LIKE '%TRASH%' AND ISNULL(FolderName,'') NOT LIKE '%Trash Compactor%';

--Process file attributes: Revision Date
UPDATE d
SET d.[Revision Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE
							SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7)))
						END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Revision Date"%';

--Process file attributes: PM Status
UPDATE d
SET d.PM_Status = SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7)))
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="PM Status"%';

--Process file attributes: Decision Code
UPDATE d
SET d.[Decision Code] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Decision Code"%';

--Process file attributes: Phase
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Phase"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.Phase = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Phase"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.Phase = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Phase"%';
	END

--Process file attributes: Document Type
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Document Type"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.Document_Type = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Document Type"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.Document_Type = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Document Type"%';
	END

--Process file attributes: Originator
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Originator"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.Originator = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Originator"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.Originator = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Originator"%';
	END

--Process file attributes: Discipline
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Discipline"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.Discipline = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Discipline"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.Discipline = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Discipline"%';
	END

--Process file attributes: Scope group
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Scope group"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.Scope_Group = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Scope group"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.Scope_Group = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Scope group"%';
	END

--Process file attributes: Criticality
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Criticality"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.Criticality = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Criticality"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.Criticality = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Criticality"%';
	END

--Process file attributes: Area
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Area"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.Area = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Area"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.Area = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Area"%';
	END

--Process file attributes: Planned Submission Date
UPDATE d
SET d.[Planned Submission Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Planned submission date"%';

--Process file attributes: Forecast Submission Date
UPDATE d
SET d.[Forecast Submission Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Forecast submission date"%';

--Process file attributes: Actual Submission Date
UPDATE d
SET d.[Actual Submission Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Actual submission date"%';

--Process file attributes: Planned Resubmission Date
UPDATE d
SET d.[Planned Resubmission Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Planned resubmission date"%';

--Process file attributes: Forecast Resubmission Date
UPDATE d
SET d.[Forecast Resubmission Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Forecast resubmission date"%';

--Process file attributes: Actual Resubmission Date
UPDATE d
SET d.[Actual Resubmission Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Actual resubmission date"%';

--Process file attributes: Planned Issue Date
UPDATE d
SET d.[Planned issue Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Planned issue date"%';

--Process file attributes: Forecast issue Date
UPDATE d
SET d.[Forecast issue Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Forecast issue date"%';

--Process file attributes: Actual issue Date
UPDATE d
SET d.[Actual issue Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Actual issue date"%';

--Process file attributes: Reason For Issue
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Reason For Issue"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.[Reason For Issue] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Reason For Issue"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.[Reason For Issue] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Reason For Issue"%';
	END

--Process file attributes: Planned return Date
UPDATE d
SET d.[Planned Return Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Planned return date"%';

--Process file attributes: Actual return Date
UPDATE d
SET d.[Actual Return Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Actual return date"%';

--Process file attributes: Due Date
UPDATE d
SET d.Due_Date = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Due Date"%';

--Process file attributes: Planned review date
UPDATE d
SET d.[Planned review date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Planned review date"%';

--Process file attributes: Actual review date
UPDATE d
SET d.[Actual review date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Actual review date"%';

--Process file attributes: Percentage Complete
UPDATE d
SET d.Percentage_Complete = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Percentage Complete"%';

--Process file attributes: Man Hours
UPDATE d
SET d.[Man Hours] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Man Hours"%';

--Process file attributes: Client Decision Code
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Client Decision Code"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.[Client Decision Code] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Client Decision Code"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.[Client Decision Code] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Client Decision Code"%';
	END

--Process file attributes: Client Reference Number
UPDATE d
SET d.[Client Reference Number] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Client Reference Number"%';

--Process file attributes: Number
UPDATE d
SET d.Number = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Number"%';

--Process file attributes: CTR
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="CTR"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.CTR = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="CTR"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.CTR = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="CTR"%';
	END

--Process file attributes: VDR Code
UPDATE d
SET d.[DRS Number] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="VDR Code"%';

IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="As Built Required"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.AsBuilt = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="As Built Required"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.AsBuilt = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="As Built Required"%';
	END

/*
SELECT f.LineText, CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END AS AsBuilt
FROM dbo.fl_raw_export_table f WHERE f.LineText LIKE '<attribute name="As Built Required"%'
AND PATINDEX('%" code=%', f.LineText) > 0

SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="As Built Required"%' AND PATINDEX('%" code=%', f.LineText) > 0

--Process file attributes: As Built Required
IF @WorkSpaceId = 16788
	BEGIN
		UPDATE d
		SET d.AsBuilt = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="As Built Required"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.AsBuilt = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="As Built Required?"%';
	END
*/

--Process file attributes: Tag
UPDATE d
SET d.Tag = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Tag"%';

--Process file attributes: Forecast Client Response Date
UPDATE d
SET d.[Forecast Client Response Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Forecast Client Response Date"%';

--Process file attributes: Actual approval date
UPDATE d
SET d.[Actual approval date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Actual approval date"%';

--Process file attributes: Client response date
UPDATE d
SET d.[Client response date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Client response date"%';

--Process file attributes: Weighting
UPDATE d
SET d.Weighting = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Weighting"%';

IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Facility"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.Facility = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Facility"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.Facility = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Facility"%';
	END

--Process file attributes: PO
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="PO"%' AND PATINDEX('value="" code=""', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.[PO Number] = NULL
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="PO"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.[PO Number] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('code="', f.LineText, 1) + 6), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('code="', f.LineText, 1) + 6))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('code="', f.LineText, 1) + 6), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('code="', f.LineText, 1) + 6))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="PO"%';
	END

--Process file attributes: Contract
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="Contract"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.[Contract] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Contract"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.[Contract] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="Contract"%';
	END

--Process file attributes: [Client Revision]
UPDATE d
SET d.[Client Revision] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Client Revision"%';

--Process file attributes: Alternative Reference Number
UPDATE d
SET d.[Alternative Reference Number] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Alternative Reference Number"%';

--Process file attributes: Vendor Reference Number
UPDATE d
SET d.[Vendor Reference Number] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Vendor Reference Number"%';

--Process file attributes: FacilityArch
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="FacilityArch"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.FacilityArch = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="FacilityArch"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.FacilityArch = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="FacilityArch"%';
	END

--Process file attributes: VDR Code
UPDATE d
SET d.[VDR Code] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="VDR Code"%';

--Process file attributes: Issue Status
UPDATE d
SET d.[Issue Status] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Issue Status"%';

--Process file attributes: ABS Stamped
IF EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_temp d INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
				WHERE f.LineText LIKE '<attribute name="ABS Stamped"%' AND PATINDEX('%" code=%', f.LineText) > 0)
	BEGIN
		UPDATE d
		SET d.[ABS Stamped] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" code=', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="ABS Stamped"%';
	END
ELSE
	BEGIN
		UPDATE d
		SET d.[ABS Stamped] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
						WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
		FROM dbo.raw_fusionLive_documents_metadata_temp d
		INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
		WHERE f.LineText LIKE '<attribute name="ABS Stamped"%';
	END
/*
UPDATE d
SET d.[ABS Stamped] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="ABS Stamped"%';
<attribute name="ABS Stamped" system_name="ABS Stamped" value="YES" code="YES" />
*/
--Process file attributes: OldFileName
UPDATE d
SET d.OldFileName = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="OldFileName"%';

--Process file attributes: Reference for I3P Reviews
UPDATE d
SET d.[Reference for I3P Reviews] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Reference for I3P Reviews"%';

--Process file attributes: Transmittal Date
UPDATE d
SET d.[Transmittal Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Transmittal Date"%';

--Process file attributes: Transmittal Number
UPDATE d
SET d.[Transmittal Number] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Transmittal Number"%';

--Process file attributes: Supersedes
UPDATE d
SET d.Supersedes = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Supersedes"%';

--Process file attributes: Superseded By
UPDATE d
SET d.[Superseded By] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Superseded By"%';

--Process file attributes: PSI Issue Date
UPDATE d
SET d.[PSI Issue Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="PSI Issue Date"%';

--Process file attributes: PSI Response Date
UPDATE d
SET d.[PSI Response Date] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="PSI Response Date"%';

--Process file attributes: Source
UPDATE d
SET d.[Source] = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Source"%';

--Process file attributes: Created
UPDATE d
SET d.Created = CASE LEN(SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))))
				WHEN 0 THEN NULL ELSE SUBSTRING(f.LineText, (CHARINDEX('value="', f.LineText, 1) + 7), (CHARINDEX('" />', f.LineText, 1) - (CHARINDEX('value="', f.LineText, 1) + 7))) END
FROM dbo.raw_fusionLive_documents_metadata_temp d
INNER JOIN dbo.fl_raw_export_table f ON d.id = f.FLID
WHERE f.LineText LIKE '<attribute name="Created"%';

-- SET FusionLive URL
UPDATE dbo.raw_fusionLive_documents_metadata_temp
SET FusionLiveURL = 'https://us.fusion.live/servlet/Document?actiontype=GetBravaDocumentViewer&lang=en&vid=' + CAST(id AS VARCHAR) + '&objectType=DOCUMENT&selectedItemId=' + CAST(id AS VARCHAR) +
				'&actionFrom=&containerId=docs-main-tabs&docId=&mode=view&errorpanelId=documents-win-error&uiVariant=DESKTOP'
WHERE IsNull(PM_Status,'') != 'Pre-register';

--Process deleted records
INSERT INTO dbo.raw_fusionLive_documents_metadata_trash (
						WorkSpaceId,
						[id],
						reference,
						title,
						revision,
						[Revision Date],
						Docstatus,
						[version],
						isDeleted,
						islatest,
						hascontent,
						haslink,
						islink,
						islocked,
						ischeckout,
						lockedbyid,
						lockedbyname,
						hasattachment,
						isattachment,
						hasmarkup,
						companyname,
						externalurl,
						uploaded,
						size,
						uptodate,
						revisioncount,
						last_updated_time,
						last_updated_by,
						uri,
						hasprojectfile,
						hasrendition,
						category_id,
						category_name,
						file_type,
						file_mimetype,
						[file_name],
						file_size,
						file_contentformatcode,
						PM_Status,
						[Decision Code],
						[DRS Number],
						Phase,
						Document_Type,
						Originator,
						Discipline,
						Area,
						Scope_Group,
						Criticality,
						Number,
						CTR,
						AsBuilt,
						Tag,
						[Planned Submission Date],
						[Forecast Submission Date],
						[Actual Submission Date],
						[Planned Resubmission Date],
						[Forecast Resubmission Date],
						[Actual Resubmission Date],
						[Planned issue date],
						[Forecast issue date],
						[Actual issue date],
						[Reason For Issue],
						[Planned Return Date],
						[Actual Return Date],
						Due_Date,
						[Planned review date],
						[Actual review date],
						Percentage_Complete,
						[Man Hours],
						[Client Decision Code],
						[Client Reference Number],
						[Forecast Client Response Date],
						[Actual approval date],
						[Client response date],
						[Weighting],
						Facility,
						[Contract],
						[Client Revision],
						[Alternative Reference Number],
						[PO Number],
						[Vendor Reference Number],
						LocationPath,
						FusionLiveURL,
						Update_Date,
						FolderID,
						FolderName,
						FacilityArch,
						[VDR Code],
						[Issue Status],
						[ABS Stamped],
						OldFileName,
						[Reference for I3P Reviews],
						[Transmittal Date],
						[Transmittal Number],
						Supersedes,
						[Superseded By],
						[PSI Issue Date],
						[PSI Response Date],
						[Source],
						Created
		)
SELECT
						t.WorkSpaceId,
						t.[id],
						t.reference,
						REPLACE(t.title, '&amp;', 'and') title,
						t.revision,
						t.[Revision Date],
						t.Docstatus,
						t.[version],
						t.isDeleted,
						t.islatest,
						t.hascontent,
						t.haslink,
						t.islink,
						t.islocked,
						t.ischeckout,
						t.lockedbyid,
						t.lockedbyname,
						t.hasattachment,
						t.isattachment,
						t.hasmarkup,
						t.companyname,
						t.externalurl,
						t.uploaded,
						t.size,
						t.uptodate,
						t.revisioncount,
						t.last_updated_time,
						t.last_updated_by,
						t.uri,
						t.hasprojectfile,
						t.hasrendition,
						t.category_id,
						t.category_name,
						t.file_type,
						t.file_mimetype,
						t.[file_name],
						t.file_size,
						t.file_contentformatcode,
						t.PM_Status,
						t.[Decision Code],
						t.[DRS Number],
						t.Phase,
						t.Document_Type,
						t.Originator,
						t.Discipline,
						t.Area,
						t.Scope_Group,
						t.Criticality,
						t.Number,
						t.CTR,
						t.AsBuilt,
						t.Tag,
						t.[Planned Submission Date],
						t.[Forecast Submission Date],
						t.[Actual Submission Date],
						t.[Planned Resubmission Date],
						t.[Forecast Resubmission Date],
						t.[Actual Resubmission Date],
						t.[Planned issue date],
						t.[Forecast issue date],
						t.[Actual issue date],
						t.[Reason For Issue],
						t.[Planned Return Date],
						t.[Actual Return Date],
						t.Due_Date,
						t.[Planned review date],
						t.[Actual review date],
						t.Percentage_Complete,
						t.[Man Hours],
						t.[Client Decision Code],
						t.[Client Reference Number],
						t.[Forecast Client Response Date],
						t.[Actual approval date],
						t.[Client response date],
						t.[Weighting],
						t.Facility,
						t.[Contract],
						t.[Client Revision],
						t.[Alternative Reference Number],
						t.[PO Number],
						t.[Vendor Reference Number],
						t.LocationPath,
						t.FusionLiveURL,
						t.Update_Date,
						t.FolderID,
						t.FolderName,
						t.FacilityArch,
						t.[VDR Code],
						t.[Issue Status],
						t.[ABS Stamped],
						t.OldFileName,
						t.[Reference for I3P Reviews],
						t.[Transmittal Date],
						t.[Transmittal Number],
						t.Supersedes,
						t.[Superseded By],
						t.[PSI Issue Date],
						t.[PSI Response Date],
						t.[Source],
						t.Created
FROM dbo.raw_fusionLive_documents_metadata_temp t
WHERE t.isDeleted = 1
AND NOT EXISTS (SELECT 1 FROM dbo.raw_fusionLive_documents_metadata_trash s
				WHERE s.WorkSpaceId = t.WorkSpaceId AND s.id = t.id);

IF EXISTS (SELECT 1 
			FROM dbo.raw_fusionLive_documents_metadata f
			INNER JOIN dbo.raw_fusionLive_documents_metadata_temp t ON f.WorkSpaceId = t.WorkSpaceId AND f.id = t.id
			--WHERE t.isDeleted = 0 AND ISNULL(t.last_updated_time, t.uploaded) > @Last_Updated
			WHERE t.isDeleted = 1
		)
	BEGIN
		DELETE f
		FROM dbo.raw_fusionLive_documents_metadata f
		INNER JOIN dbo.raw_fusionLive_documents_metadata_temp t ON f.WorkSpaceId = t.WorkSpaceId AND f.id = t.id
		--WHERE t.isDeleted = 0 AND ISNULL(t.last_updated_time, t.uploaded) > @Last_Updated
		WHERE t.isDeleted = 1
	END

DELETE f
FROM dbo.raw_fusionLive_documents_metadata f
INNER JOIN dbo.raw_fusionLive_documents_metadata_temp t ON f.WorkSpaceId = t.WorkSpaceId AND f.id = t.id
WHERE t.isDeleted = 0;

INSERT INTO dbo.raw_fusionLive_documents_metadata (
						WorkSpaceId,
						[id],
						reference,
						title,
						revision,
						[Revision Date],
						Docstatus,
						[version],
						isDeleted,
						islatest,
						hascontent,
						haslink,
						islink,
						islocked,
						ischeckout,
						lockedbyid,
						lockedbyname,
						hasattachment,
						isattachment,
						hasmarkup,
						companyname,
						externalurl,
						uploaded,
						size,
						uptodate,
						revisioncount,
						last_updated_time,
						last_updated_by,
						uri,
						hasprojectfile,
						hasrendition,
						category_id,
						category_name,
						file_type,
						file_mimetype,
						[file_name],
						file_size,
						file_contentformatcode,
						PM_Status,
						[Decision Code],
						[DRS Number],
						Phase,
						Document_Type,
						Originator,
						Discipline,
						Area,
						Scope_Group,
						Criticality,
						Number,
						CTR,
						AsBuilt,
						Tag,
						[Planned Submission Date],
						[Forecast Submission Date],
						[Actual Submission Date],
						[Planned Resubmission Date],
						[Forecast Resubmission Date],
						[Actual Resubmission Date],
						[Planned issue date],
						[Forecast issue date],
						[Actual issue date],
						[Reason For Issue],
						[Planned Return Date],
						[Actual Return Date],
						Due_Date,
						[Planned review date],
						[Actual review date],
						Percentage_Complete,
						[Man Hours],
						[Client Decision Code],
						[Client Reference Number],
						[Forecast Client Response Date],
						[Actual approval date],
						[Client response date],
						[Weighting],
						Facility,
						[Contract],
						[Client Revision],
						[Alternative Reference Number],
						[PO Number],
						[Vendor Reference Number],
						LocationPath,
						FusionLiveURL,
						Update_Date,
						FolderID,
						FolderName,
						FacilityArch,
						[VDR Code],
						[Issue Status],
						[ABS Stamped],
						OldFileName,
						[Reference for I3P Reviews],
						[Transmittal Date],
						[Transmittal Number],
						Supersedes,
						[Superseded By],
						[PSI Issue Date],
						[PSI Response Date],
						[Source],
						Created
		)
SELECT
						t.WorkSpaceId,
						t.[id],
						t.reference,
						REPLACE(t.title, '&amp;', 'and') title,
						t.revision,
						t.[Revision Date],
						t.Docstatus,
						t.[version],
						t.isDeleted,
						t.islatest,
						t.hascontent,
						t.haslink,
						t.islink,
						t.islocked,
						t.ischeckout,
						t.lockedbyid,
						t.lockedbyname,
						t.hasattachment,
						t.isattachment,
						t.hasmarkup,
						t.companyname,
						t.externalurl,
						t.uploaded,
						t.size,
						t.uptodate,
						t.revisioncount,
						t.last_updated_time,
						t.last_updated_by,
						t.uri,
						t.hasprojectfile,
						t.hasrendition,
						t.category_id,
						t.category_name,
						t.file_type,
						t.file_mimetype,
						t.[file_name],
						t.file_size,
						t.file_contentformatcode,
						t.PM_Status,
						t.[Decision Code],
						t.[DRS Number],
						t.Phase,
						t.Document_Type,
						t.Originator,
						t.Discipline,
						t.Area,
						t.Scope_Group,
						t.Criticality,
						t.Number,
						t.CTR,
						t.AsBuilt,
						t.Tag,
						t.[Planned Submission Date],
						t.[Forecast Submission Date],
						t.[Actual Submission Date],
						t.[Planned Resubmission Date],
						t.[Forecast Resubmission Date],
						t.[Actual Resubmission Date],
						t.[Planned issue date],
						t.[Forecast issue date],
						t.[Actual issue date],
						t.[Reason For Issue],
						t.[Planned Return Date],
						t.[Actual Return Date],
						t.Due_Date,
						t.[Planned review date],
						t.[Actual review date],
						t.Percentage_Complete,
						t.[Man Hours],
						t.[Client Decision Code],
						t.[Client Reference Number],
						t.[Forecast Client Response Date],
						t.[Actual approval date],
						t.[Client response date],
						t.[Weighting],
						t.Facility,
						t.[Contract],
						t.[Client Revision],
						t.[Alternative Reference Number],
						t.[PO Number],
						t.[Vendor Reference Number],
						t.LocationPath,
						t.FusionLiveURL,
						t.Update_Date,
						t.FolderID,
						t.FolderName,
						t.FacilityArch,
						t.[VDR Code],
						t.[Issue Status],
						t.[ABS Stamped],
						t.OldFileName,
						t.[Reference for I3P Reviews],
						t.[Transmittal Date],
						t.[Transmittal Number],
						t.Supersedes,
						t.[Superseded By],
						[PSI Issue Date],
						[PSI Response Date],
						t.[Source],
						t.Created
FROM dbo.raw_fusionLive_documents_metadata_temp t
WHERE t.isDeleted = 0;

IF @WorkSpaceId = 16263
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10292.200%' THEN '10292.200'
								WHEN FolderName LIKE '/10292.302%' THEN '10292.302'
							ELSE '10292.200' END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16338
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/%01-10416%' THEN '10416.100'
								WHEN FolderName LIKE '/%02-10078%' THEN '10078.103'
								WHEN FolderName LIKE '/%03-10078%' THEN '10078.104'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16392
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%10446 Hatch%' THEN '10446.009'
								WHEN FolderName LIKE '%10446 Pipe%' THEN '10446.010'
								WHEN FolderName LIKE '%10446 SW Reject%' THEN '10446.003'
								WHEN FolderName LIKE '%10446 SWIM%' THEN '10446.007'
								WHEN FolderName LIKE '%10446.011%' THEN '10446.011'
								WHEN FolderName LIKE '%10454 Baldpate Egress%' THEN '10454.007'
								WHEN FolderName LIKE '%10454 PDL-1299%' THEN '10454.003'
								WHEN FolderName LIKE '%10454 PS-227%' THEN '10454.002'
								WHEN FolderName LIKE '%10454 Well Bay%' THEN '10454.005'
								WHEN FolderName LIKE '%10454.008%' THEN '10454.008'
								WHEN FolderName LIKE '%10454.009%' THEN '10454.009'
								WHEN FolderName LIKE '%10454.010%' THEN '10454.010'
								WHEN FolderName LIKE '%10454.011%' THEN '10454.011'
								WHEN FolderName LIKE '/03 - Tubular Bells/%' THEN '6566.703'
								WHEN FolderName LIKE '/10839%' THEN '10839.002'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16548
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10614100%' THEN '10614.100'
								WHEN FolderName LIKE '/10950400%' THEN '10950.400'
								WHEN FolderName LIKE '/10951400%' THEN '10951.400'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16585
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/9874.400%' THEN '9874.400'
								WHEN FolderName LIKE '/9874.410%' THEN '9874.410'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16614
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/9287400%' THEN '9287.400'
								WHEN FolderName LIKE '/9287402%' THEN '9287.402'
								WHEN FolderName LIKE '/9068401%' THEN '9068.401'
								WHEN FolderName LIKE '/9287.450%' THEN '9287.450'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16626
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10772.301%' THEN '10772.301'
								WHEN FolderName LIKE '/10772.400%' THEN '10772.400'
								WHEN FolderName LIKE '/11611.101%' THEN '11611.101'
								WHEN FolderName LIKE '/11611.102%' THEN '11611.102'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16690
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10065.001%' THEN '10065.001'
								WHEN FolderName LIKE '/10065.420%' THEN '10065.420'
								WHEN FolderName LIKE '/10337%' THEN '10337.001'
								WHEN FolderName LIKE '/10926.001%' THEN '10926.001'
								WHEN FolderName LIKE '/11309.001%' THEN '11309.001'
								WHEN FolderName LIKE '/11335.001%' THEN '11335.001'
								WHEN FolderName LIKE '/11515.400%' THEN '11515.400'
								WHEN FolderName LIKE '/9111.420%' THEN '9111.420'
								WHEN FolderName LIKE '/9111.001%' THEN '9111.001'
								WHEN FolderName LIKE '/9174.001%' THEN '9174.001'
								WHEN FolderName LIKE '/9745.001%' THEN '9745.001'
								WHEN FolderName LIKE '/9873.001%' THEN '9873.001'
								WHEN FolderName LIKE '/9873.004%' THEN '9873.004'
								WHEN FolderName LIKE '/9879.006%' THEN '9879.006'
								WHEN FolderName LIKE '/9879.007%' THEN '9879.007'
								WHEN FolderName LIKE '/11379.001%' THEN '11379.001'
								WHEN FolderName LIKE '/11629.001%' THEN '11629.001'
								WHEN FolderName LIKE '/11670.001%' THEN '11670.001'
								WHEN FolderName LIKE '/9879.008%' THEN '9879.008'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16734
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10826401%' THEN '10826.401'
								WHEN FolderName LIKE '/10826402%' THEN '10826.402'
								WHEN FolderName LIKE '/10826403%' THEN '10826.403'
								WHEN FolderName LIKE '/10826404%' THEN '10826.404'
								WHEN FolderName LIKE '/10826405%' THEN '10826.405'
								WHEN FolderName LIKE '/10826406%' THEN '10826.406'
								WHEN FolderName LIKE '/10826407%' THEN '10826.407'
								WHEN FolderName LIKE '/10826408%' THEN '10826.408'
								WHEN FolderName LIKE '/10826501%' THEN '10826.501'
								WHEN FolderName LIKE '/From P66%' THEN 'P66'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16756
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10715.410%' THEN '10715.410'
								WHEN FolderName LIKE '/10715.420%' THEN '10715.420'
								WHEN FolderName LIKE '/10715.422%' THEN '10715.422'
								WHEN FolderName LIKE '/10715.423%' THEN '10715.423'
								WHEN FolderName LIKE '/10715.424%' THEN '10715.424'
								WHEN FolderName LIKE '/10715.500%' THEN '10715.500'
								WHEN FolderName LIKE '/10715.510%' THEN '10715.510'
								WHEN FolderName LIKE '/10715.511%' THEN '10715.511'
								WHEN FolderName LIKE '/10715.512%' THEN '10715.512'
								WHEN FolderName LIKE '/10715.513%' THEN '10715.513'
								WHEN FolderName LIKE '/10715.514%' THEN '10715.514'
								WHEN FolderName LIKE '/10715.515%' THEN '10715.515'
								WHEN FolderName LIKE '/10715.516%' THEN '10715.516'
								WHEN FolderName LIKE '/10715.517%' THEN '10715.517'
								WHEN FolderName LIKE '/10715.518%' THEN '10715.518'
								WHEN FolderName LIKE '/10715.520%' THEN '10715.520'
								WHEN FolderName LIKE '/10715.523%' THEN '10715.523'
								WHEN FolderName LIKE '/10715.524%' THEN '10715.524'
								WHEN FolderName LIKE '/10715.526%' THEN '10715.526'
								WHEN FolderName LIKE '/10715.528%' THEN '10715.528'
								WHEN FolderName LIKE '/10715.529%' THEN '10715.529'
								WHEN FolderName LIKE '/10715.530%' THEN '10715.530'
								WHEN FolderName LIKE '/10715.532%' THEN '10715.532'
								WHEN FolderName LIKE '/10715.534%' THEN '10715.534'
								WHEN FolderName LIKE '/10715.536%' THEN '10715.536'
								WHEN FolderName LIKE '/10715.538%' THEN '10715.538'
								WHEN FolderName LIKE '/10715.540%' THEN '10715.540'
								WHEN FolderName LIKE '/10715.544%' THEN '10715.544'
								WHEN FolderName LIKE '/10715.546%' THEN '10715.546'
								WHEN FolderName LIKE '/10715.550%' THEN '10715.550'
								WHEN FolderName LIKE '/10715.552%' THEN '10715.552'
								WHEN FolderName LIKE '/10715.555%' THEN '10715.555'
								WHEN FolderName LIKE '/10715.556%' THEN '10715.556'
								WHEN FolderName LIKE '/10715.xxx%' THEN '10715.XXX'
								WHEN FolderName LIKE '/11410.001%' THEN '11410.001'
								WHEN FolderName LIKE '/11410.002%' THEN '11410.002'
								WHEN FolderName LIKE '/11410.003%' THEN '11410.003'
								WHEN FolderName LIKE '/11410.004%' THEN '11410.004'
								WHEN FolderName LIKE '/11481.001%' THEN '11481.001'
								WHEN FolderName LIKE '/11620.100%' THEN '11620.100'
								WHEN FolderName LIKE '/10715.558%' THEN '10715.558'
								WHEN FolderName LIKE '/11410.007%' THEN '11410.007'
								WHEN FolderName LIKE '/10715.560%' THEN '10715.560'
								WHEN FolderName LIKE '/10715.559%' THEN '10715.559'
								WHEN FolderName LIKE '/10715.557%' THEN '10715.557'
								WHEN FolderName LIKE '/10715.562%' THEN '10715.562'
								WHEN FolderName LIKE '/10715.566%' THEN '10715.566'
								WHEN FolderName LIKE '/10715.567%' THEN '10715.567'
								WHEN FolderName LIKE '/11410.008%' THEN '11410.008'
								WHEN FolderName LIKE '/10715.563%' THEN '10715.563'
								WHEN FolderName LIKE '/10715.569%' THEN '10715.569'
								WHEN FolderName LIKE '/10715.572%' THEN '10715.572'
								WHEN FolderName LIKE '/10715.571%' THEN '10715.571'
								WHEN FolderName LIKE '/10715.564%' THEN '10715.564'
								WHEN FolderName LIKE '/11410.005%' THEN '11410.005'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16800
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10720.400%' THEN '10720.400'
								WHEN FolderName LIKE '%/10720.500%' THEN '10720.500'
								WHEN FolderName LIKE '%/10720.504%' THEN '10720.504'
								WHEN FolderName LIKE '%/10720.601%' THEN '10720.601'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16889
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10782.001%' THEN '10782.001'
								WHEN FolderName LIKE '/10782.002%' THEN '10782.002'
								WHEN FolderName LIKE '/10805.001%' THEN '10805.001'
								WHEN FolderName LIKE '/10890.001%' THEN '10890.001'
								WHEN FolderName LIKE '/10894.001%' THEN '10894.001'
								WHEN FolderName LIKE '/10895.001%' THEN '10895.001'
								WHEN FolderName LIKE '/10941.001%' THEN '10941.001'
								--WHEN FolderName LIKE '/9046.001%' THEN '9046.001'
								WHEN FolderName LIKE '/10955.001%' THEN '10955.001'
								WHEN FolderName LIKE '/11028.001%' THEN '11028.001'
								WHEN FolderName LIKE '/11055.001%' THEN '11055.001'
								WHEN FolderName LIKE '/11083.001%' THEN '11083.001'
								WHEN FolderName LIKE '/11171.001%' THEN '11171.001'
								WHEN FolderName LIKE '/11172.001%' THEN '11172.001'
								WHEN FolderName LIKE '/11243.001%' THEN '11243.001'
								WHEN FolderName LIKE '/11262.001%' THEN '11262.001'
								WHEN FolderName LIKE '/11299.001%' THEN '11299.001'
								WHEN FolderName LIKE '/11337.001%' THEN '11337.001'
								WHEN FolderName LIKE '/11361.001%' THEN '11361.001'
								WHEN FolderName LIKE '/11362.001%' THEN '11362.001'
								WHEN FolderName LIKE '/11439.001%' THEN '11439.001'
								WHEN FolderName LIKE '/11448.001%' THEN '11448.001'
								WHEN FolderName LIKE '/11456.001%' THEN '11456.001'
								WHEN FolderName LIKE '/11457.001%' THEN '11457.001'
								WHEN FolderName LIKE '/11458.001%' THEN '11458.001'
								WHEN FolderName LIKE '/11459.001%' THEN '11459.001'
								WHEN FolderName LIKE '/11489.001%' THEN '11489.001'
								WHEN FolderName LIKE '/11490.001%' THEN '11490.001'
								WHEN FolderName LIKE '/11514.001%' THEN '11514.001'
								WHEN FolderName LIKE '/11516.001%' THEN '11516.001'
								WHEN FolderName LIKE '/11517.001%' THEN '11517.001'
								WHEN FolderName LIKE '/11526.001%' THEN '11526.001'
								WHEN FolderName LIKE '/11541.001%' THEN '11541.001'
								WHEN FolderName LIKE '/11565.001%' THEN '11565.001'
								WHEN FolderName LIKE '/11583.001%' THEN '11583.001'
								WHEN FolderName LIKE '/11694.001%' THEN '11694.001'
								WHEN FolderName LIKE '/11695.001%' THEN '11695.001'
								WHEN FolderName LIKE '/11696.001%' THEN '11696.001'
								WHEN FolderName LIKE '/11697.001%' THEN '11697.001'
								WHEN FolderName LIKE '/9046.001%' THEN '9046.001'
								WHEN FolderName LIKE '/9373.001%' THEN '9373.001'
								WHEN FolderName LIKE '/9914.001%' THEN '9914.001'
								WHEN FolderName LIKE '/MP-42-L Air%' THEN '10944.001'
								WHEN FolderName LIKE '/MP 299 D%' THEN '10986.001'
								WHEN FolderName LIKE '/11598.001%' THEN '11598.001'
								WHEN FolderName LIKE '/11810.001%' THEN '11810.001'
								WHEN FolderName LIKE '/11712.003%' THEN '11712.003'
								WHEN FolderName LIKE '/11712.001%' THEN '11712.001'
								WHEN folderName LIKE '/11769.001%' THEN '11769.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16898
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10272.001%' THEN '10272.001'
								WHEN FolderName LIKE '/10380.001%' THEN '10380.001'
								WHEN FolderName LIKE '/10643.001%' THEN '10643.001'
								WHEN FolderName LIKE '/10680.001%' THEN '10680.001'
								WHEN FolderName LIKE '/10748.001%' THEN '10748.001'
								WHEN FolderName LIKE '/10814.001%' THEN '10814.001'
								WHEN FolderName LIKE '/10824.001%' THEN '10824.001'
								WHEN FolderName LIKE '/10831.001%' THEN '10831.001'
								WHEN FolderName LIKE '/10849.001%' THEN '10849.001'
								WHEN FolderName LIKE '/10856.001%' THEN '10856.001'
								WHEN FolderName LIKE '/10905.001%' THEN '10905.001'
								WHEN FolderName LIKE '/10906.001%' THEN '10906.001'
								WHEN FolderName LIKE '/10913.001%' THEN '10913.001'
								WHEN FolderName LIKE '/10927.001%' THEN '10927.001'
								WHEN FolderName LIKE '/10928.001%' THEN '10928.001'
								WHEN FolderName LIKE '/10945.001%' THEN '10945.001'
								WHEN FolderName LIKE '/10956.001%' THEN '10956.001'
								WHEN FolderName LIKE '/10967.001%' THEN '10967.001'
								WHEN FolderName LIKE '/10990.001%' THEN '10990.001'
								WHEN FolderName LIKE '/10991.001%' THEN '10991.001'
								WHEN FolderName LIKE '/11065.001%' THEN '11065.001'
								WHEN FolderName LIKE '/11071.001%' THEN '11071.001'
								WHEN FolderName LIKE '/11075.001%' THEN '11075.001'
								WHEN FolderName LIKE '/11084.001%' THEN '11084.001'
								WHEN FolderName LIKE '/11094.001%' THEN '11094.001'
								WHEN FolderName LIKE '/11097.001%' THEN '11097.001'
								WHEN FolderName LIKE '/11112.001%' THEN '11112.001'
								WHEN FolderName LIKE '/11159.001%' THEN '11159.001'
								WHEN FolderName LIKE '/11188.001%' THEN '11188.001'
								WHEN FolderName LIKE '/11188.002%' THEN '11188.002'
								WHEN FolderName LIKE '/11214.001%' THEN '11214.001'
								WHEN FolderName LIKE '/11249.001%' THEN '11249.001'
								WHEN FolderName LIKE '/11284.001%' THEN '11284.001'
								WHEN FolderName LIKE '/11328.001%' THEN '11328.001'
								WHEN FolderName LIKE '/11388.002%' THEN '11388.002'
								WHEN FolderName LIKE '/11388.003%' THEN '11388.003'
								WHEN FolderName LIKE '/11342.001%' THEN '11342.001'
								WHEN FolderName LIKE '/11389.001%' THEN '11389.001'
								WHEN FolderName LIKE '/11394.001%' THEN '11394.001'
								WHEN FolderName LIKE '/11404.001%' THEN '11404.001'
								WHEN FolderName LIKE '/11429.001%' THEN '11429.001'
								WHEN FolderName LIKE '/11430.001%' THEN '11430.001'
								WHEN FolderName LIKE '/11437.001%' THEN '11437.001'
								WHEN FolderName LIKE '/11438.001%' THEN '11438.001'
								WHEN FolderName LIKE '/11474.001%' THEN '11474.001'
								WHEN FolderName LIKE '/11475.001%' THEN '11475.001'
								WHEN FolderName LIKE '/11485.001%' THEN '11485.001'
								WHEN FolderName LIKE '/11487.001%' THEN '11487.001'
								WHEN FolderName LIKE '/11507.001%' THEN '11507.001'
								WHEN FolderName LIKE '/11508.001%' THEN '11508.001'
								WHEN FolderName LIKE '/11524.001%' THEN '11524.001'
								WHEN FolderName LIKE '/11535.001%' THEN '11535.001'
								WHEN FolderName LIKE '/11555.001%' THEN '11555.001'
								WHEN FolderName LIKE '/11568.001%' THEN '11568.001'
								WHEN FolderName LIKE '/11576.001%' THEN '11576.001'
								WHEN FolderName LIKE '/11577.001%' THEN '11577.001'
								WHEN FolderName LIKE '/11578.001%' THEN '11578.001'
								WHEN FolderName LIKE '/11579.001%' THEN '11579.001'
								WHEN FolderName LIKE '/11613.001%' THEN '11613.001'
								WHEN FolderName LIKE '/11739.001%' THEN '11739.001'
								WHEN FolderName LIKE '/11744.001%' THEN '11744.001'
								WHEN FolderName LIKE '/11745.001%' THEN '11745.001'
								WHEN FolderName LIKE '/11804.001%' THEN '11804.001'
								WHEN FolderName LIKE '/11717.001%' THEN '11717.001'
								WHEN FolderName LIKE '/11718.001%' THEN '11718.001'
								WHEN FolderName LIKE '/11914.001%' THEN '11914.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16899
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10451.210%' THEN '10451.210'
								WHEN FolderName LIKE '/8163.210%' THEN '8163.210'
								WHEN FolderName LIKE '/8434.002%' THEN '8434.002'
								WHEN FolderName LIKE '/8573.001%' THEN '8573.001'
								WHEN FolderName LIKE '/8573.007%' THEN '8573.007'
								WHEN FolderName LIKE '/11461.001%' THEN '11461.001'
								WHEN FolderName LIKE '/10388.001%' THEN '10388.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16901
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11062.200%' THEN '11062.200'
								WHEN FolderName LIKE '/8879.001%' THEN '8879.001'
								WHEN FolderName LIKE '/8879.209%' THEN '8879.209'
								WHEN FolderName LIKE '/8879.314%' THEN '8879.314'
								WHEN FolderName LIKE '/8879.430%' THEN '8879.430'
								WHEN FolderName LIKE '/8879.431%' THEN '8879.431'
								WHEN FolderName LIKE '/8879.432%' THEN '8879.432'
								WHEN FolderName LIKE '/8879.438%' THEN '8879.438'
								WHEN FolderName LIKE '/8879.439%' THEN '8879.439'
								WHEN FolderName LIKE '/8879.440%' THEN '8879.440'
								WHEN FolderName LIKE '/8879.442%' THEN '8879.442'
								WHEN FolderName LIKE '/8879.443%' THEN '8879.443'
								WHEN FolderName LIKE '/8879.445%' THEN '8879.445'
								WHEN FolderName LIKE '/8879.446%' THEN '8879.446'
								WHEN FolderName LIKE '/8879.448%' THEN '8879.448'
								WHEN FolderName LIKE '/8879.454%' THEN '8879.454'
								WHEN FolderName LIKE '/8879.455%' THEN '8879.455'
								WHEN FolderName LIKE '/8879.456%' THEN '8879.456'
								WHEN FolderName LIKE '/8879.459%' THEN '8879.459'
								WHEN FolderName LIKE '/8879.466%' THEN '8879.466'
								WHEN FolderName LIKE '/8879.467%' THEN '8879.467'
								WHEN FolderName LIKE '/8879.468%' THEN '8879.468'
								WHEN FolderName LIKE '/8879.469%' THEN '8879.469'
								WHEN FolderName LIKE '/8879.470%' THEN '8879.470'
								WHEN FolderName LIKE '/8879.471%' THEN '8879.471'
								WHEN FolderName LIKE '/8879.472%' THEN '8879.472'
								WHEN FolderName LIKE '/8879.473%' THEN '8879.473'
								WHEN FolderName LIKE '/8879.474%' THEN '8879.474'
								WHEN FolderName LIKE '/8879.475%' THEN '8879.475'
								WHEN FolderName LIKE '/8879.477%' THEN '8879.477'
								WHEN FolderName LIKE '/8879.478%' THEN '8879.478'
								WHEN FolderName LIKE '/8879.479%' THEN '8879.479'
								WHEN FolderName LIKE '/8879.480%' THEN '8879.480'
								WHEN FolderName LIKE '/8879.481%' THEN '8879.481'
								WHEN FolderName LIKE '/8879.483%' THEN '8879.483'
								WHEN FolderName LIKE '/8879.487%' THEN '8879.487'
								WHEN FolderName LIKE '/8879.310%' THEN '8879.310'
								WHEN FolderName LIKE '/8879.488%' THEN '8879.488'
								WHEN FolderName LIKE '/8879.489%' THEN '8879.489'
								WHEN FolderName LIKE '/8879.491%' THEN '8879.491'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16911
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10067.400%' THEN '10067.400'
								WHEN FolderName LIKE '/10318.300%' THEN '10318.300'
								WHEN FolderName LIKE '/10434.011%' THEN '10434.011'
								WHEN FolderName LIKE '/10434.014%' THEN '10434.014'
								WHEN FolderName LIKE '/10434.015%' THEN '10434.015'
								WHEN FolderName LIKE '/10434.016%' THEN '10434.016'
								WHEN FolderName LIKE '/10544.400%' THEN '10544.400'
								WHEN FolderName LIKE '/10604.001%' THEN '10604.001'
								WHEN FolderName LIKE '/10604.002%' THEN '10604.002'
								WHEN FolderName LIKE '/10705.400%' THEN '10705.400'
								WHEN FolderName LIKE '/10705.410%' THEN '10705.410'
								WHEN FolderName LIKE '/10705.415%' THEN '10705.415'
								WHEN FolderName LIKE '/10705.420%' THEN '10705.420'
								WHEN FolderName LIKE '/10705.425%' THEN '10705.425'
								WHEN FolderName LIKE '/10705.430%' THEN '10705.430'
								WHEN FolderName LIKE '/10705.440%' THEN '10705.440'
								WHEN FolderName LIKE '/10705.450%' THEN '10705.450'
								WHEN FolderName LIKE '/10705.460%' THEN '10705.460'
								WHEN FolderName LIKE '/10705.461%' THEN '10705.461'
								WHEN FolderName LIKE '/10705.463%' THEN '10705.463'
								WHEN FolderName LIKE '/10705.465%' THEN '10705.465'
								WHEN FolderName LIKE '/10705.467%' THEN '10705.467'
								WHEN FolderName LIKE '/10705.468%' THEN '10705.468'
								WHEN FolderName LIKE '/10705.469%' THEN '10705.469'
								WHEN FolderName LIKE '/10705.475%' THEN '10705.475'
								WHEN FolderName LIKE '/10705.476%' THEN '10705.476'
								WHEN FolderName LIKE '/10705.477%' THEN '10705.477'
								WHEN FolderName LIKE '/10705.490%' THEN '10705.490'
								WHEN FolderName LIKE '/10705.491%' THEN '10705.491'
								WHEN FolderName LIKE '/10739.001%' THEN '10739.001'
								WHEN FolderName LIKE '/10785.001%' THEN '10785.001'
								WHEN FolderName LIKE '/10785.002%' THEN '10785.002'
								WHEN FolderName LIKE '/10786.001%' THEN '10786.001'
								WHEN FolderName LIKE '/10786.002%' THEN '10786.002'
								WHEN FolderName LIKE '/10952.001%' THEN '10952.001'
								WHEN FolderName LIKE '/10953.001%' THEN '10953.001'
								WHEN FolderName LIKE '/10954.001%' THEN '10954.001'
								WHEN FolderName LIKE '/11037.200%' THEN '11037.200'
								WHEN FolderName LIKE '/11037.210%' THEN '11037.210'
								WHEN FolderName LIKE '/11064.100%' THEN '11064.100'
								WHEN FolderName LIKE '/11160.400%' THEN '11160.400'
								WHEN FolderName LIKE '/11160.500%' THEN '11160.500'
								WHEN FolderName LIKE '/11160.600%' THEN '11160.600'
								WHEN FolderName LIKE '/11285.200%' THEN '11285.200'
								WHEN FolderName LIKE '/11285.400%' THEN '11285.400'
								WHEN FolderName LIKE '/11330.400%' THEN '11330.400'
								WHEN FolderName LIKE '/9236.300%' THEN '9236.300'
								WHEN FolderName LIKE '/9372.400%' THEN '9372.400'
								WHEN FolderName LIKE '/9588.200%' THEN '9588.200'
								WHEN FolderName LIKE '/9588.400%' THEN '9588.400'
								WHEN FolderName LIKE '/9588.420%' THEN '9588.420'
								WHEN FolderName LIKE '/9588.600%' THEN '9588.600'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16913
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10047.002%' THEN '10047.002'
								WHEN FolderName LIKE '/10047.003%' THEN '10047.003'
								WHEN FolderName LIKE '/10066.001%' THEN '10066.001'
								WHEN FolderName LIKE '/10066.002%' THEN '10066.002'
								WHEN FolderName LIKE '/10104.001%' THEN '10104.001'
								WHEN FolderName LIKE '/10104.002%' THEN '10104.002'
								WHEN FolderName LIKE '/10114.001%' THEN '10114.001'
								WHEN FolderName LIKE '/10114.002%' THEN '10114.002'
								WHEN FolderName LIKE '/10182.001%' THEN '10182.001'
								WHEN FolderName LIKE '/10207.001%' THEN '10207.001'
								WHEN FolderName LIKE '/10207.002%' THEN '10207.002'
								WHEN FolderName LIKE '/10249.001%' THEN '10249.001'
								WHEN FolderName LIKE '/10297.001%' THEN '10297.001'
								WHEN FolderName LIKE '/10324.001%' THEN '10324.001'
								WHEN FolderName LIKE '/10325.001%' THEN '10325.001'
								WHEN FolderName LIKE '/10339.001%' THEN '10339.001'
								WHEN FolderName LIKE '/10366.001%' THEN '10366.001'
								WHEN FolderName LIKE '/10370.001%' THEN '10370.001'
								WHEN FolderName LIKE '/10370.002%' THEN '10370.002'
								WHEN FolderName LIKE '/10400.001%' THEN '10400.001'
								WHEN FolderName LIKE '/10472.001%' THEN '10472.001'
								WHEN FolderName LIKE '/10473.001%' THEN '10473.001'
								WHEN FolderName LIKE '/10491.001%' THEN '10491.001'
								WHEN FolderName LIKE '/10520.001%' THEN '10520.001'
								WHEN FolderName LIKE '/10576.001%' THEN '10576.001'
								WHEN FolderName LIKE '/10593.002%' THEN '10593.002'
								WHEN FolderName LIKE '/10642.001%' THEN '10642.001'
								WHEN FolderName LIKE '/10654.001%' THEN '10654.001'
								WHEN FolderName LIKE '/10658.001%' THEN '10658.001'
								WHEN FolderName LIKE '/10658.002%' THEN '10658.002'
								WHEN FolderName LIKE '/10704.001%' THEN '10704.001'
								WHEN FolderName LIKE '/10712.001%' THEN '10712.001'
								WHEN FolderName LIKE '/10718.001%' THEN '10718.001'
								WHEN FolderName LIKE '/10725.001%' THEN '10725.001'
								WHEN FolderName LIKE '/10755.001%' THEN '10755.001'
								WHEN FolderName LIKE '/10793.001%' THEN '10793.001'
								WHEN FolderName LIKE '/10793.002%' THEN '10793.002'
								WHEN FolderName LIKE '/10804.001%' THEN '10804.001'
								WHEN FolderName LIKE '/10821.001%' THEN '10821.001'
								WHEN FolderName LIKE '/10823.001%' THEN '10823.001'
								WHEN FolderName LIKE '/10842.001%' THEN '10842.001'
								WHEN FolderName LIKE '/10858.001%' THEN '10858.001'
								WHEN FolderName LIKE '/10864.001%' THEN '10864.001'
								WHEN FolderName LIKE '/10888.001%' THEN '10888.001'
								WHEN FolderName LIKE '/10896.001%' THEN '10896.001'
								WHEN FolderName LIKE '/10939.001%' THEN '10939.001'
								WHEN FolderName LIKE '/9023.001%' THEN '9023.001'
								WHEN FolderName LIKE '/9415.002%' THEN '9415.002'
								WHEN FolderName LIKE '/9523.002%' THEN '9523.002'
								WHEN FolderName LIKE '/9826.001%' THEN '9826.001'
								WHEN FolderName LIKE '/9826.002%' THEN '9826.002'
								WHEN FolderName LIKE '/9972.002%' THEN '9972.002'
								WHEN FolderName LIKE '/9972.003%' THEN '9972.003'
								WHEN FolderName LIKE '/10940.001%' THEN '10940.001'
								WHEN FolderName LIKE '/Standard Equipment Design%' THEN '10982.001'
								WHEN FolderName LIKE '/10910.001%' THEN '10910.001'
								WHEN FolderName LIKE '/10921.001%' THEN '10921.001'
								WHEN FolderName LIKE '/11036.001%' THEN '11036.001'
								WHEN FolderName LIKE '/11039.001%' THEN '11039.001'
								WHEN FolderName LIKE '/11046.001%' THEN '11046.001'
								WHEN FolderName LIKE '/11066.001%' THEN '11066.001'
								WHEN FolderName LIKE '/11067.001%' THEN '11067.001'
								WHEN FolderName LIKE '/11088.001%' THEN '11088.001'
								WHEN FolderName LIKE '/11109.001%' THEN '11109.001'
								WHEN FolderName LIKE '/11116.001%' THEN '11116.001'
								WHEN FolderName LIKE '/11118.001%' THEN '11118.001'
								WHEN FolderName LIKE '/11173.001%' THEN '11173.001'
								WHEN FolderName LIKE '/11189.001%' THEN '11189.001'
								WHEN FolderName LIKE '/11207.001%' THEN '11207.001'
								WHEN FolderName LIKE '/11213.001%' THEN '11213.001'
								WHEN FolderName LIKE '/11260.001%' THEN '11260.001'
								WHEN FolderName LIKE '/11267.001%' THEN '11267.001'
								WHEN FolderName LIKE '/11276.001%' THEN '11276.001'
								WHEN FolderName LIKE '/11277.001%' THEN '11277.001'
								WHEN FolderName LIKE '/11298.001%' THEN '11298.001'
								WHEN FolderName LIKE '/11305.001%' THEN '11305.001'
								WHEN FolderName LIKE '/11346.001%' THEN '11346.001'
								WHEN FolderName LIKE '/11360.001%' THEN '11360.001'
								WHEN FolderName LIKE '/11382.001%' THEN '11382.001'
								WHEN FolderName LIKE '/11392.001%' THEN '11392.001'
								WHEN FolderName LIKE '/11393.001%' THEN '11393.001'
								WHEN FolderName LIKE '/11395.001%' THEN '11395.001'
								WHEN FolderName LIKE '/11396.001%' THEN '11396.001'
								WHEN FolderName LIKE '/11397.001%' THEN '11397.001'
								WHEN FolderName LIKE '/11398.001%' THEN '11398.001'
								WHEN FolderName LIKE '/11399.001%' THEN '11399.001'
								WHEN FolderName LIKE '/11400.001%' THEN '11400.001'
								WHEN FolderName LIKE '/11401.001%' THEN '11401.001'
								WHEN FolderName LIKE '/11402.001%' THEN '11402.001'
								WHEN FolderName LIKE '/11405.001%' THEN '11405.001'
								WHEN FolderName LIKE '/11405.002%' THEN '11405.002'
								WHEN FolderName LIKE '/11413.001%' THEN '11413.001'
								WHEN FolderName LIKE '/11414.001%' THEN '11414.001'
								WHEN FolderName LIKE '/11415.001%' THEN '11415.001'
								WHEN FolderName LIKE '/11420.001%' THEN '11420.001'
								WHEN FolderName LIKE '/11435.001%' THEN '11435.001'
								WHEN FolderName LIKE '/11444.001%' THEN '11444.001'
								WHEN FolderName LIKE '/11445.001%' THEN '11445.001'
								WHEN FolderName LIKE '/11446.001%' THEN '11446.001'
								WHEN FolderName LIKE '/11447.001%' THEN '11447.001'
								WHEN FolderName LIKE '/11454.001%' THEN '11454.001'
								WHEN FolderName LIKE '/11455.001%' THEN '11455.001'
								WHEN FolderName LIKE '/11464.001%' THEN '11464.001'
								WHEN FolderName LIKE '/11473.001%' THEN '11473.001'
								WHEN FolderName LIKE '/11480.001%' THEN '11480.001'
								WHEN FolderName LIKE '/11493.001%' THEN '11493.001'
								WHEN FolderName LIKE '/11494.001%' THEN '11494.001'
								WHEN FolderName LIKE '/11495.001%' THEN '11495.001'
								WHEN FolderName LIKE '/11519.001%' THEN '11519.001'
								WHEN FolderName LIKE '/11534.001%' THEN '11534.001'
								WHEN FolderName LIKE '/11536.001%' THEN '11536.001'
								WHEN FolderName LIKE '/11551.001%' THEN '11551.001'
								WHEN FolderName LIKE '/11553.001%' THEN '11553.001'
								WHEN FolderName LIKE '/11582.001%' THEN '11582.001'
								WHEN FolderName LIKE '/11593.001%' THEN '11593.001'
								WHEN FolderName LIKE '/11593.002%' THEN '11593.002'
								WHEN FolderName LIKE '/11596.001%' THEN '11596.001'
								WHEN FolderName LIKE '/11596.002%' THEN '11596.002'
								WHEN FolderName LIKE '/11612.001%' THEN '11612.001'
								WHEN FolderName LIKE '/11618.001%' THEN '11618.001'
								WHEN FolderName LIKE '/11628.001%' THEN '11628.001'
								WHEN FolderName LIKE '/11653.001%' THEN '11653.001'
								WHEN FolderName LIKE '/11655.001%' THEN '11655.001'
								WHEN FolderName LIKE '/11656.001%' THEN '11656.001'
								WHEN FolderName LIKE '/11660.001%' THEN '11660.001'
								WHEN FolderName LIKE '/11664.001%' THEN '11664.001'
								WHEN FolderName LIKE '/11675.001%' THEN '11675.001'
								WHEN FolderName LIKE '/11720001%' THEN '11720.001'
								WHEN FolderName LIKE '/11778.001%' THEN '11778.001'
								WHEN FolderName LIKE '/11768.001%' THEN '11768.001'
								WHEN FolderName LIKE '/11808.001%' THEN '11808.001'
								WHEN FolderName LIKE '/11831.00%%' THEN '11831.00'
								WHEN FolderName LIKE '/11818.001%' THEN '11818.001'
								WHEN FolderName LIKE '/11762.001%' THEN '11762.001'
								WHEN FolderName LIKE '/11851.001%' THEN '11851.001'
								WHEN FolderName LIKE '/11853.001%' THEN '11853.001'
								WHEN FolderName LIKE '/10712.002%' THEN '10712.002'
								WHEN FolderName LIKE '/11854.001%' THEN '11854.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16950
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10867.400%' THEN '10867.400'
								WHEN FolderName LIKE '/10867.410%' THEN '10867.410'
								WHEN FolderName LIKE '/9653.462%' THEN '9653.462'
								WHEN FolderName LIKE '/Nitrogen%' THEN '10938.400'
								WHEN FolderName LIKE '/11816.001%' THEN '11816.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16938
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10464.010%' THEN '10464.010'
								WHEN FolderName LIKE '/10464.011%' THEN '10464.011'
								WHEN FolderName LIKE '/10464.012%' THEN '10464.012'
								WHEN FolderName LIKE '/10464.013%' THEN '10464.013'
								WHEN FolderName LIKE '/10464.014%' THEN '10464.014'
								WHEN FolderName LIKE '/10464.015%' THEN '10464.015'
								WHEN FolderName LIKE '/10464.016%' THEN '10464.016'
								WHEN FolderName LIKE '/10464.017%' THEN '10464.017'
								WHEN FolderName LIKE '/10464.018%' THEN '10464.018'
								WHEN FolderName LIKE '/10464.019%' THEN '10464.019'
								WHEN FolderName LIKE '/10464.021%' THEN '10464.021'
								WHEN FolderName LIKE '/10464.025%' THEN '10464.025'
								WHEN FolderName LIKE '/10464.028%' THEN '10464.028'
								WHEN FolderName LIKE '/10464.029%' THEN '10464.029'
								WHEN FolderName LIKE '/10464.031%' THEN '10464.031'
								WHEN FolderName LIKE '/10464.032%' THEN '10464.032'
								WHEN FolderName LIKE '/10464.034%' THEN '10464.034'
								WHEN FolderName LIKE '/10464.038%' THEN '10464.038'
								WHEN FolderName LIKE '/10464.039%' THEN '10464.039'
								WHEN FolderName LIKE '/10464.040%' THEN '10464.040'
								WHEN FolderName LIKE '/10464.041%' THEN '10464.041'
								WHEN FolderName LIKE '/10464.042%' THEN '10464.042'
								WHEN FolderName LIKE '/10464.043%' THEN '10464.043'
								WHEN FolderName LIKE '/10464.044%' THEN '10464.044'
								WHEN FolderName LIKE '/10464.045%' THEN '10464.045'
								WHEN FolderName LIKE '/10464.049%' THEN '10464.049'
								WHEN FolderName LIKE '/10464.050%' THEN '10464.050'
								WHEN FolderName LIKE '/10464.051%' THEN '10464.051'
								WHEN FolderName LIKE '/10464.056%' THEN '10464.056'
								WHEN FolderName LIKE '/10464.048%' THEN '10464.048'
								WHEN FolderName LIKE '/10464.060%' THEN '10464.060'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16940
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10809.001%' THEN '10809.001'
								WHEN FolderName LIKE '/10997.001%' THEN '10997.001'
								WHEN FolderName LIKE '/WD 710 - MOC 5014%' THEN '10929.001'
								WHEN FolderName LIKE '/EW 826 A%' THEN '10992.001'
								WHEN FolderName LIKE '/WD 71E - MOC 5013%' THEN '10930.001'
								WHEN FolderName LIKE '/MP 153C - MOC 5018%' THEN '10946.001'
								WHEN FolderName LIKE '/GI 47 Field%' THEN '10957.001'
								WHEN FolderName LIKE '/SS 274A%' THEN '10968.001'
								WHEN FolderName LIKE '/ST 295 A%' THEN '10970.001'
								WHEN FolderName LIKE '/MP 153C - MOC 4983%' THEN '10975.001'
								WHEN FolderName LIKE '/EI 188JE%' THEN '10976.001'
								WHEN FolderName LIKE '/SM 149C - MOC 4932%' THEN '10977.001'
								WHEN FolderName LIKE '/ST 49A - MOC 5031%' THEN '10978.001'
								WHEN FolderName LIKE '/GI 43A - MOC E1330%' THEN '10979.001'
								WHEN FolderName LIKE '/11038.001%' THEN '11038.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16979
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10276.020%' THEN '10276.020'
								WHEN FolderName LIKE '/10330.001%' THEN '10330.001'
								WHEN FolderName LIKE '/10734.002%' THEN '10734.002'
								WHEN FolderName LIKE '/10963.001%' THEN '10963.001'
								WHEN FolderName LIKE '/11179.001%' THEN '11179.001'
								WHEN FolderName LIKE '/11564.001%' THEN '11564.001'
								WHEN FolderName LIKE '/9544.006%' THEN '9544.006'
								WHEN FolderName LIKE '/9544.007%' THEN '9544.007'
								WHEN FolderName LIKE '/9544.008%' THEN '9544.008'
								WHEN FolderName LIKE '/9544.009%' THEN '9544.009'
								WHEN FolderName LIKE '/9544.005%' THEN '9544.005'
								WHEN FolderName LIKE '/11649.001%' THEN '11649.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16981
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10190.001%' THEN '10190.001'
								WHEN FolderName LIKE '/10190.002%' THEN '10190.002'
								WHEN FolderName LIKE '/10959.001%' THEN '10959.001'
								WHEN FolderName LIKE '/11587.001%' THEN '11587.001'
								WHEN FolderName LIKE '/9655.001%' THEN '9655.001'
								WHEN FolderName LIKE '/10190.003%' THEN '10190.003'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 16982
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10235.001%' THEN '10235.001'
								WHEN FolderName LIKE '/10374.001%' THEN '10374.001'
								WHEN FolderName LIKE '/10638.001%' THEN '10638.001'
								WHEN FolderName LIKE '/10902.001%' THEN '10902.001'
								WHEN FolderName LIKE '/10902.003%' THEN '10902.003'
								WHEN FolderName LIKE '/10902.004%' THEN '10902.004'
								WHEN FolderName LIKE '/10923.001%' THEN '10923.001'
								WHEN FolderName LIKE '/10935.001%' THEN '10935.001'
								WHEN FolderName LIKE '/10958.001%' THEN '10958.001'
								WHEN FolderName LIKE '/10958.002%' THEN '10958.002'
								WHEN FolderName LIKE '/10958.003%' THEN '10958.003'
								WHEN FolderName LIKE '/10988.001%' THEN '10988.001'
								WHEN FolderName LIKE '/11045.001%' THEN '11045.001'
								WHEN FolderName LIKE '/11099.001%' THEN '11099.001'
								WHEN FolderName LIKE '/11099.002%' THEN '11099.002'
								WHEN FolderName LIKE '/11292.001%' THEN '11292.001'
								WHEN FolderName LIKE '/11334.001%' THEN '11334.001'
								WHEN FolderName LIKE '/11373.001%' THEN '11373.001'
								WHEN FolderName LIKE '/11432.001%' THEN '11432.001'
								WHEN FolderName LIKE '/11471.001%' THEN '11471.001'
								WHEN FolderName LIKE '/11479.001%' THEN '11479.001'
								WHEN FolderName LIKE '/11543.001%' THEN '11543.001'
								WHEN FolderName LIKE '/11549.001%' THEN '11549.001'
								WHEN FolderName LIKE '/11609.001%' THEN '11609.001'
								WHEN FolderName LIKE '/11663.001%' THEN '11663.001'
								WHEN FolderName LIKE '/11795.001%' THEN '11795.001'
								WHEN FolderName LIKE '/7912.001%' THEN '7912.001'
								WHEN FolderName LIKE '/8693.003%' THEN '8693.003'
								WHEN FolderName LIKE '/8693.004%' THEN '8693.004'
								WHEN FolderName LIKE '/9741.003%' THEN '9741.003'
								WHEN FolderName LIKE '/9894.002%' THEN '9894.002'
								WHEN FolderName LIKE '/11738.001%' THEN '11738.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17009
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10916.001%' THEN '10916.001'
								WHEN FolderName LIKE '/10917.001%' THEN '10917.001'
								WHEN FolderName LIKE '/11120.100%' THEN '11120.100'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17074
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11023.001%' THEN '11023.001'
								WHEN FolderName LIKE '/11049.002%' THEN '11049.002'
								WHEN FolderName LIKE '/11049.004%' THEN '11049.004'
								WHEN FolderName LIKE '/11049.005%' THEN '11049.005'
								WHEN FolderName LIKE '/11049.006%' THEN '11049.006'
								WHEN FolderName LIKE '/11049.007%' THEN '11049.007'
								WHEN FolderName LIKE '/11049.012%' THEN '11049.012'
								WHEN FolderName LIKE '/11049.013%' THEN '11049.013'
								WHEN FolderName LIKE '/11049.014%' THEN '11049.014'
								WHEN FolderName LIKE '/11049.015%' THEN '11049.015'
								WHEN FolderName LIKE '/11049.016%' THEN '11049.016'
								WHEN FolderName LIKE '/11049.017%' THEN '11049.017'
								WHEN FolderName LIKE '/11222.001%' THEN '11222.001'
								WHEN FolderName LIKE '/11736.001%' THEN '11736.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17126
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/11081.400%' THEN '11081.400'
								WHEN FolderName LIKE '%/11081.401%' THEN '11081.401'
								WHEN FolderName LIKE '%/8794409%' THEN '8794.409'
								WHEN FolderName LIKE '%/11391.102%' THEN '11391.102'
								WHEN FolderName LIKE '%/11755.400%' THEN '11755.400'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17158
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10522.001%' THEN '10522.001'
								WHEN FolderName LIKE '/10522.002%' THEN '10522.002'
								WHEN FolderName LIKE '/10522.003%' THEN '10522.003'
								WHEN FolderName LIKE '/10522.004%' THEN '10522.004'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17159
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10103.007%' THEN '10103.007'
								WHEN FolderName LIKE '/10103.013%' THEN '10103.013'
								WHEN FolderName LIKE '/10103.014%' THEN '10103.014'
								WHEN FolderName LIKE '/10103.015%' THEN '10103.015'
								WHEN FolderName LIKE '/10103.024%' THEN '10103.024'
								WHEN FolderName LIKE '/10103.026%' THEN '10103.026'
								WHEN FolderName LIKE '/10103.033%' THEN '10103.033'
								WHEN FolderName LIKE '/10103.034%' THEN '10103.034'
								WHEN FolderName LIKE '/10103.037%' THEN '10103.037'
								WHEN FolderName LIKE '/10103.039%' THEN '10103.039'
								WHEN FolderName LIKE '/10103.040%' THEN '10103.040'
								WHEN FolderName LIKE '/10103.041%' THEN '10103.041'
								WHEN FolderName LIKE '/10103.042%' THEN '10103.042'
								WHEN FolderName LIKE '/10103.043%' THEN '10103.043'
								WHEN FolderName LIKE '/10103.044%' THEN '10103.044'
								WHEN FolderName LIKE '/10103.046%' THEN '10103.046'
								WHEN FolderName LIKE '/10103.047%' THEN '10103.047'
								WHEN FolderName LIKE '/10103.048%' THEN '10103.048'
								WHEN FolderName LIKE '/10103.049%' THEN '10103.049'
								WHEN FolderName LIKE '/10103.050%' THEN '10103.050'
								WHEN FolderName LIKE '/10103.051%' THEN '10103.051'
								WHEN FolderName LIKE '/10103.052%' THEN '10103.052'
								WHEN FolderName LIKE '/10103.053%' THEN '10103.053'
								WHEN FolderName LIKE '/10103.055%' THEN '10103.055'
								WHEN FolderName LIKE '/10103.057%' THEN '10103.057'
								WHEN FolderName LIKE '/10103.058%' THEN '10103.058'
								WHEN FolderName LIKE '/10103.059%' THEN '10103.059'
								WHEN FolderName LIKE '/10103.060%' THEN '10103.060'
								WHEN FolderName LIKE '/10103.061%' THEN '10103.061'
								WHEN FolderName LIKE '/10103.068%' THEN '10103.068'
								WHEN FolderName LIKE '/10103.070%' THEN '10103.070'
								WHEN FolderName LIKE '/10103.071%' THEN '10103.071'
								WHEN FolderName LIKE '/10103.255%' THEN '10103.255'
								WHEN FolderName LIKE '/10103.310%' THEN '10103.310'
								WHEN FolderName LIKE '/10103.334%' THEN '10103.334'
								WHEN FolderName LIKE '/10103.347%' THEN '10103.347'
								WHEN FolderName LIKE '/10103.645%' THEN '10103.645'
								WHEN FolderName LIKE '/10103.650%' THEN '10103.650'
								WHEN FolderName LIKE '/9742.001%' THEN '9742.001'
								WHEN FolderName LIKE '/10103.062%' THEN '10103.062'
								WHEN FolderName LIKE '/10103.063%' THEN '10103.063'
								WHEN FolderName LIKE '/10103.064%' THEN '10103.064'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17160
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10146.002%' THEN '10146.002'
								WHEN FolderName LIKE '/10226.003%' THEN '10226.003'
								WHEN FolderName LIKE '/10226.004%' THEN '10226.004'
								WHEN FolderName LIKE '/10915.001%' THEN '10915.001'
								WHEN FolderName LIKE '/10915.003%' THEN '10915.003'
								WHEN FolderName LIKE '/11208.001%' THEN '11208.001'
								WHEN FolderName LIKE '/11265.001%' THEN '11265.001'
								WHEN FolderName LIKE '/11273.001%' THEN '11273.001'
								WHEN FolderName LIKE '/11356.001%' THEN '11356.001'
								WHEN FolderName LIKE '/11371.001%' THEN '11371.001'
								WHEN FolderName LIKE '/11426.001%' THEN '11426.001'
								WHEN FolderName LIKE '/11431.001%' THEN '11431.001'
								WHEN FolderName LIKE '/11518.001%' THEN '11518.001'
								WHEN FolderName LIKE '/11520.001%' THEN '11520.001'
								WHEN FolderName LIKE '/11552.001%' THEN '11552.001'
								WHEN FolderName LIKE '/11584.001%' THEN '11584.001'
								WHEN FolderName LIKE '/11608.001%' THEN '11608.001'
								WHEN FolderName LIKE '/11630.001%' THEN '11630.001'
								WHEN FolderName LIKE '/11707.001%' THEN '11707.001'
								WHEN FolderName LIKE '/7056 - General-Facility-Info%' THEN '7056.002'
								WHEN FolderName LIKE '/7056.002%' THEN '7056.002'
								WHEN FolderName LIKE '/9245.002%' THEN '9245.002'
								WHEN FolderName LIKE '/11269.001%' THEN '11269.001'
								WHEN FolderName LIKE '/10467.001%' THEN '10467.001'
								WHEN FolderName LIKE '/9912.001%' THEN '9912.001'
								WHEN FolderName LIKE '/11923.001%' THEN '11923.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17202
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10120.001%' THEN '10120.001'
								WHEN FolderName LIKE '/10120.005%' THEN '10120.005'
								WHEN FolderName LIKE '/10120.006%' THEN '10120.006'
								WHEN FolderName LIKE '/10120.007%' THEN '10120.007'
								WHEN FolderName LIKE '/10969.110%' THEN '10969.110'
								WHEN FolderName LIKE '/10993.110%' THEN '10993.110'
								WHEN FolderName LIKE '/11181.001%' THEN '11181.001'
								WHEN FolderName LIKE '/11387.001%' THEN '11387.001'
								WHEN FolderName LIKE '/11390.001%' THEN '11390.001'
								WHEN FolderName LIKE '/11390.002%' THEN '11390.002'
								WHEN FolderName LIKE '/11403.001%' THEN '11403.001'
								WHEN FolderName LIKE '/11403.002%' THEN '11403.002'
								WHEN FolderName LIKE '/11403.003%' THEN '11403.003'
								WHEN FolderName LIKE '/11403.004%' THEN '11403.004'
								WHEN FolderName LIKE '/11403.005%' THEN '11403.005'
								WHEN FolderName LIKE '/11403.006%' THEN '11403.006'
								WHEN FolderName LIKE '/11585.300%' THEN '11585.300'
								WHEN FolderName LIKE '/11585.301%' THEN '11585.301'
								WHEN FolderName LIKE '/11592.200%' THEN '11592.200'
								WHEN FolderName LIKE '/11647.100%' THEN '11647.100'
								WHEN FolderName LIKE '/11662.300%' THEN '11662.300'
								WHEN FolderName LIKE '/11390.003%' THEN '11390.003'
								WHEN FolderName LIKE '/11794.100%' THEN '11794.100'
								WHEN FolderName LIKE '/11647.110%' THEN '11647.110'
								WHEN FolderName LIKE '/11797.300%' THEN '11797.300'
								WHEN FolderName LIKE '/11797.400%' THEN '11797.400'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17307
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11139.100%' THEN '11139.100'
								WHEN FolderName LIKE '/11139.300%' THEN '11139.300'
								WHEN FolderName LIKE '/11139.400%' THEN '11139.400'
								WHEN FolderName LIKE '/11271.100%' THEN '11271.100'
								WHEN FolderName LIKE '/11271.200%' THEN '11271.200'
								WHEN FolderName LIKE '/11271.300%' THEN '11271.300'
								WHEN FolderName LIKE '/11271.301%' THEN '11271.301'
								WHEN FolderName LIKE '/11271.400%' THEN '11271.400'
								WHEN FolderName LIKE '/11271.401%' THEN '11271.401'
								WHEN FolderName LIKE '/11636.100%' THEN '11636.100'
								WHEN FolderName LIKE '/11692.100%' THEN '11692.100'
								WHEN FolderName LIKE '/11692.101%' THEN '11692.101'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17308
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11263.400%' THEN '11263.400'
								WHEN FolderName LIKE '/11263.401%' THEN '11263.401'
								WHEN FolderName LIKE '/11562.300%' THEN '11562.300'
								WHEN FolderName LIKE '/11562.400%' THEN '11562.400'
								WHEN FolderName LIKE '/11594.300%' THEN '11594.300'
								WHEN FolderName LIKE '/11594.310%' THEN '11594.310'
								WHEN FolderName LIKE '/11594.401%' THEN '11594.401'
								WHEN FolderName LIKE '/11594.402%' THEN '11594.402'
								WHEN FolderName LIKE '/11699.400%' THEN '11699.400'
								WHEN FolderName LIKE '/11706.300%' THEN '11706.300'
								WHEN FolderName LIKE '/11803.200%' THEN '11803.200'
								WHEN FolderName LIKE '/11706.400%' THEN '11706.400'
								WHEN FolderName LIKE '/11803.300%' THEN '11803.300'
								WHEN FolderName LIKE '/11881.400%' THEN '11881.400'
								WHEN FolderName LIKE '/11594.404%' THEN '11594.404'
								WHEN FolderName LIKE '/11893.400%' THEN '11893.400'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17311
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10726.001%' THEN '10726.001'
								WHEN FolderName LIKE '/10745.001%' THEN '10745.001'
								WHEN FolderName LIKE '/10745.002%' THEN '10745.002'
								WHEN FolderName LIKE '/10745.003%' THEN '10745.003'
								WHEN FolderName LIKE '/11258.001%' THEN '11258.001'
								WHEN FolderName LIKE '/11258.002%' THEN '11258.002'
								WHEN FolderName LIKE '/11266.001%' THEN '11266.001'
								WHEN FolderName LIKE '/11293.001%' THEN '11293.001'
								WHEN FolderName LIKE '/11624.001%' THEN '11624.001'
								WHEN FolderName LIKE '/11638.001%' THEN '11638.001'
								WHEN FolderName LIKE '/11666.001%' THEN '11666.001'
								WHEN FolderName LIKE '/11667.001%' THEN '11667.001'
								WHEN FolderName LIKE '/11677.001%' THEN '11677.001'
								WHEN FolderName LIKE '/11667.410%' THEN '11667.410'
								WHEN FolderName LIKE '/11343.001%' THEN '11343.001'
								WHEN FolderName LIKE '/7615.001%' THEN '7615.001'
								WHEN FolderName LIKE '/7615.440%' THEN '7615.440'
								WHEN FolderName LIKE '/9402.001%' THEN '9402.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17512
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/7918.003%' THEN '7918.003'
								WHEN FolderName LIKE '%/7918.007%' THEN '7918.007'
								WHEN FolderName LIKE '%/8231.200%' THEN '8231.200'
								WHEN FolderName LIKE '%/7275.101%' THEN '7275.101'
								WHEN FolderName LIKE '%/7275.138%' THEN '7275.138'
								WHEN FolderName LIKE '%/7275.141%' THEN '7275.141'
								WHEN FolderName LIKE '%/7275.153%' THEN '7275.153'
								WHEN FolderName LIKE '%/7275.159%' THEN '7275.159'
								WHEN FolderName LIKE '%/7275.166%' THEN '7275.166'
								WHEN FolderName LIKE '%/7275.167%' THEN '7275.167'
								WHEN FolderName LIKE '%/7275.175%' THEN '7275.175'
								WHEN FolderName LIKE '%/7275.181%' THEN '7275.181'
								WHEN FolderName LIKE '%/7275.182%' THEN '7275.182'
								WHEN FolderName LIKE '%/7275.183%' THEN '7275.183'
								WHEN FolderName LIKE '%/7275.188%' THEN '7275.188'
								WHEN FolderName LIKE '%/7275.189%' THEN '7275.189'
								WHEN FolderName LIKE '%/7275.203%' THEN '7275.203'
								WHEN FolderName LIKE '%/7275.204C%' THEN '7275.204C'
								WHEN FolderName LIKE '%/7275.205%' THEN '7275.205'
								WHEN FolderName LIKE '%/7275.213%' THEN '7275.213'
								WHEN FolderName LIKE '%/7275.215%' THEN '7275.215'
								WHEN FolderName LIKE '%/7275.216%' THEN '7275.216'
								WHEN FolderName LIKE '%/7275.217%' THEN '7275.217'
								WHEN FolderName LIKE '%/7275.218%' THEN '7275.218'
								WHEN FolderName LIKE '%/7275.219%' THEN '7275.219'
								WHEN FolderName LIKE '%/7275.226%' THEN '7275.226'
								WHEN FolderName LIKE '%/7275.228%' THEN '7275.228'
								WHEN FolderName LIKE '%/7275.230%' THEN '7275.230'
								WHEN FolderName LIKE '%/7275.232%' THEN '7275.232'
								WHEN FolderName LIKE '%/7275.233%' THEN '7275.233'
								WHEN FolderName LIKE '%/7275.234%' THEN '7275.234'
								WHEN FolderName LIKE '%/7275.239%' THEN '7275.239'
								WHEN FolderName LIKE '%/7275.240%' THEN '7275.240'
								WHEN FolderName LIKE '%/7275.241%' THEN '7275.241'
								WHEN FolderName LIKE '%/7275.244%' THEN '7275.244'
								WHEN FolderName LIKE '%/7275.245%' THEN '7275.245'
								WHEN FolderName LIKE '%/8877.001%' THEN '8877.001'
								WHEN FolderName LIKE '%/8877.107%' THEN '8877.107'
								WHEN FolderName LIKE '%/8877.108%' THEN '8877.108'
								WHEN FolderName LIKE '%/8877.109%' THEN '8877.109'
								WHEN FolderName LIKE '%/8877.111%' THEN '8877.111'
								WHEN FolderName LIKE '%/8877.114%' THEN '8877.114'
								WHEN FolderName LIKE '%/8877.117%' THEN '8877.117'
								WHEN FolderName LIKE '%/8877.118%' THEN '8877.118'
								WHEN FolderName LIKE '%/8877.119%' THEN '8877.119'
								WHEN FolderName LIKE '%/8877.120%' THEN '8877.120'
								WHEN FolderName LIKE '%/8877.121%' THEN '8877.121'
								WHEN FolderName LIKE '%/8877.123%' THEN '8877.123'
								WHEN FolderName LIKE '%/8877.124%' THEN '8877.124'
								WHEN FolderName LIKE '%/8877.126%' THEN '8877.126'
								WHEN FolderName LIKE '%/8877.128%' THEN '8877.128'
								WHEN FolderName LIKE '%/8877.129%' THEN '8877.129'
								WHEN FolderName LIKE '%/8877.130%' THEN '8877.130'
								WHEN FolderName LIKE '%/8877.132%' THEN '8877.132'
								WHEN FolderName LIKE '%/8877.133%' THEN '8877.133'
								WHEN FolderName LIKE '%/8877.134%' THEN '8877.134'
								WHEN FolderName LIKE '%/8877.135%' THEN '8877.135'
								WHEN FolderName LIKE '%/8877.136%' THEN '8877.136'
								WHEN FolderName LIKE '%/8877.138%' THEN '8877.138'
								WHEN FolderName LIKE '%/8877.139%' THEN '8877.139'
								WHEN FolderName LIKE '%/8877.140%' THEN '8877.140'
								WHEN FolderName LIKE '%/8877.141%' THEN '8877.141'
								WHEN FolderName LIKE '%/8877.144%' THEN '8877.144'
								WHEN FolderName LIKE '%/9137.109%' THEN '9137.109'
								WHEN FolderName LIKE '%/9137.110%' THEN '9137.110'
								WHEN FolderName LIKE '%/9137.111%' THEN '9137.111'
								WHEN FolderName LIKE '%/7918.009%' THEN '7918.009'
								WHEN FolderName LIKE '%/7275.251%' THEN '7275.251'
								WHEN FolderName LIKE '%/7275.248%' THEN '7275.248'
								WHEN FolderName LIKE '%/7275.253%' THEN '7275.253'
								WHEN FolderName LIKE '/01 - Drawing Management/AOT%' THEN '17512.AOT.03162026'
								WHEN FolderName LIKE '/01 - Drawing Management/TAMAR%' THEN '17512.TAM.03272026'
								WHEN FolderName LIKE '/01 - Drawing Management/LPP%' THEN '17512.LPP.03302026'
								WHEN FolderName LIKE '/01 - Drawing Management/MRU%' THEN '17512.MRU.03302026'
								WHEN FolderName LIKE '/01 - Drawing Management/ECS%' THEN '17512.ECS.04092026'
								WHEN FolderName LIKE '%/8877.146%' THEN '8877.146'
								WHEN FolderName LIKE '%/8231.400%' THEN '8231.400'
								WHEN FolderName LIKE '%/8877.147%' THEN '8877.147'
								WHEN FolderName LIKE '%/7275.256%' THEN '7275.256'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17514
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10646.120%' THEN '10646.120'
								WHEN FolderName LIKE '/10646.125%' THEN '10646.125'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17516
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10486.402%' THEN '10486.402'
								WHEN FolderName LIKE '/10486.404%' THEN '10486.404'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17528
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10000.004%' THEN '10000.004'
								WHEN FolderName LIKE '/10507.001%' THEN '10507.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17585
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10832.001%' THEN '10832.001'
								WHEN FolderName LIKE '/10832.002%' THEN '10832.002'
								WHEN FolderName LIKE '/10832.003%' THEN '10832.003'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17799
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11595.001%' THEN '11595.001'
								WHEN FolderName LIKE '/11717.001%' THEN '11717.001'
								WHEN FolderName LIKE '/11718.001%' THEN '11718.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17881
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11505.200%' THEN '11505.200'
								WHEN FolderName LIKE '/11506.200%' THEN '11506.200'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17898
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11291.100%' THEN '11291.100'
								WHEN FolderName LIKE '/11332.001%' THEN '11332.001'
								WHEN FolderName LIKE '/11737.001%' THEN '11737.001'
								WHEN FolderName LIKE '/11760.001%' THEN '11760.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17933
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10361.001%' THEN '10361.001'
								WHEN FolderName LIKE '/11546.001%' THEN '11546.001'
								WHEN FolderName LIKE '/11548.001%' THEN '11548.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 17998
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11537.100%' THEN '11537.100'
								WHEN FolderName LIKE '/11537.101%' THEN '11537.101'
								WHEN FolderName LIKE '/11586.100%' THEN '11586.100'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 18000
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11147.406%' THEN '11147.406'
								WHEN FolderName LIKE '/11147.407%' THEN '11147.407'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 18005
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11366.002%' THEN '11366.002'
								WHEN FolderName LIKE '/11366.003%' THEN '11366.003'
								WHEN FolderName LIKE '/11366.004%' THEN '11366.004'
								WHEN FolderName LIKE '/11366.005%' THEN '11366.005'
								WHEN FolderName LIKE '/11602.001%' THEN '11602.001'
								WHEN FolderName LIKE '/11366.008%' THEN '11366.008'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 18228
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/11525.200%' THEN '11525.200'
								WHEN FolderName LIKE '%/11525.300%' THEN '11525.300'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
	END
ELSE IF @WorkSpaceId = 18233
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/11674.001%' THEN '11674.001'
								WHEN FolderName LIKE '%/11767.001%' THEN '11767.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 18234
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/11704.400%' THEN '11704.400'
								WHEN FolderName LIKE '%/11684.400%' THEN '11684.400'
								WHEN FolderName LIKE '%/11771.401%' THEN '11771.401'
								WHEN FolderName LIKE '%/11772.400%' THEN '11772.400'
								WHEN FolderName LIKE '%/11793.100%' THEN '11793.100'
								WHEN FolderName LIKE '%/11799.400%' THEN '11799.400'
								WHEN FolderName LIKE '%/11710.002%' THEN '11710.002'
								WHEN FolderName LIKE '%/11825.100%' THEN '11825.100'
								WHEN FolderName LIKE '%/11870.001%' THEN '11870.001'
								WHEN FolderName LIKE '/11866.100%' THEN '11866.100'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 18235
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/11631.001%' THEN '11631.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 18236
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/11758.001%' THEN '11758.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 18237
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/11652.001%' THEN '11652.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 18390
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11754.001%' THEN '11754.001'
								WHEN FolderName LIKE '/11754.002%' THEN '11754.002'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 18402
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11749.001%' THEN '11749.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 19052
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11700.001%' THEN '11700.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 19053
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11333.001%' THEN '11333.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 19054
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11761.001%' THEN '11761.001'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 19055
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11798.100%' THEN '11798.100'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 19498
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '%/11842.002%' THEN '11842.002'
								WHEN FolderName LIKE '%/11848.002%' THEN '11848.002'
								WHEN FolderName LIKE '%/11846.002%' THEN '11846.002'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 19499
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/9683.004%' THEN '9683.004'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 20856
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/10341.005%' THEN '10341.005'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 20875
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/8284.013%' THEN '8284.013'
								WHEN FolderName LIKE '/11349.001%' THEN '11349.001'
								WHEN FolderName LIKE '/8284.019%' THEN '8284.019'
								WHEN FolderName LIKE '/8284.018%' THEN '8284.018'
								WHEN FolderName LIKE '/8284.003%' THEN '8284.003' 
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE IF @WorkSpaceId = 20876
	BEGIN
		UPDATE dbo.raw_fusionLive_documents_metadata
		SET ProjectNumber = CASE
								WHEN FolderName LIKE '/11685.400%' THEN '11685.400'
							ELSE NULL END
		WHERE WorkSpaceId = @WorkSpaceId;
END
ELSE
	BEGIN
		UPDATE f
		SET f.ProjectNumber = p.ProjectNumber
		FROM dbo.raw_fusionLive_documents_metadata f
		INNER JOIN dbo.dim_rpt_project p ON f.WorkSpaceId = p.WorkSpaceId
		WHERE f.WorkSpaceId = @WorkSpaceId AND f.ProjectNumber IS NULL;
	END

INSERT INTO dbo.fusionLive_metadata_refresh_log (
						WorkSpaceId,
						RefreshTime,
						[Status],
						RecordsCount
		)
SELECT @WorkSpaceId AS WorkSpaceId,
		CURRENT_TIMESTAMP AS RefreshTime,
		'Sccusseful' AS [Status],
		COUNT(DISTINCT FLID) AS RecordsCount
FROM dbo.fl_raw_export_table



/*
INSERT INTO dbo.fusionLive_metadata_refresh_log (
						WorkSpaceId,
						RefreshTime,
						[Status],
						RecordsCount
		)
SELECT DISTINCT w.WorkspaceId AS WorkSpaceId,
		CURRENT_TIMESTAMP AS RefreshTime,
		'Zero Record' AS [Status],
		0 AS RecordsCount
FROM dbo.dim_rpt_project w
WHERE w.Active = 1
AND NOT EXISTS (SELECT 1 FROM dbo.fusionLive_metadata_refresh_log g
				WHERE g.RefreshTime > '2024-08-06 16:00:00' AND g.WorkspaceId = w.WorkspaceId)

EXEC dbo.ext_raw_hess_baldpate_loading_fl_data '\\IMSQL19.EDG.NET\SourceData\FusionLive\SearchResult.txt'
SELECT * FROM dbo.raw_fusionLive_documents_metadata_temp
SELECT * FROM dbo.raw_fusionLive_documents_metadata
SELECT * FROM dbo.raw_fusionLive_documents_metadata_trash WHERE WorkspaceId = 18228
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE ProjectNumber IS NULL

SELECT * FROM dbo.fusionLive_metadata_refresh_log
DELETE FROM dbo.fusionLive_metadata_refresh_log WHERE WorkSpaceId = 16788 AND CAST(RefreshTime AS DATE) = CAST(CURRENT_TIMESPAMP AS DATE)

SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16338
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16354
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16263
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16232
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16392
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16394
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16472
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16474
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16539
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16548
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16585
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16950

SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16354 AND reference = '7559300-56300-30601'

SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE FolderName LIKE '%trash%'

SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE FusionLiveURL LIKE '%us.fusion.live.com%'
UPDATE dbo.raw_fusionLive_documents_metadata SET FusionLiveURL = REPLACE(FusionLiveURL, 'us.fusion.live.com', 'us.fusion.live') WHERE FusionLiveURL LIKE '%us.fusion.live.com%'

DELETE FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16392
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE reference LIKE '10566200%'
DELETE FROM dbo.raw_fusionLive_documents_metadata WHERE reference LIKE '10566200%'
DELETE FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16394 AND reference NOT LIKE '10566200%'


SELECT DISTINCT WorkSpaceId FROM dbo.raw_fusionLive_documents_metadata

DELETE FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16232 AND ProcessTime > '10/11/2023 00:02:01'
DELETE FROM dbo.raw_fusionLive_documents_metadata WHERE WorkSpaceId = 16338 AND ProcessTime > '10/11/2023 00:02:01'

SELECT * FROM dbo.raw_fusionLive_documents_metadata_trash WHERE WorkSpaceId = 16338
SELECT * FROM dbo.raw_fusionLive_documents_metadata_trash WHERE WorkSpaceId = 16354
SELECT * FROM dbo.raw_fusionLive_documents_metadata_trash WHERE WorkSpaceId = 16263
SELECT * FROM dbo.raw_fusionLive_documents_metadata_trash WHERE WorkSpaceId = 16232
SELECT * FROM dbo.raw_fusionLive_documents_metadata_trash WHERE WorkSpaceId = 16392
SELECT * FROM dbo.raw_fusionLive_documents_metadata_trash WHERE WorkSpaceId = 16950

select * from dbo.fl_raw_export_emp
SELECT TOP 100 * FROM dbo.fl_raw_export_table
SELECT * FROM dbo.fl_raw_export_table
SELECT DISTINCT FLID FROM dbo.fl_raw_export_table
SELECT * FROM dbo.fl_raw_export_table WHERE RIGHT(LineText,1) != '>'
SELECT * FROM dbo.fl_raw_export_table WHERE LineText LIKE 'reference=|%'
SELECT * FROM dbo.fl_raw_export_table WHERE LineText LIKE '<attribute name=%'
SELECT * FROM dbo.fl_raw_export_table WHERE FLID IS NOT NULL
SELECT * FROM dbo.raw_fusionLive_documents_metadata_temp ORDER BY id
SELECT * FROM dbo.raw_fusionLive_documents_metadata_temp ORDER BY reference
SELECT DISTINCT reference FROM dbo.raw_fusionLive_documents_metadata_temp ORDER BY reference
SELECT DISTINCT id FROM dbo.raw_fusionLive_documents_metadata_temp ORDER BY 1

https://cwviewer.azurewebsites.net/FLView.aspx?documentId=10415129

SELECT record_id, LineText, CAST(LEFT(REPLACE(LineText,'document id="',''), CHARINDEX('"', REPLACE(LineText,'document id="','')) - 1) AS BIGINT) AS ID,
		RIGHT(LineText, LEN(LineText) - CHARINDEX('reference=', LineText, 1) + 1) AS DocNo
FROM dbo.fl_raw_export_table
WHERE LineText LIKE 'document id="%'

reference=|2200-AR-DWG-0000-EDG-0001| title=|Architectural Test Drawing 1| revision=|0| status=|Issued for Information| version=|1.0| islatest=|true| hascontent=|true| haslink=|true
| islink=|false| islocked=|false| ischeckout=|false| hasattachment=|false| isattachment=|false| hasmarkup=|false| companyname=|EDG, Inc.| externalurl=|
| uploaded=|2023-05-23 13:46| size=|37742| uptodate=|true| revisioncount=|1| last_updated_time=|2023-05-23 14:53| last_updated_by=|the internal admin non-SSO account
| uri=|https://us.fusion.live.com/pws/documents/10398657| hasprojectfiles=|false| hasrendition=|false"

<document id="10398912" reference="2200-EL-DWG-5750-EXV-0003" title="Vendor Test Document 3" revision="A" status="Issue for Review" version="1.0" islatest="true" hascontent="true" 
haslink="false" islink="false" islocked="true" ischeckout="false" lockedbyid="210453" lockedbyname="the internal admin non-SSO account" hasattachment="false" isattachment="false" hasmarkup="false" 
companyname="EDG, Inc." externalurl="" uploaded="2023-05-23 14:21" size="38521" uptodate="true" revisioncount="1" last_updated_time="2023-05-23 15:22" last_updated_by="the internal admin non-SSO account" 
uri="https://us.fusion.live.com/pws/documents/10398912" hasprojectfiles="false" hasrendition="false">

SELECT * FROM dbo.raw_fusionLive_documents_metadata_trash WHERE Discipline = 'MGT - Management, Inc Project Mgmt'
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE Discipline = 'MGT - Management, Inc Project Mgmt'

UPDATE dbo.raw_fusionLive_documents_metadata_trash SET Discipline = 'MGT - Management' WHERE Discipline = 'MGT - Management, Inc Project Mgmt'
UPDATE dbo.raw_fusionLive_documents_metadata SET Discipline = 'MGT - Management' WHERE Discipline = 'MGT - Management, Inc Project Mgmt'
UPDATE dbo.raw_fusionLive_documents_metadata SET title = REPLACE(title, '&amp;', 'and') WHERE PATINDEX('%&amp;%', title) > 0
SELECT * FROM dbo.raw_fusionLive_documents_metadata WHERE PATINDEX('%&amp;%', title) > 0

INSERT INTO dbo.raw_fusionLive_documents_metadata (
						WorkSpaceId,
						[id],
						reference,
						title,
						revision,
						[Revision Date],
						Docstatus,
						[version],
						isDeleted,
						islatest,
						hascontent,
						haslink,
						islink,
						islocked,
						ischeckout,
						lockedbyid,
						lockedbyname,
						hasattachment,
						isattachment,
						hasmarkup,
						companyname,
						externalurl,
						uploaded,
						size,
						uptodate,
						revisioncount,
						last_updated_time,
						last_updated_by,
						uri,
						hasprojectfile,
						hasrendition,
						category_id,
						category_name,
						file_type,
						file_mimetype,
						[file_name],
						file_size,
						file_contentformatcode,
						PM_Status,
						[Decision Code],
						[DRS Number],
						Phase,
						Document_Type,
						Originator,
						Discipline,
						Area,
						Scope_Group,
						Criticality,
						Number,
						CTR,
						AsBuilt,
						Tag,
						[Planned Submission Date],
						[Forecast Submission Date],
						[Actual Submission Date],
						[Planned Resubmission Date],
						[Forecast Resubmission Date],
						[Actual Resubmission Date],
						[Planned issue date],
						[Forecast issue date],
						[Actual issue date],
						[Reason For Issue],
						[Planned Return Date],
						[Actual Return Date],
						Due_Date,
						[Planned review date],
						[Actual review date],
						Percentage_Complete,
						[Man Hours],
						[Client Decision Code],
						[Client Reference Number],
						[Forecast Client Response Date],
						[Actual approval date],
						[Client response date],
						[Weighting],
						Facility,
						[Contract],
						[Client Revision],
						[Alternative Reference Number],
						[PO Number],
						[Vendor Reference Number],
						LocationPath,
						FusionLiveURL,
						Update_Date,
						FolderID,
						FolderName,
						FacilityArch,
						[VDR Code],
						[Issue Status],
						[ABS Stamped],
						OldFileName,
						[Reference for I3P Reviews],
						[Transmittal Date],
						[Transmittal Number],
						Supersedes,
						[Superseded By],
						[Source],
						Created
		)
SELECT
						t.WorkSpaceId,
						t.[id],
						t.reference,
						REPLACE(t.title, '&amp;', 'and') title,
						t.revision,
						t.[Revision Date],
						t.Docstatus,
						t.[version],
						0 isDeleted,
						t.islatest,
						t.hascontent,
						t.haslink,
						t.islink,
						t.islocked,
						t.ischeckout,
						t.lockedbyid,
						t.lockedbyname,
						t.hasattachment,
						t.isattachment,
						t.hasmarkup,
						t.companyname,
						t.externalurl,
						t.uploaded,
						t.size,
						t.uptodate,
						t.revisioncount,
						t.last_updated_time,
						t.last_updated_by,
						t.uri,
						t.hasprojectfile,
						t.hasrendition,
						t.category_id,
						t.category_name,
						t.file_type,
						t.file_mimetype,
						t.[file_name],
						t.file_size,
						t.file_contentformatcode,
						t.PM_Status,
						t.[Decision Code],
						t.[DRS Number],
						t.Phase,
						t.Document_Type,
						t.Originator,
						t.Discipline,
						t.Area,
						t.Scope_Group,
						t.Criticality,
						t.Number,
						t.CTR,
						t.AsBuilt,
						t.Tag,
						t.[Planned Submission Date],
						t.[Forecast Submission Date],
						t.[Actual Submission Date],
						t.[Planned Resubmission Date],
						t.[Forecast Resubmission Date],
						t.[Actual Resubmission Date],
						t.[Planned issue date],
						t.[Forecast issue date],
						t.[Actual issue date],
						t.[Reason For Issue],
						t.[Planned Return Date],
						t.[Actual Return Date],
						t.Due_Date,
						t.[Planned review date],
						t.[Actual review date],
						t.Percentage_Complete,
						t.[Man Hours],
						t.[Client Decision Code],
						t.[Client Reference Number],
						t.[Forecast Client Response Date],
						t.[Actual approval date],
						t.[Client response date],
						t.[Weighting],
						t.Facility,
						t.[Contract],
						t.[Client Revision],
						t.[Alternative Reference Number],
						t.[PO Number],
						t.[Vendor Reference Number],
						t.LocationPath,
						t.FusionLiveURL,
						t.Update_Date,
						t.FolderID,
						t.FolderName,
						t.FacilityArch,
						t.[VDR Code],
						t.[Issue Status],
						t.[ABS Stamped],
						t.OldFileName,
						t.[Reference for I3P Reviews],
						t.[Transmittal Date],
						t.[Transmittal Number],
						t.Supersedes,
						t.[Superseded By],
						t.[Source],
						t.Created
FROM dbo.raw_fusionLive_documents_metadata_trash t
WHERE t.FolderName LIKE '%Trash Compactor%'

DELETE FROM dbo.raw_fusionLive_documents_metadata_trash WHERE FolderName LIKE '%Trash Compactor%'
*/

SET NOCOUNT OFF;
SET QUOTED_IDENTIFIER ON;
GO


