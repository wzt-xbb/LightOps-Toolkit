#!/usr/bin/env python3

from datetime import datetime, timedelta
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "sample_logs" / "generated_app.log"

messages = [
    ("INFO", "request completed status=200"),
    ("INFO", "user login success"),
    ("WARN", "slow query detected cost=1200ms"),
    ("ERROR", "database connection failed"),
    ("ERROR", "upstream request timeout"),
    ("CRITICAL", "worker process unavailable"),
]

now = datetime.now()
lines = []

for i in range(100):
    level, message = random.choice(messages)
    ts = now - timedelta(seconds=(100 - i) * 5)
    lines.append(
        f"{ts:%Y-%m-%d %H:%M:%S} {level} client=127.0.0.1 {message}\n"
    )

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text("".join(lines), encoding="utf-8")
print(f"Generated: {OUT}")
