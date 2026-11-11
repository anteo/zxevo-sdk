"""ZEsarUX process and ZRCP transport utilities."""

__all__ = ["ZesaruxRunner", "ZrcpClient", "default_emulator"]


def __getattr__(name):
    if name in __all__:
        from .runner import ZesaruxRunner, ZrcpClient, default_emulator
        return {
            "ZesaruxRunner": ZesaruxRunner,
            "ZrcpClient": ZrcpClient,
            "default_emulator": default_emulator,
        }[name]
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
