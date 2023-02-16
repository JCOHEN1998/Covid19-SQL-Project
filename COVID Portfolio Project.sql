Select * 
FROM [dbo].[CovidDeaths]
Order by 3,4

--Select *
--FROM [dbo].[CovidVaccinations]
--Order by 3,4

-- Select Data 

Select [Location], [Date], total_cases, new_cases, total_deaths, [population]
From [dbo].[CovidDeaths]
Where continent is not null
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select [Location], [Date], total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [dbo].[CovidDeaths]
WHERE location like '%states%'
and continent is not null
order by 1,2

-- Looking at Total Cases vs Population
-- shows what percentage of population got Covid

Select [Location], [Date], total_cases, [Population],(total_cases/[population])*100 as PercentPopulationInfected
From [dbo].[CovidDeaths]
--WHERE location like '%states%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

Select [Location], [Population], MAX(total_cases) as HighestInfectionCount, MAX((total_cases/[population]))*100 as PercentPopulationInfected
From [dbo].[CovidDeaths]
--WHERE location like '%states%'
Group by [Location], [Population]
order by PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population

Select [Location], MAX(cast(Total_deaths as int)) as TotalDeathCount
From [dbo].[CovidDeaths]
--WHERE location like '%states%'
Where continent is not null
Group by [Location]
order by TotalDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT




-- Showing continent with the highest death count per population


Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [dbo].[CovidDeaths]
--WHERE location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From [dbo].[CovidDeaths]
--WHERE location like '%states%'
where continent is not null
--Group by date
order by 1,2

--Lookinh at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
,
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by dea.location, dea.Date

-- query above wouldn't work, query below works (ask why) (without the (RollingPeopleVaccinated/population)*100)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
 -- , (RollingPeopleVaccinated/population)*100
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date


-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinatinos, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--  , (RollingPeopleVaccinated/poulation)*100
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date
)
Select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac

-- TEMP TABLE

Drop Table if  exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--  , (RollingPeopleVaccinated/poulation)*100
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
  ON dea.location = vac.location
  AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date

Select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--  , (RollingPeopleVaccinated/poulation)*100
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date

Select *
FROM PercentPopulationVaccinated
