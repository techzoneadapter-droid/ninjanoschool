#!/usr/bin/env python3
"""Local-only report of MySQL dump structure. Never prints stored rows or secrets."""
import argparse
import collections
import pathlib
import re

DDL = re.compile(r"(?im)^\s*CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?[`\"]?([A-Za-z0-9_]+)")
DML = re.compile(r"(?im)^\s*(?:INSERT|REPLACE)\s+INTO\s+[`\"]?([A-Za-z0-9_]+)")
USE = re.compile(r"(?im)^\s*USE\s+[`\"]?([A-Za-z0-9_]+)")

def analyze(path):
    raw = pathlib.Path(path).read_text(encoding="utf-8-sig", errors="replace")
    tables = DDL.findall(raw)
    inserts = collections.Counter(DML.findall(raw))
    schemas = list(dict.fromkeys(USE.findall(raw)))
    print(f"{path.name}: bytes={path.stat().st_size}; tables={len(tables)}; inserts={sum(inserts.values())}")
    print("  database USE clauses:", ", ".join(schemas) or "(none)")
    print("  CREATE TABLE:", ", ".join(tables) or "(none)")
    print("  tables with INSERT statements:", ", ".join(sorted(inserts)) or "(none)")
    if "player" in tables:
        schema = re.search(r"(?is)CREATE\s+TABLE\s+`player`\s*\((.*?)\)\s*ENGINE\s*=", raw)
        if schema:
            cols = re.findall(r"(?m)^\s*`(\w+)`\s+([^,\r\n]+)", schema.group(1))
            print("  player schema column definitions (no account records):")
            for name, definition in cols:
                print("   ", name, definition.strip()[:160])
    return tables, inserts

if __name__ == "__main__":
    cli = argparse.ArgumentParser()
    cli.add_argument("dumps", nargs="+", type=pathlib.Path)
    args = cli.parse_args()
    if not all(path.is_file() for path in args.dumps):
        raise SystemExit("Some SQL dump files do not exist")
    for path in args.dumps:
        analyze(path)
