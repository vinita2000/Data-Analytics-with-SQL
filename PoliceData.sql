--USE PoliceData
-- Goal is to analyse the Police data from Kaggle dataset - https://www.kaggle.com/datasets/melihkanbay/police/data
-- Record Count
select count(*) from PoliceData

-- Datatypes
select COLUMN_NAME, DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'PoliceData'

-- check nulls
select count(*) as total_nulls
from PoliceData 
where search_type is null

-- remove the column that only contains nulls - county_name
Alter table PoliceData
Drop column county_name

-- list the column names
--Method 1
select TOP 0* from PoliceData
--Method 2
select COLUMN_NAME
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'PoliceData'

-- Do women or men speed more often ?
select driver_gender, count(*)
from PoliceData
group by driver_gender
order by count(*) desc

-- clearly men are speeding more often, lets replace the driver_gender blanks with some text 
update PoliceData
set driver_gender = 'Unknow'
where driver_gender is null

--Lets find violations for each gender
select driver_gender, violation_raw, count(*) as total_violations
from PoliceData
group by violation_raw, driver_gender
order by driver_gender, violation_raw

--Does gender affect who gets searched during a stop?
select driver_gender, 
case when search_conducted=0 then 'No' else 'Yes' end as search_conducted, 
count(*) as search_count
from PoliceData
group by driver_gender, search_conducted
order by driver_gender, search_conducted
-- Men are searched relatively more often but then the break rules more often too

--query on types of searches and respective counts
select search_type, count(*) as total
from PoliceData
group by search_type
order by count(*) asc

-- replace search type null to unknown
Update PoliceData
set search_type = 'Unknown'
where search_type is null

--During a search, how often is the driver frisked?
select search_type, count(*) as total
from PoliceData
where search_type like '%[Ff]risk%'
group by search_type
order by count(*) desc

--Which year had the least number of stops?
select year(stop_date) as 'year', count(*) as total_Stops
from PoliceData
group by year(stop_date)
order by count(*) asc

--How does drug activity change by time of day?
select str(Datepart(hour, stop_time))+':00' as 'hour', count(*) as total_Stops
from PoliceData 
group by Datepart(hour, stop_time)
order by Datepart(hour, stop_time)

--Do most stops occur at night?
select str(Datepart(hour, stop_time))+':00' as 'hour', count(*) as total_Stops
from PoliceData 
group by Datepart(hour, stop_time)
order by count(*) desc -- Yes most stops occur at night around 10-11pm

--Find the bad data in the stop_duration column and fix it!
select count(*)
from PoliceData
where stop_duration is null
-- we have 5333 null values in stop_duration column, lets fix it with duration = 0
--lets first check if any other bad data in the column 
select stop_duration, count(*) as cnt
from PoliceData
group by stop_duration
-- 1, 2 data is also not in accordance with the column, lets make those null
update PoliceData
set stop_duration = null
where stop_duration in ('1', '2')
-- now we have 5335 nulls in the data
update policeData
set stop_duration = '0 Min'
where stop_duration is null

--What is the mean stop_duration for each violation_raw? 
--we will need to convert stop_duration strings to numbers
with convertStopDuration as (
	select stop_duration,
	case 
		when stop_duration='0 Min' then 0
		when stop_duration='0-15 Min' then 10
		when stop_duration='16-30 Min' then 25
		when stop_duration='30+ Min' then 45
	end as 'time',
	count(*) as total_stops
	from policeData 
	group by stop_duration
)
--adding a new column called stop_minutes in the table
Alter table policeData add stop_minutes int

update policeData
set stop_minutes = (
	case 
		when stop_duration='0 Min' then 0
		when stop_duration='0-15 Min' then 10
		when stop_duration='16-30 Min' then 25
		when stop_duration='30+ Min' then 45
	end
)

--select * from convertStopDuration
select stop_duration, avg(time*total_Stops) as 'Avg_stop_time'
from convertStopDuration
group by stop_duration


-- mean and count for each violation
select violation_raw, count(*) as 'cnt', avg(stop_minutes) as 'average'
from policeData
group by violation_raw
order by violation_raw

--Compare the age distributions for each violation
select violation_raw, driver_age, count(*) as total_violations
from policeData
group by violation_raw, driver_age
order by count(*) desc
-- since we have drivers of various different ages, the group by result is not very well readable
-- lets group drivers by age groups rather than individual age
-- add a new column for age group
alter table policeData add age_group varchar(20)
update policeData
set age_group = (
	case 
	when driver_age<18 then '18 below'
	when driver_age>=18 and driver_age<25 then '18-25'
	when driver_age>=25 and driver_age<60 then '25-60'
	when driver_age>=60 then '60+'
	when driver_age is null then 'Unkown'
	end 
)

select violation_raw, age_group, count(*) as total_violations
from policeData
group by age_group, violation_raw
order by age_group

select * from policeData
--create current driver age as curr_age from driver_age_raw (and call it curr_age)
alter table policeData add curr_age int
update policeData 
set curr_age = year(GETDATE()) - driver_age_raw

-- get count of =< 15 age and 90 and + age drivers
select driver_age, violation_raw, stop_duration, 
case when search_conducted=0 then 'No' else 'Yes' end as search_conducted, 
stop_outcome
from policeData
where driver_age<=15 or driver_age>=90
order by driver_age 
-- the underage drivers were in most cases arrested
 