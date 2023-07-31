-- Inserting dummy data into the FactShootState table
INSERT INTO Report.FactShootStatetbd (
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
    shootResumeDateTime,
    ExpectedMorningstartTime,
    ExpectedAfternoonStarttime,
    ExpectedEveningStarttime,
    EventTimeStamp,
    LastUpdatedTimeStamp
)
VALUES
---- First row (EventTypeId: 55, Shoot Timing Set)
--(1, 1, 55, 1, 1, 1, 1, 1, '2023-07-31 10:00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2023-07-31 10:05:00'),

---- Second row (EventTypeId: 56, Shoot Started)
--(2, 2, 56, 2, 2, 2, 2, 0, '2023-07-31 11:00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, '2023-07-31 11:10:00'),

---- Third row (EventTypeId: 57, Shoot Paused)
--(3, 3, 57, 3, 3, 3, 3, 1, '2023-07-31 14:00:00', 3, 'Issue 1', 'Comment 1', 1, 0, '2023-07-31 15:00:00', NULL, NULL, NULL, NULL, 3, '2023-07-31 15:05:00'),

---- Fourth row (EventTypeId: 58, Shoot Resumed)



(4, 4, 58, 3, 3, 3, 3, 1, '2023-07-31 14:00:00', NULL, NULL, NULL, NULL, NULL, '2023-07-31 15:00:00', '2023-07-31 15:45:00', '2023-07-31 09:00:00', '2023-07-31 14:00:00',NULL, 4, '2023-07-31 15:45:00')  ,

-- Fifth row (EventTypeId: 59, Shoot Initialized)
(5, 5, 59, 5, 5, 5, 5, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, '2023-07-31 16:00:00'),

-- Sixth row (EventTypeId: 57, Shoot Paused with null values in additional columns)
(6, 6, 57, 6, 6, 6, 6, 1, '2023-07-31 17:00:00', 6, NULL, NULL, NULL, NULL, '2023-07-31 17:10:00', NULL, NULL, NULL, NULL, 6, '2023-07-31 17:15:00'),

-- Seventh row (EventTypeId: 57, Shoot Paused with non-null values in additional columns)
(7, 7, 57, 7, 7, 7, 7, 1, '2023-07-31 18:00:00', 7, 'Issue 2', 'Comment 2', 2, 0, '2023-07-31 18:10:00', NULL, NULL, NULL, NULL, 7, '2023-07-31 18:15:00');


select * from Report.FactShootStatetbd



delete report.factShootstatetbd
where factshootstateid=7 

55 shoottimingset
56 shootstarted
57 shootpaused
58 shootresume
59 shootinitialized

update Report.FactShootStatetbd
set ExpectedMorningStartTime= '2023-07-31 09:30:00'
where factshootstateid =3

update Report.FactShootStatetbd
set ExpectedAfternoonStartTime= '2023-07-31 13:30:00'
where factshootstateid=8

update Report.FactShootStatetbd
set ExpectedEveningstarttime= '2023-07-31 17:30:00'
where EventTypeId= 56