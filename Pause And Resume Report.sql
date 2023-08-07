select * from Report.vmdailyshootTrack
select * from Report.getvmshoottimelost

select st.[Studio Name],st.[DAY],st.[First Shot AM],st.[Last Shot AM],TL.[TotalTimeLostAM],TL.[TotalTimeLostPm]
from Report.vmdailyshootTrack ST
left join Report.getvmshoottimelost TL
on ST.[studio Name]=TL.[studio Name]