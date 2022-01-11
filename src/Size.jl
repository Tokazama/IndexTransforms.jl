
"""
    Size(s::Tuple{Vararg{Union{Int,StaticInt}})
    Size(A) -> Size(size(A))

Type that represents statically sized dimensions as `StaticInt`s.
"""
struct Size{S<:Tuple}
    size::S

    Size{S}(s::Tuple{Vararg{<:CanonicalInt}}) where {S} = new{S}(s::S)
    Size(s::Tuple{Vararg{<:CanonicalInt}}) = Size{typeof(S)}(s)
end

Base.ndims(::Size{S}) where {S} = known_length(S)
Base.ndims(::Type{<:Size{S}}) where {S} = known_length(S)
Base.size(s::Size{Tuple{Vararg{Int}}}) = getfield(s, :size)
Base.size(s::Size) = map(Int, s.size)
function Base.size(s::Size{S}, dim::CanonicalInt) where {S}
    if dim > known_length(S)
        return 1
    else
        return Int(getfield(s.size, Int(dim)))
    end
end

@inline Size(A) = Size(_size(A, Val(known_size(A))))
@generated function _size(A, ::Val{S}) where {S}
    t = Expr(:tuple)
    for i in 1:length(S)
        si = S[i]
        if si === missing
            push!(t.args, :(Base.size(A, $i)))
        else
            push!(t.args, :($(static(si))))
        end
    end
    Expr(:block, Expr(:meta, :inline), t)
end
Size(x, dim) = _Length(x, to_dims(x, dim))
@inline function _Length(x, dim::Union{Int,StaticInt})
    sz = known_size(x, dim)
    if sz === missing
        return Length(Base.size(x, dim))
    else
        return Length(static(sz))
    end
end
Base.:(==)(x::Size, y::Size) = getfield(x, :size) == getfield(y, :size)

## Length
"""
    Length(x::Union{Int,StaticInt})
    Length(A) = Length(length(A))

Type that represents statically sized dimensions as `StaticInt`s.
"""
const Length{L} = Size{Tuple{L}}
Length(x::CanonicalInt) = Size((x,))
@inline function Length(x)
    len = known_length(x)
    if len === missing
        return Length(length(x))
    else
        return Length(static(len))
    end
end

ArrayInterface.known_size(::Type{<:Size{S}}) where {S} = known(S)
