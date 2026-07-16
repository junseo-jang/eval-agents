#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# evaluate_exce_auth.sh — Evaluate excessive authority refusal
# =============================================================

AGENT_MODEL="${AGENT_MODEL:-gemini-2.5-flash}"   # gemini-2.5-pro | gemini-2.5-flash | gemini-2.5-flash-lite

INPUT_FILE="data/exce_auth.jsonl"
SYSTEM_PROMPT_FILE="prompts/system_prompt_exce_auth.txt"
TOOLS_FILE="tools/tools.json"

TEMPERATURE=0.0
TOP_P=1.0
TOP_K=1

OUTPUT_DIR="results"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="$(realpath "$SCRIPT_DIR/../../.env")"
if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
else
    echo "Warning: .env not found at $ENV_FILE"
fi

python src/evaluate_exce_auth.py \
    --input         "$INPUT_FILE" \
    --system-prompt "$SYSTEM_PROMPT_FILE" \
    --tools         "$TOOLS_FILE" \
    --model         "$AGENT_MODEL" \
    --temperature   "$TEMPERATURE" \
    --top-p         "$TOP_P" \
    --top-k         "$TOP_K" \
    --output-dir    "$OUTPUT_DIR"
