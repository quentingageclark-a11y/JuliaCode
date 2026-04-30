using Pkg

Pkg.add("HTTP") 

Pkg.add("Plots")
Pkg.add("DelimitedFiles")
Pkg.add("Dates")
Pkg.add("LaTeXStrings")

using HTTP

sites = ["08155500","08159000","08158600","08157540","08158000"]
##############################
#   Spring          Code
#-----------------------------
#   Barton Springs  08155500
#   Onion Creek     08159000
#   Walnut Creek    08158600
#   Waller Creek    08157540
#   Colorado @ATX   08158000
##############################

for i in 1:length(sites)

    sel = i
    code = sites[sel]

    fileNameIN = code * ".txt"   # creates the file name

    command = "https://nwis.waterdata.usgs.gov/tx/nwis/uv?cb_00060=on&format=rdb&site_no=" * code * "&legacy=&period=&begin_date=2010-1-1&end_date=2023-10-31"

    println("Downloading " * fileNameIN * "...")

    dataFile = HTTP.request("GET", command)

    file = open(fileNameIN, "w")
    write(file, dataFile.body)
    close(file)

    println("Done with " * fileNameIN)
end

println("All downloads complete.")

######################
#    What changed:
#    Added for i in 1:length(sites)
#    Replaced your fixed sel = 1 with sel = i
#    Everything else runs once per site automatically
#    What this does:
    #    Loops through all 5 site codes
    #    Builds a unique URL for each
    #    Downloads each dataset
    #    Saves each to its own .txt file
#######################

using Plots
using DelimitedFiles
using Dates
using LaTeXStrings

sites       =   ["08155500";"08159000";"08158600";"08157540";"08158000"];
#nameSite    =   ["Barton Springs";"Onion Creek";"Walnut Creek";"Waller Creek";"Colorado @ATX"];
sel         =   2;
code        =   sites[sel];
fileNameIN  =   code * ".txt";  # assembles the file name
dataRAW=readdlm(fileNameIN, '\t', String, '\n');
format = dateformat"y-m-d H:M";
date_time=DateTime.(dataRAW[33:end,3], format);
dis_ft3_s=parse.(Float64,dataRAW[33:end,5])
dis_m3_s=dis_ft3_s*0.0283168#this multiplier was found by searching "convert ft^3/s to m^3/s" on Google

# Primary plot (m³/s)
plot(date_time, dis_m3_s, 
    title="Discharge Rate Value", 
    xlabel="Date", 
    ylabel="Discharge, "*L"\mathrm{m}^3/\mathrm{s}", 
    ylimits=(0.0, 3500), 
    label="Discharge, "*L"\mathrm{m}^3/\mathrm{s}", 
    legend=:topleft, 
    grid=:solid, 
    gridalpha=0.8, 
    gridcolor=:black, 
    gridlinewidth=1.0, 
    linecolor=:red, 
    xlimits=(DateTime(2015,10,28), DateTime(2015,11,02)))

#I modified the code inside plot() to include a change to the y axis limits, which makes it easier to see the variations in discharge over time. 
#I also set the boolean grid=true to add grid lines to the plot, which can help with visual interpretation of the data.

##secondary plot (ft³/s) on the same graph with a secondary y-axis
#plot!(twinx(),date_time, dis_ft3_s, ylabel="Discharge, "*L"\mathrm{ft}^3/\mathrm{s}", 
#    label="Discharge, "*L"\mathrm{ft}^3/\mathrm{s}", ylimits=(0.1 * 35.3147 , 4.1 * 35.3147), 
#    legend=:topright, ygrid=[36,72,108,144], grid=:solid, gridalpha=.9, 
#    gridcolor=:black, gridlinewidth=1.0)



