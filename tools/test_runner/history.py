"""Persist SDK test failures and pending runs as cases complete."""

import sqlite3
from contextlib import closing
from uuid import uuid4

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
            connection.execute("""
                CREATE TABLE IF NOT EXISTS pending_runs (
                    scope TEXT NOT NULL,
                    plan_id TEXT NOT NULL,
                    suite TEXT NOT NULL,
                    machine TEXT NOT NULL,
                    case_path TEXT NOT NULL,
                    profile TEXT NOT NULL,
                    PRIMARY KEY (scope, suite, machine, case_path, profile)
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


def load_pending(scope):
    if not HISTORY_PATH.is_file():
        return None, set()
    with closing(open_history()) as connection:
        rows = connection.execute(
            "SELECT plan_id, suite, machine, case_path, profile FROM pending_runs WHERE scope = ?",
            (scope,),
        ).fetchall()
    if not rows:
        return None, set()
    return rows[0][0], {row[1:] for row in rows}


def count_pending(scope):
    if not HISTORY_PATH.is_file():
        return 0
    with closing(open_history()) as connection:
        return connection.execute(
            "SELECT COUNT(*) FROM pending_runs WHERE scope = ?", (scope,)
        ).fetchone()[0]


def start_plan(connection, scope, runs):
    plan_id = uuid4().hex
    with connection:
        connection.execute("DELETE FROM pending_runs WHERE scope = ?", (scope,))
        connection.executemany(
            "INSERT INTO pending_runs (scope, plan_id, suite, machine, case_path, profile) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            ((scope, plan_id, *key) for key in runs),
        )
    return plan_id


def record_outcome(connection, key, failed, *, scope, plan_id):
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
        if plan_id is not None:
            # A later invocation may have replaced the checkpoint for this scope.
            connection.execute(
                "DELETE FROM pending_runs WHERE scope = ? AND plan_id = ? "
                "AND suite = ? AND machine = ? AND case_path = ? AND profile = ?",
                (scope, plan_id, *key),
            )
