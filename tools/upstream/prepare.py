#!/usr/bin/env python3
"""Export a Git revision, apply ordered patch series and overlay local files."""

import argparse
import hashlib
import shutil
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", type=Path, required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--paths", nargs="+", default=[], help="paths to export from Git")
    parser.add_argument("--patch-dir", type=Path, nargs="+", default=[],
                        help="patch directories in application order")
    parser.add_argument("--overlay-dir", type=Path,
                        help="tree of files copied over the patched source")
    parser.add_argument("--config", nargs="+", default=[],
                        help="additional values included in the source stamp")
    args = parser.parse_args()

    repository = args.repository.resolve()
    prefix = subprocess.check_output(
        ["git", "-C", repository, "rev-parse", "--show-prefix"], text=True)
    if prefix.strip():
        parser.error(f"Expected the root of a Git repository: {repository}")
    revision = subprocess.check_output(
        ["git", "-C", repository, "rev-parse", "--verify", "--end-of-options",
         args.revision + "^{commit}"], text=True).strip()

    patches = []
    for directory in args.patch_dir:
        if not directory.is_dir():
            parser.error(f"Patch directory does not exist: {directory}")
        patches.extend(patch.resolve() for patch in sorted(directory.glob("*.patch")))

    overlay = {}
    if args.overlay_dir is not None:
        if not args.overlay_dir.is_dir():
            parser.error(f"Overlay directory does not exist: {args.overlay_dir}")
        overlay = {path.relative_to(args.overlay_dir): path.read_bytes()
                   for path in sorted(args.overlay_dir.rglob("*")) if path.is_file()}

    fingerprint = hashlib.sha256(Path(__file__).read_bytes())
    fingerprint.update(repr((revision, args.paths, args.config)).encode())
    for patch in patches:
        fingerprint.update(b"patch\0" + patch.name.encode() + b"\0")
        fingerprint.update(hashlib.sha256(patch.read_bytes()).digest())
    for name, content in overlay.items():
        fingerprint.update(b"overlay\0" + name.as_posix().encode() + b"\0")
        fingerprint.update(hashlib.sha256(content).digest())

    destination = args.destination.resolve()
    stamp = f"{revision}\n{fingerprint.hexdigest()}\n"
    stamp_file = destination / ".upstream-source"
    if stamp_file.is_file() and stamp_file.read_text() == stamp:
        return

    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=f".{destination.name}-", dir=destination.parent) as temp:
        stage = Path(temp).resolve() / "source"
        stage.mkdir()
        with subprocess.Popen(["git", "-C", repository, "archive", revision, "--", *args.paths],
                              stdout=subprocess.PIPE) as archive:
            subprocess.run(["tar", "-xf", "-", "-C", stage], stdin=archive.stdout, check=True)
            if archive.wait():
                raise SystemExit(f"Could not export {revision} from {repository}")
        if patches:
            subprocess.run(["git", "init", "--quiet"], cwd=stage, check=True)
            for patch in patches:
                subprocess.run(["git", "apply", "--whitespace=nowarn", patch], cwd=stage, check=True)
            shutil.rmtree(stage / ".git")
        for name, content in overlay.items():
            target = (stage / name).resolve()
            if not target.is_relative_to(stage):
                parser.error(f"Overlay path points outside the prepared tree: {name}")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content)
        (stage / stamp_file.name).write_text(stamp)
        if destination.exists():
            shutil.rmtree(destination)
        stage.rename(destination)


if __name__ == "__main__":
    main()
