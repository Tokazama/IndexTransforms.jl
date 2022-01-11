
"""
    LinearView(offset, stride)

Subtype of `IndexTransform` that provides linear indexing for `Base.FastSubArray` and
`FastContiguousSubArray`.
"""
struct LinearView{O<:CanonicalInt,S<:CanonicalInt} <: IndexTransform{1,1}
    offset::O
    stride::S
end

const Offset{O} = LinearView{O,StaticInt{1}}
Offset(o::CanonicalInt) = LinearView(o, static(1))

(t::LinearView)(x::CanonicalInt) = getfield(t, :offset) + getfield(t, :stride) * x
@inline function (t::LinearView)(x::AbstractRange{Int})
    t(static_first(i)):t(static_step(i)):t(static_last(i))
end
@inline function (t::LinearView)(x::AbstractArray{Int})
    TransformedIndex{Int,ndims(i),typeof(i),typeof(t)}(i, t)
end
@inline function (t1::LinearView)(t2::LinearView)
    LinearView(
        getfield(t2, :offset) + getfield(t1, :offset) * getfield(t2, :stride),
        getfield(t1, :stride) * getfield(t2, :stride)
    )
end

function Base.show(io::IO, ::MIME"text/plain", @nospecialize(x::LinearView))
    if static(1) === x.stride
        print(io, "Offset($(x.offset))")
    else
        print(io, "LinearView(offset=$(x.offset), stride=$(x.stride))")
    end
end

