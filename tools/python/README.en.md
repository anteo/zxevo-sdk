# Python tool environments

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

`environment.py` prepares private dependencies for command-line tools in this repository. Users run
the tool or `make` normally; they do not activate a venv or pass its interpreter path. Python 3.11+
with `venv`/`ensurepip` is required. First-time setup needs access to the packages through pip's
configured index or cache. Nothing is installed into the system Python environment.

## Using it in a tool

Keep dependencies in a requirements file next to the tool. After parsing command arguments, but
before importing third-party modules, call:

```python
from pathlib import Path
from tools.python.environment import ensure_environment

ensure_environment(Path(__file__).with_name("requirements.txt"))

# Import third-party modules and run the command here.
```

Keep this call in the CLI entry point, not at module import time or inside library functions.
Parsing first allows `--help` to exit without installation. Commands using only the standard library
should skip it. Catch `ValueError` in the CLI and report it with `parser.exit(1, f"{error}\n")` if a
concise diagnostic is desired.

For `python3 -m tools.some_tool.main` from the SDK root, `tools` is already importable. A directly
executed `tools/some_tool/main.py` can add the repository root first:

```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
```

An explicit cache directory is optional:

```python
ensure_environment(requirements_path, directory=cache_path)
```

## Lifecycle

- The default is `build/python-<requirements stem>` beside the requirements file. For
  `tools/assets/requirements.txt`, this is `tools/assets/build/python-requirements`.
- The helper creates the environment and runs its Python with `-m pip install -r`. The pip working
  directory is the requirements file's directory; normal pip index and proxy settings apply. The
  tool's own working directory remains unchanged.
- A stamp records the supplied file's content hash, Python runtime and environment location.
  Unchanged subsequent runs reuse the environment without invoking pip. Updating the supplied
  requirements file or Python runtime triggers setup again. This stamp is not a dependency lockfile;
  pin versions in requirements when needed.
- Setup is locked per environment, including between separate `make` processes. A failed
  installation leaves no successful stamp and is retried on the next run.
- The current entry point is restarted with the prepared interpreter, preserving arguments and
  working directory, including `python -m` invocation. The restarted process continues without
  running setup again. Call before any side effects.
- Setup output goes to stderr. Generated tool output remains on stdout.

The cache is disposable build output, ignored by Git. Remove the environment directory while no tool
is using it to force complete recreation. Environments are not automatically pruned when a package
is removed from requirements.

[Asset converter](../assets/README.en.md) and both evosdk resource recipes use this module.
