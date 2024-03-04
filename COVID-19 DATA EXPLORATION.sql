-- COVID-19 DATA EXPLORATION 
--Skills used; JOINS, CTEs, Aggregate Finctions, Converting Data Types, 
  

--Raw Data 

SELECT * 
FROM Portfolio..CovidDeaths AS CD
JOIN Portfolio..CovidVaccinations AS CV
ON CV.iso_code = CD.iso_code

 

---Total cases per continent using CTE.

WITH Cases AS (Location, Continent, TotalCases)
	(
    SELECT DISTINCT Location, continent, CAST(Total_cases AS BIGINT) AS TotalCases 
    FROM Portfolio..CovidDeaths 
    WHERE continent IS NOT NULL 
) 

SELECT continent AS Continent, 
SUM(TotalCases) AS TotalCasesPerContinent 
FROM Cases 
GROUP BY continent; 

  

--Case every year in every country 
--I excluded the 'World' as its showing up in location.

 SELECT Location, SUM(CAST(Total_cases AS BIGINT)) AS TotalCases,
 YEAR(TRY_CAST(Date AS Date)) AS Years
FROM Portfolio..CovidDeaths
WHERE Location <> 'World'
GROUP BY Location,
YEAR(TRY_CAST(Date AS Date));



--Percentage of population in the Philippines that is vaccinated.
--I'm still looking for a way to show the percentage as a whole numbers.

WITH Vaccination AS ( ---Location, population, vaccinated

SELECT CD.Location, CD.Population, SUM(CAST(CV.new_Vaccinations AS BIGINT)) AS Vaccinated
FROM Portfolio..CovidDeaths AS CD
JOIN Portfolio..CovidVaccinations AS CV
ON CV.iso_code = CD.iso_code
WHERE CD.Location = 'Philippines'
GROUP BY CD.Location, CD.population
)

SELECT 
    Location AS location,
    Population AS population,
    ROUND((Vaccinated * 100 / Population), 0) AS PercentageOfPopulation
FROM 
    Vaccination;



	--Total Covid-19 deaths worldwide

SELECT SUM(CAST(Total_deaths AS BIGINT)) AS totalDeaths
FROM Portfolio..CovidDeaths


--Total Vaccinations Administered

SELECT DISTINCT CD.Location, SUM(CAST(CV.Total_vaccinations AS BIGINT)) AS TotalVaccinated
FROM Portfolio..CovidDeaths AS CD
JOIN Portfolio..CovidVaccinations AS CV
ON CV.iso_code = CD.iso_code
GROUP BY CD.Location
HAVING SUM(CAST(CV.Total_vaccinations AS BIGINT)) > 0;


--Percentage of poopulation vaccinated including the max and avg of deaths in every country.

WITH Percentage AS (
SELECT DISTINCT CD.Location, CV.Population, SUM(CAST(CV.Total_vaccinations AS BIGINT)) AS TotalVaccinated, 
MAX(CAST(CD.Total_deaths AS BIGINT)) AS MaxDeaths,
AVG(CAST(CD.Total_deaths AS BIGINT)) AS AvgDeaths,
COUNT (*) AS NumRecords
FROM Portfolio..CovidDeaths AS CD
JOIN Portfolio..CovidVaccinations AS CV
ON CV.iso_code = CD.iso_code
GROUP BY CD.Location, CV.Population
HAVING SUM(CAST(CV.Total_vaccinations AS BIGINT)) > 0
AND SUM(CAST(CD.Total_deaths AS BIGINT)) > 0
)
SELECT Location AS Country,
ROUND((TotalVaccinated *100 / population), 0) AS PercentPopulationVac,
MaxDeaths, AvgDeaths, NumRecords
FROM Percentage



---Total cases vs. total deaths in every country

SELECT Location AS Country, date,
Population, SUM(CAST(Total_cases AS BIGINT)) AS TotalCases,
SUM(CAST(Total_deaths AS BIGINT)) AS TotalDeath
FROM Portfolio..CovidDeaths
--ORDER BY Location
GROUP BY Location, date,
Population
HAVING SUM(CAST(Total_cases AS BIGINT)) > 0
AND SUM(CAST(Total_deaths AS BIGINT)) > 0;


---Using a temp table to calculate the number of people who survived COVID-19 after being affected by it.

DROP TABLE IF EXISTS  #TotalCasesAndDeaths
CREATE TABLE #TotalCasesAndDeaths (
Country Varchar(50),
population NUMERIC,
TotalCases BIGINT,
TotalDeath BIGINT
)

INSERT INTO #TotalCasesAndDeaths (Country, population, TotalCases, TotalDeath)
SELECT Location AS Country,
Population, SUM(CAST(Total_cases AS BIGINT)) AS TotalCases,
SUM(CAST(Total_deaths AS BIGINT)) AS TotalDeath
FROM Portfolio..CovidDeaths
--ORDER BY Location
GROUP BY Location,
Population
HAVING SUM(CAST(Total_cases AS BIGINT)) > 0
AND SUM(CAST(Total_deaths AS BIGINT)) > 0;

SELECT Country, TotalCases, TotalDeath, 
(TotalCases - TotalDeath) AS TotalSuurvived
FROM #TotalCasesAndDeaths 
ORDER BY 1;


---Creating VIEW to store for visualization for later.

CREATE VIEW PercentPopulationVac AS
WITH Percentage AS (
SELECT DISTINCT CD.Location, CV.Population, SUM(CAST(CV.Total_vaccinations AS BIGINT)) AS TotalVaccinated, 
MAX(CAST(CD.Total_deaths AS BIGINT)) AS MaxDeaths,
AVG(CAST(CD.Total_deaths AS BIGINT)) AS AvgDeaths,
COUNT (*) AS NumRecords
FROM Portfolio..CovidDeaths AS CD
JOIN Portfolio..CovidVaccinations AS CV
ON CV.iso_code = CD.iso_code
GROUP BY CD.Location, CV.Population
HAVING SUM(CAST(CV.Total_vaccinations AS BIGINT)) > 0
AND SUM(CAST(CD.Total_deaths AS BIGINT)) > 0
)
SELECT Location AS Country,
ROUND((TotalVaccinated *100 / population), 0) AS PercentPopulationVac,
MaxDeaths, AvgDeaths, NumRecords
FROM Percentage
