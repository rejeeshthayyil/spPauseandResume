USE [Onlinestore]
GO

/****** Object:  View [Report].[ShootTimeLostViewDuplicate]    Script Date: 18/09/2023 18:50:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [Report].[ShootTimeLostViewDuplicate]
AS 
WITH Timelost AS (
    SELECT 
        ds.StudioName,
        st.ShootTimeName,
        di.issueName AS [ShootStartStatus],

      CASE
            WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00' AND CAST([ShootResumeDateTime] AS TIME) <= '13:45:00' THEN 
                 DATEDIFF(MINUTE, CAST([ShootPausedDateTime] AS TIME), CAST([ShootResumeDateTime] AS TIME))
            WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00' AND CAST([ShootResumeDateTime] AS TIME) > '13:45:00' THEN 
                 DATEDIFF(MINUTE, CAST([ShootPausedDatetime] AS TIME), 
				 CAST('13:45:00' AS TIME))
        END AS [TimeLostAM],


         CASE       
            WHEN CAST([ShootPausedDateTime] AS TIME) > '13:45:00' AND CAST([ShootResumeDateTime] AS TIME) > '13:45:00' THEN 
                DATEDIFF(MINUTE, CAST([ShootPausedDateTime] AS TIME), CAST([ShootResumeDateTime] AS TIME))
            WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00' AND CAST([ShootResumeDateTime] AS TIME) > '13:45:00' THEN 
                DATEDIFF(MINUTE, CAST('13:45:00' AS TIME),CAST([ShootResumeDateTime] AS TIME))
        END AS [TimeLostPM],

			 CASE
    WHEN CAST([ShootPausedDateTime] AS TIME) > '17:30:00' AND CAST([ShootResumeDateTime] AS TIME) > '17:30:00' THEN
        DATEDIFF(MINUTE, CAST([ShootPausedDateTime] AS TIME), CAST([ShootResumeDateTime] AS TIME))
    WHEN CAST([ShootPausedDateTime] AS TIME) <= '17:30:00' AND CAST([ShootResumeDateTime] AS TIME) > '17:30:00' THEN
	 DATEDIFF(MINUTE, CAST([ShootResumeDateTime] AS TIME),CAST('17:30:00' AS TIME))

END AS [TimeLostEV],



        fs.ShootPausedDateTime,
        fs.ShootResumeDateTime
    FROM
        report.FactShootStatetbd fs
    JOIN
        Report.DimIssue di ON fs.IssuedId = di.issueId
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
        SUM(TimeLostAM)   AS TimeLostAM, 
        SUM(TimeLostPM)   AS TimeLostPM,
		sum(TimeLostEV)   AS TimeLostEV
    FROM 
        Timelost
    GROUP BY 
        studioName, ShootTimeName, [ShootStartStatus]
		
	    
)
, StudioLevel AS (
    SELECT 
        studioName, 
        SUM(TimeLostAM) AS TotalTimeLostAM, 
        SUM(TimeLostPM) AS TotalTimeLostPM,
		sum(TimeLostEV) AS TotalTimeLostEV
    FROM 
        Studios
    GROUP BY 
        studioName
)
SELECT 
    studioName,
    SUM(TotalTimeLostAM) AS TotalTimeLostAM,
    SUM(TotalTimeLostPM) AS TotalTimeLostPM,
	sum(TotalTimeLostEV) as TotalTimeLostEV
FROM 
    StudioLevel
GROUP BY 
    studioName;
GO


