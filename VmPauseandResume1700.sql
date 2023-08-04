--CREATE VIEW [Report].[ShootTimeLostView]
--AS 
WITH Timelost AS (
    SELECT 
        ds.StudioName,
        st.ShootTimeName,
        di.issueName AS [ShootStartStatus],

        CASE
            WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00' AND CAST([ShootResumeDateTime] AS TIME) <= '13:45:00' THEN 
                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), CAST([ShootResumeDateTime] AS TIME)) - 
                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), CAST([ShootPausedDateTime] AS TIME))
            WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00' AND CAST([ShootResumeDateTime] AS TIME) > '13:45:00' THEN 
                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), CAST('13:45:00' AS TIME)) - 
                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), CAST([ShootPausedDateTime] AS TIME))
        END AS [TimeLostAM],

        CASE       
            WHEN CAST([ShootPausedDateTime] AS TIME) > '13:45:00' AND CAST([ShootResumeDateTime] AS TIME) > '13:45:00' THEN 
                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), CAST([ShootResumeDateTime] AS TIME)) - 
                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), CAST([ShootPausedDateTime] AS TIME))
            WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00' AND CAST([ShootResumeDateTime] AS TIME) > '13:45:00' THEN 
                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), CAST([ShootResumeDateTime] AS TIME)) - 
                DATEDIFF(SECOND, CAST('00:00:00' AS TIME), CAST('13:45:00' AS TIME))
        END AS [TimeLostPM],

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
)
, Studios AS (
    SELECT 
        studioName,
        ShootTimeName,
        [ShootStartStatus] ,
        SUM(TimeLostAM) / 60 AS TimeLostAM, 
        SUM(TimeLostPM) / 60 AS TimeLostPM
    FROM 
        Timelost
    GROUP BY 
        studioName, ShootTimeName, [ShootStartStatus]
		
	    
)
, StudioLevel AS (
    SELECT 
        studioName, 
        SUM(TimeLostAM) AS TotalTimeLostAM, 
        SUM(TimeLostPM) AS TotalTimeLostPM
    FROM 
        Studios
    GROUP BY 
        studioName
)
SELECT 
    studioName,
    SUM(TotalTimeLostAM) AS TotalTimeLostAM,
    SUM(TotalTimeLostPM) AS TotalTimeLostPM
FROM 
    StudioLevel
GROUP BY 
    studioName;
