#=
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Plots")
Pkg.add("GLM")
Pkg.add("StatsModels")
=#

using CSV
using DataFrames
using Plots
using GLM
using StatsModels

# -----------------------------
# Load CSV
# -----------------------------
function load_data(fname)
    return CSV.read(fname, DataFrame, missingstring="NaN")
end

# -----------------------------
# Clean data
# -----------------------------
function clean_data(dataRAW)
    t_year = tryparse.(Float64, dataRAW[:, 1])
    sat = zeros(length(t_year))
    sealevel = zeros(length(t_year))

    for n in 6:length(t_year)  # skip header rows
        vals = tryparse.(Float64, collect(dataRAW[n, 2:end]))
        valid = findall(!isnothing, vals)

        if !isempty(valid)
            sat[n] = valid[end]                     # satellite ID
            sealevel[n] = vals[valid[end]]         # sea level value
        end
    end

    # trim first 5 rows
    df = DataFrame(
        time_year = Float64.(t_year[6:end]),
        sat = Float64.(sat[6:end]),
        sealevel_mm = Float64.(sealevel[6:end])
    )

    return df
end

# -----------------------------
# Plot function (NOAA-style)
# -----------------------------
function plot_sealevel(df)

    # --- baseline adjustment ---
    baseline = df.sealevel_mm[1]
    df.change = df.sealevel_mm .- baseline

    # --- create plot ---
    p = plot(
        xlabel = "Year",
        ylabel = "Change in Mean Sea Level [mm]",
        title = "Global Mean Sea Level",
        legend = :topleft,
        linewidth = 2,
        grid = true,
        framestyle = :box
    )

    # --- color map for satellites ---
    colors = Dict(
        1.0 => :blue,    # TOPEX
        2.0 => :red,     # Jason-1
        3.0 => :green,   # Jason-2
        4.0 => :purple,  # Jason-3
        5.0 => :cyan
    )

    # --- plot each satellite segment ---
    for s in unique(df.sat)
        sub = df[df.sat .== s, :]
        plot!(sub.time_year, sub.change,
              color = get(colors, s, :black),
              label = "",
              linewidth = 2)
    end

    # --- linear regression ---
    model = lm(@formula(change ~ time_year), df)
    trend = predict(model)

    plot!(df.time_year, trend,
          color = :black,
          linewidth = 3,
          label = "", legend=true)

    # --- slope annotation ---
    slope = coef(model)[2]
    annotate!(
        minimum(df.time_year) + 2,
        maximum(df.change) - 10,
        text("Trend: $(round(slope, digits=2)) mm/yr", 10)
    )

    return p
end

# -----------------------------
# MAIN
# -----------------------------
dataRAW = load_data("NOAA_seaLevel_Mar2025.csv")
df = clean_data(dataRAW)

p = plot_sealevel(df)
display(p)

function plot_all_data(df)

    # --- baseline adjustment ---
    baseline = df.sealevel_mm[1]
    change = df.sealevel_mm .- baseline

    # --- main plot (single line) ---
    p = plot(df.time_year, change,
        color = :blue,
        linewidth = 2,
        label = "Sea Level",
        xlabel = "Year",
        ylabel = "Change in Mean Sea Level [mm]",
        title = "Global Mean Sea Level (All Satellites Combined)",
        grid = true,
        framestyle = :box
    )

    # --- linear regression (trend line) ---
    df.change = change
    model = lm(@formula(change ~ time_year), df)
    trend = predict(model)

    plot!(df.time_year, trend,
        color = :black,
        linewidth = 3,
        label = "Trend")

    # --- slope annotation ---
    slope = coef(model)[2]
    annotate!(
        minimum(df.time_year) + 2,
        maximum(change) - 10,
        text("Trend: $(round(slope, digits=2)) mm/yr", 10)
    )

    return p
end

# Run it
p = plot_all_data(df)
display(p)

function compute_fits(df)

    # --- baseline adjustment (same as before) ---
    baseline = df.sealevel_mm[1]
    df.change = df.sealevel_mm .- baseline

    # -------------------------
    # Linear fit: y = a + b*x
    # -------------------------
    model1 = lm(@formula(change ~ time_year), df)
    cf1 = coef(model1)   # [intercept, slope]

    # -------------------------
    # Parabolic fit: y = a + b*x + c*x^2
    # -------------------------
    df.time_year2 = df.time_year .^ 2
    model2 = lm(@formula(change ~ time_year + time_year2), df)
    cf2 = coef(model2)   # [a, b, c]

    return cf1, cf2
end

# Run it
cf1, cf2 = compute_fits(df)

println("Linear coefficients (cf1): ", cf1)
println("Parabolic coefficients (cf2): ", cf2)

#Linear coefficients (cf1): [-6336.302794762554, 3.1772878963455318]
#Parabolic coefficients (cf2): [0.0, -3.1291436772220225, 0.0015691438076413722]

# Extract time
t = df.time_year

# --- Linear fit ---
a1, b1 = cf1
sealevelLin_mm = a1 .+ b1 .* t

# --- Parabolic fit ---
a2, b2, c2 = cf2
sealevelPar_mm = a2 .+ b2 .* t .+ c2 .* t.^2

# Baseline-adjusted data (same as before)
baseline = df.sealevel_mm[1]
change = df.sealevel_mm .- baseline

# Base data plot
p = plot(df.time_year, change,
    color = :blue,
    linewidth = 2,
    label = "Data",
    xlabel = "Year",
    ylabel = "Change in Mean Sea Level [mm]",
    title = "Sea Level with Linear & Parabolic Fits",
    grid = true,
    framestyle = :box
)

# Add linear fit
plot!(df.time_year, sealevelLin_mm .- sealevelLin_mm[1],
    color = :black,
    linewidth = 3,
    label = "Linear Fit"
)

# Add parabolic fit
plot!(df.time_year, sealevelPar_mm .- sealevelPar_mm[1],
    color = :red,
    linewidth = 2,
    linestyle = :dash,
    label = "Parabolic Fit"
)

display(p)

t = df.time_year
t0 = mean(t)
t_shift = t .- t0

a1, b1 = cf1
sealevelLin_mm = a1 .+ b1 .* t

a2, b2, c2 = cf2
sealevelPar_mm = a2 .+ b2 .* t .+ c2 .* t.^2

df.t_shift = df.time_year .- mean(df.time_year)

# Linear fit
model1 = lm(@formula(change ~ t_shift), df)
cf1 = coef(model1)

# Quadratic fit
model2 = lm(@formula(change ~ t_shift + t_shift^2), df)
cf2 = coef(model2)

t_shift = df.t_shift

# Linear
a1, b1 = cf1
sealevelLin_mm = a1 .+ b1 .* t_shift

# Parabolic
a2, b2, c2 = cf2
sealevelPar_mm = a2 .+ b2 .* t_shift .+ c2 .* t_shift.^2

function plot_with_fits_2100_R2(df)

    # -----------------------------
    # 1. Baseline-adjust data
    # -----------------------------
    baseline = df.sealevel_mm[1]
    df.change = df.sealevel_mm .- baseline

    # -----------------------------
    # 2. Center time
    # -----------------------------
    t0 = mean(df.time_year)
    df.t_shift = df.time_year .- t0

    # -----------------------------
    # 3. Linear fit
    # -----------------------------
    model1 = lm(@formula(change ~ t_shift), df)
    cf1 = coef(model1)
    r2_lin = r2(model1)  # R^2 for linear fit

    # -----------------------------
    # 4. Quadratic fit
    # -----------------------------
    model2 = lm(@formula(change ~ t_shift + t_shift^2), df)
    cf2 = coef(model2)
    r2_quad = r2(model2)  # R^2 for quadratic fit

    # -----------------------------
    # 5. Compute fitted curves
    # -----------------------------
    t = df.t_shift
    a1, b1 = cf1
    sealevelLin_mm = a1 .+ b1 .* t

    a2, b2, c2 = cf2
    sealevelPar_mm = a2 .+ b2 .* t .+ c2 .* t.^2

    # -----------------------------
    # 6. Predict for 2100
    # -----------------------------
    year2100_shift = 2100 - t0
    projLin = a1 + b1 * year2100_shift
    projPar = a2 + b2 * year2100_shift + c2 * year2100_shift^2

    println("Linear fit: 2100 = $(round(projLin,digits=1)) mm, R^2 = $(round(r2_lin,digits=3))")
    println("Quadratic fit: 2100 = $(round(projPar,digits=1)) mm, R^2 = $(round(r2_quad,digits=3))")

    # -----------------------------
    # 7. Plot everything with updated legend
    # -----------------------------
    p = plot(df.time_year, df.change,
        color = :blue,
        linewidth = 2,
        label = "Data",
        xlabel = "Year",
        ylabel = "Change in Mean Sea Level (mm)",
        title = "Sea Level with Linear & Quadratic Fits (Projected 2100)",
        grid = true,
        framestyle = :box
    )

    # Linear fit with 2100 projection and R^2 in label
    plot!(df.time_year, sealevelLin_mm,
        color = :black,
        linewidth = 3,
        label = "Linear Fit (2100: $(round(projLin,digits=1)) mm, R²=$(round(r2_lin,digits=3)))"
    )

    # Quadratic fit with 2100 projection and R^2 in label
    plot!(df.time_year, sealevelPar_mm,
        color = :red,
        linewidth = 2,
        linestyle = :dash,
        label = "Quadratic Fit (2100: $(round(projPar,digits=1)) mm, R²=$(round(r2_quad,digits=3)))"
    )

    return p
end

# Run it
p = plot_with_fits_2100_R2(df)
display(p)