"""Persist SDK test failures as cases complete."""

import sqlite3
from contextlib import closing

from .support import ROOT


HISTORY_PATH = ROOT / "build" / "test-runner" / "failed.sqlite3"


def open_history():
    HISTORY_PATH.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(HISTORY_PATH)
    try:
        with connection:
            connection.execute("""
                CREATE TABLE IF NOT EXISTS failed_runs (
                    suite TEXT NOT NULL,
                    machine TEXT NOT NULL,
                    case_path TEXT NOT NULL,
                    profile TEXT NOT NULL,
                    PRIMARY KEY (suite, machine, case_path, profile)
                )
            """)
    except BaseException:
        connection.close()
        raise
    return connection


def load_failures():
    if not HISTORY_PATH.is_file():
        return set()
    with closing(open_history()) as connection:
        return set(connection.execute("SELECT suite, machine, case_path, profile FROM failed_runs"))


def record_outcome(connection, key, failed):
    with connection:
        if failed:
            connection.execute(
                "INSERT OR IGNORE INTO failed_runs (suite, machine, case_path, profile) VALUES (?, ?, ?, ?)",
                key,
            )
        else:
            connection.execute(
                "DELETE FROM failed_runs WHERE suite = ? AND machine = ? AND case_path = ? AND profile = ?",
                key,
            )
