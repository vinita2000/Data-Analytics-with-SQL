-- DATASET - https://www.kaggle.com/datasets/ravindrasinghrana/employeedataset/data?select=employee_engagement_survey_data.csv

select * from engagement_survey

-- count employee surveyed by year
select year(Survey_Date) as Year, count(*) as total
from engagement_survey
group by year(Survey_Date)
-- all the surveys are done in 2022 and 2023

-- find the date when first and the last survey was done
select min(Survey_Date) as first_survey_date, max(Survey_Date) as last_survey_date
from engagement_survey

-- find gender wise engagement score of employees
select GenderCode, Engagement_Score, count(*) as total
from engagement_survey a
inner join employee_data b 
on a.Employee_ID = b.EmpID
group by GenderCode, Engagement_Score
order by GenderCode, Engagement_Score

-- group work life balance on division
select Division, Work_Life_Balance_Score, count(*) as total
from engagement_survey a
inner join employee_data b
on a.Employee_ID = b.EmpID
group by Division, Work_Life_Balance_Score
order by Division, Work_Life_Balance_Score
-- work life balance score 5 is the highest

-- find out which department employees have the best work life balance
select top 1 DepartmentType, Work_Life_Balance_Score, count(*) as total
from engagement_survey a
inner join employee_data b
on a.Employee_ID = b.EmpID
where EmployeeStatus = 'Active'
group by DepartmentType, Work_Life_Balance_Score
having Work_Life_Balance_Score = 5
order by count(*) desc
-- Production department has the max number of employees who gave 5 score for the work life balance

select * from engagement_survey

-- grouping on satisfaction score and calculating percentage
select *, 
(cnt*100/(select count(*) from engagement_survey)) as '%'
from (
	select Satisfaction_Score, count(*) as cnt
	from engagement_survey
	group by Satisfaction_Score
)a
order by a.Satisfaction_Score asc
-- satisfaction score is evenly distributed

select distinct Division from employee_data

-- what is the average engagement score in finance and Accounting division
select AVG(Engagement_Score) as AvgEngagementScore
from engagement_survey a
inner join employee_data b
on a.Employee_ID = b.EmpID
where Division = 'Finance & Accounting'

-- which employees have a performance score of fully meets and and engagement score or 4 or higher
select FirstName+' '+LastName as EmployeeName, Performance_Score, Engagement_Score
from engagement_survey a 
inner join employee_data b
on a.Employee_ID = b.EmpID
where Engagement_Score >= 4
and Performance_Score = 'Fully Meets'
order by 1 asc

-- what is the average work life balance score of employees who started in 2023
select avg(work_life_balance_score) as AvgWorkLifeBalanceScore
from engagement_survey a
inner join employee_data b
on a.Employee_ID = b.EmpID
where year(b.StartDate) = '2023'

-- what is the trend of engagement score over time for each business unit
select BusinessUnit, year(Survey_Date) as year, avg(Engagement_Score) as avgEngagementScore
from engagement_survey a
inner join employee_data b
on a.Employee_ID = b.EmpID
group by BusinessUnit, year(Survey_Date)
order by BusinessUnit, year(Survey_Date)

-- what is the average performance score by race and gender
select RaceDesc, GenderCode, 
cast(avg(case when Performance_Score='PIP' then 1
	 when Performance_Score='Needs Improvement' then 2
	 when Performance_Score='Fully Meets' then 3.5
	 when Performance_Score='Exceeds' then 5
end) as decimal(10,2)) as averagePerformance
from engagement_survey a
inner join employee_data b
on a.Employee_ID = b.EmpID
group by GenderCode, RaceDesc
order by GenderCode, RaceDesc

select * from engagement_survey

-- what is the engagement score for employee under each supervisor
select Supervisor, avg(Engagement_Score) as avgEngagementScore
from engagement_survey a
inner join employee_data b
on a.Employee_ID = b.EmpID
group by b.Supervisor

