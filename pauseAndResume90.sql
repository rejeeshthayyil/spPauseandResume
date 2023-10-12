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
)

SELECT 
    StudioId,
    SUM(DATEDIFF(MINUTE, MergedPauseTime, MergedResumeTime)) AS TotalLostTime
FROM MergedIntervals
GROUP BY StudioId;