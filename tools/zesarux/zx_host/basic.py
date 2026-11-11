"""ZX BASIC helpers for initializing a ZXHost request mailbox."""


class ZXHostBasic:
    """Build target-side BASIC statements from the shared ZXHost descriptor."""

    @staticmethod
    def initialize_request(protocol, command=0, args=(0, 0), sequence=0):
        """POKE initial request bytes using descriptor field offsets.

        This is used by a standalone TAP launch before the resident CRT starts.
        The target runtime then preserves the request while initializing the
        mailbox. Host sessions use ``ZXHostProtocol.prepare_request`` instead.
        """
        if len(args) != 2:
            raise ValueError("ZXHost requests contain exactly two argument bytes")
        values = {
            "cancel": 0,
            "command": command,
            "arg0": args[0],
            "arg1": args[1],
            "sequence": sequence,
        }
        header_address = protocol["header_address"]
        fields = protocol["fields"]
        statements = []
        for field in ("cancel", "command", "arg0", "arg1", "sequence"):
            value = values[field]
            if not isinstance(value, int) or not 0 <= value <= 0xFF:
                raise ValueError("ZXHost BASIC request fields must fit in one byte")
            statements.append(f"POKE {header_address + fields[field]},{value}")
        return tuple(statements)
