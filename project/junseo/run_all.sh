#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# run_all.sh — Run evaluation across all model × prompt combinations
# Models : gemini-2.5-pro | gemini-2.5-flash | gemini-2.5-flash-lite
# Prompts: system_prompt.txt (KO) | system_prompt_en.txt (EN)
# Total  : 6 cases
# =============================================================

TASK="all"
INTENDED_FILE="data/intended_utterances.jsonl"
UNINTENDED_FILE="data/unintended_utterances.jsonl"
TOOLS_FILE="tools/tools.json"
SERVICE_MAP_FILE="tools/service_map.json"
TEMPERATURE=0.0
TOP_P=1.0
TOP_K=1
OUTPUT_DIR="results"

MODELS=(
    "gemini-2.5-pro"
    "gemini-2.5-flash"
    "gemini-2.5-flash-lite"
)

PROMPTS=(
    "prompts/system_prompt.txt:ko"
    # "prompts/system_prompt_en.txt:en"
)

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

TOTAL=$(( ${#MODELS[@]} * ${#PROMPTS[@]} ))
CASE=0

for MODEL in "${MODELS[@]}"; do
    for PROMPT_ENTRY in "${PROMPTS[@]}"; do
        PROMPT_FILE="${PROMPT_ENTRY%%:*}"
        PROMPT_LANG="${PROMPT_ENTRY##*:}"
        CASE=$(( CASE + 1 ))

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Case ${CASE}/${TOTAL} | model=${MODEL} | prompt=${PROMPT_LANG}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        python src/evaluate.py \
            --intended      "$INTENDED_FILE" \
            --unintended    "$UNINTENDED_FILE" \
            --task          "$TASK" \
            --model         "$MODEL" \
            --system-prompt "$PROMPT_FILE" \
            --tools         "$TOOLS_FILE" \
            --service-map   "$SERVICE_MAP_FILE" \
            --temperature   "$TEMPERATURE" \
            --top-p         "$TOP_P" \
            --top-k         "$TOP_K" \
            --output-dir    "$OUTPUT_DIR"
    done
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All ${TOTAL} cases completed. Results saved to: ${OUTPUT_DIR}/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
