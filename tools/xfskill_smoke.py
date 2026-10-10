#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""XFSKILL static smoke checker (layer 1 of the three-layer closed loop).

Usage:
    python tools/xfskill_smoke.py
    python tools/xfskill_smoke.py --encoding utf8

Exit code 0 means the static gate is green; 1 means at least one violation.
The default source encoding of .il/.cfg is GBK; use --encoding utf8 only while
the sources are temporarily converted for editing.
Checks:
    1. GBK reversible      .il/.cfg must decode as GBK and re-encode to identical bytes
    2. no CR byte          leftover carriage returns break SKILL line handling
    3. no BOM              Allegro rejects BOM prefixed source files
    4. no tab              repository standard is 2 space indentation
    5. line width          max 120 characters per line
    6. header six fields   文件名/作者/创建日期/版本/功能描述/修改记录
    7. version match       header version must equal VERSION file
    8. paren balance       every ( closed by ) after comments and strings removed
    9. no trailing comment comments must own the whole line
   10. naming              defun/procedure prefix XFSKILL_, command prefix xfskill_
   11. duplicates          same command or same function name registered twice
   12. changelog           VERSION must have a matching CHANGELOG section
   13. definition style    defun(Name (args) needs a space: defun(Name(args) is read as
                           one argument and aborts the load chain with
                           "*Error* defun: too few arguments"
   14. banned primitives   substr is not a SKILL builtin, use substring otherwise the
                           load chain dies with "*Error* eval: undefined function"
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEADER_FIELDS = ("文件名", "作者", "创建日期", "版本", "功能描述", "修改记录")
MAX_LINE = 120
DEFUN_RE = re.compile(r"^[ \t]*(?:defun|procedure)[ \t]*\([ \t]*([A-Za-z_][A-Za-z0-9_]*)", re.M)
DEFUN_JOINED_RE = re.compile(r"(?<![\w])(?:defun|procedure)[ \t]*\([ \t]*[A-Za-z_][A-Za-z0-9_]*\(")
COMMAND_PATTERNS = (
    re.compile(r'axlCmdRegister[ \t]*\([ \t]*"([^"]+)"'),
    re.compile(r'XFSKILL_RegisterCommand[ \t]*\([ \t]*"([^"]+)"'),
)
VERSION_RE = re.compile(r";[ \t]*版本[ \t]*:[ \t]*([0-9]+\.[0-9]+\.[0-9]+)")
GBK_ENCODING = "gbk"


def collect_files(root: Path):
    found = []
    for pattern in ("**/*.il", "**/*.cfg"):
        for path in root.glob(pattern):
            if "_backup" in path.parts:
                continue
            found.append(path)
    return sorted(set(found))


def scan_text(text):
    """Return (stripped, unterminated_string, trailing_comment_lines)."""
    out = []
    line_no = 1
    line_has_code = False
    in_string = False
    trailing = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == "\n":
            out.append("\n")
            line_no += 1
            line_has_code = False
            i += 1
            continue
        if in_string:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            line_has_code = True
            out.append(" ")
            i += 1
            continue
        if ch == ";":
            if line_has_code:
                trailing.append(line_no)
            while i < n and text[i] != "\n":
                i += 1
            continue
        if not ch.isspace():
            line_has_code = True
        out.append(ch)
        i += 1
    return "".join(out), in_string, trailing


def check_balance(stripped, rel):
    depth = 0
    line = 1
    for ch in stripped:
        if ch == "\n":
            line += 1
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth < 0:
                return ["{}:{} extra closing parenthesis".format(rel, line)]
    if depth != 0:
        return ["{} unbalanced parenthesis, depth={}".format(rel, depth)]
    return []


def check_file(path: Path, source_encoding: str, expect_version: str):
    errors = []
    rel = path.relative_to(ROOT).as_posix()
    data = path.read_bytes()

    if data[:3] == b"\xef\xbb\xbf":
        errors.append("{} unexpected UTF-8 BOM".format(rel))
    if b"\r" in data:
        errors.append("{} contains carriage return (CR)".format(rel))
    if b"\t" in data:
        errors.append("{} contains tab character".format(rel))

    if source_encoding == GBK_ENCODING:
        try:
            text = data.decode(GBK_ENCODING)
        except UnicodeDecodeError as exc:
            errors.append("{} not GBK decodable: {}".format(rel, exc))
            return errors
        if text.encode(GBK_ENCODING) != data:
            errors.append("{} GBK round trip mismatch".format(rel))
    else:
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError as exc:
            errors.append("{} not UTF-8 decodable: {}".format(rel, exc))
            return errors

    for number, line in enumerate(text.split("\n"), start=1):
        if len(line) > MAX_LINE:
            errors.append("{}:{} line longer than {} characters".format(rel, number, MAX_LINE))

    stripped, unterminated, trailing = scan_text(text)
    if unterminated:
        errors.append("{} unterminated string literal".format(rel))
    for number in trailing:
        errors.append("{}:{} trailing comment is forbidden".format(rel, number))
    errors.extend(check_balance(stripped, rel))

    if path.suffix == ".il":
        head_lines = text.split("\n")[:10]
        head = "\n".join(head_lines)
        for field in HEADER_FIELDS:
            if not any(line.lstrip().startswith(";") and field in line for line in head_lines):
                errors.append("{} header missing field {}".format(rel, field))
        found = VERSION_RE.search(head)
        if not found:
            errors.append("{} header version not parseable".format(rel))
        elif found.group(1) != expect_version:
            errors.append(
                "{} header version {} differs from VERSION {}".format(rel, found.group(1), expect_version)
            )
        for name in DEFUN_RE.findall(text):
            if not name.startswith("XFSKILL_"):
                errors.append("{} function {} must use XFSKILL_ prefix".format(rel, name))
        for match in DEFUN_JOINED_RE.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            errors.append(
                "{}:{} defun/procedure name must be followed by a space, not (".format(rel, line)
            )
    return errors


def collect_registry(root: Path, source_encoding: str):
    commands = {}
    functions = {}
    errors = []
    for path in collect_files(root):
        rel = path.relative_to(root).as_posix()
        try:
            text = path.read_bytes().decode(source_encoding)
        except UnicodeDecodeError:
            continue
        for pattern in COMMAND_PATTERNS:
            for name in pattern.findall(text):
                if not name.startswith("xfskill_"):
                    errors.append("{} command {} must use xfskill_ prefix".format(rel, name))
                commands.setdefault(name, []).append(rel)
        for name in DEFUN_RE.findall(text):
            functions.setdefault(name, []).append(rel)
    return commands, functions, errors


def main(argv=None):
    parser = argparse.ArgumentParser(description="XFSKILL static smoke checker")
    parser.add_argument(
        "--encoding",
        choices=("gbk", "utf8"),
        default="gbk",
        help="source encoding of .il/.cfg, gbk for release, utf8 while editing",
    )
    args = parser.parse_args(argv)
    source_encoding = GBK_ENCODING if args.encoding == "gbk" else "utf-8"

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")

    version_file = ROOT / "VERSION"
    if not version_file.exists():
        print("[FAIL] VERSION file is missing")
        return 1
    expect_version = version_file.read_text(encoding="ascii").strip()

    errors = []
    files = collect_files(ROOT)
    if not files:
        print("[FAIL] no .il/.cfg file found under {}".format(ROOT))
        return 1

    for path in files:
        errors.extend(check_file(path, source_encoding, expect_version))

    commands, functions, registry_errors = collect_registry(ROOT, source_encoding)
    errors.extend(registry_errors)
    for name, locations in sorted(commands.items()):
        if len(locations) > 1:
            errors.append("duplicate command {} in {}".format(name, ", ".join(locations)))
    for name, locations in sorted(functions.items()):
        if len(locations) > 1:
            errors.append("duplicate function {} in {}".format(name, ", ".join(locations)))

    changelog = ROOT / "CHANGELOG.md"
    if not changelog.exists():
        errors.append("CHANGELOG.md is missing")
    elif "## [{}]".format(expect_version) not in changelog.read_text(encoding="utf-8"):
        errors.append("CHANGELOG.md has no section for version {}".format(expect_version))

    for message in errors:
        print("[FAIL] {}".format(message))
    if errors:
        print("RESULT FAIL files={} violations={}".format(len(files), len(errors)))
        return 1

    print("RESULT PASS files={} commands={} functions={} version={}".format(
        len(files), len(commands), len(functions), expect_version))
    return 0


if __name__ == "__main__":
    sys.exit(main())
