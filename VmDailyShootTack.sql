CREATE VIEW [Report].[vwGetDailyShootTrackerSummary]
AS

WITH cte_main 
AS
(
SELECT DISTINCT
       fss.OptionId,
       fss.ProductId,
       fss.StudioId,
       fss.SKU,
       fss.ShootDateId,
       fss.ShootTimeId,
       fss.ModelName,
       fss.PhotographerCompletionTimeStamp,
       fss.PhotoGrapherCompletionStateId,
       fss.RejectionStateId,
       fss.GoalTypeId,
       fss.GoalApproavalStateId,
       fss.EventTimestamp,
       fss.LastUpdatedTimestamp,
       fss.RejectionComments,
       fss.RejectionReasonCodeId,
       CASE
           WHEN fss.ShootTimeId IN ( 2, 3, 4 ) THEN
               2
           WHEN fss.ShootTimeId IN ( 8, 9, 10 ) THEN
               8
           ELSE
               fss.ShootTimeId
       END AS Calc_ShootTimeId,
       --
       COALESCE(fo1.[Photographer], fo2.[Photographer]) AS [Photographer],
       COALESCE(fo1.[Stylist], fo2.[Stylist]) AS [Stylist],
       COALESCE(fo1.[Producer], fo2.[Producer]) AS [Producer],
       CASE
           WHEN GoalTypeId = 4 -- Video 
                AND ISNULL(RejectionStateId, 0) != 15 -- Not rejected
       THEN
               1 -- Uploaded
           WHEN GoalTypeId != 4 -- Non Video
                AND GoalApproavalStateId = 9 -- Approved
                AND ISNULL(RejectionStateId, 0) != 15 -- Not Rejected
       THEN
               1 --Uploaded			
           WHEN RejectionStateId = 15 -- Rejected				
                AND drc.ReasonId IN ( 1, 2, 3, 4, 5, 6, 7, 8 ) --,182,183,184) -- Only Not shots, buying queries and reshoot reason for Studiuo rejections
       THEN
               0 -- Rejected to shoot ops i.e. not shot
           WHEN RejectionStateId = 15 -- Rejected				
                AND drc.ReasonId IN ( 162, 178, 179, 180, 181 ) -- Post production rejections (Manual Rejections)
       THEN
               1 -- Rejected to shoot ops i.e. not shot
           ELSE
               NULL
       END AS Uploaded,
       --------------------------------------------------------------------------------------------------
       CASE
           WHEN GoalTypeId = 4 -- Video 
                AND ISNULL(RejectionStateId, 0) != 15 -- Not rejected
       THEN
               fss.UploadedDateTimeStamp -- UploadedDateTimeStamp
           WHEN GoalTypeId != 4 -- Non Video
                AND GoalApproavalStateId = 9 -- Approved
                AND ISNULL(RejectionStateId, 0) != 15 -- Not Rejected
       THEN
               fss.UploadedDateTimeStamp --Uploaded			
           WHEN RejectionStateId = 15 -- Rejected				
                AND drc.ReasonId IN ( 1, 2, 3, 4, 5, 6, 7, 8 ) --,182,183,184) -- Only Not shots, buying queries and reshoot reason for Studiuo rejections
       THEN
               NULL                      -- Rejected to shoot ops i.e. not shot
           WHEN RejectionStateId = 15 -- Rejected				
                AND drc.ReasonId IN ( 162, 178, 179, 180, 181 ) -- Post production rejections (Manual Rejections)
       THEN
               fss.UploadedDateTimeStamp -- Rejected to shoot ops i.e. not shot
           ELSE
               NULL
       END AS UploadedDateTimeStamp,
       CASE
           WHEN GoalTypeId = 4 -- Video 
                AND
                (
                    ISNULL(RejectionStateId, 0) != 15 -- Not rejected
                    OR EventTypeId = 26
                ) -- StudiosGoalsRejectedOutExternal
       THEN
               1 -- Photographer Shot 
           WHEN GoalTypeId != 4 -- Non Video
                --AND ISNULL(RejectionStateId, 0) != 15 -- Not rejected
                AND PhotoGrapherCompletionStateId = 24 -- Photographer Compoletion State = Completed
       THEN
               1 -- Photographer Shot 
           ELSE
               NULL
       END AS PhotographerShot,
       --
       DENSE_RANK() OVER (PARTITION BY OptionId ORDER BY fss.EventTimestamp DESC) AS RN,
       CASE
           WHEN ISNULL(fss.CFSTag, 'X') IN ( 'Focus Shoot', 'Elevated' ) THEN
               1
           ELSE
               0
       END AS HasCFSTag
FROM Report.FactStudiosSnapshot fss
    LEFT JOIN Report.vwGetFactOps fo1
        ON fss.StudioId = fo1.StudioId
           AND fss.ShootDateId = fo1.ShootDateId
           AND fss.ShootTimeId = fo1.ShootTimeId
    LEFT JOIN Report.vwGetFactOps fo2
        ON fss.StudioId = fo2.StudioId
           AND fss.ShootDateId = fo2.ShootDateId
    LEFT JOIN Report.DimReasonCode drc
        ON fss.RejectionReasonCodeId = drc.ReasonId
WHERE fss.ShootDateId = CONVERT(INT, CONVERT(VARCHAR(8), GETDATE(), 112))
      AND
      (
          fss.IsActive = 1 -- Option is Active
          OR IsEnrichmentComplete = 1 -- Option is complete
          OR
          (
              fss.IsActive = 0
              AND fss.PhotoGrapherCompletionStateId IN ( 24, 25 )
          ) -- Option is In Active and it is either Photographer Shot or rejected to photographer
      )
),

--==========================================================================================================================================================
cte_upload_view
AS (SELECT OptionId,
           fss.ProductId,
           SKU,
           fss.StudioId,
           StudioSortKey,
           StudioName,
           CASE
               WHEN StudioName LIKE 'GLH%' THEN
                   'GLH'
               WHEN StudioName LIKE 'LEA%' THEN
                   'Leavesden'
               WHEN StudioName LIKE 'MAH%' THEN
                   'MAH'
               WHEN StudioName LIKE 'SAH%' THEN
                   'SAH'
               ELSE
                   'NA'
           END AS StudioType,
           fss.ShootDateId,
           CASE
               WHEN fss.ShootTimeId IN ( 2, 3, 4 ) THEN
                   2
               WHEN fss.ShootTimeId IN ( 8, 9, 10 ) THEN
                   8
               ELSE
                   fss.ShootTimeId
           END AS ShootTimeId,
           StandardDate,
           fss.[Photographer],
           fss.[Stylist],
           fss.[Producer],
           MAX(fss.EventTimestamp) AS EventTimestamp,
           DATEADD(
                      MINUTE,
                      DATEPART(tz, MAX(fss.LastUpdatedTimestamp)AT TIME ZONE 'GMT Standard Time'),
                      MAX(fss.LastUpdatedTimestamp)
                  ) AS LastUpdatedTimestamp,
           MAX(fss.LastUpdatedTimestamp) AS LastUpdatedTimestamp_utc,
           CASE
               WHEN COUNT(DISTINCT ISNULL(Uploaded, -1)) = 1 THEN
                   MAX(Uploaded)
               ELSE
                   NULL
           END AS [Uploaded Y/N],
           CASE
               WHEN COUNT(DISTINCT ISNULL(fss.PhotographerShot, -1)) = 1 THEN
                   MAX(fss.PhotographerShot)
               ELSE
                   NULL
           END AS [PhotographerShot Y/N],
           MAX(ReasonCodeName) AS ReasonCodeName,
           MAX(RejectionComments) AS RejectionComments,
           MAX(ProductTitle) AS ProductTitle,
           MAX(ModelName) AS ModelName,
           MAX(DATEADD(
                          MINUTE,
                          DATEPART(tz, UploadedDateTimeStamp AT TIME ZONE 'GMT Standard Time'),
                          UploadedDateTimeStamp
                      )
              ) AS UploadedDateTimeStamp,
           MAX(fss.HasCFSTag) AS HasCFSShoot
    FROM cte_main fss
        INNER JOIN Report.DimProduct P
            ON fss.ProductId = P.ProductId
        INNER JOIN Report.DimStudio st
            ON fss.StudioId = st.StudioId
        INNER JOIN Report.DimShootTime sti
            ON fss.ShootTimeId = sti.ShootTimeId
        INNER JOIN Report.DimDate dt
            ON fss.ShootDateId = dt.DateId
        LEFT JOIN Report.DimStudioState dss
            ON dss.StudioStateId = fss.PhotoGrapherCompletionStateId
        LEFT JOIN Report.DimReasonCode drc
            ON fss.RejectionReasonCodeId = drc.ReasonId
        LEFT JOIN Report.vwGetFactOps fo1
            ON fss.StudioId = fo1.StudioId
               AND fss.ShootDateId = fo1.ShootDateId
               AND fss.ShootTimeId = fo1.ShootTimeId
        LEFT JOIN Report.vwGetFactOps fo2
            ON fss.StudioId = fo2.StudioId
               AND fss.ShootDateId = fo2.ShootDateId
    WHERE RN = 1
    GROUP BY OptionId,
             fss.ProductId,
             SKU,
             fss.StudioId,
             st.StudioSortKey,
             st.StudioName,
             fss.ShootDateId,
             fss.ShootTimeId,
             dt.StandardDate,
             fss.[Photographer],
             fss.[Stylist],
             fss.[Producer]),
     cte_Upload
AS (SELECT [OptionId],
           [ProductId],
           [SKU],
           [StudioId],
           CAST([StudioSortKey] AS INT) AS [StudioSortKey],
           [StudioName],
           [StudioType],
           [ShootDateId],
           F.[ShootTimeId],
           DT.[ShootTimeName] AS [ShootTimeName],
           [StandardDate],
           F.[LastUpdatedTimestamp],
           [LastUpdatedTimestamp_utc],
           DATEADD(MINUTE, DATEPART(tz, EventTimestamp AT TIME ZONE 'GMT Standard Time'), EventTimestamp) AS EventTimestamp_utc,
           [Uploaded Y/N],
           CASE
               WHEN [UploadedDateTimeStamp] = '1900-01-01 00:00:00.000'
                    OR [UploadedDateTimeStamp] IS NULL THEN
                   0
               WHEN CAST([UploadedDateTimeStamp] AS TIME) <= '13:45:00'
                    AND DT.ShootTimeName = 'AM' THEN
                   1
               WHEN CAST([UploadedDateTimeStamp] AS TIME) <= '13:45:00'
                    AND DT.ShootTimeName = 'PM' THEN
                   1
               WHEN CAST([UploadedDateTimeStamp] AS TIME) <= '13:45:00'
                    AND DT.ShootTimeName = 'FD' THEN
                   1
               ELSE
                   0
           END AS [AM Uploaded],
           CASE
               WHEN [UploadedDateTimeStamp] = '1900-01-01 00:00:00.000'
                    OR [UploadedDateTimeStamp] IS NULL THEN
                   0
               WHEN CAST([UploadedDateTimeStamp] AS TIME) > '13:45:00'
                    AND DT.ShootTimeName = 'PM' THEN
                   1
               WHEN CAST([UploadedDateTimeStamp] AS TIME) > '13:45:00'
                    AND DT.ShootTimeName = 'AM' THEN
                   1
               WHEN CAST([UploadedDateTimeStamp] AS TIME) > '13:45:00'
                    AND DT.ShootTimeName = 'FD' THEN
                   1
               ELSE
                   0
           END AS [PM Uploaded],
           [UploadedDateTimeStamp],
           ----------------------------------------
           CASE
               WHEN DT.ShootTimeName = 'AM' THEN
                   1
               ELSE
                   0
           END AS [AM Target],
           -----------------------------------------

           CASE
               WHEN DT.ShootTimeName = 'PM' THEN
                   1
               ELSE
                   0
           END AS [PM Target],
           -----------------------------------------
           CASE
               WHEN DT.ShootTimeName = 'FD' THEN
                   1
               ELSE
                   0
           END AS [FD Target],
           ------------------------------------------
           ISNULL([PhotographerShot Y/N], 0) AS [PhotographerShot Y/N],
           CASE
               WHEN ISNULL([Uploaded Y/N], 0) = 0
                    AND ISNULL([PhotographerShot Y/N], 0) = 0 THEN
                   1
               ELSE
                   0
           END AS Outstanding,
           CASE
               WHEN ISNULL([Uploaded Y/N], 0) = 0
                    AND ISNULL([PhotographerShot Y/N], 0) = 1 THEN
                   1
               ELSE
                   0
           END AS Shot,
           CASE
               WHEN [Uploaded Y/N] = 0 THEN
                   1
               ELSE
                   0
           END AS NotShot,

		    CASE
               WHEN DT.ShootTimeName = 'AM'
                    AND LEFT(ISNULL(F.[ReasonCodeName], 'X'), 8) = 'Not Shot'
                    AND F.[Uploaded Y/N] = 0 THEN
                   1
               WHEN DT.ShootTimeName = 'FD'
                    AND LEFT(ISNULL(F.[ReasonCodeName], 'X'), 8) = 'Not Shot'
                    AND CAST(DATEADD(
                                        MINUTE,
                                        DATEPART(tz, EventTimestamp AT TIME ZONE 'GMT Standard Time'),
                                        EventTimestamp
                                    ) AS TIME) <= '13:45:00' THEN
                   1
               ELSE
                   0
           END AS [AM Notshot],
           CASE
               WHEN DT.ShootTimeName = 'PM'
                    AND LEFT(ISNULL(F.[ReasonCodeName], 'X'), 8) = 'Not Shot'
                    AND F.[Uploaded Y/N] = 0 THEN
                   1
               WHEN DT.ShootTimeName = 'FD'
                    AND LEFT(ISNULL(F.[ReasonCodeName], 'X'), 8) = 'Not Shot'
                    AND CAST(DATEADD(
                                        MINUTE,
                                        DATEPART(tz, EventTimestamp AT TIME ZONE 'GMT Standard Time'),
                                        EventTimestamp
                                    ) AS TIME) > '13:45:00' THEN
                   1
               ELSE
                   0
           END AS [PM Notshot],
           HasCFSShoot
    FROM [Report].[vwGetFactStudiosUploadStats] F
        JOIN Report.DimShootTime DT
            ON F.ShootTimeId = DT.ShootTimeId
     --WHERE F.StudioName IN('LEA 5')
     --WHERE DT.ShootTimeName='FD'
     --'GLH 4','LEA 1.2','GLH 1','

     ),
     cte_UploadSummary
AS (SELECT StudioType,
           CAST(StudioSortKey AS INT) AS StudioSortKey,
           StudioName,
           ShootDateId,
           [ShootTimeName] AS ShootTimeName,
           --UploadAmPm,
           ISNULL(SUM(Shot), 0) AS Shot,
           ISNULL(SUM([Uploaded Y/N]), 0) AS [Uploaded],
           ISNULL(SUM([AM Uploaded]), 0) AS [AM Uploaded],
           ISNULL(SUM([PM Uploaded]), 0) AS [PM Uploaded],
           ISNULL(SUM(Outstanding), 0) AS Outstanding,
           ISNULL(SUM(NotShot), 0) AS NotShot,
           ISNULL(SUM([AM Notshot]), 0) AS [AM Notshot],
           ISNULL(SUM([PM Notshot]), 0) AS [PM Nothsot],
           CASE
               WHEN cte_Upload.ShootTimeName = 'AM' THEN
                   ISNULL(SUM([AM Target]), 0)
               ELSE
                   0
           END AS [AM Target],
           CASE
               WHEN cte_Upload.ShootTimeName = 'PM' THEN
                   ISNULL(SUM([PM Target]), 0)
               ELSE
                   0
           END AS [PM Target],
           CASE
               WHEN cte_Upload.ShootTimeName = 'FD' THEN
                   ISNULL(SUM([FD Target]), 0)
               ELSE
                   0
           END AS [FD Target],
           ISNULL(COUNT(ISNULL(OptionId, 0)), 0) AS TARGET,
           (
               SELECT MAX([LastUpdatedTimestamp])FROM cte_Upload
           ) AS [LastUpdatedTimestamp],
           SUM(ISNULL(HasCFSShoot, 0)) AS HasCFSShoot
    FROM cte_Upload
    GROUP BY CAST(StudioSortKey AS INT),
             StudioName,
             StudioType,
             ShootDateId,
             [ShootTimeName])
---=======================================================================================================================================================================
---=======================================================================================================================================================================
---=======================================================================================================================================================================
,    cte_before_lunch
    AS
    (
        SELECT
            fss.StudioId
            ,fss.ShootTimeId
            ,CASE 
           WHEN fss.ShootTimeId IN (2,3,4) THEN 2
           WHEN fss.ShootTimeId IN (8,9,10) THEN 8
           ELSE fss.ShootTimeId
           END AS Calc_ShootTimeId
            ,CONVERT(VARCHAR(5), MIN(DATEADD(MINUTE, DATEPART(tz, PhotographerCompletionTimeStamp AT TIME ZONE 'GMT Standard Time'), PhotographerCompletionTimeStamp)), 108) AS min_before_lunch
            ,CONVERT(VARCHAR(5), MAX(DATEADD(MINUTE, DATEPART(tz, PhotographerCompletionTimeStamp AT TIME ZONE 'GMT Standard Time'), PhotographerCompletionTimeStamp)), 108) AS max_before_lunch
        FROM
            cte_main fss
        WHERE fss.ShootDateId = CONVERT(INT, CONVERT(VARCHAR(8), GETDATE(), 112))
            AND CONVERT(DATE, DATEADD(MINUTE, DATEPART(tz, PhotographerCompletionTimeStamp AT TIME ZONE 'GMT Standard Time'), PhotographerCompletionTimeStamp)) = CONVERT(DATE, DATEADD(MINUTE, DATEPART(tz, GETDATE() AT TIME ZONE 'GMT Standard Time'), GETDATE()))
            AND CONVERT(TIME, DATEADD(MINUTE, DATEPART(tz, PhotographerCompletionTimeStamp AT TIME ZONE 'GMT Standard Time'), PhotographerCompletionTimeStamp)) < '13:46:00.0000000'
        -- Maximum time before lunch		
        GROUP BY fss.StudioId, fss.ShootTimeId
    )

--============================================================================================================================================================

    ,cte_after_lunch
    AS
    (
        SELECT
            fss.StudioId
            ,fss.ShootTimeId
            ,CASE 
           WHEN fss.ShootTimeId IN (2,3,4) THEN 2
           WHEN fss.ShootTimeId IN (8,9,10) THEN 8
           ELSE fss.ShootTimeId
           END AS Calc_ShootTimeId
            ,CONVERT(VARCHAR(5), MIN(DATEADD(MINUTE, DATEPART(tz, PhotographerCompletionTimeStamp AT TIME ZONE 'GMT Standard Time'), PhotographerCompletionTimeStamp)), 108) AS min_after_lunch
            ,CASE 
			WHEN CONVERT(TIME, DATEADD(MINUTE, DATEPART(tz, GETDATE() AT TIME ZONE 'GMT Standard Time'), GETDATE())) > '16:30:00.0000000' -- time after which Last Shot should be calculated
				THEN CONVERT(VARCHAR(5), MAX(DATEADD(MINUTE, DATEPART(tz, PhotographerCompletionTimeStamp AT TIME ZONE 'GMT Standard Time'), PhotographerCompletionTimeStamp)), 108)
			ELSE NULL
			END AS max_after_lunch
        FROM
            cte_main fss
        WHERE fss.ShootDateId = CONVERT(INT, CONVERT(VARCHAR(8), GETDATE(), 112))
            AND CONVERT(DATE, DATEADD(MINUTE, DATEPART(tz, PhotographerCompletionTimeStamp AT TIME ZONE 'GMT Standard Time'), PhotographerCompletionTimeStamp)) = CONVERT(DATE, DATEADD(MINUTE, DATEPART(tz, GETDATE() AT TIME ZONE 'GMT Standard Time'), GETDATE()))
            AND CONVERT(TIME, DATEADD(MINUTE, DATEPART(tz, PhotographerCompletionTimeStamp AT TIME ZONE 'GMT Standard Time'), PhotographerCompletionTimeStamp)) >= '13:46:00.0000000' -- Minimum time after lunch
            --AND fss.ShootTimeId <> 5
        GROUP BY fss.StudioId,fss.ShootTimeId
    )
--============================================================================================================================================================
,cte_timing
AS
(

	SELECT
            DISTINCT
            fss.StudioId
            ,MAX(fo1.Photographer) Photographer
            ,MAX(fo1.Stylist) Stylist
            ,MAX(fo1.Producer) Producer
            ,SUM(CASE 
				WHEN pdm.ProductDivision = 'MW'
					THEN 1
				ELSE 0
				END) MW_Count
            ,SUM(CASE 
				WHEN pdm.ProductDivision = 'WW'
					THEN 1
				ELSE 0
				END) WW_Count
            ,fss.ShootTimeId
                ,CASE 
           WHEN fss.ShootTimeId IN (2,3,4) THEN 2
           WHEN fss.ShootTimeId IN (8,9,10) THEN 8
           ELSE fss.ShootTimeId
           END AS Calc_ShootTimeId
            ,MAX(Stime.ShootTimeName) AS ShootTimeName
            ,MAX(fss.ModelName) AS ModelName
            ,MAX(fss.LastUpdatedTimestamp) AS LastUpdatedTimestamp
        FROM
            cte_main fss
            LEFT JOIN Report.DimOption DO ON FSS.OptionId = DO.OptionId
            LEFT JOIN Report.DimProduct P ON DO.ProductId = P.ProductId
            LEFT JOIN Report.DimProductDivisionMapping PDM ON PDM.RetailBuyingSubGroup = P.RetailBuyingSubGroup
                AND PDM.RetailDepartmentName = P.RetailDepartmentName
            LEFT JOIN Report.DimShootTime Stime ON Stime.ShootTimeId = CASE 
                                                                               WHEN fss.ShootTimeId IN (2,3,4) THEN 2
                                                                               WHEN fss.ShootTimeId IN (8,9,10) THEN 8
                                                                               ELSE fss.ShootTimeId
                                                                           END
            LEFT JOIN Report.vwGetFactOps fo1 ON fss.StudioId = fo1.StudioId
                AND fss.ShootDateId = fo1.ShootDateId
                AND (
			fss.ShootTimeId = fo1.ShootTimeId
                OR (fo1.ShootTimeId = 2 AND fss.ShootTimeId IN (2,3,4))
                OR (fo1.ShootTimeId = 3 AND fss.ShootTimeId IN (2,3,4))
                OR (fo1.ShootTimeId = 4 AND fss.ShootTimeId IN (2,3,4))
                OR (fo1.ShootTimeId = 8 AND fss.ShootTimeId IN (8,9,10))
                OR (fo1.ShootTimeId = 9 AND fss.ShootTimeId IN (8,9,10))
                OR (fo1.ShootTimeId = 10 AND fss.ShootTimeId IN (8,9,10))
                OR (fss.ShootTimeId = 6 AND fo1.ShootTimeId IN  (2,3,4,8,9,10))
                OR (fss.ShootTimeId IN  (2,3,4,8,9,10) AND fo1.ShootTimeId = 6)
        )


        GROUP BY fss.StudioId,
		fss.ShootDateId,
		fss.ShootTimeId
),

----=====================================================================================================================================================================
cte_timing_view
AS
(
SELECT
    DISTINCT
    st.StudioSortKey
    ,st.StudioName
    ,UPPER(cpi.ShootTimeName) AS ShootTimeName
    ,CASE 
		WHEN StudioName LIKE 'GLH%'
			THEN 'GLH'
		WHEN StudioName LIKE 'LEA%'
			THEN 'Leavesden'
		WHEN StudioName LIKE 'MAH%'
			THEN 'MAH'
		WHEN StudioName LIKE 'SAH%'
			THEN 'SAH'
		ELSE 'NA'
		END AS StudioType
    ,CASE 
		WHEN SUM(mw_count) > SUM(ww_count)
			THEN 'MW'
		WHEN SUM(ww_count) >= SUM(mw_count)
			THEN 'WW'
		ELSE NULL
		END AS PredominantGender
    --sum(mw_count), sum(ww_count),
    ,MAX(cpi.Photographer) AS Photographer
    ,MAX(cpi.Producer) AS Producer
    ,MAX(cpi.Stylist) AS Stylist
    ,MAX(cpi.ModelName) AS ModelName
    ,MAX(cbl.min_before_lunch) AS FirstShot
    ,MAX(cbl.max_before_lunch) AS LastShotAM
    ,MAX(cal.min_after_lunch) AS FirstShotPM
    ,MAX(cal.max_after_lunch) AS LastShot
    ,MAX(cpi.LastUpdatedTimestamp) AS LastUpdatedTimestamp_UTC
    ,DATEADD(MINUTE, DATEPART(tz, MAX(cpi.LastUpdatedTimestamp) AT TIME ZONE 'GMT Standard Time'), MAX(cpi.LastUpdatedTimestamp)) AS LastUpdatedTimestamp
FROM
    cte_timing cpi
    INNER JOIN Report.DimStudio st ON cpi.StudioId = st.StudioId
    LEFT JOIN cte_before_lunch cbl ON cpi.StudioId = cbl.StudioId AND cpi.Calc_ShootTimeId = cbl.Calc_ShootTimeId
    LEFT JOIN cte_after_lunch cal ON cpi.StudioId = cal.StudioId AND cpi.Calc_ShootTimeId = cal.Calc_ShootTimeId
WHERE st.StudioName <> 'Brand Images' 
GROUP BY st.StudioSortKey,
	st.StudioName, cpi.ShootTimeName
),

     cte_timing_summary

AS (SELECT CAST(StudioSortKey AS INT) AS StudioSortKey,
           [StudioName],
           [ShootTimeName],
           [StudioType],
           [PredominantGender],
           [Photographer],
           [Producer],
           [Stylist],
           [ModelName],
           [FirstShot] AS [FirstShotAM],
           [LastShotAM],
           [FirstShotPM],
           [LastShot] AS [LastShotPM],
           [LastUpdatedTimestamp_UTC],
           [LastUpdatedTimestamp]
    FROM [Report].[vwGetMarkAsShotStats]
),
cte_join
AS (SELECT ISNULL(t.[StudioName], u.[StudioName]) AS [StudioName],
           ISNULL(t.ShootTimeName, u.ShootTimeName) AS ShootTimeName,
                                                    --u.ShootTimeName u_UploadShootTimeName,
                                                    --ISNULL([UploadAmPm],u.ShootTimeName) AS [UploadAmPm],
                                                    --[UploadAmPm],
           [FirstShotAM],
           [LastShotAM],
           [FirstShotPM],
           [LastShotPM],
           CASE
               WHEN t.[StudioName] IS NULL THEN
                   1
               ELSE
                   0
           END AS [No Timing],
           u.Shot,
           u.NotShot,
                                                    --u.Uploaded,
           u.[AM Uploaded],
           u.[PM Uploaded],
           u.[AM Notshot],
           u.[PM Nothsot],
           u.[AM Target],
           u.[PM Target],
           u.[FD Target],
           u.Outstanding,
           ISNULL(u.HasCFSShoot, 0) AS HasCFSShoot, ------------------------------------------------------------------HasCFSShoot
           CASE
               WHEN ISNULL(t.StudioSortKey, 0) <> 0 THEN
                   t.StudioSortKey
               WHEN ISNULL(u.StudioSortKey, 0) <> 0 THEN
                   u.StudioSortKey
               ELSE
                   0
           END AS StudioSortKey
    FROM cte_timing_summary t
        JOIN cte_UploadSummary u
            ON t.StudioName = u.StudioName),
     --     --SELECT * FROM cte_join				   

     cte_all
AS (SELECT [StudioName],
           [ShootTimeName],
           --[UploadAmPm],
           [StudioSortKey],
           [FirstShotAM],
           [LastShotAM],
           [FirstShotPM],
           [LastShotPM],
           ISNULL(SUM([No Timing]), 0) AS [No Timing],
           ISNULL(SUM([Shot]), 0) AS [Shot],
           ISNULL(SUM([NotShot]), 0) AS [NotShot],
           --ISNULL(SUM([Uploaded]),0) AS [Uploaded],
           ISNULL(SUM([AM Uploaded]), 0) AS [AM Uploaded],
           ISNULL(SUM([PM Uploaded]), 0) AS [PM Uploaded],
           ISNULL(SUM([cte_join].[AM Notshot]), 0) AS [AM Notshot],
           ISNULL(SUM([cte_join].[PM Nothsot]), 0) AS [PM Notshot],
           ISNULL(SUM([AM Target]), 0) [AM Target],
           ISNULL(SUM([PM Target]), 0) [PM Target],
           ISNULL(SUM([FD Target]), 0) [FD Target],
           ISNULL(SUM([Outstanding]), 0) AS [Outstanding],
           ISNULL(SUM([HasCFSShoot]), 0) AS [HasCFSShoot]
    FROM cte_join
    GROUP BY [StudioName],
             [ShootTimeName],
             [StudioSortKey],
             [FirstShotAM],
             [LastShotAM],
             [FirstShotPM],
             [LastShotPM]),
     --SELECT * FROM cte_all
     cte_AM
AS (SELECT [StudioName],
           [ShootTimeName],
           [StudioSortKey],
           [FirstShotAM],
           [LastShotAM],
           [cte_all].[FirstShotPM],
           [cte_all].[LastShotPM],
           [Shot],
           [NotShot],
           [cte_all].[AM Uploaded],
           [cte_all].[PM Uploaded],
           [cte_all].[AM Notshot],
           [cte_all].[PM Notshot],
           [cte_all].[AM Target],
           [Outstanding],
           [HasCFSShoot]
    FROM cte_all
    WHERE cte_all.ShootTimeName = 'AM'),
     --SELECT * FROM cte_AM
     --     ---====================================================================================================================================================
     cte_PM
AS (SELECT [StudioName],
           [ShootTimeName],
           [StudioSortKey],
           [FirstShotPM],
           [LastShotPM],
           [cte_all].[FirstShotAM],
           [cte_all].[LastShotAM],
           [Shot],
           [NotShot],
           [cte_all].[PM Uploaded],
           [cte_all].[AM Notshot],
           [cte_all].[PM Notshot],
           [cte_all].[PM Target],
           [Outstanding],
           [HasCFSShoot]
    FROM cte_all
    WHERE cte_all.ShootTimeName = 'PM'),
     --SELECT * FROM cte_pm



     --     --     ---====================================================================================================================================================

     cte_FD
AS (SELECT [StudioName],
           [ShootTimeName],
           [StudioSortKey],
           [FirstShotAM],
           [LastShotAM],
           FirstShotPM,
           LastShotPM,
           [Shot],
           [NotShot],
           [AM Uploaded],
           [PM Uploaded],
           [cte_all].[AM Notshot],
           [cte_all].[PM Notshot],
           [Outstanding],
           [cte_all].[FD Target],
           [HasCFSShoot]
    FROM cte_all
    WHERE cte_all.ShootTimeName = 'FD'),
     --SELECT * FROM cte_FD

     --     ----==================================================================
     cte_AMPMFD
AS (SELECT CASE
               WHEN fd.ShootTimeName = 'FD' THEN
                   fd.StudioSortKey
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'AM' THEN
                   am.StudioSortKey
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'X'
                    AND pm.ShootTimeName = 'PM' THEN
                   pm.StudioSortKey
               ELSE
                   NULL
           END AS StudioSortKey,
           CASE
               WHEN fd.ShootTimeName = 'FD' THEN
                   fd.StudioName
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'AM' THEN
                   am.StudioName
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'X'
                    AND pm.ShootTimeName = 'PM' THEN
                   pm.StudioName
               ELSE
                   NULL
           END AS StudioName,
           CASE
               WHEN fd.ShootTimeName = 'FD' THEN
                   'FD'
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'AM' THEN
                   'AM'
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'X'
                    AND pm.ShootTimeName = 'PM' THEN
                   'PM'
               ELSE
                   NULL
           END AS DAY,
           ------------------------------------------------------------  AM and PM
           CASE
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'AM'
                    AND ISNULL(pm.ShootTimeName, 'X') = 'PM' THEN
                   'Yes'
               ELSE
                   'No'
           END AS [AM and PM Shoot],
           CASE
               WHEN fd.ShootTimeName = 'FD' THEN
                   fd.FirstShotAM
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'AM' THEN
                   am.FirstShotAM
               ELSE
                   NULL
           END AS FirstShotAM,
           -------------------------------------------------------------LastShotAM
           CASE
               WHEN fd.ShootTimeName = 'FD' THEN
                   fd.LastShotAM
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X'
                    AND ISNULL(am.ShootTimeName, 'X') = 'AM' THEN
                   am.LastShotAM
               ELSE
                   NULL
           END AS LastShotAM,
           -------------------------------------------------------------AM Notshot
           CASE
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD') THEN
                   ISNULL(fd.[AM Notshot], 0)
               WHEN (ISNULL(am.ShootTimeName, 'X') = 'AM') THEN
                   ISNULL(am.[AM Notshot], 0)
               ELSE
                   0
           END AS [AM NotShot],
           ------------------------------------------------------------- PM Notshot
           CASE
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD') THEN
                   ISNULL(fd.[PM Notshot], 0)
               WHEN (ISNULL(pm.ShootTimeName, 'X') = 'PM') THEN
                   ISNULL(pm.[PM Notshot], 0)
               ELSE
                   0
           END AS [PM NotShot],
           ------------------------------------------------------------- FirstShotPM
           CASE
               WHEN fd.ShootTimeName = 'FD' THEN --No
                   fd.FirstShotPM
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X' --not FD
                    AND ISNULL(am.ShootTimeName, 'X') = 'X' --not AM
                    AND ISNULL(pm.ShootTimeName, 'X') = 'PM'
                    AND pm.FirstShotPM IS NOT NULL THEN --when only PM row exists
                   pm.FirstShotPM
               WHEN am.ShootTimeName IS NOT NULL
                    AND pm.FirstShotPM IS NULL THEN
                   am.FirstShotPM --when am and pm exists but pm.FirstPm is NULL
               WHEN pm.FirstShotPM IS NOT NULL THEN
                   pm.FirstShotPM -- when pm.firstPm is not null
           END AS FirstShotPM,



           ------------------------------------------------------------- LastShotPM


           CASE
               WHEN fd.ShootTimeName = 'FD' THEN --No
                   fd.LastShotPM
               WHEN ISNULL(fd.ShootTimeName, 'X') = 'X' --not FD
                    AND ISNULL(am.ShootTimeName, 'X') = 'X' --not AM
                    AND ISNULL(pm.ShootTimeName, 'X') = 'PM'
                    AND pm.LastShotPM IS NOT NULL THEN --when only PM row exists
                   pm.LastShotPM
               WHEN am.ShootTimeName IS NOT NULL
                    AND pm.LastShotPM IS NULL THEN
                   am.LastShotPM --when am and pm exists but pm.FirstPm is NULL
               WHEN pm.LastShotPM IS NOT NULL THEN -- when pm.LastPm is not null
                   pm.LastShotPM
           END AS LastShotPM,


           ------------------------------------------------------------- AM TARGET
           CASE
               WHEN (ISNULL(am.ShootTimeName, 'X') = 'AM') THEN
                   ISNULL(am.[AM Target], 0)
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD')
                    AND fd.[FD Target] > 1 THEN
                   CASE
                       WHEN fd.[FD Target] % 2 = 0 THEN
                           fd.[FD Target] / 2
                       ELSE
                           fd.[FD Target] / 2 + 1
                   END
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD')
                    AND fd.[FD Target] = 1
                    AND ISNULL(fd.[AM Uploaded], 0) <> 0 THEN
                   1
               ELSE
                   0
           END AS [AM Target],
           ------------------------------------------------------------- PM TARGET
           CASE
               WHEN (ISNULL(pm.ShootTimeName, 'X') = 'PM') THEN
                   ISNULL(pm.[PM Target], 0)
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD')
                    AND fd.[FD Target] > 1 THEN
                   fd.[FD Target] / 2
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD')
                    AND fd.[FD Target] = 1
                    AND ISNULL(fd.[PM Uploaded], 0) <> 0 THEN
                   1
               ELSE
                   0
           END AS [PM Target],

           ------------------------------------------------------------- AM UPLOADED
           CASE
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD') THEN
                   ISNULL(fd.[AM Uploaded], 0)
               WHEN (ISNULL(am.ShootTimeName, 'X') = 'PM') THEN
                   0
               WHEN (ISNULL(am.ShootTimeName, 'X') = 'AM') THEN
                   ISNULL(am.[AM Uploaded], 0)
               --WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD') THEN fd.Uploaded
               ELSE
                   0
           END AS [AM Uploaded],
           ------------------------------------------------------------- PM UPLOADED
           CASE
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD') THEN
                   ISNULL(fd.[PM Uploaded], 0)
               WHEN (ISNULL(am.ShootTimeName, 'X') = 'AM')
                    AND
                    (
                        pm.[PM Uploaded] = 0
                        OR ISNULL(pm.[PM Uploaded], 0) = 0
                    )
                    AND am.[PM Uploaded] > 0 THEN
                   am.[PM Uploaded]
               WHEN (ISNULL(pm.ShootTimeName, 'X') = 'AM') THEN
                   0
               WHEN (ISNULL(pm.ShootTimeName, 'X') = 'PM') THEN
                   ISNULL(pm.[PM Uploaded], 0)
               ELSE
                   0
           END AS [PM Uploaded],

           CASE
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'FD') THEN
                   ISNULL(fd.HasCFSShoot, 0)
               WHEN (ISNULL(am.ShootTimeName, 'X') = 'AM') THEN
                   ISNULL(am.HasCFSShoot, 0)
               WHEN (ISNULL(fd.ShootTimeName, 'X') = 'PM') THEN
                   ISNULL(pm.HasCFSShoot, 0)
               ELSE
                   0
           END AS HasCFSShoot
    FROM cte_AM am
        FULL OUTER JOIN cte_PM pm
            ON am.StudioName = pm.StudioName
        FULL OUTER JOIN cte_FD fd
            ON am.StudioName = fd.StudioName)

,cte_summary
AS
(
SELECT c.StudioSortKey,
       c.StudioName AS [Studio Name],
       c.DAY,
       c.[AM and PM Shoot],
       c.FirstShotAM AS [First Shot AM],
       c.LastShotAM AS [Last Shot AM],
       c.[AM Target],
       c.[AM Uploaded],
	   (c.[AM Uploaded] * 100) / NULLIF(c.[AM Target], 0) AS [AM Uploaded%],
	   ([PM Uploaded] * 100) / NULLIF([PM Target], 0) AS [PM Uploaded%],
       c.[AM NotShot],
       c.FirstShotPM AS [First Shot PM],
       c.LastShotPM AS [Last Shot PM],
       c.[PM NotShot],
       c.[PM Target],
       c.[PM Uploaded],
       c.HasCFSShoot AS [Has CFS Shoot],
       CASE
           WHEN DAY = 'FD' THEN
               1
           WHEN DAY = 'AM'
                AND [AM and PM Shoot] = 'Yes' THEN
               1
           WHEN DAY = 'AM'
                AND [AM and PM Shoot] = 'No' THEN
               0.5
           WHEN DAY = 'PM'
                AND [AM and PM Shoot] = 'Yes' THEN
               1
           WHEN DAY = 'PM'
                AND [AM and PM Shoot] = 'No' THEN
               0.5
           ELSE
               0
       END AS [Studio Open]
FROM cte_AMPMFD c
),
cte_withqod
AS
(
SELECT 
[StudioSortKey]
      ,[Studio Name]
      ,[DAY]
      ,[AM and PM Shoot]
      ,[First Shot AM]
      ,[Last Shot AM]
      ,[AM Target]
      ,[AM Uploaded]
	  ,[AM Uploaded%]
	  ,[PM Uploaded%]
      ,[AM NotShot]
      ,[First Shot PM]
      ,[Last Shot PM]
      ,[PM NotShot]
      ,[PM Target]
      ,[PM Uploaded]
      ,[Has CFS Shoot]
      ,[Studio Open]
	   ,(SELECT MAX(Report.[udfGetQuadrantOfDay] (GETDATE()))) AS qod
FROM cte_summary
)

SELECT 
       CAST([StudioSortKey] AS INT) AS [StudioSortKey]
      ,[Studio Name]
      ,[DAY]
      ,[AM and PM Shoot]
      ,[First Shot AM]
      ,[Last Shot AM]
      ,[AM Target]
      ,[AM Uploaded]
	  ,ISNULL([AM Uploaded%],0) AS [AM Uploaded%]
	  ,ISNULL([PM Uploaded%],0)AS [PM Uploaded%]
      ,[AM NotShot]
      ,[First Shot PM]
      ,[Last Shot PM]
      ,[PM NotShot]
      ,[PM Target]
      ,[PM Uploaded]
      ,[Has CFS Shoot]
      ,[Studio Open]
	  ,([AM Uploaded] + [PM Uploaded]) AS [Total Uploaded]
      ,([AM Target] + [PM Target]) AS [Total Target]
	  ,([AM NotShot] + [PM NotShot]) AS [Total NotShot]
	  ,qod
	  , CASE
        WHEN qod = 0 THEN 5
        WHEN (qod = 1 AND ISNULL([AM Uploaded%],0) < 15)
            OR (qod = 2 AND ISNULL([AM Uploaded%],0) < 40)
            OR (qod = 3 AND ISNULL([AM Uploaded%],0) < 65)
            OR (qod = 4 AND ISNULL([AM Uploaded%],0) < 90)
            THEN 4
        WHEN (qod = 1 AND (ISNULL([AM Uploaded%],0) >= 15 AND ISNULL([AM Uploaded%],0) < 20))
            OR (qod = 2 AND (ISNULL([AM Uploaded%],0) >= 40 AND ISNULL([AM Uploaded%],0) < 45))
            OR (qod = 3 AND (ISNULL([AM Uploaded%],0) >= 65 AND ISNULL([AM Uploaded%],0) < 70))
            OR (qod = 4 AND (ISNULL([AM Uploaded%],0) >= 90 AND ISNULL([AM Uploaded%],0) < 95))
            THEN 3
        WHEN (qod = 1 AND (ISNULL([AM Uploaded%],0) >= 20 AND ISNULL([AM Uploaded%],0) < 25))
            OR (qod = 2 AND (ISNULL([AM Uploaded%],0) >= 45 AND ISNULL([AM Uploaded%],0) < 50))
            OR (qod = 3 AND (ISNULL([AM Uploaded%],0) >= 70 AND ISNULL([AM Uploaded%],0) < 75))
            OR (qod = 4 AND (ISNULL([AM Uploaded%],0) >= 95 AND ISNULL([AM Uploaded%],0) < 100))
            THEN 2
        WHEN (qod = 1 AND ISNULL([AM Uploaded%],0) >= 25)
            OR (qod = 2 AND ISNULL([AM Uploaded%],0) >= 50)
            OR (qod = 3 AND [AM Uploaded%] >= 75)
            OR (qod = 4 AND [AM Uploaded%] = 100)
            THEN 1
        ELSE 5
    END AS AMcolorcode,
	   CASE
        WHEN qod = 0 THEN 5
        WHEN (qod = 1 AND ISNULL([PM Uploaded%],0) < 15)
            OR (qod = 2 AND ISNULL([PM Uploaded%],0) < 40)
            OR (qod = 3 AND ISNULL([PM Uploaded%],0) < 65)
            OR (qod = 4 AND ISNULL([PM Uploaded%],0) < 90)
            THEN 4
        WHEN (qod = 1 AND (ISNULL([PM Uploaded%],0) >= 15 AND ISNULL([PM Uploaded%],0) < 20))
            OR (qod = 2 AND (ISNULL([PM Uploaded%],0) >= 40 AND ISNULL([PM Uploaded%],0) < 45))
            OR (qod = 3 AND (ISNULL([PM Uploaded%],0) >= 65 AND ISNULL([PM Uploaded%],0) < 70))
            OR (qod = 4 AND (ISNULL([PM Uploaded%],0) >= 90 AND ISNULL([PM Uploaded%],0) < 95))
            THEN 3
        WHEN (qod = 1 AND (ISNULL([PM Uploaded%],0) >= 20 AND ISNULL([PM Uploaded%],0) < 25))
            OR (qod = 2 AND (ISNULL([PM Uploaded%],0) >= 45 AND ISNULL([PM Uploaded%],0) < 50))
            OR (qod = 3 AND (ISNULL([PM Uploaded%],0) >= 70 AND ISNULL([PM Uploaded%],0) < 75))
            OR (qod = 4 AND (ISNULL([PM Uploaded%],0) >= 95 AND ISNULL([PM Uploaded%],0) < 100))
            THEN 2
        WHEN (qod = 1 AND ISNULL([PM Uploaded%],0) >= 25)
            OR (qod = 2 AND ISNULL([PM Uploaded%],0) >= 50)
            OR (qod = 3 AND ISNULL([PM Uploaded%],0) >= 75)
            OR (qod = 4 AND ISNULL([PM Uploaded%],0) = 100)
            THEN 1
        ELSE 5
        --ELSE 5
    END AS PMcolorcode
	FROM cte_withqod
GO
