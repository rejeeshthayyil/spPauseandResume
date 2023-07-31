Create proc ETL.[SpFactShootStateUpsert]@ShootStateEventFeed [ETL].[UDFFactShootState] READONLY
AS 
BEGIN
		SET NOCOUNt, XACT_ABORT ON;

	--delare the variables
DECLARE @LastUpdatedTimeStamp date =GETDATE();

--source table variables

DECLARE @SourcecorrelationId	int
DECLARE @SourceShootStateId	int
DECLARE @SourceEventTypeId	int
DECLARE @SourceShootTimeId	int
DECLARE @SourceShootDateId	int
DECLARE @SourceStudioId	int
DECLARE @SourceShootTypeId	int
DECLARE @SourceIsshootstarted	int
DECLARE @SourceShootStartedDateTime	datetime
DECLARE @SourceIssuedId	int
DECLARE @SourceReason	varchar
DECLARE @SourceComments	varchar
DECLARE @SourceUserId	int
DECLARE @SourceIsissueResolved	int
DECLARE @SourceShootPausedDatetime	datetime
DECLARE @SourceExpectedMorningstartTime	varchar
DECLARE @SourceExpectedAfternoonStarttime	varchar
DECLARE @SourceExpectedEveningStarttime	varchar
DECLARE @SourceEventTimeStamp	int

SELECT DISTINCT @SourceCorrelationId=CorrelationId,
@sourceEventTypeId=EventTypeId,
@sourceEventTimeStamp=EventTimeStamp
from @ShootStateEventFeed

--declare target variable

DECLARE @TargetcorrelationId	int
DECLARE @TargetShootStateId	int
DECLARE @TargetEventTypeId	int
DECLARE @TargetShootTimeId	int
DECLARE @TargetShootDateId	int
DECLARE @TargetStudioId	int
DECLARE @TargetShootTypeId	int
DECLARE @TargetIsshootstarted	int
DECLARE @TargetShootStartedDateTime	datetime
DECLARE @TargetIssuedId	int
DECLARE @TargetReason	varchar
DECLARE @TargetComments	varchar
DECLARE @TargetUserId	int
DECLARE @TargetIsissueResolved	int
DECLARE @TargetShootPausedDatetime	datetime
DECLARE @TargetExpectedMorningstartTime	varchar
DECLARE @TargetExpectedAfternoonStarttime	varchar
DECLARE @TargetExpectedEveningStarttime	varchar
DECLARE @TargetEventTimeStamp	int

SELECT DISTINCT 
@TargetcorrelationId=ISNULL(CorrelationId,0),
@TargetEventTypeId=ISNULL(EventTypeId,0),
@TargetEventTimeStamp=ISNULL(EventTimeStamp,'1900-01-01 00:00:00:00')
from Report.factshootstateSnapShot
WHERE CorrelationId=@SourcecorrelationId

--Get the existing state of the option in temp table

SELECT * into #TempFactShootStateSnapShot
FROM Report.factShootStateSnapShot
WHERE CorrelationId=@SourcecorrelationId

BEGIN TRY

	BEGIN TRANSACTION T1;
	--Condition to check
  --1 if the correlationid is already exist,
  --2 if the incoming source event timeStamp > Target event TimeStamp,
  --3 if the incomeing event is part of the listed Event Types,

  if @SourcecorrelationId=ISNULL(@TargetCorrelationid,0)
  AND @SourceEventTimeStamp>=ISNULL(@TargetEventTimeStamp,'1900-01-01 00:00:00:00')
  AND @SourceEventTypeId in(55--ShootPaused
							,56 --ShootResume
							,57 --ShootStarted
							,58 --ShootTimingSet
							,59 --ShootInitialized
							)
	BEGIN
		

	
