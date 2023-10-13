-CREATE VIEW [Report].[vwGetPauseAndResumeTimeLost]
--AS
WITH RankedData AS (
    SELECT 
        StudioId,
		Reason AS StartTimeStatus,
        ShootPauseDateTime,
        ShootResumeDateTime,
        LAG(ShootResumeDateTime, 1, '1900-01-01') OVER (PARTITION BY StudioId ORDER BY ShootPauseDateTime) AS PrevResumeTime
    FROM [Report].[FactShootState]
),

GroupedData AS (
    SELECT 
        StudioId,
		StartTimeStatus,
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
		StartTimeStatus,
        ShootPauseDateTime,
        ShootResumeDateTime,
        SUM(IsNewGroup) OVER (PARTITION BY StudioId ORDER BY ShootPauseDateTime) AS GroupId
    FROM GroupedData
),

MergedIntervals AS (
    SELECT 
        StudioId,
		StartTimeStatus,
        MIN(ShootPauseDateTime) AS MergedPauseTime,
        MAX(ShootResumeDateTime) AS MergedResumeTime
    FROM CumulativeGroup
    GROUP BY StudioId,StartTimeStatus, GroupId

	),

SectionWiseLostTime AS (
    SELECT
        StudioId,
	 StartTimeStatus,
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
,RankedReason AS(
SELECT studioid,
StartTimeStatus,

SUM(DATEDIFF(MINUTE,MergedPauseTime,MergedResumeTime)) AS TotalTiemForReason,
ROW_NUMBER()OVER (PARTITION BY studioid order BY SUM(DATEDIFF(MINUTE, MergedPauseTime, MergedResumeTime)) DESC) as rn
    FROM MergedIntervals
	GROUP BY studioid, StartTimeStatus
	)
SELECT 
    StudioId,
	StartTimeStatus,
    SUM(TimeLostAM) AS TotalLostTimeAM,
    SUM(TimeLostPM) AS TotalLostTimePM,
    SUM(TimeLostEvening) AS TotalLostTimeEvening
FROM 
    SectionWiseLostTime
	WHERE EXISTS (
    SELECT 1 
    FROM RankedReason rr 
    WHERE rr.StudioId = SectionWiseLostTime.StudioId 
      AND rr.StartTimeStatus = SectionWiseLostTime.StartTimeStatus
      AND rr.rn = 1)
GROUP BY StudioId, StartTimeStatus, StartTimeStatus;
 
  