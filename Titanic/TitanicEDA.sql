-- Data analysis/EDA on Kaggle Titanic dataset - https://www.kaggle.com/datasets/yasserh/titanic-dataset/data

select * from Titanic

-- show count of survived/non-survived
select 
case when Survived=0 then 'No' else 'Yes' end as Survived
, count(*) as 'count'
from Titanic
group by Survived

-- show survival rate 
with survivalCnt as(
select
case when Survived=0 then 'No' else 'Yes' end as Survived,
sum(count(*)) over(partition by Survived ) as cnt
from Titanic
group by Survived
)
SELECT Survived, cnt,
    ROUND(cnt * 100 / (SELECT SUM(cnt) FROM survivalCnt), 2) AS "%"
FROM survivalCnt;

-- show male vs female count in the ship
select Sex, count(*) as 'count'
from Titanic
group by Sex

-- show sex wise survival count 
select Sex,
case when Survived=0 then 'No' else 'Yes' end as Survived,
count(*) as 'count'
from Titanic
group by Survived, Sex
order by Sex, Survived

select * from Titanic
-- divide people in age group
-- 0-18, 19-30, 31-50, 51-80, 80+
alter table Titanic add  ageGrp varchar(10)

update Titanic 
set ageGrp = (
	case
	when age<=18 then '0-18'
	when age>18 and age<=30 then '19-30'
	when age>30 and age<=50 then '31-50'
	when age>50 and age<=80 then '51-80'
	when age>80 then '80+'
	end 
)
-- now we can group by ageGrp and check survival counts
select Survived, ageGrp, count(*) as 'total'
from Titanic
group by ageGrp, Survived
order by ageGrp, Survived

-- find how many passenger are on board without a ticket
select count(*)
from Titanic
where Ticket is null
-- no passenger is travelling without a ticket

-- finding, max, min, average Fare
select round(max(Fare), 2) as max_Fare, 
round(min(Fare), 2) as min_Fare, 
round(Avg(Fare), 2) as avg_Fare
from Titanic

--seems like some passengers paid no money for their ticket, find the count with 0 fare
select count(*)
from Titanic where Fare=0

select *
from Titanic
where Fare = 0 and cabin is not null
-- out of 15 passengers who paid nothing for the ticket, 3 even have their own cabin - strange

-- count of passenger with cabin
select count(*)
from Titanic
where Cabin is not null

-- create a new column with family size of each passenger
alter table Titanic add familySize int

update Titanic 
set familySize = SibSp+Parch+1

-- grouping on family size
select familySize, count(*) as total
from Titanic
group by familySize
order by familySize asc
-- most passengers were crusing alone

-- calculate percentage by familySize 
with familySizeGrp as(
select familySize, count(*) as total
from Titanic
group by familySize
)
select familySize, total, 
round(total*100/(select sum(total) from familySizeGrp), 2) as 'percentage'
from familySizeGrp
order by familySize asc

-- grouping passengers on class
select Pclass, count(*)
from Titanic 
group by Pclass
-- adding  gender to the above grouping
select Pclass, Sex, count(*) as 'count'
from Titanic
group by Pclass, Sex
order by Pclass, Sex

-- finding rolling fare price
select round(Fare, 2) as rounded_Fare ,
round(sum(Fare) over(order by PassengerId), 2) as rolling_sum
from Titanic

-- partition fare on age group and find top prices from each group
with ageFareRank as (
	select ageGrp, round(fare, 0) as fare_int,
	dense_rank() over(partition by ageGrp order by round(fare, 0)) as rk
	from Titanic
	--where ageGrp is not null
)
select distinct ageGrp,
min(fare_int) over(partition by ageGrp) as min_fare,
max(fare_int) over(partition by ageGrp) as max_Fare
--first_value(fare_int) over(order by ageGrp, fare_int, rk) as first_value
--LAST_VALUE(fare_int) over(partition by ageGrp order by rk) as last_Value
from ageFareRank
order by ageGrp asc

/*
	Port of Embarkation:C = Cherbourg, Q = Queenstown, S = Southampton
*/
-- group on port of embarkation and find respective counts
select 
(case
	when Embarked='C' then 'Cherbourg'
	when Embarked='Q' then 'Queenstown'
	when Embarked='S' then 'Southampton'
	else 'Unknown'
	end
) as 'Port of Embarkment', 
count(*) as 'No of passengers Embarked'
from Titanic
group by Embarked
order by 'Port of Embarkment' asc

-- count gender wise with port of embarkement
select 
(case
	when Embarked='C' then 'Cherbourg'
	when Embarked='Q' then 'Queenstown'
	when Embarked='S' then 'Southampton'
	else 'Unknown'
	end
) as 'Port of Embarkment',  Sex,
count(*) as 'No of passengers Embarked'
from Titanic
group by Embarked, Sex
order by 'Port of Embarkment' asc, Sex

select * from Titanic
-- lets find if we have any passenger called 'Rose' or 'Jack'
select Name, Sex, Age
from Titanic
where name like '%[Rr]ose%' or name like '%[Jj]ack%'
-- I don't think we have who we were looking for

-- that is the end of data analysis/EDA on Titanic dataset with SQL ---




