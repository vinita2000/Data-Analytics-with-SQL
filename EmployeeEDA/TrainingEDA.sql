-- Dataset url - https://www.kaggle.com/datasets/ravindrasinghrana/employeedataset

select * from training_data

-- categories on Training type
select Training_Type, count(*) as total
from training_data
group by Training_Type

-- categories on training outcome
select Training_Outcome, count(*) as total
from training_data
group by Training_Outcome

-- how many current employees Passed vs Failed their training
select Training_Outcome, count(*) as total
from training_data a
inner join employee_data b
on a.Employee_ID = b.EmpID
where b.EmployeeStatus = 'Active'
group by Training_Outcome
having Training_Outcome in ('Passed', 'Failed')

-- how many current employee attended the training in the most recent year
select year(Training_Date) as RecentYear, count(*) as noofEmployees
from training_data a 
inner join employee_data b
on a.Employee_ID = b.EmpID
where b.EmployeeStatus = 'Active'
group by year(Training_Date)
having year(Training_Date) = (select max(year(Training_Date)) from training_data)

-- which year was the first training organized, who was the trainer, location and the outcome
select Training_Date, Trainer, Location, Training_Outcome
from training_data
where year(Training_Date) = (select min(year(Training_Date)) from training_data)

-- find out all the locations where trainings were held
select distinct Location
from training_data

-- find out the number of training in each location and which location has had the most trainings
select Location, count(*) as total_trainings
from training_data
group by Location
order by count(*) desc

-- how many distinct trainers have trainerd the employees
select distinct Trainer
from training_data
-- Its almost like there has been a new trainer for every training

-- find trainers who trained the employees more than once
select Trainer, count(*) as no_of_trainings
from training_data
group by Trainer
having count(*) > 1

-- which trainer took the most number of trainings and how many
select TOP 1 Trainer, count(*) as no_of_trainings
from training_data
group by Trainer
having count(*) > 1
order by count(*) desc
-- the Max trainings were taken by Michael Smith a total of 4

-- what is the average training duration 
select avg(Training_Duration_Days) as average_Training_duration
from training_data

-- what is the average training duration for each year
select year(Training_Date) as TrainingYear, avg(Training_Duration_Days) as average_Training_duration
from training_data
group by year(Training_Date)

-- find the total days of training conducted by the firm
select sum(Training_Duration_Days) as total_training_days
from training_data

-- find the total training cost incurred to the firm
select round(sum(Training_Cost), 0) as total_training_cost
from training_data

-- find total earnings for each trainer
select Trainer, round(sum(Training_Cost), 0) as Total_earnings
from training_data
group by Trainer
order by round(sum(Training_Cost), 0) desc


select * from training_data
