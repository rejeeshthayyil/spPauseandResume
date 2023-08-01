


CREATE VIEW [Report].[ShootTimeLostView]
AS
SELECT
    ds.StudioName,
    di.issueName as [Shoot Start Status],
    st.ShootTimeName,
    fs.ShootPausedDateTime,
    fs.ShootResumeDateTime,
    DATEDIFF(MINUTE, fs.ShootPausedDateTime, fs.shootresumedatetime) AS [Time Lost]
FROM
    report.FactShootStatetbd fs
JOIN
    Report.DimIssues di ON fs.IssuedId = di.issueId
JOIN
    Report.DimShootTime st ON st.ShootTimeId = fs.shoottimeId
join 
	Report.DimStudio ds ON ds.StudioId=fs.StudioId


