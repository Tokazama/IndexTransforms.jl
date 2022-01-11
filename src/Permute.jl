
"""
    Permute

Subtype of `IndexTransform` that permutes each index prior to accessing.
"""
struct Permute{P,I,NI,NO} <: IndexTransform{NI,NO}
    perm::P
    iperm::I

    function Permute(
        perm::Tuple{Vararg{CanonicalInt,NI}},
        iperm::Tuple{Vararg{CanonicalInt,NO}}
    ) where {NI,NO}
        new{typeof(perm),typeof(iperm),NI,NO}(perm, iperm)
    end
end

Base.invperm(x::Permute) = getfield(x, :iperm)
perm(x::Permute) = getfield(x, :perm)

const VecPermute = Permute{Tuple{StaticInt{2},StaticInt{1}},Tuple{StaticInt{1}},2,1}
const MatPermute = Permute{Tuple{StaticInt{2},StaticInt{1}},Tuple{StaticInt{2},StaticInt{1}},2,2}

@inline function (p::Permute{P,I})(x::Tuple{Vararg{Any}}) where {P,I}
    Static.permute(x, getfield(p, :perm))
end
(t::Permute)(i::AbstractCartesianIndex) = t(Tuple(i))
@inline function (t1::Permute{P1,I1})(t2::Permute{P2,I2}) where {P1,I1,P2,I2}
    Permute(Static.permute(perm(t2), perm(t1)), Static.permute(invperm(t2), invperm(t1)))
end

function Base.show(io::IO, ::MIME"text/plain", @nospecialize(x::Permute))
    print(io, "Permute(x.perm, x.iperm)")
end


