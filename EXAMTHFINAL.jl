#=== GEODATA course UT Austin - NOAA NCEI data - Some useful resources
https://www.ncei.noaa.gov/support/access-data-service-api-user-documentation
https://github.com/partytax/ncei-api-guide
https://www.ncdc.noaa.gov/cdo-web/webservices/v2#gettingStarted
https://developers.google.com/kml/documentation/kml_tut ===#

"""
using Pkg
Pkg.add("HTTP")
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Dates")
Pkg.add("Plots")
Pkg.add("RollingFunctions")
"""

using HTTP
using CSV
using DataFrames
using Dates
using Plots
using RollingFunctions
using Statistics

# get data and create a DataFrame. Download example: see
#https://github.com/partytax/ncei-api-guide for data_types and other parameters
global data = DataFrame()
for cnt in 1925:2025
    print("Downloading year " * string(cnt) * "\n")
    YearSel = cnt
    MonthSel = 5
    # used May since it is the month before the hurricanes hit the Gulf of Mexico,
    # so sensors should be less likely to be damaged by hurricanes, 
    # and thus more likely to have data for the whole month.
    fromDay = Dates.Date(YearSel, MonthSel, 1)
    toDay = Dates.lastdayofmonth(fromDay)
    command = "https://www.ncei.noaa.gov/access/services/data/v1?dataset=global-marine" *
              "&dataTypes=AIR_TEMP" *
              "&startDate=" * string(fromDay) *
              "&endDate=" * string(toDay) *
              "&boundingBox=29.25,-97.25,25,-94.5&units=metric"
    f = CSV.File(HTTP.request("GET", command).body)
    df = f |> DataFrame
    if nrow(data) == 0
        global data = df
    else
        global data = vcat(data, df)
    end
end

# Save the full data to a CSV file for analysis
CSV.write("WeatherStationsFull.csv", data)

# create a KML file of all the weather stations
nameStation = string.(unique(data[:,1]));
global io = open("WeatherStationsFull.kml", "w");
write(io,"""<?xml version="1.0" encoding="UTF-8"?>""",
"\n");
write(io,"""<kml xmlns="http://earth.google.com/kml/2.2">""",
"\n");
write(io," <Document>",
"\n");
for cnt in 1:length(nameStation)
    print("Writing KML file... $(cnt/length(nameStation)*100) %\n");
    ID=findall(nameStation .== nameStation[cnt]);
    write(io," <Placemark>",
    "\n");
    write(io," <name>"*nameStation[cnt]*"</name>\n");
    write(io," <Point>",
    "\n");
    write(io,"
    <coordinates>",string(data[ID[1],4]),",",string(data[ID[1],3]),"</coordinates>",
    "\n");
    write(io," </Point>",
    "\n");
    write(io," </Placemark>",
    "\n");
end
write(io," </Document>",
"\n");
write(io,"</kml>",
"\n");
close(io);

##########################################################
