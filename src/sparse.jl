
""" SparseIndex """
struct SparseIndex{B<:BoolType,I}
    issparse::B
    index::I
end

@inline function unsafe_getvalue(x, i::SparseIndex{Bool})
    if getfield(i, :issparse)
        return zero(eltype(x))
    else
        return unsafe_getvalue(x, getfield(i, :index))
    end
end

"""
    SparseLinear{T}(nonzeros::Vector{T})

Transforms to sparsely populated linear space.
"""
struct SparseLinear{T<:Integer} <: CoordinateTransform{1,1}
    nonzeros::Vector{T}

    SparseLinear(x::AbstractSparseVector{<:Any,T}) where {T} = new{T}(nonzeros(x))
end

SparseArrays.nonzeros(x::SparseLinear) = getfield(x, :nonzeros)
SparseArrays.nnz(x::SparseLinear) = length(nonzeros(x))

@inline function (t::SparseLinear{T})(i::CanonicalInt) where {T}
    nzind = nonzeros(t)
    ii = searchsortedfirst(nzind, convert(T, i))
    if ii <= length(nzind) && (nzind[ii] == i)
        return SparseIndex(false, @inbounds(nzval[ii]))
    else
        return SparseIndex(true, ii)
    end
end

"""
    CompactSparseColumn{T}(colptr::Vector{T}, rowval::Vector{T})

Transforms two dimensional coordinates to linearly stored values, representing a compact
sparse column matrix.
"""
struct CompactSparseColumn{T<:Integer} <: CoordinateTransform{2,1}
    colptr::Vector{T}      # Column i is in colptr[i]:(colptr[i+1]-1)
    rowval::Vector{T}      # Row indices of stored values

    global function _CompactSparseColumn(m::Int, n::Int, c::Vector{T}, r::Vector{T}) where {T}
        new{T}(m, n, c, r)
    end
    CompactSparseColumn{T}() where {T} = new{T}(T[1], T[])
    function CompactSparseColumn{T}(n::Integer) where {T}
        (n < 0) && throw(ArgumentError("size of SquareCompactSparseColumn cannot be negative"))
        return new{T}(fill(one(T), n + 1), T[], m)
    end
    function CompactSparseColumn{T}(c::Vector{T}, r::Vector{T}) where {T}
        if 0 ≤ n && (!isbitstype(Ti) || n ≤ typemax(Ti))
            throw(ArgumentError("number of columns (c = $n) does not fit in eltype = $(T)"))
        end
        if !((c[end] - 1) === length(r))
            throw(ArgumentError("Illegal buffers for AdjacencyMap construction $n $colptr $rowval $nzval"))
        end
        return new{T}(c, r)
    end
    function CompactSparseColumn(x::AbstractSparseMatrixCSC{Tv,Ti}) where {Tv,Ti}
        n, m = size(x)
        n === m || throw(ArgumentError("cannot derive SquareCompactSparseColumn from a matrix with unequal rows and columns"))
        return new{Ti}(copy(getcolptr(x)), copy(rowvals(x)))
    end
end

SparseArrays.getcolptr(x::CompactSparseColumn) = getfield(x, :colptr)
SparseArrays.rowvals(x::CompactSparseColumn) = getfield(x, :rowval)
SparseArrays.nnz(x::CompactSparseColumn) = Int(getcolptr(x)[end]) - 1

@inline function (t::CompactSparseColumn)(index::AbstractCartesianIndex{2})
    i0, i1 = Tuple(index)
    r1 = Int(@inbounds(getcolptr(t)[i1]))
    r2 = Int(@inbounds(getcolptr(t)[i1+1])-1)
    if r1 > r2
        return SparseIndex(true, r1)
    else
        r1 = searchsortedfirst(rowvals(t), i0, r1, r2, Base.Forward)
        if ((r1 > r2) || (@inbounds(rowvals(t)[r1]) != i0))
            return SparseIndex(true, r1)
        else
            return SparseIndex(false, r1)
        end
    end
end


