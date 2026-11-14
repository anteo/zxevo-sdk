"""Discover and run test suites, then compare and report their results."""

import json
import re
import shutil
import sys
import tomllib
from pathlib import Path

from ..comparison import compare_data_files, compare_screenshots, expected_files, output_prefix, write_expected
from ..emulator import find_zesarux, run_session
from ..profiles import case_profile_names, profile_layers
from ..support import FrameworkError, TestFailure, console_label


class TestSuite:
    """Run a suite with target-specific compiler options and mapper writes."""

    case_source_pattern = "*.c"
    default_profile = None

    def __init__(self, tests, machine, *, common_tests=None):
        self.tests = common_tests if common_tests is not None else tests
        self.machine = machine
        self.case_prefix = f"{machine}/" if common_tests is not None else ""
        self.cases = self.tests / "cases"
        self.build_dir = self.tests / "build"
        if common_tests is not None:
            self.build_dir /= machine.lower()
        self.profiles_file = tests / "profiles.toml"

    def compile_case(self, case_path, meta, profile, verbose=False):
        """Return the launch manifest path and the assembled code size."""
        raise NotImplementedError

    def build_case(self, case_path, meta, profile, verbose):
        name = self.case_prefix + self.case_relative_path(case_path).as_posix()
        print(f"{console_label('BUILD', 6)}{name} [{profile['name']}]: ", end="", flush=True)
        manifest, size = self.compile_case(case_path, meta, profile, verbose)
        print(f"code={size}B", flush=True)
        return manifest

    def run(self, args):
        try:
            if args.command == "clean":
                self.clean_outputs(args.case, args.filter and re.compile(args.filter))
                return 0
            profiles = self.load_profiles()
            if args.command == "list":
                return self.command_list(args, profiles)
            if args.command == "build":
                return self.command_build(args, profiles)
            return self.command_check(args, profiles)
        except (FrameworkError, OSError, tomllib.TOMLDecodeError) as error:
            print(f"{console_label('error', stream=sys.stderr)}: {error}", file=sys.stderr)
            return 2

    def load_profiles(self):
        with self.profiles_file.open("rb") as stream:
            settings = tomllib.load(stream)
        profiles = settings.get("profiles")
        if not isinstance(profiles, dict):
            raise FrameworkError(f"{self.profiles_file}: expected a [profiles] table")
        return profiles

    def case_relative_path(self, path):
        return path.relative_to(self.cases).with_suffix("")

    def select_case_paths(self, selected, filter_re):
        paths = {self.case_relative_path(path).as_posix(): path
                 for path in sorted(self.cases.rglob(self.case_source_pattern)) if not path.name.startswith("_")}
        matched = set()
        for selector in selected or ():
            if selector in paths:
                matched.add(paths[selector])
                continue
            prefix = selector.rstrip("/") + "/"
            descendants = [path for name, path in paths.items() if name.startswith(prefix)]
            if descendants:
                matched.update(descendants)
                continue
            names = [name for name in paths if Path(name).name == selector]
            if not names:
                raise FrameworkError(f"unknown case or directory {selector!r}; use 'list' to see cases")
            if len(names) > 1:
                raise FrameworkError(f"ambiguous case {selector!r}; choose one of {', '.join(names)}")
            matched.add(paths[names[0]])

        return [path for path in paths.values() if (not selected or path in matched)
                and (not filter_re or filter_re.search(self.case_relative_path(path).name))]

    def discover_cases(self, selected, filter_re):
        cases = []
        for path in self.select_case_paths(selected, filter_re):
            meta = {}
            meta_path = path.with_suffix(".toml")
            if meta_path.is_file():
                with meta_path.open("rb") as stream:
                    meta = tomllib.load(stream)
            if self.machine is not None:
                overrides = meta.pop("targets", {}).get(self.machine.lower(), {})
                if "profile" in overrides or "profiles" in overrides:
                    meta.pop("profile", None)
                    meta.pop("profiles", None)
                meta.update(overrides)
            cases.append((path, meta))
        return cases

    def profiles_for_case(self, meta, profiles, selected_profiles):
        """Resolve the profiles that a case should run with."""
        runs = []
        for name in case_profile_names(meta, default=self.default_profile):
            if selected_profiles and name not in selected_profiles:
                continue
            layers = profile_layers(profiles, name)
            runs.append(dict(self.merge_profile(layers), name=name, layers=tuple(layers)))
        return runs

    def merge_profile(self, layers):
        """Combine the ordered profile layers using the suite's settings."""
        raise NotImplementedError

    def run_directory(self, relative_case, profile):
        return self.build_dir / relative_case / profile["name"]

    def expected_directories(self, case_path, profile):
        """Return reference directories in order from shared to profile-specific."""
        shared = self.cases / self.case_relative_path(case_path)
        specific = shared / self.machine.lower() if self.case_prefix else shared
        names = dict.fromkeys((*profile["layers"], profile["name"]))
        return (shared, *(specific / name for name in names))

    def updates_shared_expectations(self, meta, profile):
        return False

    def expected_outputs(self, directories, case_name):
        return {path.name: path for directory in directories for path in expected_files(directory, case_name)}

    def enumerate_runs(self, args, profiles):
        runs = []
        for case_path, meta in self.discover_cases(args.case, args.filter and re.compile(args.filter)):
            chosen = self.profiles_for_case(meta, profiles, set(args.profile or []))
            if not chosen:
                continue
            runs.append((case_path, meta, chosen))
        return runs


    def command_list(self, args, profiles):
        runs = self.enumerate_runs(args, profiles)
        if not runs:
            print("no cases")
            return 0
        for case_path, meta, chosen in runs:
            shots = 0
            relative_case = self.case_relative_path(case_path)
            for profile in chosen:
                directories = self.expected_directories(case_path, profile)
                shots += len(self.expected_outputs(directories, relative_case.name))
            description = meta.get("description", "")
            name = self.case_prefix + relative_case.as_posix()
            print(f"{name:32s} profiles={','.join(p['name'] for p in chosen):24s} "
                  f"expected={shots:2d} {description}".rstrip())
        return 0


    def command_build(self, args, profiles):
        failures = 0
        for case_path, meta, chosen in self.enumerate_runs(args, profiles):
            for profile in chosen:
                try:
                    self.build_case(case_path, meta, profile, args.verbose)
                except FrameworkError as error:
                    failures += 1
                    print()
                    name = self.case_relative_path(case_path).as_posix()
                    print(f"{console_label('BUILD FAIL')} {self.case_prefix}{name} [{profile['name']}]: {error}")
        return 1 if failures else 0


    def clean_outputs(self, selected, filter_re):
        if selected or filter_re:
            for case_path in self.select_case_paths(selected, filter_re):
                relative_case = self.case_relative_path(case_path)
                shutil.rmtree(self.build_dir / relative_case, ignore_errors=True)
            return
        shutil.rmtree(self.build_dir, ignore_errors=True)
        for cache in list(self.tests.rglob("__pycache__")):
            if cache.is_dir():
                shutil.rmtree(cache, ignore_errors=True)


    def command_check(self, args, profiles):
        started = 0
        passed = 0
        failures = 0
        errors = 0
        build_failures = 0
        total_outputs = 0
        runs = self.enumerate_runs(args, profiles)
        zesarux = find_zesarux(args.zesarux)
        for case_path, meta, chosen in runs:
            for profile in chosen:
                relative_case = self.case_relative_path(case_path)
                name = relative_case.name
                run_dir = self.run_directory(relative_case, profile)
                directories = self.expected_directories(case_path, profile)
                shared_dir, specific_dir = directories[0], directories[-1]
                label = f"{self.case_prefix}{relative_case.as_posix()} [{profile['name']}]"
                try:
                    if args.no_build:
                        manifest_path = run_dir / "manifest.json"
                        if not manifest_path.is_file():
                            raise FrameworkError(f"no previous build at {manifest_path.parent}")
                    else:
                        manifest_path = self.build_case(case_path, meta, profile, args.verbose)
                except FrameworkError as error:
                    if not args.no_build:
                        print()
                    print(f"{console_label('BUILD FAIL')} {label}: {error}")
                    build_failures += 1
                    if args.fail_fast:
                        break
                    continue
                timeout = args.timeout or meta.get("timeout", 30)
                started += 1
                print(f"{console_label('RUN', 6)}{label}", flush=True)
                try:
                    result = run_session(manifest_path, name, profile["name"],
                                         zesarux, args.port, timeout, run_dir, args.verbose,
                                         meta.get("audio_capture", False),
                                         meta.get("audio_expectations"),
                                         meta.get("audio_step_flush_cycles", 0),
                                         meta.get("emulator_steps"))
                except TimeoutError as error:
                    print(f"{console_label('FAIL')} {label}: test timeout: {error}")
                    failures += 1
                    if args.fail_fast:
                        break
                    continue
                except (OSError, ValueError, RuntimeError) as error:
                    print(f"{console_label('FAIL')} {label}: emulator error: {error}")
                    errors += 1
                    if args.fail_fast:
                        break
                    continue
                case_failures = []
                case_failures.extend(result["audio_errors"])
                case_failures.extend(result["step_errors"])
                do_update = args.update and result["status"] == 0
                update_shared = len(directories) == 1 or self.updates_shared_expectations(meta, profile)
                inherited = self.expected_outputs(directories[:-1], name)
                references = inherited | self.expected_outputs(directories[-1:], name)
                if args.update and result["status"] != 0:
                    case_failures.append("target reported FAIL; expected files were not updated")
                produced = set()
                for step, step_title, actual in result["shots"]:
                    total_outputs += 1
                    produced.add(actual.name)
                    if do_update:
                        write_expected(actual, shared_dir, specific_dir, update_shared, inherited.get(actual.name))
                        continue
                    expected = references.get(actual.name, specific_dir / actual.name)
                    if actual.name not in references:
                        case_failures.append(f"missing expected {expected.relative_to(self.tests)}")
                        continue
                    try:
                        count, first = compare_screenshots(
                            expected, actual, run_dir / f"{actual.stem}.diff.png",
                            meta.get("emulator_steps", {}).get(step_title, {}).get("region"))
                    except (TestFailure, FrameworkError) as error:
                        case_failures.append(str(error))
                        continue
                    if count:
                        where = f"first at {first[0]},{first[1]}" if first else ""
                        case_failures.append(
                            f"{actual.name}: {count} pixel(s) differ ({where}); "
                            f"see {run_dir / (actual.stem + '.diff.png')}")
                for step, step_title, actual, kind in result["data"]:
                    total_outputs += 1
                    produced.add(actual.name)
                    if do_update:
                        write_expected(actual, shared_dir, specific_dir, update_shared, inherited.get(actual.name))
                        continue
                    expected = references.get(actual.name, specific_dir / actual.name)
                    if actual.name not in references:
                        case_failures.append(f"missing expected {expected.relative_to(self.tests)}")
                        continue
                    try:
                        message = compare_data_files(
                            expected, actual, run_dir / f"{actual.stem}.diff.txt")
                    except (TestFailure, FrameworkError, OSError) as error:
                        case_failures.append(str(error))
                        continue
                    if message:
                        case_failures.append(message)
                case_failures.extend(result.get("data_errors", []))
                for orphan in references.values():
                    if orphan.name in produced:
                        continue
                    shared = shared_dir / orphan.name
                    if (do_update and inherited.get(orphan.name, shared) == shared
                            and (update_shared or not shared.is_file())):
                        for path in dict.fromkeys((orphan, shared)):
                            if path.is_file():
                                path.unlink()
                                print(f"     removed stale golden {path.relative_to(self.tests)}")
                    else:
                        case_failures.append(
                            f"golden without a produced output: {orphan.relative_to(self.tests)}")
                failed_steps = [step for step in result["steps"] if step["status"] == 1]
                for step in failed_steps:
                    detail = " | ".join(line.strip() for line in step["log"].splitlines()[1:]
                                        if line.strip() and not line.startswith("DATA "))
                    case_failures.append(
                        f"step {step['step']}: {step['name']}: {detail or 'FAIL'}")
                if result["status"] == 1 and not failed_steps:
                    detail = result.get("completion_detail", [])
                    case_failures.extend(detail or ["target reported FAIL"])
                report = {
                    "case": name,
                    "machine": profile.get("machine", self.machine),
                    "profile": profile["name"],
                    "status": result["status"],
                    "skips": result["skips"],
                    "steps": result["steps"],
                    "screenshots": [
                        {"step": step, "name": step_title, "file": actual.name}
                        for step, step_title, actual in result["shots"]
                    ],
                    "data": [
                        {"step": step, "name": step_title, "file": actual.name, "kind": kind}
                        for step, step_title, actual, kind in result["data"]
                    ],
                    "failures": case_failures,
                    "updated": do_update,
                }
                report_path = run_dir / f"{output_prefix(name, profile['name'])}report.json"
                report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
                if case_failures:
                    failures += 1
                    print(f"{console_label('FAIL')} {label}")
                    for line in case_failures:
                        if (result.get("completion_failure_inline") and
                                line in result.get("completion_detail", [])):
                            continue
                        print(f"     {line}")
                    if args.fail_fast:
                        break
                else:
                    passed += 1
                    skip_text = f" ({result['skips']} skipped step(s))" if result["skips"] else ""
                    print(f"{console_label('PASS', 6)}{label}{skip_text}")
            if args.fail_fast and (failures or errors or build_failures):
                break
        if args.update:
            print(f"updated {total_outputs} output(s)")
        summary = f"Tests: {started} run, {passed} passed, {failures + errors} failed"
        if build_failures:
            summary += f", {build_failures} build failure(s)"
        print(f"\n{summary}", flush=True)
        if errors:
            return 2
        return 1 if failures or build_failures else 0
