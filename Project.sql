Select * from CovidDeaths
order by location,date

Select * from CovidVaccinations
order by location,date

--Altering columns with numeric data from Nvarchar to float

Alter table CovidDeaths
Alter column total_deaths float


Alter table CovidDeaths
Alter column total_cases float


Alter table CovidVaccinations
Alter column New_vaccinations float

Alter table CovidVaccinations
Alter column People_vaccinated float

Alter table CovidVaccinations
Alter column new_vaccinations_smoothed float

Alter table CovidDeaths
Alter column new_deaths float

--Major data that we are going to be using
Select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
Order by location,date

-- Total cases vs Total death (Death Percentage)
--Shows likelyhood of dying if exposed to Covid
SELECT
    location, date, total_cases, total_deaths,
    ROUND((total_deaths / total_cases) * 100, 2) AS Death_Percentage
FROM
    CovidDeaths
WHERE
    total_cases IS NOT NULL
    AND total_deaths IS NOT NULL
ORDER BY
    location,
    date;


--In India
SELECT
    location, date, total_cases, total_deaths,
    ROUND((total_deaths / total_cases) * 100, 2) AS Death_Percentage
FROM
    CovidDeaths
WHERE
    location LIKE '%India%'
    AND total_cases IS NOT NULL
    AND total_deaths IS NOT NULL
ORDER BY
    date;


--Times of maximum chances of death
SELECT top 5
    location, date, total_cases, total_deaths,
    ROUND((total_deaths / total_cases) * 100, 2) AS Death_Percentage
FROM
    CovidDeaths
WHERE
    location LIKE '%India%'
ORDER BY
    Death_Percentage DESC;


-- Total cases vs Population
--Shows what percentage of population got exposed covid
SELECT
    location, date, population, total_cases,
    ROUND((total_cases / population) * 100, 2) AS Percentage_Population_infected
FROM
    CovidDeaths
WHERE
    continent is not null    
	AND total_cases IS NOT NULL
    AND total_deaths IS NOT NULL
ORDER BY
    location, date;


--Countries with highest infection rate compared to its population
SELECT
    location, population,
    MAX(total_cases) AS Highest_Infection_count,
    ROUND(MAX(total_cases / population) * 100, 2) AS Percentage_Population_infected
FROM
    CovidDeaths
WHERE
     total_cases IS NOT NULL
GROUP BY
    location,
    population
ORDER BY
    Percentage_Population_infected DESC;


--Top 20 Countries with Highest Total Deaths
SELECT TOP 20
    location,
    MAX(total_deaths) AS Total_death_count
FROM
    CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY
    location
ORDER BY
    Total_death_count DESC;


--Continents with highest deaths
SELECT
    continent,
    MAX(total_deaths) AS Total_death_count
FROM
    CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY
    continent
ORDER BY
    Total_death_count DESC;

--Global insights
--New Cases everyday globally
SELECT
    date,
    SUM(new_cases) AS Daily_new_Cases,
    SUM(new_deaths) AS Daily_Casualties
FROM
    CovidDeaths
WHERE
    continent IS NOT NULL
	AND new_cases IS NOT NULL
    AND new_deaths IS NOT NULL
GROUP BY
    date
ORDER BY
    date,
    Daily_new_Cases;


--Vaccinated people across the world
--Total population vaccinated and percentage of population vaccianted of each country
SELECT
    CD.location, CD.population,
    MAX(CV.people_vaccinated) AS Total_population_Vaccinated,
    ROUND((MAX(CV.people_vaccinated) / CD.population) * 100, 2) AS Vaccinated_Percentage
FROM
    CovidDeaths CD
JOIN
    CovidVaccinations CV ON CD.location = CV.location
    AND CD.date = CV.date
WHERE
    CD.continent IS NOT NULL
    AND CV.new_vaccinations IS NOT NULL
GROUP BY
    CD.location, CD.population
ORDER BY
    CD.location, CD.population;


--Pro active countries - Identifying nations that achieved their maximum vaccination capacity at the earliest.
WITH cte AS (
    SELECT
        location, date, new_vaccinations_smoothed,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY new_vaccinations_smoothed DESC) AS 'Row_Number'
    FROM
        CovidVaccinations 
    WHERE
        continent IS NOT NULL )
SELECT
    location, date, new_vaccinations_smoothed AS Most_vaccinated_in_a_day
FROM
    cte 
WHERE
    ROW_NUMBER = 1
    AND new_vaccinations_smoothed IS NOT NULL
ORDER BY
    date ASC;


 --Pro active continents - Identify continents that achieved their maximum vaccination capacity at the earliest
WITH cte AS (
    SELECT
        continent, date, new_vaccinations_smoothed,
        ROW_NUMBER() OVER (PARTITION BY continent ORDER BY new_vaccinations_smoothed DESC) AS 'Row_Number'
    FROM
        CovidVaccinations 
    WHERE
        continent IS NOT NULL )
SELECT
    continent, date,
    new_vaccinations_smoothed AS Most_vaccinated_in_a_day
FROM
    cte 
WHERE
    ROW_NUMBER = 1
    AND new_vaccinations_smoothed IS NOT NULL
ORDER BY
    date ASC;


--First mover countries
--Countries that initiated their vaccination programs the earliest.
WITH cte AS (
    SELECT
        location, date,
        new_vaccinations_smoothed,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY date) AS 'Row_Number'
    FROM
        CovidVaccinations 
    WHERE
        continent IS NOT NULL
        AND new_people_vaccinated_smoothed > 0 )

SELECT
    location, date,
    new_vaccinations_smoothed AS Vaccinations_rolled_out
FROM
    cte 
WHERE
    ROW_NUMBER = 1
ORDER BY
    date ASC;


-- No. of countires that initiated there vaccination programme overtime

    SELECT
         date,count(location) No_of_Countries,
		 ROW_NUMBER() OVER(PARTITION BY date ORDER BY date) as RN
    FROM
        CovidVaccinations 
    WHERE
        continent IS NOT NULL
        AND new_people_vaccinated_smoothed >1 
		AND date < '2021-10-21'
		GROUP BY date
        ORDER BY date

--Indentifying death rate before and after achieveing maximum vaccination capacity

--Using Temp Table
WITH cte AS (
    SELECT
        CV.location, CV.date, CV.new_vaccinations_smoothed,
        ROW_NUMBER() OVER (PARTITION BY CV.location ORDER BY CV.new_vaccinations_smoothed DESC) AS 'Row_Number'
    FROM
        CovidVaccinations CV
    WHERE
        CV.continent IS NOT NULL )

SELECT
    location, date, new_vaccinations_smoothed AS Most_vaccinated_in_a_day
INTO
    temptable
FROM
    cte
WHERE
    Row_Number = 1
    AND new_vaccinations_smoothed IS NOT NULL;


SELECT
    CD.location,
    ROUND(AVG(CASE WHEN CD.date < tt.date THEN CD.new_deaths END), 0) AS Average_Daily_Deaths_Before_Peak_Vaccination_Day,
    ROUND(AVG(CASE WHEN CD.date > tt.date THEN CD.new_deaths END), 0) AS Average_Daily_Deaths_After_Peak_Vaccination_Day
FROM
    CovidDeaths CD

JOIN
    temptable tt ON CD.location = tt.location
	WHERE CD.new_deaths is not  null
GROUP BY
    CD.location
ORDER BY
    AVG(CD.new_deaths) DESC;



-- Using Subquery
 
WITH cte AS (
    SELECT CV.location, CV.date, CV.new_vaccinations_smoothed,
        ROW_NUMBER() OVER (PARTITION BY CV.location ORDER BY CV.new_vaccinations_smoothed DESC) AS 'Row_Number'
    FROM
        CovidVaccinations CV
    WHERE
        CV.continent IS NOT NULL )

SELECT
    CD.location,
    ROUND(AVG(CASE WHEN CD.date < tt.date THEN CD.new_deaths END), 0) AS Average_Daily_Deaths_Before_Peak_Vaccination_Day,
    ROUND(AVG(CASE WHEN CD.date > tt.date THEN CD.new_deaths END), 0) AS Average_Daily_Deaths_After_Peak_Vaccination_Day
FROM
    CovidDeaths CD
JOIN (SELECT location, date, new_vaccinations_smoothed AS Most_vaccinated_in_a_day
      FROM
         CTE 
      WHERE
         ROW_NUMBER = 1
         AND new_vaccinations_smoothed IS NOT NULL ) tt 
ON
    CD.location = tt.location
Where CD.new_deaths is not  null
GROUP BY
    CD.location
ORDER BY
    AVG(CD.new_deaths) DESC;


