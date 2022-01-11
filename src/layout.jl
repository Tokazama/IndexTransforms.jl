
import Base.Broadcast: instantiate, materialize, materialize!

@inline layout(x, ::NOnes{N}) where {N} = _layout(x, buffer(x), CoordinateTransform{N}(x))
@inline function _layout(x::X, y::Y, t1::CoordinateTransform{NI,NO}) where {X,Y,NI,NO}
    b, t2 = layout(y, NOnes(static(NO)))
    return b, t2(t1)
end
# end recursion b/c no new buffer
_layout(x::X, y::X, t::ComposedTransform) where {X} = x, t
# no new buffer and unkown index transformation, s
_layout(x::X, y::X, ::UnkownTransform{N}) where {X,N} = x, IdentityTransform{N}()
# new buffer, but don't know how to transform indices properly
_layout(x::X, y::Y, ::UnkownTransform{N}) where {X,Y,N} = x, IdentityTransform{N}()

# TODO conversion to pointers
#=
tryptr(x::X) where {X} = tryptr(device(X), x)
tryptr(::CPUPointer, x) = LazyPreserve(x)
tryptr(::AbstractDevice, x) = PseudoPtr(x)  # TODO handle cartesian indexers
=#

# TODO layout
struct Layouted{B,I,T}
    buffer::B
    indices::I
    tform::T
end

@inline function instantiate(lyt::Layouted{B,I}) where {B,I}
    b, t = layout(getfield(lyt, :buffer), NOnes(index_dimsum(I)))
    return Layouted(tryptr(b), getfield(lyt, :indices), t)
end

@inline materialize(lyt::Layouted{B,I,Nothing}) where {B,I} = materialize(instantiate(lyt))
function materialize(lyt::Layouted{B,I,T}) where {B,I,T} end


