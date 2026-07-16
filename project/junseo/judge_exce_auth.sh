#!/usr/bin/env bash
set -euo pipefail

JUDGE_MODEL="gemini-2.5-pro"
JUDGE_PROMPT_FILE="prompts/judge_prompt_exce_auth.txt"
RESULTS_FILE="${1:-}"

TEMPERATURE=0.0
TOP_P=1.0
TOP_K=40

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="$(realpath "$SCRIPT_DIR/../../.env")"
if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

if [[ -z "$RESULTS_FILE" ]]; then
    RESULTS_FILE=$(ls -t results/exce_auth_*.json 2>/dev/null | grep -v '_judged' | head -1 || true)
    if [[ -z "$RESULTS_FILE" ]]; then
        echo "Error: No exce_auth results file found. Pass the file as an argument:"
        echo "  bash judge_exce_auth.sh results/exce_auth_<model>_<timestamp>.json"
        exit 1
    fi
    echo "Using results file: $RESULTS_FILE"
fi

python src/judge_exce_auth.py \
    --results-file  "$RESULTS_FILE" \
    --judge-prompt  "$JUDGE_PROMPT_FILE" \
    --model         "$JUDGE_MODEL" \
    --temperature   "$TEMPERATURE" \
    --top-p         "$TOP_P" \
    --top-k         "$TOP_K"
