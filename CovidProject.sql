-- SQL practice working with Covid data from https://ourworldindata.org/covid-deaths

-- Basic queries to initially work with data
Select *
From CovidProject..CovidDeaths
order by 3,4

Select *
From CovidProject..CovidVaccines
order by 3,4

Select location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in the US
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
Where location like '%states%'
order by 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select location, date, population, total_cases, (total_cases/population)*100 as InfectedPercentage
From CovidProject..CovidDeaths
Where location like '%states%'
order by 1,2


-- Looking at Countries with Highest Infection Rate Compared to Population
Select location, population, MAX(total_cases) as HighestInfectionCount, 
	MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..CovidDeaths
Group by location, population
order by PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidProject..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount desc


-- Showing continents with the highest death count per population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
Where continent is not null
Order by 1,2


-- Looking at Total Population vs Vaccinations
-- USE CTE
With PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingTotalVaccinations)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
	dea.Date) as RollingTotalVaccinations
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingTotalVaccinations/Population)*100 as PercentVaccinatedPopulation
From PopvsVac


-- TEMP TABLE
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingTotalVaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
	dea.Date) as RollingTotalVaccinations
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingTotalVaccinations/Population)*100 as PercentVaccinatedPopulation
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
	dea.Date) as RollingTotalVaccinations
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
