#!/usr/bin/env python3

import argparse
import collections
import re
import sys
from pathlib import Path
from datetime import datetime

DEFAULT_KEYWORDS = ("ERROR", "WARN", "CRITICAL", "FATAL")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Analyze application log and count error keywords."
    )
    parser.add_argument("--log", required=True, help="Application log file")
    parser.add_argument(
        "--output",
        default=None,
        help="Report output path. If omitted, print only to stdout.",
    )
    parser.add_argument(
        "--keywords",
        nargs="+",
        default=list(DEFAULT_KEYWORDS),
        help="Keywords to count, e.g. ERROR WARN CRITICAL",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=10,
        help="Top normalized error messages to display",
    )
    return parser.parse_args()


def normalize_message(line: str) -> str:
    line = re.sub(r"\b\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:,\d+)?\b", "<TIME>", line)
    line = re.sub(r"\b\d+\b", "<N>", line)
    line = re.sub(r"\b(?:\d{1,3}\.){3}\d{1,3}\b", "<IP>", line)
    return line.strip()


def analyze(log_path: Path, keywords):
    keyword_counts = collections.Counter()
    message_counts = collections.Counter()
    total_lines = 0
    matched_lines = 0

    pattern = re.compile(
        r"\b(" + "|".join(re.escape(k) for k in keywords) + r")\b",
        re.IGNORECASE,
    )

    with log_path.open("r", encoding="utf-8", errors="replace") as fh:
        for raw_line in fh:
            total_lines += 1
            match = pattern.search(raw_line)
            if not match:
                continue

            matched_lines += 1
            keyword_counts[match.group(1).upper()] += 1
            message_counts[normalize_message(raw_line)] += 1

    return total_lines, matched_lines, keyword_counts, message_counts


def build_report(log_path, total_lines, matched_lines, keyword_counts, message_counts, top_n):
    lines = []
    lines.append("=" * 60)
    lines.append("LightOps Log Analysis Report")
    lines.append("=" * 60)
    lines.append(f"Generated : {datetime.now():%Y-%m-%d %H:%M:%S}")
    lines.append(f"Log file  : {log_path}")
    lines.append(f"Total     : {total_lines}")
    lines.append(f"Matched   : {matched_lines}")
    lines.append("")
    lines.append("Keyword counts:")

    if keyword_counts:
        for key, value in keyword_counts.most_common():
            lines.append(f"  {key:<10} {value}")
    else:
        lines.append("  No matching error keywords found.")

    lines.append("")
    lines.append(f"Top {top_n} error/warning messages:")
    if message_counts:
        for idx, (msg, count) in enumerate(message_counts.most_common(top_n), 1):
            lines.append(f"  {idx:02d}. [{count:>3}] {msg}")
    else:
        lines.append("  No matching messages.")

    return "\n".join(lines)


def main():
    args = parse_args()
    log_path = Path(args.log)

    if not log_path.exists():
        print(f"[ERROR] log file not found: {log_path}", file=sys.stderr)
        return 2

    if not log_path.is_file():
        print(f"[ERROR] path is not a file: {log_path}", file=sys.stderr)
        return 3

    try:
        result = analyze(log_path, args.keywords)
        report = build_report(log_path, *result, args.top)
        print(report)

        if args.output:
            output_path = Path(args.output)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(report + "\n", encoding="utf-8")
            print(f"\nReport saved to: {output_path}")

        return 0
    except PermissionError as exc:
        print(f"[ERROR] permission denied: {exc}", file=sys.stderr)
        return 4
    except OSError as exc:
        print(f"[ERROR] OS error: {exc}", file=sys.stderr)
        return 5


if __name__ == "__main__":
    raise SystemExit(main())
