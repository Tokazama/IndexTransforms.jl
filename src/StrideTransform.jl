
"""
    StrideTransform(x)

Subtype of `IndexTransform` that transforms and index using stride layout information
derived from `x`.
"""
struct StrideTransform{N,S,O} <: IndexTransform{N,1}
    strides::S
    offsets::O

    StrideTransform{N}(s::S, o::O) where {N,S<:Tuple,O<:Tuple} = new{N,S,O}(s, o)
    StrideTransform(s::CanonicalInt, o::CanonicalInt) = StrideTransform{1}((s,), (o,))
    function StrideTransform{N}(a::A) where {N,A}
        StrideTransform{N}(ArrayInterface.strides(a), offsets(a))
    end
    StrideTransform(a::A) where {A} = StrideTransform{ndims(A)}(a)
end

#const OffsetTransform{O} = StrideTransform{1,Tuple{Static{1}},Tuple{O}}
#OffsetTransform(o::CanonicalInt) = StrideTransform(static(1), o)

@generated function _strides2int(o::O, s::S, i::I) where {O,S,I}
    N = known_length(S)
    out = :()
    for i in 1:N
        tmp = :(((getfield(i, $i) - getfield(o, $i)) * getfield(s, $i)))
        out = ifelse(i === 1, tmp, :($out + $tmp))
    end
    return Expr(:block, Expr(:meta, :inline), out)
end
function (t::StrideTransform{N})(i::AbstractCartesianIndex{N}) where {N}
    _strides2int(getfield(t, :offsets), getfield(t, :strides), Tuple(i))
end

@inline function (t::StrideTransform{1})(i::CanonicalInt)
    (i - getfield(getfield(t, :offsets), 1)) * getfield(getfield(t, :strides), 1)
end
@inline function (t::StrideTransform{1})(i::AbstractRange{Int})
    t(static_first(i)):t(static_step(i)):t(static_last(i))
end

(t::StrideTransform{1})(i::AbstractVector{Int}) = TransformedIndex(i, t)

function (t::StrideTransform{N})(i::AbstractArray{T}) where {N,T<:AbstractCartesianIndex{N}}
    TransformedIndex(i, t)
end

struct ReduceTransform{I,F} <: CoordinateTransform{I,1}
    f::F
end

(t::ReduceTransform{I,F})(x::AbstractCartesianIndex) where {I,F} = t(Tuple(x))
@inline (t::ReduceTransform{I,F})(x::Tuple) where {I,F} = Static.reduce_tup(getfield(t, :f), x)

function ReduceTransform(f::F, t::CoordinateTransform{<:Any,O}) where {F,O}
    ComposedTransform(ReduceTransform{O,F}(f), t)
end
function Base.show(io::IO, ::MIME"text/plain", @nospecialize(x::StrideTransform))
    print(io, "StrideTransform{$(ndims(x))}($(strides(x)), $(offsets(x)))")
end

