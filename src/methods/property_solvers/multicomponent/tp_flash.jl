"""
    TPFlashMethod

Abstract type for `tp_flash` routines. it requires defining `numphases(method)` and `tp_flash_impl(model,p,T,n,method)`.

"""
abstract type TPFlashMethod end

"""
    tp_flash(model, p, T, n, method::TPFlashMethod =DETPFlash())

Routine to solve non-reactive multicomponent flash problem.
The default method uses Global Optimization. see [DETPFlash](@ref)

Inputs: 
 - T, Temperature
 - p, Pressure
 - n, vector of number of moles of each species

Outputs - Tuple containing: 
 - xᵢⱼ, Array of mole fractions of species j in phase i
 - nᵢⱼ, Array of mole numbers of species j in phase i, [mol]
 - G, Gibbs Free Energy of Equilibrium Mixture [J]
"""
function tp_flash end

"""
    numphases(method::TPFlashMethod)

return the number of phases supported by the TP flash method. by default its set to 2.
it the method allows it, you can set the number of phases by doing `method(;numphases = n)`.
"""
numphases(method::TPFlashMethod) = 2

#default
include("tp_flash/DifferentialEvolutiontp_flash.jl")
include("tp_flash/RachfordRicetp_flash.jl")

function expand_matrix(x,idr,numspecies)
    numspecies == length(idr) && return x
    numphases,_ = size(x)
    res = zeros(eltype(x),numphases, numspecies)
    for (jj,j) ∈ pairs(idr)
        for i in 1:numphases
            res[i,j] = x[i,jj]
        end
    end
    return res
end
function tp_flash(model::EoSModel, p, T, n,method::TPFlashMethod = DETPFlash())
    numspecies = length(model)
    if numspecies != length(n)
        error("There are ", numspecies,
            " species in the model, but the number of mole numbers specified is ", 
            length(n))
    end

    model_r,idx_r = index_reduction(model,n)
    n_r = n[idx_r]
    if length(model_r) == 1
        V = volume(model_r,p,T,n_r)
        return (n, n / sum(n), VT_gibbs_free_energy(model_r, V, T, n_r))
    end

    if numphases(method) == 1
        V = volume(model_r,p,T,n_r,phase =:stable)
        return (n, n / sum(n), VT_gibbs_free_energy(model_r, V, T, n_r))
    end
    
    xij_r,nij_r,g = tp_flash_impl(model_r,p,T,n_r,index_reduction(method,idx_r))
    #TODO: perform stability check ritht here:
    #expand reduced model:
    nij = expand_matrix(nij_r,idx_r,numspecies)
    xij = expand_matrix(xij_r,idx_r,numspecies)
    return xij,nij,g
end

export tp_flash
