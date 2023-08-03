--CREATE VIEW [Report].[ShootTimeLostView]
--AS
With Timelost as(
SELECT 
    ds.StudioName,
	st.ShootTimeName,
    di.issueName AS [Shoot Start Status],
    SUM(CASE WHEN st.ShootTimeName = 'AM' THEN DATEDIFF(MINUTE, fs.ShootPausedDateTime, fs.shootresumedatetime) ELSE 0 END) AS TimeLost_AM,
    SUM(CASE WHEN st.ShootTimeName = 'PM' THEN DATEDIFF(MINUTE, fs.ShootPausedDateTime, fs.shootresumedatetime) ELSE 0 END) AS TimeLost_PM,
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
	st.ShootTimeName,
    di.issueName,
    fs.ShootPausedDateTime,
    fs.ShootResumeDateTime
	)

select studioName,ShootTimeName,[Shoot Start Status], sum(timeLost_Am) as TimeLostAM, sum(TimeLost_Pm) as TimelostPM
from timelost
group by studioname,
ShootTimeName,
[Shoot Start Status]
