using Pkg
#=
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Plots")

Pkg.add("StatsBase")
Pkg.add("GLM")
=#
using CSV
using DataFrames           # dataframes deal with tables https://dataframes.juliadata.org/stable/
using Plots
using StatsBase  # Import StatsBase for statistical functions
using GLM  # Import GLM for LinearModel

# Function to load the CSV file
function LoadFileCSV(fname, dirpath)
    fpath = joinpath(dirpath, fname)
    mydata = CSV.read(fpath, DataFrame, missingstring="NaN")
    return mydata
end

# Function to clean and homogenize the data
function cleandata(dataRAW)
    t_year = tryparse.(Float64, dataRAW[:, 1])
    sat = zeros(length(t_year))
    sealevel_mm = zeros(length(t_year))

    for n = 6:length(t_year)  # Skip the first 6 rows (header)
        id = (!).(isnothing.(tryparse.(Float64, collect(dataRAW[n, 2:end]))))  # Find valid data columns
        id = findall(==(1), id)  # Get indices of valid columns
        sat[n] = id[end]  # Record the satellite source
        sealevel_mm[n] = parse.(Float64, dataRAW[n, id[end] + 1])  # Record sea level data
    end

    t_year = Float64.(t_year[6:end])
    sat = Float64.(sat[6:end])
    sealevel_mm = Float64.(sealevel_mm[6:end])

    return DataFrame(hcat(t_year, sat, sealevel_mm), ["time_year", "sat", "sealevel_mm"])
end

# Function to write the cleaned data to a new CSV file
function WriteNewHomogonizedCSV(df, fname, dirpath)
    fpath = joinpath(dirpath, fname)
    CSV.write(fpath, df)
end

# Main script
function main_cleaning()
    dataRAW = LoadFileCSV("NOAA_seaLevel_Mar2025.csv", ".")
    cleaned_data = cleandata(dataRAW)
    WriteNewHomogonizedCSV(cleaned_data, "NOAA_seaLevel_Mar2025_OUT4.csv", ".")
    return cleaned_data
end

function makeaplot(df)
    # Calculate change in mean sea level (relative to first measurement)
    baseline = df.sealevel_mm[1]
    change_in_level = df.sealevel_mm .- baseline
    
    # Plot all data together
    p = plot(df.time_year, change_in_level, xlabel="Year", ylabel="Change in Mean Sea Level [mm]", label="", color=:blue, linewidth=2)
    
    # Add line of best fit
    model = GLM.lm(@formula(sealevel_mm ~ time_year), df)
    trend_line = predict(model)
    trend_baseline = trend_line[1]
    trend_line_adjusted = trend_line .- trend_baseline
    plotdf.time_year, trend_line_adjusted, label="", color=:black, linewidth=3, linestyle=:solid)
    
    return p
end



# Run the main cleaning function
cleaned_data = main_cleaning()

# Make a plot of the cleaned data
#makeaplot(cleaned_data)
#plot!(cleaned_data.time_year, cleaned_data.sealevel_mm, group=cleaned_data.sat, title="Sea Level Rise Over Time", xlabel="Year", ylabel="Change in mean Sea Level (mm)", legend=:topleft)


function make_NOAA_style_plot(df)

    # --- Baseline adjustment ---
    baseline = df.sealevel_mm[1]
    df.change = df.sealevel_mm .- baseline

    # --- Create base plot ---
    p = plot(
        xlabel = "Year",
        ylabel = "Change in Mean Sea Level [mm]",
        title = "Global Mean Sea Level",
        legend = :topleft,
        linewidth = 2,
        grid = true
    )

    # --- Plot each satellite in different colors ---
    sats = unique(df.sat)
    colors = [:blue, :red, :green, :purple, :cyan]

    for (i, s) in enumerate(sats)
        sub = df[df.sat .== s, :]
        plot!(sub.time_year, sub.change,
              label = "Sat $(Int(s))",
              color = colors[i],
              linewidth = 2)
    end

    # --- Linear regression (trend line) ---
    model = lm(@formula(change ~ time_year), df)
    trend = predict(model)

    plot!(df.time_year, trend,
          color = :black,
          linewidth = 3,
          label = "Trend")

    # --- Optional: annotate slope ---
    slope = coef(model)[2]
    annotate!(minimum(df.time_year)+2,
              maximum(df.change)-10,
              text("Trend: $(round(slope, digits=2)) mm/yr", 10))

    return p
end

# Run it
p = make_NOAA_style_plot(cleaned_data)
display(p)
