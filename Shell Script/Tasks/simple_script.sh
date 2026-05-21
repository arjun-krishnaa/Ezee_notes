#!/usr/bin/env bash
set -euo pipefail

# simple_script.sh - minimal example
# Usage: ./simple_script.sh [name]

NAME="${1:-World}"

echo "Hello, ${NAME}!"
echo "Today is: $(date +'%Y-%m-%d %H:%M:%S')"

# Exit status 0 indicates success
exit 0
