--CREATE VIEW [Report].[ShootTimeLostView]
--AS

SELECT
    ds.StudioName,
    di.issueName AS [Shoot Start Status],
    SUM(CASE WHEN st.ShootTimeName = 'AM' THEN DATEDIFF(MINUTE, fs.ShootPausedDateTime, fs.shootresumedatetime) ELSE 0 END) AS TimeLostAM,
    SUM(CASE WHEN st.ShootTimeName = 'PM' THEN DATEDIFF(MINUTE, fs.ShootPausedDateTime, fs.shootresumedatetime) ELSE 0 END) AS TimeLostPM,
    fs.ShootPausedDateTime,
    fs.ShootResumeDateTime
FROM
    report.FactShootStatetbd fs
JOIN
    Report.DimIssues di ON fs.IssuedId = di.issueId
JOIN
    Report.DimShootTime st ON st.ShootTimeId = fs.shoottimeId
JOIN
    Report.DimStudio ds ON ds.StudioId = fs.StudioId
GROUP BY
    ds.StudioName,
    di.issueName,
    fs.ShootPausedDateTime,
    fs.ShootResumeDateTime;
