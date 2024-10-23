select * from FIFA22_Matches

-- find the number of distinct teams playing in FIFA 22
SELECT COUNT(*) AS Total_Teams
from (
select distinct team1 from FIFA22_Matches
union
select distinct team2 from FIFA22_Matches
)a

-- find total matches
select count(*) AS Total_Matches from FIFA22_Matches

-- find total number of goals
select SUM(number_of_goals_team1) + sum(number_of_goals_team2) as Total_tournament_goals
from FIFA22_Matches

-- find total number of red cards in the fifa 22
select SUM(red_cards_team1) + sum(red_cards_team2) as Total_Red_cards
from FIFA22_Matches

-- find total yellow cards in fifa 22
select SUM(yellow_cards_team1) + sum(yellow_cards_team2) as Total_Yellow_cards
from FIFA22_Matches

-- fouls committed by top 10 teams
select top 10 team, sum(fouls) as total_fouls
from(
	select team1 as team, fouls_against_team1 as fouls from FIFA22_Matches
	union all
	select team2 as team , fouls_against_team2 as fouls from FIFA22_Matches
)a
group by team
order by total_fouls desc

-- possession values have '%' towards the end we need to trim the special character
update FIFA22_Matches
set possession_team1 = trim('%' from possession_team1)

update FIFA22_Matches
set possession_team2 = trim('%' from possession_team2)

update FIFA22_Matches
set possession_in_contest = trim('%' from possession_in_contest)

-- Identify the Team with the Highest Average Possession
select team, avg(cast(possesion as int)) as avg_possesion
from(
select team1 as team, possession_team1 as possesion from FIFA22_Matches
union all
select team2 as team, possession_team2 as possesion from FIFA22_Matches
) a
group by team
order by avg_possesion desc
-- spain has the highest average possession of any team

select * from FIFA22_Matches

-- Order teams by possession in contest
select team, avg(cast(possesion as int)) as avg_possesion_in_contest
from(
select team1 as team, possession_in_contest as possesion from FIFA22_Matches
union all
select team2 as team, possession_in_contest as possesion from FIFA22_Matches
) a
group by team
order by avg_possesion_in_contest desc

-- Team with best goal conversion rate
select team, goals, attempts, cast((100*goals)/attempts as varchar) + '%' as conversion_rate
from (
select team, sum(goals) as goals, sum(attempts) as attempts
from(
select team1 as team, number_of_goals_team1 as goals, on_target_attempts_team1 as attempts from FIFA22_Matches
union all
select team2 as team, number_of_goals_team2 as goals,  on_target_attempts_team2 as attempts from FIFA22_Matches
) a
group by team
) b
order by (100*goals)/attempts desc

select * from FIFA22_Matches

-- goal distribution inside and outside the box
select team, sum(inside_goals) as total_inside_goals, sum(outside_goals) as total_outside_goals
from(
select team1 as team, goal_inside_the_penalty_area_team1 as inside_goals, 
goal_outside_the_penalty_area_team1 as outside_goals 
from FIFA22_Matches
union all
select team2 as team, goal_inside_the_penalty_area_team2 as inside_goals, 
goal_outside_the_penalty_area_team2 as outside_goals 
from FIFA22_Matches
) a
group by team
order by sum(inside_goals) + sum(outside_goals) desc