"""Select test profiles and expand their parent chains."""

import re

from .support import FrameworkError


def case_profile_names(meta, *, default):
    if "profile" in meta and "profiles" in meta:
        raise FrameworkError("use either profile or profiles in case metadata")
    if "profiles" in meta:
        names = meta["profiles"]
    elif "profile" in meta:
        names = [meta["profile"]]
    elif default is not None:
        names = [default]
    else:
        raise FrameworkError("case must specify profile or profiles")
    if not isinstance(names, list) or not names:
        raise FrameworkError("case profiles must be a nonempty list of profile names")
    if any(not isinstance(name, str) or not re.fullmatch(r"[\w-]+(?:\+[\w-]+)*", name)
           for name in names):
        raise FrameworkError("invalid case profile name")
    if len(names) != len(set(names)):
        raise FrameworkError("case profiles must not contain duplicate names")
    return names


def profile_layers(profiles, name):
    """Expand a run name into ordered layers, visiting each parent once."""
    names = name.split("+")
    if len(names) != len(set(names)):
        raise FrameworkError(f"profile {name!r} repeats a layer")

    layers = {}
    for layer in names:
        pending = []
        while layer is not None and layer not in layers:
            if layer not in profiles:
                raise FrameworkError(f"unknown profile {layer!r} in {name!r}")
            if layer in pending:
                cycle = " -> ".join((*pending, layer))
                raise FrameworkError(f"cyclic profile inheritance: {cycle}")
            pending.append(layer)
            parent = profiles[layer].get("parent")
            if parent is not None and (not isinstance(parent, str) or not re.fullmatch(r"[\w-]+", parent)):
                raise FrameworkError(f"invalid parent {parent!r} in profile {layer!r}")
            layer = parent
        for layer in reversed(pending):
            layers[layer] = profiles[layer]
    return layers
