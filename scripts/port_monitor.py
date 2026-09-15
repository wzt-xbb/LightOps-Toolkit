#!/usr/bin/env python3

import argparse
import socket
import sys
from datetime import datetime
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description="TCP port availability monitor")
    parser.add_argument("--config", required=True, help="ports.conf path")
    parser.add_argument("--timeout", type=float, default=2.0)
    parser.add_argument("--log", default=None, help="Optional monitor log file")
    return parser.parse_args()


def load_targets(path: Path):
    targets = []
    with path.open("r", encoding="utf-8") as fh:
        for lineno, raw_line in enumerate(fh, 1):
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue

            parts = line.split()
            if len(parts) < 3:
                raise ValueError(
                    f"{path}:{lineno}: expected 'host port name'"
                )

            host, port_text = parts[0], parts[1]
            name = " ".join(parts[2:])

            try:
                port = int(port_text)
            except ValueError as exc:
                raise ValueError(
                    f"{path}:{lineno}: invalid port: {port_text}"
                ) from exc

            if not 1 <= port <= 65535:
                raise ValueError(
                    f"{path}:{lineno}: port out of range: {port}"
                )

            targets.append((host, port, name))
    return targets


def check_target(host: str, port: int, timeout: float):
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True, "reachable"
    except socket.timeout:
        return False, "timeout"
    except ConnectionRefusedError:
        return False, "connection refused"
    except OSError as exc:
        return False, str(exc)


def main():
    args = parse_args()
    config_path = Path(args.config)

    if not config_path.exists():
        print(f"[ERROR] config not found: {config_path}", file=sys.stderr)
        return 2

    try:
        targets = load_targets(config_path)
    except (OSError, ValueError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 3

    lines = []
    failures = 0
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines.append(f"{now} [INFO] checking {len(targets)} target(s)")

    for host, port, name in targets:
        ok, detail = check_target(host, port, args.timeout)
        status = "OK" if ok else "ALERT"
        if not ok:
            failures += 1
        lines.append(
            f"{now} [{status}] {name:<15} {host}:{port:<5} {detail}"
        )

    output = "\n".join(lines)
    print(output)

    if args.log:
        log_path = Path(args.log)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as fh:
            fh.write(output + "\n")

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
