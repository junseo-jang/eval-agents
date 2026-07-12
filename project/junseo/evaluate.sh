#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# evaluate.sh — Run evaluation against an LLM agent with tools
# =============================================================

# ---- Configuration (edit these) ----
TASK="all"                                # 필터: all | SVC_001 | SVC_002 | ...
AGENT_MODEL="gemini-2.5-flash"            # gemini-2.5-pro | gemini-2.5-flash | gemini-2.5-flash-lite

INTENDED_FILE="data/intended_utterances.jsonl"
UNINTENDED_FILE="data/unintended_utterances.jsonl"
SYSTEM_PROMPT_FILE="prompts/system_prompt.txt"      # system_prompt_en.txt for English version
TOOLS_FILE="tools/tools.json"
SERVICE_MAP_FILE="tools/service_map.json"

TEMPERATURE=0.0
TOP_P=1.0
TOP_K=40

OUTPUT_DIR="results"
# ---- End configuration ----

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables from repo root .env
ENV_FILE="$(realpath "$SCRIPT_DIR/../../.env")"
if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
else
    echo "Warning: .env not found at $ENV_FILE"
fi

python src/evaluate.py \
    --intended        "$INTENDED_FILE" \
    --unintended      "$UNINTENDED_FILE" \
    --task            "$TASK" \
    --model           "$AGENT_MODEL" \
    --system-prompt   "$SYSTEM_PROMPT_FILE" \
    --tools           "$TOOLS_FILE" \
    --service-map     "$SERVICE_MAP_FILE" \
    --temperature     "$TEMPERATURE" \
    --top-p           "$TOP_P" \
    --top-k           "$TOP_K" \
    --output-dir      "$OUTPUT_DIR"
