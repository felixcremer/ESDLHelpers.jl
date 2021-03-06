"""
timestats(cube, )

Compute the multi temporal statistics of a cube with temporal axis and return a cube with an `Stats` axis.
"""
function timestats(cube;kwargs...)

    indims = InDims("Time")
    funcs = ["Mean", "5th Quantile", "25th Quantile", "Median", "75th Quantile", "95th Quantile",
            "Standard Deviation", "Minimum", "Maximum",
            "Skewness", "Kurtosis", "Median Absolute Deviation"]

    stataxis = CategoricalAxis("Stats", funcs)
    od = OutDims(stataxis)
    stats = mapCube(ctimestats!, cube, indims=indims, outdims=od, kwargs...)
end

function ctimestats!(xout, xin)
    ts = collect(skipmissing(xin))
    m = mean(ts)
    T = eltype(m)
    stats = Vector{T}(undef,12)
    stats[1] = m
    stats[2:6] = quantile(ts, [0.05,0.25,0.5, 0.75,0.95])
    stats[7] = std(ts)
    stats[8] = minimum(ts)
    stats[9] = maximum(ts)
    stats[10] = skewness(ts)
    stats[11] = kurtosis(ts)
    stats[12] = mad(ts, normalize=true)
    xout .=stats
end

function decompose(cube, num_imfs=6)
    indims = InDims("Time")
    imfax = CategoricalAxis("IntrinsicModeFunctions", [(Ref("IMF ") .* string.(1:num_imfs))..., "Residual"])
    @show imfax
    @show length(imfax)
    timeax = ESDL.getAxis("Time", cube)
    od = OutDims(imfax, timeax)

    dateint = intify(cube)
    mapCube(cubeemd!, cube, dateint, num_imfs,  indims=indims, outdims=od)
end

function rqats(cube::YAXArrays.Cubes.YAXArray, dist=1)
    indims = InDims("Time")
    r = rqa(RecurrenceMatrix(rand(10), 1))
    rqanames = string.(keys(r))
    @show rqanames
    rqaaxis = CategoricalAxis("RQA Metrics", collect(rqanames))
    @show rqaaxis
    od = OutDims(rqaaxis)
    @show dist
    @show od
    mapCube(crqa!, cube, indims=indims, outdims=od)
end



function crqa!(xout, xin)
    ts = collect(skipmissing(xin))
    rp = RecurrenceMatrix(ts, 1)
    xout .= values(rqa(rp))
end


function cubeemd!(xout, xin, times, num_imfs)
    ts = collect(skipmissing(xin))
    ind = .!ismissing.(xin)
    dateint = times[ind]
    @show size(xout)
    imfs = EMD.ceemd(ts, dateint, num_imfs=num_imfs)
    @show length(imfs)
    for i in 1:length(imfs)
    
        xout[i,:] .= imfs[i]
    end
end

function lombscargle(cube, kwargs...)
    indims = InDims("Time")
    lombax = CategoricalAxis("LombScargle", ["Number of Frequencies", "Period with maximal power", "Maximal Power"])
    @show cube
    dateint = intify(cube)
    od = OutDims(lombax)
    mapCube(clombscargle, cube, dateint, indims=indims, outdims=od)
end

function clombscargle(xout, xin, times)
    ind = .!ismissing.(xin)
    ts = collect(nonmissingtype(eltype(xin)), xin[ind])
    dateint = times[ind]
    if length(ts) < 10
        @show length(ts)
        xout .= missing
        return
    end
    pl = LombScargle.plan(dateint, ts)
    #@show pl
    pgram = LombScargle.lombscargle(pl)
    lsperiod= findmaxperiod(pgram)
    lspower = findmaxpower(pgram)
    lsnum = LombScargle.M(pgram)
    #@show lsperiod, lspower
    #@show findmaxfreq(pgram), findmaxpower(pgram)
    xout .= [lsnum, lsperiod[1], lspower]
end

function ctslength(xin)
    ind = .!ismissing.(xin)
    return count(ind)
end

tslength(cube) = mapslices(ctslength, cube, dims="Time")

function intify(cube)
    timeax = ESDL.getAxis("Time", cube)
    x = timeax.values
    datediff = Date.(x) .- Date(x[1])
    dateint = getproperty.(datediff, :value)
end