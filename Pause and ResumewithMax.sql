--USE [Manufacturing]
--GO

--/****** Object:  View [Report].[GetVmShootTimeLost]    Script Date: 8/11/2023 9:55:04 AM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE VIEW [Report].[GetVmShootTimeLost]
--AS 
WITH Timelost AS (
    SELECT 
        ds.StudioName AS [Studio Name],
        st.ShootTimeName AS [DAY],

		 CASE
               WHEN [ShootPausedDateTime] = '1900-01-01 00:00:00.000'
                    OR sT.ShootTimeName IS NULL THEN
                   0
               WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00'
                    AND sT.ShootTimeName = 'AM' THEN
                   1
               WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00'
                    AND sT.ShootTimeName = 'PM' THEN
                   1
               WHEN CAST([ShootPausedDateTime] AS TIME) <= '13:45:00'
                    AND sT.ShootTimeName = 'FD' THEN
                   1
               ELSE
                   0
           END AS [AM Shoot],
           CASE
               WHEN [ShootPausedDateTime] = '1900-01-01 00:00:00.000'
                    OR [ShootPausedDateTime] IS NULL THEN
                   0
               WHEN CAST([ShootPausedDateTime] AS TIME) > '13:45:00'
                    AND sT.ShootTimeName = 'PM' THEN
                   1
               WHEN CAST([ShootPausedDateTime] AS TIME) > '13:45:00'
                    AND sT.ShootTimeName = 'AM' THEN
                   1
               WHEN CAST([ShootPausedDateTime] AS TIME) > '13:45:00'
                    AND sT.ShootTimeName = 'FD' THEN
                   1
               ELSE
                   0
           END AS [PM Shoot],


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
),
Studios AS (
    SELECT 
        [Studio Name],
		[DAY],
		[AM Shoot],
		[PM Shoot],
        [ShootStartStatus],
        MAX(TimeLostAM) / 60 AS TimeLostAM, 
        MAX(TimeLostPM) / 60 AS TimeLostPM
    FROM 
        TimeLost
    GROUP BY 
        [Studio Name],[DAY], [AM Shoot],[PM Shoot],[ShootStartStatus]
),
StudioLevel AS (
    SELECT 
        [Studio Name], 
		[DAY],
		[ShootStartStatus],
        SUM(TimeLostAM) AS TotalTimeLostAM, 
        SUM(TimeLostPM) AS TotalTimeLostPM
    FROM 
        Studios
    GROUP BY 
        [Studio Name],[DAY],[ShootStartStatus]
),
RankedStatus AS (
    SELECT
        [Studio Name],
        [DAY],
        [ShootStartStatus],
        TotalTimeLostAM,
        TotalTimeLostPM,
        ROW_NUMBER() OVER(PARTITION BY [Studio Name] ORDER BY TotalTimeLostAM + TotalTimeLostPM DESC) AS rn
    FROM 
        StudioLevel
)
SELECT 
    [Studio Name],
    [DAY],
    [ShootStartStatus],
    TotalTimeLostAM,
    TotalTimeLostPM
FROM 
    RankedStatus
WHERE
    rn = 1;
