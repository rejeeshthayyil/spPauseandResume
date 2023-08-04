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



--(4, 4, 58, 3, 3, 3, 3, 1, '2023-07-31 14:00:00', NULL, NULL, NULL, NULL, NULL, '2023-07-31 15:00:00', '2023-07-31 15:45:00', '2023-07-31 09:00:00', '2023-07-31 14:00:00',NULL, 4, '2023-07-31 15:45:00')  ,

---- Fifth row (EventTypeId: 59, Shoot Initialized)
--(5, 5, 59, 5, 5, 5, 5, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, '2023-07-31 16:00:00'),

---- Sixth row (EventTypeId: 57, Shoot Paused with null values in additional columns)
--(6, 6, 57, 6, 6, 6, 6, 1, '2023-07-31 17:00:00', 6, NULL, NULL, NULL, NULL, '2023-07-31 17:10:00', NULL, NULL, NULL, NULL, 6, '2023-07-31 17:15:00'),

---- Seventh row (EventTypeId: 57, Shoot Paused with non-null values in additional columns)
--(7, 7, 57, 7, 7, 7, 7, 1, '2023-07-31 18:00:00', 7, 'Issue 2', 'Comment 2', 2, 0, '2023-07-31 18:10:00', NULL, NULL, NULL, NULL, 7, '2023-07-31 18:15:00');


--(1000238, 7, 57, 7, 31072023, 7, 4, 1, '2023-07-31 14:00:00', 1, 'Issue 1', 'Comment 1', 2, 0, '2023-07-31 14:30:00', NULL, '2023-07-31 09:30:00', '2023-07-31 13:30:00', NULL, 7, '2023-07-31 14:30:00');


--(1000239, 7, 58, 7, 31072023, 7, 4, 1, '2023-07-31 14:30:00', null, null, null, 2, 1, null, '2023-07-31 14:30:00.000', '2023-07-31 09:30:00', '2023-07-31 13:30:00', NULL, 7, '2023-07-31 14:30:00')

--- Second row (EventTypeId: 56, Shoot Started)
--(1000241, 2, 57, 2, 31072023, 2, 2, 1, '2023-07-31 09:30:00', 6, 'Fire alarm', 'Fire alar 6', 4, 0, '2023-07-31 10:15:00', NULL, '2023-07-31 09:30:00', '2023-07-31 13:30:00', '2023-07-31 17:30:00', 2, '2023-07-31 10:15:00'),


--(1000242, 2, 57, 2, 31072023, 102, 2, 1, '2023-07-31 09:30:00', 6, 'Fire alarm', 'Fire alar 6', 4, 0, Null, '2023-07-31 10:30:00', '2023-07-31 09:30:00', '2023-07-31 13:30:00', '2023-07-31 17:30:00', 2, '2023-07-31 10:30:00')

--(1000242, 2, 57, 2, 31072023, 102, 2, 1, '2023-07-31 09:30:00', 3, 'Tech Issue', 'Tech Issue 6', 4, 0, Null, '2023-07-31 09:30:00', Null, '2023-07-31 09:30:00', '2023-07-31 13:45:00', 2, '2023-07-31 17:00:00')


--CORRid  SI  ET STIME, SDID    STU,  STY ISSHO,  SHOOTSTARDATE,    ISSUID,   REASON,       COMMENTS,         UID, ISRES,     SHOOPAUsed date,         SHOOTRESUME,		        EXPEMORNSTART,	     EXPECTAFTERST,            EXPECTEDEVEST,     EVENTTIMESTAMP,  LASTUPDATEDTIMESTAMP
--(1000243, 3, 57, 2, 31072023, 4,   2, 0,     '2023-07-31 09:30:00', 3,   'Tech Issue',  'Tech Issue 3',   4,    0,     '2023-07-31 09:30:00',         Null,			    '2023-07-31 09:30:00', '2023-07-31 13:45:00', '2023-07-31 17:00:00',     2,            '2023-07-31 17:00:00')
--(1000244, 3, 57, 2, 31072023, 4,   2, 0,     '2023-07-31 09:30:00', 2,   'Model Issue', 'Model Issue 2',  4,    0,     '2023-07-31 09:45:00',           Null,			    '2023-07-31 09:30:00', '2023-07-31 13:45:00', '2023-07-31 17:00:00',     2,            '2023-07-31 17:00:00')
--(1000245, 3, 57, 2, 31072023, 4,   2, 0,     '2023-07-31 09:30:00', 3,   'Tech Issue',  'Tech Issue 3',   4,    1,     '2023-07-31 09:30:00',    '2023-07-31 10:00:00',   '2023-07-31 09:30:00', '2023-07-31 13:45:00', '2023-07-31 17:00:00',     2,            '2023-07-31 17:00:00')
--(1000246, 3, 57, 2, 31072023, 4,   2, 1,     '2023-07-31 09:30:00', 2,   'Model Issue', 'Model Issue 2',  4,    1,     '2023-07-31 09:45:00',    '2023-07-31 11:00:00',	'2023-07-31 09:30:00', '2023-07-31 13:45:00', '2023-07-31 17:00:00',     2,            '2023-07-31 11:00:00')

 --(1000247, 3, 57, 5, 31072023, 4,   2, 1,     '2023-07-31 09:30:00', 3,   'Tech Issue',  'Tech Issue 3',   4,    0,     '2023-07-31 13:00:00',      NULL,					'2023-07-31 09:30:00', '2023-07-31 13:45:00', '2023-07-31 17:00:00',	 2,			   '2023-07-31 13:00:00'),
 --(1000248, 3, 58, 5, 31072023, 4,   2, 1,     '2023-07-31 09:30:00', 3,   'Tech Issue',  'Tech Issue 3',   4,    1,     '2023-07-31 13:00:00',    '2023-07-31 14:30:00',	'2023-07-31 09:30:00', '2023-07-31 13:45:00', '2023-07-31 17:00:00',     2,            '2023-07-31 14:30:00')

 
 (1000249, 3, 57, 5, 31072023, 10,   2, 1,     '2023-07-31 09:30:00', 3,   'Tech Issue',  'Tech Issue 3',   4,    0,     '2023-07-31 13:30:00',      NULL,					'2023-07-31 09:30:00', '2023-07-31 13:45:00', '2023-07-31 17:00:00',	 2,			   '2023-07-31 13:30:00'),
 (1000250, 3, 58, 5, 31072023, 10,   2, 1,     '2023-07-31 09:30:00', 3,   'Tech Issue',  'Tech Issue 3',   4,    1,     '2023-07-31 13:30:00',    '2023-07-31 14:30:00',	'2023-07-31 09:30:00', '2023-07-31 13:45:00', '2023-07-31 17:00:00',     2,            '2023-07-31 14:30:00')




select * from Report.FactShootStatetbd



 Delete report.factShootstatetbd
where factshootstateid=28

	--EVENTS				ISSUE
55 shoottimingset		1 Model Lateness
56 shootstarted			2 Model Issue
57 shootpaused			3 Tech Issue
58 shootresume			4 H & M Issue
						5 Shoot team lateness
59 shootinitialized		6 Fire alarm
						7 Oher


select * from Report.FactShootStatetbd

update Report.FactShootStatetbd
set ShootTimeId= 7
where factshootstateid =8

delete Report.FactShootStatetbd
where factshootstateid=24

update Report.FactShootStatetbd
set shootResumeDateTime=Null
where FactShootStateId= 19

SELECT fs.StudioId,ds.issueName,st.ShootTimeName,
    fs.ShootPausedDateTime,
    fs.shootresumedatetime,
    DATEDIFF(MINUTE, ShootPausedDateTime, shootresumedatetime) AS [Time Lost]
FROM
    report.FactShootStatetbd fs
	join Report.DimIssues ds
	on fs.IssuedId=ds.issueId
	join Report.DimShootTime st 
	on st.ShootTimeId=fs.shoottimeId


	--if the first puase started at 9:30 second pause started at 9:45 
	--then first puse resumed at 10:00 second pause resumed at 11:00
	--1:30 
	-- Time lost = substract first puase time from 2nd Resume Time
	--in the above case 9:30 - 11:00

(1000243, 3, 57, 2, 31072023, 'GLH4', 2, 0, '2023-07-31 09:30:00', 3, 'Tech Issue', 'Tech Issue 6', 4, 0, Null, '2023-07-31 09:30:00', Null, '2023-07-31 09:30:00', '2023-07-31 13:45:00', 2, '2023-07-31 17:00:00')
