# mhmt

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

This directory contains the unchanged MeHruMsT (`mhmt`) host compressor source by lvd^nedopc. The
same source is distributed in NedooS with the [GPLv3 license](LICENSE); the license is kept with
this copy.

Build it with `make -C tools/mhmt`. The executable is `tools/mhmt/build/mhmt`. Building the SDK's
appmake also builds this executable automatically. Appmake invokes it as a separate process for SPG
MegaLZ/Hrust compression; the two programs are not linked together. Other host tools may invoke the
executable directly or depend on its Make target.

See [appmake](../appmake/README.en.md) for the SPG options.
