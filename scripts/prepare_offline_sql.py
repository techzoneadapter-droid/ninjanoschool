#!/usr/bin/env python3
"""Generate offline SQL: game reference data and an EMPTY account schema."""
from __future__ import annotations
import argparse
from pathlib import Path
import re
import sys

GAME_TABLES = frozenset("""
Effdata effect item itemsell level map mob nj_arrow nj_effect nj_image nj_part
nj_skill npc optionitem optionskill skill tasks
""".split())
GAME_REQUIRED = frozenset("tasks level effect mob npc map optionitem item skill nj_part optionskill itemsell".split())
ACCOUNT_REQUIRED = frozenset("player ninja clan alert shinwa thiendia".split())
CREATE = re.compile(r"^\s*CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?\x60?([A-Za-z0-9_]+)\x60?", re.I)
INSERT = re.compile(r"^\s*(?:INSERT|REPLACE)\s+INTO\s+\x60?([A-Za-z0-9_]+)\x60?", re.I)


def sql_statements(content: str):
    """Split SQL semicolons outside quotes/comments, preserving SQL string content."""
    buf = []
    quoted = None
    in_line = False
    in_block = False
    i = 0
    n = len(content)
    while i < n:
        char = content[i]
        next_char = content[i + 1] if i + 1 < n else ""
        if in_line:
            if char == "\n":
                in_line = False
                buf.append("\n")
            i += 1
            continue
        if in_block:
            if char == "*" and next_char == "/":
                in_block = False
                i += 2
            else:
                i += 1
            continue
        if quoted is not None:
            buf.append(char)
            if char == "\\" and i + 1 < n:
                buf.append(content[i + 1])
                i += 2
                continue
            if char == quoted:
                if next_char == quoted:
                    buf.append(next_char)
                    i += 2
                    continue
                quoted = None
            i += 1
            continue
        if char == "-" and next_char == "-" and (i + 2 >= n or content[i + 2].isspace()):
            in_line = True
            i += 2
            continue
        if char == "#":
            in_line = True
            i += 1
            continue
        if char == "/" and next_char == "*":
            in_block = True
            i += 2
            continue
        if char in ("'", '"', "\x60"):
            quoted = char
            buf.append(char)
            i += 1
            continue
        if char == ";":
            statement = "".join(buf).strip()
            if statement:
                yield statement + ";\n"
            buf = []
        else:
            buf.append(char)
        i += 1
    if quoted is not None or in_block:
        raise ValueError("SQL contains an unterminated quote or comment")
    if "".join(buf).strip():
        raise ValueError("SQL ends with a partial statement; refusing to import")


def select_sql(path: Path, *, account: bool) -> tuple[str, set[str], int]:
    sql = path.read_text(encoding="utf-8-sig", errors="replace")
    ddl = []
    inserts = []
    tables = set()
    for stmt in sql_statements(sql):
        create = CREATE.match(stmt)
        if create:
            tables.add(create.group(1))
            ddl.append(stmt)
            continue
        insert = INSERT.match(stmt)
        if insert and not account and insert.group(1) in GAME_TABLES:
            inserts.append(stmt)

    required = ACCOUNT_REQUIRED if account else GAME_REQUIRED
    missing = required - tables
    if missing:
        raise ValueError(f"{path.name}: missing required tables: {sorted(missing)}")
    label = "ACCOUNT SCHEMA ONLY. No upstream records." if account else "GAME REFERENCE DATA ONLY."
    header = (
        "-- GENERATED for offline testing; not a production backup.\n"
        f"-- {label}\n"
        "SET NAMES utf8mb4;\n"
        "SET FOREIGN_KEY_CHECKS=0;\n"
    )
    return header + "\n".join(ddl) + "\n".join(inserts) + "SET FOREIGN_KEY_CHECKS=1;\n", tables, len(inserts)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default=".offline/generated")
    args = parser.parse_args()
    out = Path(args.output_dir)
    src = Path("database-sql")
    account_src = src / "nsohuyda_account (1).sql"
    game_src = src / "nsohuyda_data (1).sql"
    if not account_src.is_file() or not game_src.is_file():
        parser.error("Run from repo root with both original SQL files")
    account_sql, account_tables, account_inserts = select_sql(account_src, account=True)
    game_sql, game_tables, game_inserts = select_sql(game_src, account=False)
    if account_inserts != 0:
        raise AssertionError("Never copy account records")
    out.mkdir(parents=True, exist_ok=True)
    (out / "account_schema.sql").write_text(account_sql, encoding="utf-8")
    (out / "game_data.sql").write_text(game_sql, encoding="utf-8")
    print(f"Game database: {len(game_tables)} tables, {game_inserts} static INSERT statements.")
    print(f"Account database: {len(account_tables)} tables, ZERO upstream records.")
    print("Prepared in:", out.resolve())
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(2)
