/*
COVID-19 Data Analysis & Exploration

Database : Covid_Data
Tables   : Covid_Deaths
		 : Covid_Vaccinations
		 : World_Demographics
*/
USE Covid_Data
EXEC sp_help 'Covid_Data.dbo.World_Demographics';
EXEC sp_help 'Covid_Data.dbo.Covid_Deaths';
EXEC sp_help 'Covid_Data.dbo.Covid_Vaccinations';


/*
--Excluding unwanted rows--
There is a NULL row in 'CONTINENT' column.
Which has continent and some other random values in location which is not proper.So, moving forward will be excluding these rows
*/
SELECT 
	DISTINCT(continent)
FROM World_Demographics;

SELECT 
	DISTINCT(location)
FROM World_Demographics
WHERE 
	continent IS NULL;


-- The probability of death if you are infected with COVID.
SELECT 
	continent, 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	ROUND((total_deaths/total_cases)*100,2) AS death_percentage
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD ON CD.iso_code = WD.iso_code
WHERE 
	continent IS NOT NULL
ORDER BY 1,2,3;


---- The highest death percenatge till date.('North Korea' location data is not proper. So, wrong value)
SELECT 
	continent, 
	location, 
	MAX(total_cases) AS highest_cases, 
	MAX(CAST(total_deaths AS INT)) AS highest_deaths , 
	(MAX(CAST(total_deaths AS INT))/MAX(total_cases))*100 AS highest_death_percentage
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD ON CD.iso_code = WD.iso_code
WHERE 
	continent IS NOT NULL
GROUP BY 
	continent, 
	location
ORDER BY 5 DESC;


-- The percentage of population infected as compared to population.
SELECT 
	continent, 
	location, 
	date, 
	total_cases, 
	population, 
	ROUND((total_cases/population)*100,10) AS infection_percentage
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD ON CD.iso_code = WD.iso_code
WHERE 
	continent IS NOT NULL
ORDER BY 1,2,3;


-- Countries(location) with the highest percentage of population infected till date.
SELECT 
	continent, 
	location, 
	MAX(total_cases) as highest_cases, 
	population, 
	MAX(ROUND((total_cases/population)*100,10)) AS population_infection_percentage
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD ON CD.iso_code = WD.iso_code
WHERE 
	continent IS NOT NULL
GROUP BY 
	continent, 
	location,
	population
ORDER BY 5 DESC;


-- Highest number of deaths based on countries(location).
SELECT 
	continent, 
	location,  
	MAX(CAST(total_deaths AS INT)) AS highest_deaths
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD ON CD.iso_code = WD.iso_code
WHERE 
	continent IS NOT NULL
GROUP BY 
	continent, 
	location
ORDER BY 3 DESC;


-- Highest death per population based on countries(location).
SELECT 
	continent, 
	location,  
	MAX(CAST(total_deaths AS INT)) as highest_deaths,
	population,
	ROUND((MAX(CAST(total_deaths AS INT))/population)*100,2) AS highest_death_percentage
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD ON CD.iso_code = WD.iso_code
WHERE 
	continent IS NOT NULL
GROUP BY 
	continent, 
	location,
	population
ORDER BY 5 DESC;


--
SELECT
	COUNT(*)
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD ON CD.iso_code = WD.iso_code
	JOIN Covid_Vaccinations AS CV ON CV.iso_code = WD.iso_code AND CV.date = CD.date
	