-- Preview all data--
Select *
From PortfolioProject..CovidData

--Identify rows that may contaminate results
Select Distinct location
From PortfolioProject..CovidData
Where location like '%income%'
order by 1

--Remove rows for High Income, Upper middle income, Lower middle income, Low income
Delete From PortfolioProject..CovidData Where Location like '%income%'

--Identity data types of each column
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'CovidData'

--Potentially problematic data types:
	--date as datetime
	--total_deaths, new_deaths as nvarchar
		--these will be cast as integers for any future calculations

--Simplify date format--
	--verify correctness prior to update
Select date, CONVERT(Date, date)
From PortfolioProject..CovidData
	--add new column
ALTER TABLE CovidData
Add date_converted Date;
	--update table
Update CovidData
SET date_converted = CONVERT(Date, date)

--Preview most impactful data--
Select location, date_converted, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidData
Where continent is not null
Order by 1,2

--Total Cases vs. Total Deaths--
Select location, date_converted, total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
From PortfolioProject..CovidData
Where continent is not null
Order by 1,2

--Total Cases vs. Population--
Select location, date_converted, population, total_cases, (total_cases / population) * 100 as PercentPopulationInfected
From PortfolioProject..CovidData
Order by PercentPopulationInfected desc

--Countries w/ highest infection rate--
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases / population)) * 100 as PercentPopulationInfected
From PortfolioProject..CovidData
Group by location, population
Order by PercentPopulationInfected desc

--Countries with most deaths--
Select location, MAX(cast(total_deaths as int)) as TotalDeaths
From PortfolioProject..CovidData
Group by location
Order by TotalDeaths desc

--Global numbers--
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int)) / SUM(new_cases) * 100 as PercentDead
From PortfolioProject..CovidData
Where continent is not null
Order by 1,2

--Running tally of vaccinated population--
Select continent, location, date_converted, population, new_vaccinations, SUM(cast(new_vaccinations as bigint)) OVER (Partition by location Order by location, date) as running_tally_vaccinated
From PortfolioProject..CovidData
where continent is not null
Order by 2,3

--Create temp table to perform calculation on previous query
DROP Table if exists #PercentVaccinated
Create Table #PercentVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date Date,
Population numeric,
New_vaccinations numeric,
Tally_vaccinated numeric
)

Insert into #PercentVaccinated
Select continent, location, date_converted, population, new_vaccinations
, SUM(cast(new_vaccinations as bigint)) OVER (Partition by Location Order by location, Date) as tally_vaccinated
From PortfolioProject..CovidData

Select *, CAST(ROUND((tally_vaccinated/Population)*100, 5) as DECIMAL(8, 2)) as Percent_vaccinated
From #PercentVaccinated