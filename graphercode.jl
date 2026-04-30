Pkg.add("HTTP")
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Dates")
Pkg.add("Plots")
Pkg.add("RollingFunctions")
Pkg.add("Statistics")
Pkg.add("Loess")

using CSV
using DataFrames
using Dates
using Plots
using RollingFunctions
using Statistics
using Loess

#load the csv dataframe
df = CSV.read("CleanWeatherData2.csv", DataFrame)

# Convert date column to DateTime format
df.date = DateTime.(df.date)

# Extract year from date
df.YEAR = year.(df.date)

# Group by year and calculate mean air temperature for each year in May
grouped_df = combine(groupby(df, :YEAR),
                     :AIR_TEMP => mean => :MEAN_AIR_TEMP)

sort!(grouped_df, :YEAR)

x = grouped_df.YEAR
y = grouped_df.MEAN_AIR_TEMP

#show the base plot that will have the loess curve added to it later
plot(x, y,
    title="Mean Air Temperature in May for Each Year",
    xlabel="Year",
    ylabel="Mean Air Temperature (°C)",
    label="Yearly Mean",
    linewidth=2, fontfamily="Helvetica", color=:blue)

#smooth the data using LOESS and predict the smoothed values for the x range
model = loess(x, y)

x_fit = range(minimum(x), maximum(x), length=200)
y_fit = predict(model, x_fit)

# Add the LOESS trend line to the existing plot

plot!(x_fit, y_fit,
    label="LOESS Trend",
    linewidth=3,
    color=:red)
#savefig the plot as a png file
savefig("MeanAirTemperatureTrendwithLOESS2.png")
