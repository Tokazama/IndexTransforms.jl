
""" TransformedIndex """
struct TransformedIndex{T,I,F} <: AbstractArray{T,1}
    index::I
    tform::F

    function TransformedIndex(index::AbstractRange{Int}, tform::CoordinateTransform{<:Any,NO}) where {NO}
        @assert !isempty(index)
        if NO === 1
            return new{Int,typeof(index),typeof(tform)}(index, tform)
        else
            return new{CartesianIndex{NO},typeof(index),typeof(tform)}(index, tform)
        end
    end
end

Base.length(x::TransformedIndex) = length(getfield(x, :index))

ArrayInterface.known_size(::Type{<:TransformedIndex{I}}) where {I} = known_size(I)

Base.IteratorSize(::Type{<:TransformedIndex}) = Base.HasLength()

@propagate_inbounds function Base.getindex(x::TransformedIndex, i::Vararg{Any})
    getfield(x, :tform)(getfield(x, :index)[i...])
end
@inline function Base.nextind(x::TransformedIndex{I,F}, state::Int) where {I,F}
    if known_step(I) === missing
        return state + step(getfield(x, :index))
    else
        return state + known_step(I)
    end
end
@inline function Base.isdone(x::TransformedIndex{I,F}, state::Int) where {I,F}
    if known_last(I) === missing
        return state === last(getfield(x, :index))
    else
        return state === known_last(I)
    end
end

@inline function Base.iterate(x::TransformedIndex{I}) where {I}
    if known_first(I) === missing
        state = first(getfield(x, :index))
    else
        state = known_first(I)
    end
    return getfield(x, :tform)(state), state
end

@inline function Base.iterate(x::TransformedIndex, state::Int)
    if isdone(x, state)
        return nothing
    else
        newstate = nextind(x, state)
        return getfield(x, :tform)(newstate), newstate
    end
end

""" GetIndex """
struct GetIndex{inbounds,X,NI,NO} <: CoordinateTransform{NI,NO}
    x::X

    function GetIndex{inbounds}(a::A) where {inbounds,A}
        new{inbounds::Bool,A,ndims(A),dynamic(ndims_index(A))}(A)
    end
end

(t::GetIndex{true})(i) = @inbounds(getfield(t, :x)[i])
function (t::GetIndex{false})(i)
    data = getfield(t, :x)
    @boundscheck checkbounds(data, i)
    return @inbounds(data[i])
end

""" TransformedIndices """
struct TransformedIndices{T,N,I,F} <: AbstractArray{T,N}
    indices::I
    tform::F
end


""" reindex """
reindex(x::AbstractRange) = x
@inline function reindex(x::AbstractArray{T,N}) where {T,N}
    if N === 1
        return TransformedIndex(ArrayInterface.indices(x), GetIndex{true}(x))
    else
        return x
    end
end
reindex(x::Integer) = Int(x)
reindex(x::StaticInt) = x



