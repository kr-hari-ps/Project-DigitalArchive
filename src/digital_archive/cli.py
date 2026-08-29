from __future__ import annotations

import argparse


def main() -> int:
    parser = argparse.ArgumentParser(prog="digital-archive")
    parser.add_argument("--version", action="version", version="digital-archive 0.1.0")
    parser.parse_args()
    return 0
