# IndexTransforms

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/IndexTransforms.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/IndexTransforms.jl/dev)
[![Build Status](https://github.com/Tokazama/IndexTransforms.jl/workflows/CI/badge.svg)](https://github.com/Tokazama/IndexTransforms.jl/actions)


Experimental multistage indexing transformations before lowering code to IR or compiler optimizations.


Access to any collection of data can be represented in three stages:

1. Index transformation
2. Memory access
3. Transformation of accessed memory (in place or returned)

```
julia> A = [1 3; 2 4];

julia> A[2, 2]
4

julia> index_1, index_2 = (2, 2);

# step 1: transform to linear indexing
julia> index_0 = ((index_1 - 1) * 1) + ((index_2 - 1) * 2)

# step 2: access memory backing A
julia> ptr = pointer(A);  # step 2

# step 3: Offset memory access and load value 
julia> unsafe_load(ptr + index_0 * sizeof(eltype(ptr)))  # step 3
4

```


