
"""
    ComposedTransform(outer, inner)

A subtype of `CoordinateTransform` that lazily combines index `outer` and `inner`. Indexing a
`ComposedTransform` whith `i` is equivalent to `outer[inner[i]]`.
"""
struct ComposedTransform{NI,NO,O,I} <: CoordinateTransform{NI,NO}
    outer::O
    inner::I

    function ComposedTransform(o::CoordinateTransform{O,N}, i::CoordinateTransform{N,I}) where {O,N,I}
        @assert !(i isa ComposedTransform) 
        new{O,I,typeof(o),typeof(i)}(o, i)
    end
end

@inline (t::ComposedTransform)(x) = getfield(t, :outer)(getfield(t, :inner)(x))

function Base.show(io::IO, m::MIME"text/plain", @nospecialize(x::ComposedTransform))
    show(io, m, x.outer)
    print(io, " ∘ ")
    show(io, m, x.inner)
end

@inline (t::CoordinateTransform)(::IdentityTransform) = t
@inline (t1::CoordinateTransform)(t2::CoordinateTransform) = ComposedTransform(t2, t1)

@inline function (t1::VecPermute)(t2::StrideTransform{1})
    s = getfield(getfield(t1, :strides), 1)
    StrideTransform((s, s), (static(1), getfield(getfield(t1, :offsets), 1)))
end

@inline function (t2::Permute{I1,I2,N})(t1::StrideTransform{N}) where {N,I1,I2}
    StrideTransform{N}(t2(getfield(x, :strides)), t2(getfield(x, :offsets)))
end

function (v::View{NI,NO,I})(t::StrideTransform{NO,S,O}) where {NI,NO,I,S,O}
    _combined_sub_strides(ArrayInterface.stride_preserving_index(I), t, v)
end

@inline function _combined_sub_strides(::False, t::StrideTransform, v::View{NI,NO,I}) where {NI,NO,I}
    __map_strides(View(_map_strides(
        Static.eachop(ArrayInterface._ndims_index, Static.nstatic(Val(known_length(I))), I),
        getfield(v, :indices),
        getfield(t, :strides),
        getfield(t, :offsets)
        )))
end
@inline function __map_strides(v::View{<:Any,O}) where {O}
    ComposedTransform(ComposedTransform(Offset(static(1)), ReduceTransform{O,typeof(+)}(+)), v)
end
@generated function _map_strides(::NDimsIndex, inds::I, s::S, o::O) where {NDimsIndex,I,S,O}
    t = Expr(:tuple)
    dim = 0
    ndi = known(NDimsIndex)
    for i in 1:length(ndi)
        indsexpr = :(@inbounds(getfield(inds, $i)))
        stride_expr = Expr(:tuple)
        offset_expr = Expr(:tuple)
        for j in 1:ndi[i]
            dim += 1
            push!(stride_expr.args, :(@inbounds(getfield(s, $dim))))
            push!(offset_expr.args, :(@inbounds(getfield(o, $dim))))
        end
        push!(t.args, :(StrideTransform($stride_expr, $offset_expr)($indsexpr)))
    end
    Expr(:block, Expr(:meta, :inline), t)
end
@inline function _combined_sub_strides(::True,
    x::StrideTransform{NO,S,O},
    i::View{NI,NO,I}
) where {NI,NO,S,O,I}
    pdims = ArrayInterface._to_sub_dims(I)
    o = getfield(x, :offsets)
    s = getfield(x, :strides)
    inds = getfield(i, :indices)
    out = StrideTransform(
        eachop(getmul, pdims, map(maybe_static_step, inds), s),
        Static.permute(o, pdims)
    )
    ComposedTransform(Offset(Static.reduce_tup(+, map(*, map(_diff, inds, o), s))), out)
end
getmul(x::Tuple, y::Tuple, ::StaticInt{i}) where {i} = getfield(x, i) * getfield(y, i)
@inline _diff(::Base.Slice, ::Any) = Zero()
@inline _diff(x::AbstractRange, o) = static_first(x) - o
@inline _diff(x::Integer, o) = x - o


