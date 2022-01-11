
# TODO this should be reimplemented to work for nd to nd stuff like reshaped arrays
struct Reshape{I,O,S} <: IndexTransform{I,O}
    size::Size{S}

    Reshape(s::Size{S}) where {S} = new{1,known_length(S),S}(s)
end

function (r::Reshape{1,O,S})(i::CanonicalInt) where {I,O,S}
    _lin2sub(NOnes(static(O)), getfield(s, :size), i)
end
@generated function _lin2sub(o::O, s::S, i::I) where {O,S,I}
    out = Expr(:block, Expr(:meta, :inline))
    t = Expr(:tuple)
    iprev = :(i - 1)
    N = length(S.parameters)
    for i in 1:N
        if i === N
            push!(t.args, :($iprev + getfield(o, $i)))
        else
            len = gensym()
            inext = gensym()
            push!(out.args, :($len = getfield(s, $i)))
            push!(out.args, :($inext = div($iprev, $len)))
            push!(t.args, :($iprev - $len * $inext + getfield(o, $i)))
            iprev = inext
        end
    end
    push!(out.args, :(NDIndex($(t))))
    out
end

