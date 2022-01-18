--SELECT * FROM PortfolioProjects..covid_deaths$

SELECT * FROM PortfolioProjects..covid_vaccinations$ vac
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects..covid_deaths$
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
--Shows likelihood of Dying if we get contracted by COVID in India
SELECT location, date, total_cases, total_deaths, (Total_deaths/Total_cases)*100 AS DeathPercentage
FROM PortfolioProjects..covid_deaths$
WHERE location =  'india' AND continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of Population got COVID in India
SELECT location, date, population, total_cases, (Total_deaths/population)*100 AS InfectedPercentage
FROM PortfolioProjects..covid_deaths$
WHERE location LIKE  '__dia' AND continent IS NOT NULL
ORDER BY 1,2

--Which country has highest infection rate compared to Population?
SELECT location, MAX(total_cases) AS MaxInfectionCount, population, (MAX(Total_cases/population)) *100 AS PercentagePopulationInfected
FROM PortfolioProjects..covid_deaths$
GROUP BY location, population
ORDER BY PercentagePopulationInfected desc

--Which country has highest Death rate compared to Population?
SELECT location, MAX(CAST(total_deaths AS INT)) AS MaxDeathCount
FROM PortfolioProjects..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MaxDeathCount desc

--Which continet has highest Death rate compared to Population? 
SELECT location, MAX(CAST(total_deaths AS INT)) AS MaxDeathCount
FROM PortfolioProjects..covid_deaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY MaxDeathCount desc

--GLOBAL NUMBERS

--Total Cases and Deaths of the World
SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths as INT)) AS Total_deaths, 
SUM(CAST(new_deaths as INT)) / SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProjects..covid_deaths$ dea
WHERE continent IS NOT NULL
ORDER BY 1,2

--Total population vs vaccinations by country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
from PortfolioProjects..covid_deaths$ dea
JOIN PortfolioProjects..covid_vaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Per Day vaccinations and Total Vaccinations by Country & Date
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
from PortfolioProjects..covid_deaths$ dea
JOIN PortfolioProjects..covid_vaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Percentage of people vaccinated of a Country

--1)Using CTE
With PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS 
(
SELECT dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
from PortfolioProjects..covid_deaths$ dea
JOIN PortfolioProjects..covid_vaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (Rolling_vaccinations/population)*100 AS PercentagePopulationVaccinated
FROM PopvsVac


--2) Using TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nVARCHAR(255),
Location nVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
Rolling_Vaccinations NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
from PortfolioProjects..covid_deaths$ dea
JOIN PortfolioProjects..covid_vaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (Rolling_Vaccinations/Population)*100 AS PercentagePopulationVaccinated
FROM #PercentPopulationVaccinated

--CREATING VIEWS FOR DATA VISUALISATION 

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
from PortfolioProjects..covid_deaths$ dea
JOIN PortfolioProjects..covid_vaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentagePopulationVaccinated