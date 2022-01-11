

NOnes{N} = NTuple{N,StaticInt{1}}
@inline NOnes(::StaticInt{N}) where {N} = ntuple(Returns(static(1)), Val(N))

@generated function _flatten_indices(inds::I) where {I}
    out = Expr(:block, Expr(:meta, :inline))
    t = Expr(:tuple)
    any_flattened = false
    for i in known_length(I)
        if I.parameters[i] <: AbstractCartesianIndex
            isym = gensym(i)
            push!(out.args, :(@inbounds(Tuple(getfield(inds, $i)))))
            for j in known_length(I.parameters[i])
                push!(t.args, :(@inbounds(getfield($isym, $i))))
            end
            any_flattened = true
        elseif I.parameters[i] <:  CartesianIndices
            isym = gensym(i)
            push!(out.args, :(@inbounds(axes(getfield(inds, $i)))))
            for j in known_length(I.parameters[i])
                push!(t.args, :(@inbounds(getfield($isym, $i))))
            end
            any_flattened = true
        else
            push!(t.args, :(@inbounds(getfield(inds, $i))))
        end
    end
    push!(out.args, t)
    if any_flattened
        return out
    else
        return :inds
    end
end

const SymbolType = Union{Symbol,StaticSymbol}
const BoolType = Union{Bool,True,False}

const DynamicField = Union{Symbol,Int}
const StaticField{F} = Union{StaticSymbol{F},StaticInt{F}}

@inline get_field(x::X, f::DynamicField) where {X} = getfield(x, f)
@inline function get_field(x::X, f::StaticField{F}) where {X,F}
    out = known(field_type(X, f))
    if out === missing
        return getfield(x, F)
    else
        return static(known(field_type(X, f)))
    end
end
const Field{X} = Base.Fix2{typeof(get_field),X}
Field(f) = Base.Fix2(get_field, f)


_check_uplo(::StaticSymbol{S}) where {S} = _check_uplo(S)
function _check_uplo(uplo::Symbol)
    if uplo === :U || uplo === :L || uplo === :L
        return nothing
    else
        throw(ArgumentError("uplo argument must be :U (upper), :L (lower), or :D (diagonal)."))
    end
end

