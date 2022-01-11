
struct View{NI,NO,I} <: IndexTransform{NI,NO}
    indices::I

    global _View(::StaticInt{NI}, ::StaticInt{NO}, i::I) where {NI,NO,I} = new{NI,NO,I}(i)
end

View(i::Tuple) = _view(_flatten_indices(i))
_view(i::I) where {I} = _View(index_dimsum(I), index_outdimsum(I), i)


(v::View)(i::AbstractCartesianIndex) = v(Tuple(i))
(v::View)(i::Tuple{Vararg{Integer}}) = NDIndex(_subview(getfield(v, :indices), i))
@generated function _subview(subinds::SI, i::I) where {SI,I}
    out = Expr(:block, Expr(:meta, :inline))
    t = Expr(:tuple)
    itr = 1
    for sitr in 1:known_length(SI)
        SIType = SI.parameters[sitr]
        if SIType <: Union{Int,StaticInt}
            push!(t.args, :(@inbounds(getfield(subinds, $sitr))))
        else
            if eltype(SIType) <: AbstractCartesianIndex
                push!(t.args, :(Tuple(@inbounds(getfield(subinds, $sitr)[getfield(i, $itr)]))))
            else
                push!(t.args, :(@inbounds(getfield(subinds, $sitr)[getfield(i, $itr)])))
            end
            itr += 1
        end
    end
    push!(out.args, :(ArrayInterface._flatten_tuples($t)))
    out
end

function Base.show(io::IO, ::MIME"text/plain", @nospecialize(x::View))
    print(io, "View($(x.indices))")
end

