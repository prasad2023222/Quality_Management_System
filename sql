SELECT DB_NAME() AS CurrentDatabase;

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

Use FujitecQMS;

USE FujitecQMS;
GO

-- Check columns and data types in our four tables
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'DocumentTypes',
    'QMSDepartments',
    'Documents',
    'DocumentRevisions'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Check existing document types
SELECT * FROM dbo.DocumentTypes;

-- Check existing QMS departments
SELECT * FROM dbo.QMSDepartments;


USE FujitecQMS;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Insert sample document types
    INSERT INTO dbo.DocumentTypes (TypeCode, TypeName)
    VALUES
        ('PM', 'Process Manuals'),
        ('WP', 'Work Procedures'),
        ('FM', 'Formats');

    -- 2. Insert sample QMS departments
    INSERT INTO dbo.QMSDepartments (DepartmentCode, DepartmentName)
    VALUES
        ('PRD', 'Production Department'),
        ('ITD', 'IT Department'),
        ('QAD', 'Quality Assurance Department');

    -- 3. Insert sample documents
    INSERT INTO dbo.Documents
        (DocumentNo, Title, DocumentTypeId, DepartmentId, RetentionPeriod, Status)
    SELECT
        sample.DocumentNo,
        sample.Title,
        dt.DocumentTypeId,
        dept.DepartmentId,
        '5 Years',
        'Approved'
    FROM
        (VALUES
            ('TEST-PM-001', 'Sample Production Manual', 'PM', 'PRD'),
            ('TEST-PM-002', 'Sample IT Manual', 'PM', 'ITD'),
            ('TEST-WP-001', 'Sample Quality Procedure', 'WP', 'QAD'),
            ('TEST-FM-001', 'Sample Production Inspection Format', 'FM', 'PRD')
        ) AS sample(DocumentNo, Title, TypeCode, DepartmentCode)
    INNER JOIN dbo.DocumentTypes dt
        ON dt.TypeCode = sample.TypeCode
    INNER JOIN dbo.QMSDepartments dept
        ON dept.DepartmentCode = sample.DepartmentCode;

    -- 4. Insert sample document revisions
    INSERT INTO dbo.DocumentRevisions
        (DocumentId, RevisionNumber, PageCount, RevisionDate)
    SELECT
        d.DocumentId,
        sample.RevisionNumber,
        sample.PageCount,
        sample.RevisionDate
    FROM
        (VALUES
            ('TEST-PM-001', 0, 5, CAST('2026-01-10' AS date)),
            ('TEST-PM-001', 1, 7, CAST('2026-06-15' AS date)),
            ('TEST-PM-001', 2, 8, CAST('2026-10-01' AS date)),
            ('TEST-PM-002', 0, 4, CAST('2026-02-20' AS date)),
            ('TEST-WP-001', 0, 3, CAST('2026-03-05' AS date)),
            ('TEST-WP-001', 1, 4, CAST('2026-08-12' AS date)),
            ('TEST-FM-001', 0, 2, CAST('2026-04-18' AS date))
        ) AS sample(DocumentNo, RevisionNumber, PageCount, RevisionDate)
    INNER JOIN dbo.Documents d
        ON d.DocumentNo = sample.DocumentNo;

    COMMIT TRANSACTION;

    PRINT 'Fake QMS data inserted successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO


SELECT * FROM dbo.DocumentTypes;
SELECT * FROM dbo.QMSDepartments;
SELECT * FROM dbo.Documents;
Select * from dbo.DocumentRevisions;

SELECT
    d.DocumentNo,
    d.Title,
    r.RevisionNumber,
    r.PageCount,
    r.RevisionDate
FROM dbo.Documents d
INNER JOIN dbo.DocumentRevisions r
    ON d.DocumentId = r.DocumentId
ORDER BY d.DocumentNo, r.RevisionNumber;



USE FujitecQMS;
GO

UPDATE d
SET d.RetentionPeriod =
    CASE
        WHEN dt.TypeCode = 'FM' THEN '5 Years'
        ELSE NULL
    END
FROM dbo.Documents d
INNER JOIN dbo.DocumentTypes dt
    ON d.DocumentTypeId = dt.DocumentTypeId
WHERE d.DocumentNo LIKE 'TEST-%';
GO

UPDATE dbo.Documents
SET Status = 'Active'
WHERE DocumentNo LIKE 'TEST-%';
GO

