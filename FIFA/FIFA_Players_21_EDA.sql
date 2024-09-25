-- starting EDA on Players 21 data from FIFA dataset Kaggle
-- https://www.kaggle.com/datasets/stefanoleone992/fifa-21-complete-player-dataset/data

select * from players21
--drop table players21bio

-- create a subset table of players21 called players21bio
SELECT sofifa_id, short_name, long_name, age, dob, height_cm, weight_kg, 
nationality, club_name,league_name, league_rank, overall, value_eur, wage_eur, preferred_foot,
international_reputation, work_rate, release_clause_eur, player_tags, joined, contract_valid_until
into players21bio
from players21

-- fetch data from players21bio
select * from players21bio
 
-- find total players in the fifa 21
select count(distinct sofifa_id) as total_players
from players21bio

-- find players with same short and long names
select *
from players21bio
where short_name = long_name

-- find the player/s with longest short name
select short_name
from players21bio
where len(short_name) = (select max(len(short_name)) from players21bio)

-- find the player/s with shortest short name
select short_name
from players21bio
where len(short_name) = (select min(len(short_name)) from players21bio)

-- find the player/s with longest long name
select long_name
from players21bio
where len(long_name) = (select max(len(long_name)) from players21bio)

-- find the player/s with shortest long name
select long_name
from players21bio
where len(long_name) = (select min(len(long_name)) from players21bio)

-- find the age distribution under 18, under 30 and above 30
select ageGrp, count(*) as Total_Players
from(
	select
	case when age < 18 then 'under 18'
	when age>=18 and age<=30 then '18-30'
	else '30+' end as ageGrp
	from players21bio	
)a
group by ageGrp

-- find the oldest and youngest player in the league
select sofifa_id, short_name, age, dob
from players21bio
where age = (select min(age) from players21bio)
and dob = (select max(dob) from players21bio)
-- although there are multiple players who are 16 years but R Richards is youngest

select sofifa_id, short_name, age, dob
from players21bio
where age = (select max(age) from players21bio)
and dob = (select min(dob) from players21bio)

-- find height distribution under 150 cm, 151-170 cm, 171-190cm and over 190 cm
select heightGrp, count(*) as 'Total Players'
from(
	select
	case when height_cm <= 150 then '150 & under'
	when height_cm > 150 and height_cm <=170 then '151-170 cm'
	when height_cm > 170 and height_cm <=190 then '171-190 cm'
	else '190 cm+' end as heightGrp
	from players21bio
)a
group by heightGrp

-- replace nulls in league_name 
update players21bio
set league_name = 'Unknown'
where league_name is null

-- find the tallest and shortest player in the league
with cte as(
	select distinct league_name,min(height_cm) as shortest_player,max(height_cm) as tallest_player
	from players21bio
	group by league_name
)
select league_name, short_name, long_name, height_cm
from players21bio a
where a.height_cm =  (
	select shortest_player from cte b where a.league_name = b.league_name 
)
or a.height_cm = (
	select tallest_player from cte b where a.league_name = b.league_name 
)
order by league_name, height_cm asc

-- find the difference in the wage_eur of a player with its preceding players in terms of overall rank, wage_eur and value_eur
select short_name, overall, league_name, league_rank, wage_eur, value_eur,
wage_eur - wageLag as wageDiff, value_eur - valueLag as valueDiff
from(
select short_name, overall, league_name, league_rank, wage_eur, value_eur,
coalesce(lag(wage_eur)over(partition by league_name order by overall, league_rank desc, wage_eur, value_eur), 0) wageLag,
coalesce(lag(value_eur)over(partition by league_name order by overall, league_rank desc, value_eur, wage_eur), 0) valueLag
from players21bio
)a
order by league_name, overall, league_rank desc, wage_eur, value_eur

-- find weight distribution of players, calculate bmi
-- calculating height in meters since the height_cm is tinyint and height_cm**2 was throwing overflow error
alter table players21bio
add bmi as(
	 round(cast(weight_kg/((1.0*height_cm/100)*(1.0*height_cm/100))as float(2)),2)
)
select * from players21bio

-- group players on bmi
select bmiCat, count(*) as 'Total Players'
from (
	-- categorising bmi
	select case when bmi < 18.5 then 'Underweight'
	when bmi>=18.5 and bmi<25 then 'Normal weight'
	when bmi>=25 and bmi<30 then 'Overweight'
	else 'obesity' end as bmiCat
	from players21bio
)a
group by bmiCat

-- find out the obese player
select *
from (
	select *, case when bmi < 18.5 then 'Underweight'
	when bmi>=18.5 and bmi<25 then 'Normal weight'
	when bmi>=25 and bmi<30 then 'Overweight'
	else 'obesity' end as bmiCat
	from players21bio
) a
where bmiCat = 'Obesity'

-- find the heaviest and lightest players
select * 
from players21bio
where weight_kg in (select min(weight_kg) from players21bio)
or weight_kg in(select max(weight_kg) from players21bio)
order by weight_kg

-- calculate weight mean, median and mode
-- mean
select avg(weight_kg) as mean_weight
from players21bio

-- declaring a total count variable to avoid using the count query repitively
declare @PlayerCnt as integer = (select count(*) from players21bio)
print @PlayerCnt
-- median
select distinct case 
when @PlayerCnt%2!=0 then (
	select weight_kg
	from(
		select weight_kg, row_number() over(order by weight_kg) as rn
		from players21bio
	)b
	where rn = @PlayerCnt/2
) 
else (
	select avg(weight_kg) 
	from(
		select weight_kg, row_number() over(order by weight_kg) as rn
		from players21bio
	)c
	where rn = @PlayerCnt/2 and rn = (@PlayerCnt/2)+1
)
end 
from(
	select weight_kg, row_number() over(order by weight_kg) as rn
	from players21bio
)a


-- mode
select weight_kg as mode_weight
from (
	select weight_kg, count(*) as total
	from players21bio
	group by weight_kg
)a
where total = (select max(total)
	from (
		select weight_kg, count(*) as total
		from players21bio
		group by weight_kg
	)b
)

-- calculate height mean, median and mode

-- select nth heaviest and nth lightest players
-- nth heaviest
DECLARE @N AS INTEGER = 10;
with cte as(
	select weight_kg 
	from(
		select weight_kg, row_number() over(order by weight_kg desc) as rn
		from (select distinct weight_kg from players21bio)a
	)b where rn = @N
)
select short_name, weight_kg
from players21bio where weight_kg = (select * from cte)

-- nth lighest
DECLARE @N2 AS INTEGER = 1;
with cte as(
	select weight_kg 
	from(
		select weight_kg, row_number() over(order by weight_kg asc) as rn
		from (select distinct weight_kg from players21bio)a
	)b where rn = @N2
)
select short_name, weight_kg
from players21bio where weight_kg = (select * from cte)

select * from players21bio

-- wage and value columns are int and won't be able to hold the sum values
alter table players21bio 
alter column wage_eur bigint;

alter table players21bio 
alter column value_eur bigint;

-- group on nationality and use agg functions
select nationality, count(*) as 'Total Players', min(overall) as minOverallScore
,max(overall) as maxOverallScore, min(international_reputation) as highestInternRepo
,max(international_reputation) as lowestInternRepo, round(avg(wage_eur),2) as averageWage
,round(avg(value_eur),2) as averageValue
from players21bio 
group by nationality
order by nationality 

-- how overall rank and wage are related
select overall, avg(wage_eur) as averageWage
from players21bio
group by overall
order by 2 desc
-- there is disparity in wage players with 89 overall score have greater wage than those with 92

-- find the count distinct countries, leagues, and clubs 
select count(distinct nationality) as 'Total Countries'
,count(distinct league_name) as 'Total leagues', count(distinct club_name) as 'Total Clubs'
from players21bio

-- top ranked(overall) player from each country
select short_name, age, nationality, overallScore
from (
	select short_name, age, overall, nationality,
	max(overall) over(partition by nationality) as overallScore
	from players21bio
)a where overall = overallScore
union all
-- last ranked(overall) player from each country
select short_name, age, nationality, overallScore 
from(
	select short_name, age, overall, nationality,
	min(overall) over(partition by nationality) as overallScore
	from players21bio
) a where overallScore = overall
order by nationality, overallScore

-- most valued and least valued player from each country
select short_name, age, overall, nationality,
case when value_eur = maxValue then maxValue
else minValue end as 'Highest/Least Value'
from (
	select distinct short_name, age, overall, nationality, value_eur,
	max(value_eur) over(partition by nationality) as maxValue, 
	min(value_eur) over(partition by nationality)  as minValue 
	from players21bio 
)a where value_eur = maxValue or value_eur = minValue
order by nationality desc, value_eur asc

select * from players21bio
-- group by preferred_foot
select preferred_foot, count(*) as 'Total Players', 
max(value_eur) as maxVal, min(value_eur) as minVal
from players21bio
group by preferred_foot

-- how preferred foot correlates to overall
select preferred_foot, min(overall), max(overall)
from players21bio
group by preferred_foot

-- group by work_rate
select work_rate, count(*) as 'Total Players'
from players21bio
group by work_rate
order by 2 desc

-- find the max and min release_clause
select min(release_clause_eur) as min_release_cause, max(release_clause_eur) as max_release_clause
from players21bio

-- find the players without any release clause
select sofifa_id, wage_eur, release_clause_eur
from players21bio
where release_clause_eur is null
-- 995 players without a release_clause

-- for the players without release clause amount fill the amount as 
-- if sofifa_id is even, then wage_eur*200, if sofifa_id is odd then wage_eur wage_eur*300,
-- if sofifa_id is a multiple of 10 then wage_eur*(first digit of wage_eur)*100
-- eg sofifa_id = 10, wage_eur = 7000, then release_clause = 7000 * 7* 100 

-- first write a select before directly updating
select sofifa_id, wage_eur, release_clause_eur,
case	
	when sofifa_id%10 = 0 then 500*wage_eur
	when sofifa_id%2 = 0 then 200*wage_eur
	when sofifa_id%2 != 0 then 300*wage_eur
	end as new_release_clause
from players21bio
where release_clause_eur is null

update players21bio
set release_clause_eur = (
	case 
	when sofifa_id%10 = 0 then 500*wage_eur
	when sofifa_id%2 = 0 then 200*wage_eur
	when sofifa_id%2 != 0 then 300*wage_eur
	end
)
where release_clause_eur is null

-- find the average, median release_clause

-- group the players based on joining year
select year(joined) as 'Year', count(*) as 'Total Players'
from players21bio
group by year(joined)
order by count(*)

-- figure out why some players have no joining date
select *
from players21bio 
where joined is null

-- find the player who has the earliest and latest joined date
select *
from players21bio
where joined = (select min(joined) from players21bio )

select *
from players21bio
where joined = (select max(joined) from players21bio )

-- check if we have data for India
select *
from players21bio where nationality = 'India'
-- data for Indian players is mostly incomplete

-- find the player/s who has/have the earliest and latest joined date for each country
select short_name, a.nationality, joined
from players21bio a
inner join
(select distinct nationality,
	min(joined) over(partition by nationality) as earliest,
	max(joined) over(partition by nationality) as latest
	from players21bio 
) b
on a.nationality = b.nationality
and (a.joined = b.earliest or a.joined = b.latest)
order by nationality, joined, short_name


-- the players need to travel from their respective countries to FIFA location by air
-- calculate the total weight of players from each country, 2 air hostess - 150kg average and 2 pilots - 170kg
-- calculate the min weight capacity flight required for each country
select * from players21bio

-- how many players contracts have expired as of 2024
select contract_valid_until, count(*) as 'Total Players with Expired contract'
from players21bio
where contract_valid_until < year(CURRENT_TIMESTAMP)
group by contract_valid_until

-- expired contracts nationality wise
select nationality, count(*) as 'Total Players with Expired contract'
from players21bio
where contract_valid_until < year(CURRENT_TIMESTAMP)
group by nationality
order by 2 desc

-- find the percentage of players with expired contracts nationality wise
select a.nationality, (100*(TEP)/Total) as 'Expired Contracts Percentage'
from (select nationality, count(*) as Total from players21bio group by nationality) a
left join
(select nationality, count(*) as 'TEP' from players21bio
	where contract_valid_until < year(CURRENT_TIMESTAMP) group by nationality
) b
on a.nationality = b.nationality
order by 2 asc

select * from players21bio
-- find length of contract of each player, contract_valid_until - joined(year)
select short_name, age, nationality, 
contract_valid_until - year(joined) as 'contract length(yrs)'
from players21bio

-- find the player with the longest/shortest contract
select min(contract_length) as shortest_contract, max(contract_length) as longest_contract
from (
	select short_name, age, nationality, 
	contract_valid_until - year(joined) as contract_length
	from players21bio
)a

-- find the player with the longest/shortest contract for each country
select short_name, age, nationality, joined, contract_valid_until, contract_valid_until-year(joined) as length
from(
	select short_name, age, a.nationality, joined, contract_valid_until, shortest_contract, longest_contract
	from players21bio a
	left join
	(select distinct nationality, 
	min(contract_valid_until-year(joined)) over(partition by nationality) as shortest_contract,
	max(contract_valid_until-year(joined)) over(partition by nationality) as longest_contract
	from players21bio) b
	on a.nationality = b.nationality
)c
where contract_valid_until-year(joined) = shortest_contract 
or contract_valid_until-year(joined) = longest_contract
order by nationality desc, contract_valid_until-year(joined)

-- find the player with the longest/shortest contract for each league
select short_name, age, league_name, joined, contract_valid_until, contract_valid_until-year(joined) as length
from(
	select short_name, age, a.league_name, joined, contract_valid_until, shortest_contract, longest_contract
	from players21bio a
	left join
	(select distinct league_name, 
	min(contract_valid_until-year(joined)) over(partition by league_name) as shortest_contract,
	max(contract_valid_until-year(joined)) over(partition by league_name) as longest_contract
	from players21bio) b
	on a.league_name = b.league_name
)c
where contract_valid_until-year(joined) = shortest_contract 
or contract_valid_until-year(joined) = longest_contract
order by league_name desc, contract_valid_until-year(joined)