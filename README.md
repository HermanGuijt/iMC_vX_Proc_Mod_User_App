qtphy – PHYTEC's Qt6 Reference Implementation
================================================================================

[![Build status](https://github.com/phytec/qtphy/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/phytec/qtphy/actions/workflows/build.yml)

Building
--------------------------------------------------------------------------------

Build *qtphy* with the [Meson Build system](https://mesonbuild.com/):
```
meson setup build
meson compile -C build
```
After building, the resulting binary is located at `build/qtphy` and can be
directly executed.

Maintainers
--------------------------------------------------------------------------------

* Maintainer: Martin Schwan `m.schwan@phytec.de`
* Co-maintainer: Stefan Müller-Klieser `s.mueller-klieser@phytec.de`

License
--------------------------------------------------------------------------------

*qtphy* is licensed under the *MIT License*. See `LICENSE` for the full
terms and conditions.

Fonts located in `resources/fonts/` may have a different license. See the
respective file named `*.license`.
