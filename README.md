# mod_coulcc

A modern Fortran wrapper for the **COULCC37** Coulomb / Bessel function routines.  
https://www.fresco.org.uk/functions/coulcc/index.htm

This project provides a clean, type-bound Fortran API around the original
`coulcc37.f90` implementation, with the goals of:

* encapsulating legacy routines in a modern module
* hiding internal implementation modules
* exposing a stable public interface (`mod_coulcc`)
* easy reuse as a standalone library or Git submodule


## Features

* Coulomb wave functions (regular / irregular)
* Bessel and modified Bessel functions
* Spherical Bessel functions
* Real and complex interfaces
* Generic type-bound procedures
* Internal implementation modules are hidden from users


## Repository structure

```
mod_coulcc/
├── src/
│   ├── coulcc37.f90 (original code)
│   └── mod_coulcc37.f90
├── tests/
│   ├── test_coulcc.f90
│   └── test_bessel.ipynb
└── Makefile
```


## Build

### Build everything

```bash
make
```

This creates:

```
build/
  lib/
    libcoulcc.a
    libcoulcc.so
  include/
    mod_coulcc.mod    (public module only)
```

### Build only static or shared library

```bash
make static
make shared
```


### Run tests

```bash
make run
```


## Installation (staging)

You can install the library and public module interface into a prefix directory:

```bash
make install PREFIX=/path/to/install
```

Result:

```
<prefix>/
  include/mod_coulcc.mod
  lib/libcoulcc.a
  lib/libcoulcc.so
```


## Using the library

### Compile

```bash
gfortran -I/path/to/install/include -c user_code.f90
```

### Link

```bash
gfortran user_code.o -L/path/to/install/lib -lcoulcc
```


## Example usage

```fortran
use mod_coulcc
use iso_fortran_env, only : real64

type(coulcc) :: cc
real(real64) :: x, y

x = 1.0_real64
y = cc%jv(0.0_real64, x)
```


## Design notes

### Public API

Only one module is intended for users:

```
mod_coulcc
```

Internal modules generated from the legacy implementation are intentionally hidden.


## Compiler compatibility

This project is regularly tested with:

* gfortran (GNU Fortran)

Other compilers may work but are not yet tested.


## Using as a Git submodule

This project is designed to be embedded as a dependency:

```bash
git submodule add <repo-url> external/mod_coulcc
```

Then build/install from the parent project:

```bash
make -C external/mod_coulcc install PREFIX=$(PWD)/external/install
```


## License

This repository follows the license terms of the original COULCC implementation.  
https://www.fresco.org.uk/functions/coulcc/index.htm

Permission is granted to use, copy, modify, and distribute the software under the terms included in `src/coulcc37.f90`. 
See LICENSE for full license text.

The wrapper code in this repository is distributed under the same terms.



## Acknowledgements

Original COULCC algorithms by:
* I.J. Thompson
* A.R. Barnett
