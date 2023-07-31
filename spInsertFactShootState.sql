USE [Manufacturing]
GO
alter PROCEDURE spInsertFactShootState
    @factshootstate ETL.udtFactShootState READONLY
AS
BEGIN
    INSERT INTO [Report].[FactShootState] (
        correlationId,
        ShootStateId,
        EventTypeId,
        ShootTimeId,
        ShootDateId,
        StudioId,
        ShootTypeId,
        Isshootstarted,
        ShootStartedDateTime,
        IssuedId,
        Reason,
        Comments,
        UserId,
        IsissueResolved,
        ShootPausedDateTime,
        ShootResumeDateTime,
        ExpectedMorningstartTime,
        ExpectedAfternoonStarttime,
        ExpectedEveningStarttime,
        EventTimeStamp,
        LastUpdatedTimeStamp
    )
    SELECT
        correlationId,
        ShootStateId,
        EventTypeId,
        ShootTimeId,
        ShootDateId,
        StudioId,
        ShootTypeId,
        Isshootstarted,
        ShootStartedDateTime,
        IssuedId,
        Reason,
        Comments,
        UserId,
        IsissueResolved,
        ShootPausedDateTime,
        ShootResumeDateTime,
        ExpectedMorningstartTime,
        ExpectedAfternoonStarttime,
        ExpectedEveningStarttime,
        EventTimeStamp,
        LastUpdatedTimeStamp
    FROM @factshootstate;
END;

