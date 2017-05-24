The hol package
===============

The [hol package][] implements a higher order logic kernel as a [Haskell][] library. It can read proof files in [OpenTheory][] format, and includes a pretty-printer compatible with the [standard theory library][].

This software is released under the [MIT License][].

Install
-------

Installing the hol package requires [cabal][]:

    git clone https://github.com/gilith/hol.git
    cd hol
    cabal install .

Test
----

First use the [opentheory tool] to create a test file:

    opentheory info --article -o base.art base

Then use [cabal][] to run the test suite:

    cabal test hol-test

Profile
-------

Before starting, make sure we have the relevant GHC libraries installed with profiling support. On a Debian system they are installed like so:

     apt-get install ghc-prof libghc-text-prof libghc-transformers-prof

Next use [cabal][] to install the dependent libraries with profiling support:

    cabal sandbox init
    cabal install --only-dependencies --enable-library-profiling
    cabal install --enable-library-profiling --enable-executable-profiling .

Use the [opentheory tool] to create a benchmark file:

     opentheory info --article -o base.art base

Then use [cabal][] to run the benchmark:

    cabal bench hol-profile

The time and memory allocation profile of the program can be viewed in text format:

    less hol-profile.prof

Alternatively the memory allocation profile can be viewed as a graph:

    hp2ps -e8in -c hol-profile.hp
    ps2pdf hol-profile.ps
    xpdf hol-profile.pdf

[cabal]: https://www.haskell.org/cabal/ "Cabal"
[Haskell]: https://www.haskell.org/
[hol package]: https://hackage.haskell.org/package/hol "hol package"
[MIT License]: https://github.com/gilith/hol/blob/master/LICENSE "MIT License"
[OpenTheory]: http://www.gilith.com/research/opentheory/ "The OpenTheory project home page"
[opentheory tool]: http://www.gilith.com/software/opentheory/ "The opentheory tool"
[standard theory library]: http://opentheory.gilith.com/?pkg=base "The OpenTheory standard theory library"
