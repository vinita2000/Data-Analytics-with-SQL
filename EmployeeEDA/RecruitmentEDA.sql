-- Dataset url - https://www.kaggle.com/datasets/ravindrasinghrana/employeedataset

select * from recruitment_data
select * from employee_data

-- let see if we have anything common with Employee_data table
select *
from recruitment_data a
inner join employee_data b
on a.First_Name = b.FirstName
and a.Last_Name =  b.LastName
and a.Gender = b.GenderCode
-- only 3 applicants are common

-- count applicants on application date and month
select a.ApplYear, a.ApplMonth, count(*) as total
from (
	select *, year(Application_Date) as ApplYear, month(Application_Date) as ApplMonth
	from recruitment_data 
)a
group by a.ApplYear, a.ApplMonth
-- the recruitment data is all for 2023 starting may and ending in august

-- find applicant distribution by country, education level
select Country, Education_Level, count(*) as total
from recruitment_data
group by Country, Education_Level
order by total desc

-- find applicant salary distribution on years of experience and  education level
select Years_of_Experience, Education_Level, round(avg(Desired_Salary), 2) as avgDesiredSalary
from recruitment_data
group by Years_of_Experience, Education_Level
order by avgDesiredSalary desc

select * from recruitment_data
-- find the applicants who were hired and running total of their salaries based on name
select a.Applicant_ID, a.First_Name, a.Last_Name,a.Education_Level, a.Years_of_Experience, 
round(a.Desired_Salary, 2) as roundedDesiredSal,
round(sum(Desired_Salary) over(order by a.Applicant_ID), 2) as runningTotal
from recruitment_data a
inner join employee_data b
on a.First_Name = b.FirstName
and a.Last_Name =  b.LastName