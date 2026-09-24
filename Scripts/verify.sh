#!/usr/bin/env bash
# Source verification is the default. Scaffold checks apply only to an empty repository.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
  --scaffold) python3 "$ROOT/Scripts/verify-scaffold.py" ;;
  --self-test)
    bash "$ROOT/Scripts/verify-source.sh" --self-test
    ;;
  "") bash "$ROOT/Scripts/verify-source.sh" ;;
  *) echo "Usage: $0 [--scaffold|--self-test]" >&2; exit 2 ;;
esac
