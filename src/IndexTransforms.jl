module IndexTransforms

using ArrayInterface
using ArrayInterface: offsets, offset1, known_length, known_offsets, known_size, buffer,
    known_step, ndims_index, static_first, static_step, static_last, device
using ArrayInterface: OptionallyStaticUnitRange, OptionallyStaticStepRange, OptionallyStaticRange,
    CanonicalInt, AbstractDevice, AbstractCPU, CPUPointer 
using LinearAlgebra
using SparseArrays
using SparseArrays: getcolptr, AbstractSparseMatrixCSC
using Static

using Base: @propagate_inbounds, AbstractCartesianIndex, Fix2, isdone, ReshapedArray, Generator

abstract type CoordinateTransform{I,O} end

abstract type IndexTransform{I,O} <: CoordinateTransform{I,O} end

"""
    UnkownTransform{N}

Represents an unkown transform that throws an error when called.
"""
struct UnkownTransform{N} <: CoordinateTransform{N,N} end

(::UnkownTransform)(x) = error("Attempt to execute an unkown transform.")

"""
    IdentityTransform

Returns the input unchanged.
"""
struct IdentityTransform{N} <: CoordinateTransform{N,N} end

(::IdentityTransform)(x) = x

include("utils.jl")
include("Size.jl")
include("TransformedIndex.jl")
include("Permute.jl")
include("StrideTransform.jl")
include("LinearView.jl")
include("View.jl")
include("Reshape.jl")
include("sparse.jl")
include("ComposedTransform.jl")

@inline function _to_linear(x)
    StrideTransform(ArrayInterface.size_to_strides(ArrayInterface.size(x), static(1)), offsets(x))
end

@inline _to_cartesian(x) = reshape(Size(x))

## constructors
CoordinateTransform{N}(x) where {N} = UnkownTransform{N}()
CoordinateTransform{1}(::DenseArray{<:Any,1}) = IdentityTransform{1}()
CoordinateTransform{1}(::DenseArray{<:Any,N}) where {N} = IdentityTransform{1}()
CoordinateTransform{N}(A::DenseArray{<:Any,N}) where {N} = StrideTransform(A)

CoordinateTransform{2}(::Diagonal) = Permute{(1,1),(1,)}()

CoordinateTransform{2}(x::SparseArrays.AbstractSparseMatrixCSC) = CompactSparseColumn(x)
CoordinateTransform{2}(x::AbstractSparseVector) = SparseLinear(x)

CoordinateTransform{1}(x::ReshapedArray) = IdentityTransform{1}()
CoordinateTransform{N}(x::ReshapedArray) where {N} = _to_linear(x)

# TODO should we only define index constructors for explicit types?
CoordinateTransform{1}(x::AbstractRange) = OffsetTransform(offset1(x) - static(1))

## SubArray
CoordinateTransform{N}(x::SubArray{<:Any,N}) where {N} = View(getfield(x, :indices))
@inline function CoordinateTransform{1}(x::SubArray{T,N}) where {T,N}
    if N === 1
        return View(getfield(x, :indices))
    else
        return ComposedTransform(View(getfield(x, :indices)), _to_cartesian(x))
    end
end
CoordinateTransform{1}(x::Base.FastContiguousSubArray) = LinearView(getfield(x, :offset1), static(1))
CoordinateTransform{1}(x::Base.FastSubArray) = LinearView(getfield(x, :offset1), getfield(x, :stride1))

## PermutedDimsArray
CoordinateTransform{1}(::PermutedDimsArray{<:Any,1,(1,),(1,)}) = IdentityTransform{1}()
@inline CoordinateTransform{N}(::PermutedDimsArray{<:Any,N,perm,iperm}) where {N,perm,iperm} = Permute(static(perm), static(iperm))
function CoordinateTransform{1}(x::PermutedDimsArray{<:Any,N,perm,iperm}) where {N,perm,iperm}
    ComposedTransform(CoordinateTransform{N}(x), _to_cartesian(x))
end

## Transpose/Adjoint{Real}
CoordinateTransform{1}(::Transpose{<:Any,<:AbstractVector{<:Any}}) = IdentityTransform{1}()
CoordinateTransform{2}(::Transpose{<:Any,<:AbstractVector{<:Any}}) = Permute((static(2), static(1)), (static(2),))
CoordinateTransform{2}(::Transpose{<:Any,<:AbstractMatrix{<:Any}}) = Permute((static(2), static(1)), (static(2), static(1)))
function CoordinateTransform{1}(x::Transpose{<:Any,<:AbstractMatrix{<:Any}})
    ComposedTransform(Permute((static(2), static(1)), (static(2), static(1))), _to_cartesian(x))
end
CoordinateTransform{1}(::Adjoint{<:Real,<:AbstractVector{<:Real}}) = IdentityTransform{1}()
CoordinateTransform{2}(::Adjoint{<:Real,<:AbstractVector{<:Real}}) = Permute((static(2), static(1)), (static(2),))
CoordinateTransform{2}(::Adjoint{<:Real,<:AbstractMatrix{<:Real}}) = Permute((static(2), static(1)), (static(2), static(1)))
function CoordinateTransform{1}(x::Adjoint{<:Real,<:AbstractMatrix{<:Real}})
    ComposedTransform(Permute((static(2), static(1)), (static(2), static(1))), _to_cartesian(x))
end

include("layout.jl")


end
