-- Dataset url - https://www.kaggle.com/datasets/ravindrasinghrana/employeedataset

select * from employee_data 

-- find average salary for each department/Business unit
select DepartmentType, round(avg(Desired_Salary), 2) as averageSalary
from employee_data a
inner join recruitment_data b
on a.EmpID = b.Applicant_ID
where EmployeeStatus = 'Active'
group by DepartmentType
order by DepartmentType

-- write a query to find the employee with highest performance in each department
-- break tie with ascending order of first name and last name
select * from (
	select EmpID, FirstName +' '+ LastName as FullName,  DepartmentType,
	rank() over(partition by DepartmentType order by Current_Employee_Rating desc, firstName, lastName) as rk
	from employee_data 
)a
where rk = 1

-- what is the highest performance score in each department
select distinct DepartmentType,
max(Current_Employee_Rating) over(partition by DepartmentType) as maxPerformanceRating
from employee_data 

--find the list of employees from IT department with rating above 3
select EmpID, FirstName +' '+ LastName as FullName, Current_Employee_Rating
from employee_data 
where DepartmentType = 'IT/IS'
and Current_Employee_Rating > 3
order by FullName asc

-- rank employees within each department based on salary
select EmpID, FirstName +' '+ LastName as FullName,
DepartmentType, round(Desired_Salary, 2) as Desired_Salary,
DENSE_RANK() over(partition by DepartmentType order by round(Desired_Salary, 2) desc) as salaryRank
from employee_data a
inner join recruitment_data b
on a.EmpID = b.Applicant_ID
where EmployeeStatus = 'Active'

-- find the count of employees who quit their jobs in 2023
select count(*)
from employee_data
where year(ExitDate) = '2023'

-- list supervisors and count of employees working under them
select Supervisor, count(*) as Juniors
from employee_data
group by Supervisor
order by count(*) desc

-- group employees on job types
select EmployeeType, count(*) as total
from employee_data
group by EmployeeType
order by EmployeeType

-- group employees on gender
select GenderCode, count(*) as total
from employee_data
group by GenderCode

-- which division has the highest employees
select Division, count(*) as total
from employee_data
where EmployeeStatus = 'Active' and ExitDate is null
group by Division
order by count(*) desc
-- field operations has the highest number of current active employees - 392

-- group on race for the current employees
select RaceDesc, count(*) as total
from employee_data
where ExitDate is null
group by RaceDesc
-- company seems to have maintained diversity well

-- find tenure of each employee, if exit date is null use current date
select FirstName + ' ' + LastName as Name, StartDate, ExitDate,
datediff(year, StartDate, coalesce( ExitDate,convert(date, getDate()) )) as 'tenure(yrs)'
from employee_data

-- add a tenure column in the employee_date table
alter table employee_data
add tenure int

update employee_data
set tenure = datediff(year, StartDate, coalesce( ExitDate,convert(date, getDate()) ))

select StartDate, ExitDate, tenure 
from employee_data

-- categories employees as senior and junior by join date <=5 junior, >5 seniors
select SeniorityLevel, count(*) as total
from (
	select *,
	case when datediff(year, StartDate, coalesce( ExitDate,convert(date, getDate()) )) <= 5 then 'Junior'
	else 'Senior' end as SeniorityLevel
	from employee_data
)a
where a.ExitDate is null and a.EmployeeStatus = 'Active'
group by a.SeniorityLevel

-- find count for each departments division
select DepartmentType, Division, count(*) as total
from employee_data
group by DepartmentType, Division
order by DepartmentType, Division

-- which department and division has the most engineers
select DepartmentType, Division, count(*) as total
from employee_data
where Division = 'Engineers' and EmployeeStatus = 'Active'
group by DepartmentType, Division
order by count(*) desc
-- production department has the most engineers

select * from employee_data

-- group by performance score, with percentage
with cte as (
	select Performance_Score, count(*) as total
	from employee_data
	where ExitDate is null
	group by Performance_Score
)
select *,
(total*100/(select sum(total) from cte)) as 'percentage'
from cte
-- 86 employees need improvement while 44 are currently under Performance imporovement plan

-- select those under PIP
select *
from employee_data
where Performance_Score = 'PIP'
and ExitDate is null

-- PIVOT TABLES
-- Create a employeestatus and employee classification pivot type output
-- columns employeeclassification type row should be status, along with total for each row and column

with pivotTable as 
(
select EmployeeClassificationType, [Active],[Future Start], [Leave of Absence], 
	[Terminated for Cause], [Voluntarily Terminated],
	([Active]+[Future Start]+[Leave of Absence]+[Terminated for Cause]+[Voluntarily Terminated]) as total
from (
		select EmployeeStatus, EmployeeClassificationType, count(*) as total
		from employee_data
		group by EmployeeStatus, EmployeeClassificationType
	)a
pivot(
	sum(total)
	for employeeStatus in ([Active],[Future Start], [Leave of Absence], [Terminated for Cause], [Voluntarily Terminated] )
	) as pivotTable
)
-- rollup and find the grand total as well as add a row to total 
--select * from pivotTable
-- find grand total
SELECT
coalesce(EmployeeClassificationType,' Grand Total') as EmployeeClassificationType,
SUM(Active) Active,
SUM([Future Start])  FutureStart,
SUM([Leave of Absence])   LeaveOfAbsence,
SUM([Terminated for Cause])  TerminatedForCause,
SUM([Voluntarily Terminated])  VoluntarilyTerminated,
SUM(total) total
FROM 
pivotTable
 group 
    by EmployeeClassificationType with rollup

-- who was the first employee of the company
select EmpID, FirstName, LastName, StartDate
from employee_data
where StartDate = (select min(StartDate) from employee_data)
-- 4 different employees were hired on 2018-08-07 as the first day ever of hiring 

-- last hired employees
select EmpID, FirstName, LastName, StartDate
from employee_data
where StartDate = (select max(StartDate) from employee_data)

-- first employees to quit the company
select EmpID, FirstName, LastName, StartDate, ExitDate
from employee_data
where ExitDate = (select min(ExitDate) from employee_data)
-- Elizabeth left the company in 4 day, don't know if that's even allowed

-- What is the average tenure of employees grouped by perfocmance score
select Performance_Score, avg(tenure) as averageTenure
from employee_data
group by Performance_Score

-- what is the average performance-Current employee rating score by race and gender
select RaceDesc, GenderCode, avg(Current_Employee_Rating) as avgPerformanceScore
from employee_data 
group by RaceDesc, GenderCode

-- which job functions have the highest percentage of employees with a performance score or "Exceeds"
-- Method 1 - using groupby
select JobFunctionDescription, count(*) as 'total',
cast((100*count(*)/(select count(*) from employee_data where Performance_Score='Exceeds')) as varchar) + '%' as 'Percentage'
from employee_data e
where Performance_Score = 'Exceeds'
group by JobFunctionDescription
order by count(*) desc

-- Method 2 - using window function
select distinct JobFunctionDescription,
count(*) over(partition by JobFunctionDescription) as 'total'
from employee_data
where Performance_Score = 'Exceeds'
order by total desc

