#=
Sea Level Data Helper Functions for Lab 3

This file provides functions to load and work with sea level rise projection data
for Sewells Point, Norfolk, VA.

Data sources:
- BRICK model: Ruckert et al. (2019) - probabilistic projections
- NOAA scenarios: Sweet et al. (2017) - deterministic scenarios
=#

using NetCDF
using Statistics

# Path to data file
const DATA_PATH = joinpath(@__DIR__, "data", "sea_level_projections.nc")

"""
    load_brick_projections()

Load BRICK sea level rise projections from NetCDF file.

Returns a NamedTuple with:
- `years`: Vector of years (e.g., 2000:2100)
- `ensemble`: Vector of ensemble member indices
- `rcps`: Vector of RCP scenario names
- `slr`: 3D Array of sea level rise [meters] with dimensions (time, ensemble, rcp)
"""
function load_brick_projections()
    years = Int.(ncread(DATA_PATH, "time"))
    ensemble = Int.(ncread(DATA_PATH, "ensemble"))
    slr = ncread(DATA_PATH, "brick_slr")  # (time, ensemble, rcp)

    rcps = ["rcp26", "rcp45", "rcp60", "rcp85"]

    return (years=years, ensemble=ensemble, rcps=rcps, slr=slr)
end

"""
    load_noaa_scenarios()

Load NOAA sea level rise scenarios from NetCDF file.

Returns a NamedTuple with:
- `years`: Vector of years
- `scenarios`: Vector of scenario names (low, int_low, intermediate, int_high, high)
- `slr`: 2D Array of sea level rise [meters] with dimensions (time, scenario)
"""
function load_noaa_scenarios()
    years = Int.(ncread(DATA_PATH, "time"))
    slr = ncread(DATA_PATH, "noaa_slr")  # (time, scenario)

    scenarios = ["low", "int_low", "intermediate", "int_high", "high"]

    return (years=years, scenarios=scenarios, slr=slr)
end

"""
    get_brick_scenario(data, rcp::String)

Extract a single RCP scenario from BRICK projections.

Arguments:
- `data`: NamedTuple from `load_brick_projections()`
- `rcp`: RCP scenario name (e.g., "rcp45", "rcp85")

Returns a 2D Array of sea level rise [meters] with dimensions (time, ensemble).
"""
function get_brick_scenario(data, rcp::String)
    idx = findfirst(==(rcp), data.rcps)
    if isnothing(idx)
        error("Unknown RCP scenario: $rcp. Available: $(data.rcps)")
    end
    return data.slr[:, :, idx]
end

"""
    get_noaa_scenario(data, scenario::String)

Extract a single NOAA scenario.

Arguments:
- `data`: NamedTuple from `load_noaa_scenarios()`
- `scenario`: Scenario name (e.g., "low", "intermediate", "high")

Returns a Vector of sea level rise [meters] over time.
"""
function get_noaa_scenario(data, scenario::String)
    idx = findfirst(==(scenario), data.scenarios)
    if isnothing(idx)
        error("Unknown NOAA scenario: $scenario. Available: $(data.scenarios)")
    end
    return data.slr[:, idx]
end

"""
    brick_quantiles(scenario_data, probs=[0.05, 0.5, 0.95])

Compute quantiles across the ensemble dimension.

Arguments:
- `scenario_data`: 2D Array (time, ensemble) from `get_brick_scenario()`
- `probs`: Quantile probabilities

Returns a 2D Array (time, quantile).
"""
function brick_quantiles(scenario_data, probs=[0.05, 0.5, 0.95])
    n_years = size(scenario_data, 1)
    n_probs = length(probs)
    result = zeros(n_years, n_probs)

    for t in 1:n_years
        result[t, :] = quantile(scenario_data[t, :], probs)
    end

    return result
end

"""
    meters_to_feet(slr_meters)

Convert sea level rise from meters to feet.
"""
meters_to_feet(slr_meters) = slr_meters * 3.28084

"""
    slr_at_year(data, rcp::String, year::Int)

Get the distribution of sea level rise at a specific year for a given RCP.

Arguments:
- `data`: NamedTuple from `load_brick_projections()`
- `rcp`: RCP scenario name
- `year`: Target year

Returns a Vector of SLR values [meters] across all ensemble members.
"""
function slr_at_year(data, rcp::String, year::Int)
    scenario_data = get_brick_scenario(data, rcp)
    year_idx = findfirst(==(year), data.years)
    if isnothing(year_idx)
        error("Year $year not in data. Available: $(data.years[1]) to $(data.years[end])")
    end
    return scenario_data[year_idx, :]
end

"""
Print a summary of the loaded data.
"""
function data_summary(brick_data, noaa_data)
    println("Sea Level Rise Projection Data Summary")
    println("=" ^ 50)
    println("Location: Sewells Point, Norfolk, VA")
    println("Baseline: Year 2000")
    println()
    println("BRICK Projections (probabilistic):")
    println("  Years: $(brick_data.years[1]) to $(brick_data.years[end])")
    println("  RCP scenarios: $(join(brick_data.rcps, ", "))")
    println("  Ensemble members: $(length(brick_data.ensemble))")
    println()
    println("NOAA Scenarios (deterministic):")
    println("  Years: $(noaa_data.years[1]) to $(noaa_data.years[end])")
    println("  Scenarios: $(join(noaa_data.scenarios, ", "))")
    println("=" ^ 50)
end
