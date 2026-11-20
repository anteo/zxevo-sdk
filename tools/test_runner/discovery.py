"""Discover SDK test suites and their machine-specific profiles."""

import re
import tomllib

from .support import ROOT, FrameworkError
from .suites.baseconf import BaseConfSuite
from .suites.tsconf import TSConfSuite


ADAPTERS = {
    "baseconf": BaseConfSuite,
    "tsconf": TSConfSuite,
}


def discover_suites(root=ROOT / "lib"):
    """Read suite.toml manifests next to each suite's cases directory."""
    suites = {}
    for manifest in sorted(root.rglob("suite.toml")):
        if "build" in manifest.relative_to(root).parts:
            continue
        with manifest.open("rb") as stream:
            config = tomllib.load(stream)
        name = config.get("name")
        if (not isinstance(name, str) or not re.fullmatch(r"[a-z][a-z0-9_-]*", name)
                or name in {"all", "asm"}):
            raise FrameworkError(f"{manifest}: invalid suite name {name!r}")
        if name in suites:
            raise FrameworkError(f"{manifest}: duplicate suite name {name!r}")
        targets = config.get("targets")
        if not isinstance(targets, list) or not targets:
            raise FrameworkError(f"{manifest}: expected at least one [[targets]] entry")

        tests = manifest.parent
        if not (tests / "cases").is_dir():
            raise FrameworkError(f"{manifest}: missing cases directory")
        suites[name] = []
        machines = set()
        for target in targets:
            if not isinstance(target, dict):
                raise FrameworkError(f"{manifest}: expected a [[targets]] table")
            adapter = target.get("adapter")
            if not isinstance(adapter, str) or adapter not in ADAPTERS:
                raise FrameworkError(f"{manifest}: unknown test adapter {adapter!r}")
            machine = target.get("machine")
            if not isinstance(machine, str) or not re.fullmatch(r"[\w-]+", machine):
                raise FrameworkError(f"{manifest}: invalid machine {machine!r}")
            if machine.lower() in machines:
                raise FrameworkError(f"{manifest}: duplicate machine {machine!r}")
            machines.add(machine.lower())
            profiles = target.get("profiles", "profiles.toml")
            if not isinstance(profiles, str) or not profiles:
                raise FrameworkError(f"{manifest}: invalid profiles path {profiles!r}")
            suites[name].append(ADAPTERS[adapter](
                tests, machine, profiles_file=(tests / profiles).resolve(),
                per_machine=len(targets) > 1,
            ))
    return suites
