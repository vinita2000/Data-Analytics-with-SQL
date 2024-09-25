select * from players15

-- start with checking if any player/s from FIFA 15 is/are still playing in FIFA 21
select a.short_name from players15 a
inner join 
(select short_name from players21) b
on a.short_name = b.short_name

-- common players in fifa 16 and 15
select a.short_name, a.age, a.dob, a.overall as Fifa15_overall, b.overall as Fifa16_overall
from players15 a
inner join players16 b
on a.short_name = b.short_name

-- need to change the data type for overall from tinyint to int
-- since tiny int range is 0-256, it does not allow negative numbers
alter table players15
alter column overall int

alter table players16
alter column overall int

-- list of players whose overall rating decreased in fifa 16
with cte as(
	select *,  Fifa16_overall - Fifa15_overall as diff
	from (
		select a.short_name, a.age, a.dob, a.overall as Fifa15_overall, b.overall as Fifa16_overall
		from players15 a inner join players16 b on a.short_name = b.short_name
	)x
)
select * from cte
where diff > 0

-- list of players whose overall rating increased in fifa 16
with cte as(
	select *,  Fifa16_overall - Fifa15_overall as diff
	from (
		select a.short_name, a.age, a.dob, a.overall as Fifa15_overall, b.overall as Fifa16_overall
		from players15 a inner join players16 b on a.short_name = b.short_name
	)x
)
select * from cte
where diff < 0

-- which player/s had the max raise in rating
with cte as(
	select *,  Fifa16_overall - Fifa15_overall as diff
	from (
		select a.short_name, a.age, a.dob, a.nationality, a.overall as Fifa15_overall, b.overall as Fifa16_overall
		from players15 a inner join players16 b on a.short_name = b.short_name
	)x
)
select short_name, age, dob, nationality, Fifa15_overall, Fifa16_overall
from cte 
where diff = (select max(diff) as biggest_jump from cte where diff > 0)
order by short_name

-- what was the difference in the value/wage for the players with highest jump in ratings
with cte as(
	select *,  Fifa16_overall - Fifa15_overall as diff
	from (
		select a.short_name, a.age, a.dob, a.nationality, a.overall as Fifa15_overall, b.overall as Fifa16_overall,
		a.value_eur as Fifa15_value, b.value_eur as Fifa16_value
		from players15 a inner join players16 b on a.short_name = b.short_name
	)x
)
select short_name, age, dob, nationality, Fifa15_overall, Fifa16_overall, Fifa16_value-Fifa15_value as value_jump
from cte 
where diff = (select max(diff) as biggest_jump from cte where diff > 0)
order by short_name
-- hence the players had a huge jump in the value as well
-- One more observation - both the players are very young, and possibly age could be the reason for such a jump


-- which player/s had the max dip in the ratings
with cte as(
	select *,  Fifa16_overall - Fifa15_overall as diff
	from (
		select a.short_name, a.age, a.dob, a.nationality, a.overall as Fifa15_overall, b.overall as Fifa16_overall,
		a.value_eur as Fifa15_value, b.value_eur as Fifa16_value
		from players15 a inner join players16 b on a.short_name = b.short_name
	)x
)
select short_name, age, dob, nationality, Fifa15_overall, Fifa16_overall, Fifa16_value-Fifa15_value as value_dip
from cte 
where diff = (select min(diff) from cte where diff < 0)
order by short_name

-- find the list of players who were part of all 5 leagues
select a.sofifa_id, a.long_name, a.age, a.nationality
from players15 a
inner join players16 b
on a.short_name = b.short_name and a.sofifa_id = b.sofifa_id
inner join players17 c
on a.short_name = c.short_name and a.sofifa_id = c.sofifa_id
inner join players18 d
on a.short_name = d.short_name and a.sofifa_id = d.sofifa_id
inner join players19 e
on a.short_name = e.short_name and a.sofifa_id = e.sofifa_id
inner join players20 f
on a.short_name = f.short_name and a.sofifa_id = f.sofifa_id
inner join players21 g
on a.short_name = g.short_name and a.sofifa_id = g.sofifa_id
-- 3790 players were present in all FIFA games from 2015 to 2021

-- find the longevitiy of players from each country, which country has the most players who played the longest
with cte as (
select a.sofifa_id, a.long_name, a.age, a.nationality
from players15 a
inner join players16 b
on a.short_name = b.short_name and a.sofifa_id = b.sofifa_id
inner join players17 c
on a.short_name = c.short_name and a.sofifa_id = c.sofifa_id
inner join players18 d
on a.short_name = d.short_name and a.sofifa_id = d.sofifa_id
inner join players19 e
on a.short_name = e.short_name and a.sofifa_id = e.sofifa_id
inner join players20 f
on a.short_name = f.short_name and a.sofifa_id = f.sofifa_id
inner join players21 g
on a.short_name = g.short_name and a.sofifa_id = g.sofifa_id
)
select nationality, count(*) Total_Players
from cte group by nationality
order by count(*) desc, nationality asc
-- English players are most likely to have an extensive career

-- find average overall rating of each players from fifa 15 to fifa 21
with cte as (
select sofifa_id, long_name, age, nationality, overall from players15 
union 
select sofifa_id, long_name, age, nationality, overall from players16 
union
select sofifa_id, long_name, age, nationality, overall from players17 
union 
select sofifa_id, long_name, age, nationality, overall from players18 
union 
select sofifa_id, long_name, age, nationality, overall from players19 
union 
select sofifa_id, long_name, age, nationality, overall from players20 
union 
select sofifa_id, long_name, age, nationality, overall from players21 
)
select sofifa_id, long_name, avg(overall) as average_rating
from cte
group by sofifa_id, long_name
order by 3

-- find average rating for countries from FIFA15 - FIFA21
with cte as (
select sofifa_id, long_name, age, nationality, overall from players15 
union 
select sofifa_id, long_name, age, nationality, overall from players16 
union
select sofifa_id, long_name, age, nationality, overall from players17 
union 
select sofifa_id, long_name, age, nationality, overall from players18 
union 
select sofifa_id, long_name, age, nationality, overall from players19 
union 
select sofifa_id, long_name, age, nationality, overall from players20 
union 
select sofifa_id, long_name, age, nationality, overall from players21 
)
select nationality, avg(overall) as average_rating
from cte
group by nationality
order by 2 desc, 1 asc

-- find total wage/earning of each player from fifa15 to fifa21
-- find top 5 highest earners for FIFA 15- FIFA21
with cte as (
select sofifa_id, long_name, age, nationality, wage_eur from players15 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players16 
union
select sofifa_id, long_name, age, nationality, wage_eur from players17 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players18 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players19 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players20 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players21 
)
select top 5 sofifa_id, long_name, avg(wage_eur) as average_wage 
from cte
group by sofifa_id, long_name
order by 3 desc

-- find bottom 5 lowest earners for FIFA 15-FIFA21
with cte as (
select sofifa_id, long_name, age, nationality, wage_eur from players15 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players16 
union
select sofifa_id, long_name, age, nationality, wage_eur from players17 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players18 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players19 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players20 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players21 
)
select top 5 sofifa_id, long_name, avg(wage_eur) as average_wage 
from cte
group by sofifa_id, long_name
order by 3 asc
-- its shocking to see some players did not earn anything

-- find out the players whose average wage was 0 throughout and find count for the nationalities
with cte as (
select sofifa_id, long_name, age, nationality, wage_eur from players15 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players16 
union
select sofifa_id, long_name, age, nationality, wage_eur from players17 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players18 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players19 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players20 
union 
select sofifa_id, long_name, age, nationality, wage_eur from players21 
)
select nationality, count(*) as 'Total Players with no wage'
from(
	select sofifa_id, long_name, nationality, avg(wage_eur) as average_wage 
	from cte
	group by sofifa_id, long_name, nationality
	having avg(wage_eur) = 0
)a
group by nationality
order by 2 asc
-- there are 456 players whose average wage is 0, possibility is that there wage was not captured