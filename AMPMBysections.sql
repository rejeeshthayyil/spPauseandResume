WITH RankedData AS (
    SELECT 
        StudioId,
        ShootPauseDateTime,
        ShootResumeDateTime,
        LAG(ShootResumeDateTime, 1, '1900-01-01') OVER (PARTITION BY StudioId ORDER BY ShootPauseDateTime) AS PrevResumeTime
    FROM [Report].[FactShootState]
),

GroupedData AS (
    SELECT 
        StudioId,
        ShootPauseDateTime,
        ShootResumeDateTime,
        PrevResumeTime,
        CASE WHEN ShootPauseDateTime <= ISNULL(PrevResumeTime, '1900-01-01') 
             THEN 0 
             ELSE 1 
        END AS IsNewGroup
    FROM RankedData
),

CumulativeGroup AS (
    SELECT 
        StudioId,
        ShootPauseDateTime,
        ShootResumeDateTime,
        SUM(IsNewGroup) OVER (PARTITION BY StudioId ORDER BY ShootPauseDateTime) AS GroupId
    FROM GroupedData
),

MergedIntervals AS (
    SELECT 
        StudioId,
        MIN(ShootPauseDateTime) AS MergedPauseTime,
        MAX(ShootResumeDateTime) AS MergedResumeTime
    FROM CumulativeGroup
    GROUP BY StudioId, GroupId

	),

SectionWiseLostTime AS (
    SELECT
        StudioId,
        MergedPauseTime,
        MergedResumeTime,
        CASE
            WHEN CAST(MergedPauseTime AS TIME) <= '13:45:00' AND CAST(MergedResumeTime AS TIME) <= '13:45:00' THEN 
                DATEDIFF(MINUTE, CAST(MergedPauseTime AS TIME), CAST(MergedResumeTime AS TIME))
            WHEN CAST(MergedPauseTime AS TIME) <= '13:45:00' AND CAST(MergedResumeTime AS TIME) > '13:45:00' THEN 
                DATEDIFF(MINUTE, CAST(MergedPauseTime AS TIME), CAST('13:45:00' AS TIME))
            ELSE 0
        END AS TimeLostAM,
        CASE
            WHEN CAST(MergedPauseTime AS TIME) > '13:45:00' AND CAST(MergedPauseTime AS TIME) <= '17:30:00' AND CAST(MergedResumeTime AS TIME) <= '17:30:00' THEN 
                DATEDIFF(MINUTE, CAST(MergedPauseTime AS TIME), CAST(MergedResumeTime AS TIME))
            WHEN CAST(MergedPauseTime AS TIME) <= '17:30:00' AND CAST(MergedResumeTime AS TIME) > '17:30:00' THEN 
                DATEDIFF(MINUTE, CAST('13:45:00' AS TIME), CAST(MergedResumeTime AS TIME))
            ELSE 0
        END AS TimeLostPM,
        CASE
            WHEN CAST(MergedPauseTime AS TIME) > '17:30:00' THEN 
                DATEDIFF(MINUTE, CAST(MergedPauseTime AS TIME), CAST(MergedResumeTime AS TIME))
            ELSE 0
        END AS TimeLostEvening
    FROM 
        MergedIntervals
)

SELECT 
    StudioId,
    SUM(TimeLostAM) AS TotalLostTimeAM,
    SUM(TimeLostPM) AS TotalLostTimePM,
    SUM(TimeLostEvening) AS TotalLostTimeEvening
FROM 
    SectionWiseLostTime
GROUP BY 
    StudioId;