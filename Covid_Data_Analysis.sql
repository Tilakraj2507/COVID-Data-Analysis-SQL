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
WHERE continent IS NULL;


-- The probability of death if you are infected with COVID.
SELECT 
	continent, 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	ROUND((total_deaths/total_cases)*100,2) AS death_percentage
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
WHERE continent IS NOT NULL
ORDER BY 1,2,3;


---- The highest death percenatge till date.('North Korea' location data is not proper. So, wrong value)
SELECT 
	continent, 
	location, 
	MAX(total_cases) AS highest_cases, 
	MAX(CAST(total_deaths AS INT)) AS highest_deaths , 
	(MAX(CAST(total_deaths AS INT))/MAX(total_cases))*100 AS highest_death_percentage
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
WHERE continent IS NOT NULL
GROUP BY continent, 
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
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
WHERE continent IS NOT NULL
ORDER BY 1,2,3;


-- Countries(location) with the highest percentage of population infected till date.
SELECT 
	continent, 
	location, 
	MAX(total_cases) as highest_cases, 
	population, 
	MAX(ROUND((total_cases/population)*100,10)) AS population_infection_percentage
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
WHERE continent IS NOT NULL
GROUP BY continent, 
	location,
	population
ORDER BY 5 DESC;


-- Highest number of deaths based on countries(location).
SELECT 
	continent, 
	location,  
	MAX(CAST(total_deaths AS INT)) AS highest_deaths
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
WHERE continent IS NOT NULL
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
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
WHERE continent IS NOT NULL
GROUP BY continent, 
	location,
	population
ORDER BY 5 DESC;

-- COVID test start date based on locations 
SELECT
	continent, 
	location,  
	MIN(cv.date) as vaccination_started_date
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
	JOIN Covid_Vaccinations AS CV 
		ON CV.iso_code = WD.iso_code 
		AND CV.date = CD.date
WHERE continent IS NOT NULL
	AND new_tests IS NOT NULL
GROUP BY continent, 
	location
ORDER BY 3;


-- COVID vaccinations start date based on locations 
SELECT
	continent, 
	location,  
	MIN(cv.date) as vaccination_started_date
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
	JOIN Covid_Vaccinations AS CV 
		ON CV.iso_code = WD.iso_code 
		AND CV.date = CD.date
WHERE continent IS NOT NULL
	AND new_vaccinations IS NOT NULL
GROUP BY continent, 
	location
ORDER BY 3;


-- Rolling people vacinnated based on location
SELECT
	continent, 
	location, 
	CV.date,
	population,
	new_vaccinations,
	SUM(CONVERT(float,new_vaccinations)) OVER (PARTITION BY location ORDER BY location,CV.date) as rolling_people_vaccinated
	--(total_vaccinations/population)*100
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
	JOIN Covid_Vaccinations AS CV 
		ON CV.iso_code = WD.iso_code 
		AND CV.date = CD.date
WHERE continent IS NOT NULL
ORDER BY 2,3;


-- total and percentage of people tested based on locations(USING temp table)
DROP TABLE IF EXISTS #PopulationTested
CREATE TABLE #PopulationTested
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_tests numeric,
total_tests numeric
)

INSERT INTO #PopulationTested
SELECT
	continent, 
	location, 
	CV.date,
	population,
	new_tests,
	total_tests
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
	JOIN Covid_Vaccinations AS CV 
		ON CV.iso_code = WD.iso_code 
		AND CV.date = CD.date
WHERE continent IS NOT NULL

SELECT
	continent,
	location,
	population,
	MAX(total_tests) AS total_test,
	(MAX(total_tests)/population)*100 as test_percentage
FROM #PopulationTested
GROUP BY continent,
	location,
	population
ORDER BY 1,2,4


-- total and percentage of people vaccinated based on locations(USING CTE)
WITH PopulationVaccinated (continent, location, date, population, new_vaccinations, rolling_people_vaccinated )
AS
(
SELECT
	continent, 
	location, 
	CV.date,
	population,
	new_vaccinations,
	SUM(CONVERT(float,new_vaccinations)) OVER (PARTITION BY location ORDER BY location,CV.date) as rolling_people_vaccinated
	--(total_vaccinations/population)*100
FROM Covid_Deaths AS CD
	JOIN World_Demographics AS WD 
		ON CD.iso_code = WD.iso_code
	JOIN Covid_Vaccinations AS CV 
		ON CV.iso_code = WD.iso_code 
		AND CV.date = CD.date
WHERE continent IS NOT NULL
)

SELECT
	continent,
	location,
	population,
	MAX(rolling_people_vaccinated) as total_vaccinated,
	(MAX(rolling_people_vaccinated)/population)*100 as vaccinated_percentage
FROM PopulationVaccinated
GROUP BY continent,
	location,
	population
ORDER BY 1,2,5



	