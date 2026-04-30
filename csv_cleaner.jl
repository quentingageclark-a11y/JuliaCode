using CSV
using DataFrames
using Dates
using Statistics

#load the full data
df = CSV.read("WeatherStationsFull.csv", DataFrame)

# Keep only rows where AIR_TEMP is not missing
df = filter(row -> !ismissing(row.AIR_TEMP), df)

#now we want to split the date collum into date and time, so we will use the split function to split the date collum into date and time
df.date = Date.(df.DATE)
df.time = Time.(df.DATE)
#this creates two new collums, one for date and one for time, and fills them with the date and time values from the original DATE collum

# Save new cleaned dataset
CSV.write("CleanWeatherData2.csv", df)