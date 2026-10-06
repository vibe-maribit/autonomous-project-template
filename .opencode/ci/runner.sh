#!/usr/bin/env bash
# ==============================================================================
# OpenCode Autonomous CI Runner
# Script di orchestrazione unificato compatibile con GitHub, Gitea e GitLab
# ==============================================================================
set -euo pipefail

PLAN_KEY="${PLAN_KEY:-${BRANCH_NAME:-plan}}"
CHOSEN_MODEL="${CHOSEN_MODEL:-${DEFAULT_MODEL:-opencode/big-pickle}}"
MAX_ITERATIONS="${MAX_ITERATIONS:-4}"
PLAN_FILE="issue_plans/${PLAN_KEY}.md"

mkdir -p issue_plans /tmp

echo "=========================================================="
echo "🚀 Avvio OpenCode Autonomous Runner"
echo "Modello: $CHOSEN_MODEL | Max Iterazioni: $MAX_ITERATIONS"
echo "Branch: ${BRANCH_NAME:-main} | Plan Key: $PLAN_KEY"
echo "=========================================================="

# ── 1. FASE PLAN ─────────────────────────────────────────────────────────────
if [ -s "$PLAN_FILE" ]; then
  echo "📋 Piano esistente trovato in $PLAN_FILE: riutilizzo del piano."
  cp "$PLAN_FILE" /tmp/plan.md
else
  echo "📝 Generazione nuovo piano con OpenCode (agente planner)..."
  CLEAN_PROMPT=$(cat /tmp/clean_prompt.txt 2>/dev/null || echo "Nessun prompt")
  CONTEXT=$(cat /tmp/context.txt 2>/dev/null || echo "")

  opencode run --agent planner --model "$CHOSEN_MODEL" \
    "Analizza la richiesta e crea il piano di lavoro.
Richiesta: $CLEAN_PROMPT
Contesto: ${ISSUE_TITLE:-} - ${ISSUE_BODY:-}
$CONTEXT" | tee "$PLAN_FILE"

  cp "$PLAN_FILE" /tmp/plan.md

  # Commit & push del piano
  git add "$PLAN_FILE"
  git commit -m "OpenCode: piano di lavoro ($PLAN_KEY)" || echo "Nessun piano da committare."
  if [ -n "${BRANCH_NAME:-}" ]; then
    git push origin "$BRANCH_NAME" || true
  fi
fi

# ── 2. FASE BUILD & REVIEW LOOP ──────────────────────────────────────────────
PLAN=""; [ -f /tmp/plan.md ] && PLAN="$(cat /tmp/plan.md)"
CLEAN_PROMPT=$(cat /tmp/clean_prompt.txt 2>/dev/null || echo "")
CONTEXT=$(cat /tmp/context.txt 2>/dev/null || echo "")
REVIEW_FEEDBACK="(prima iterazione: nessun feedback)"
VERDICT="FAIL"

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo "::group::Iterazione $i — BUILD ($CHOSEN_MODEL)"
  opencode run --agent build --auto --model "$CHOSEN_MODEL" \
    "Sei in modalità BUILD. Implementa il piano completando TUTTI i task e
soddisfacendo TUTTI gli Acceptance Criteria. Applica le modifiche ai file.

=== PIANO ===
${PLAN:-Richiesta: $CLEAN_PROMPT}

=== CONTESTO ===
$CONTEXT

=== FEEDBACK REVIEW PRECEDENTE ===
$REVIEW_FEEDBACK"
  echo "::endgroup::"

  # Checkpoint commit & push
  git add .
  git commit -m "OpenCode ($CHOSEN_MODEL): build progress (iterazione $i)" || true
  if [ -n "${BRANCH_NAME:-}" ]; then
    git push origin "$BRANCH_NAME" || true
  fi

  echo "::group::Iterazione $i — REVIEW ($CHOSEN_MODEL)"
  opencode run --agent reviewer --auto --model "$CHOSEN_MODEL" \
    "Verifica sul codice ATTUALE se OGNI Acceptance Criterion del piano è
soddisfatto. Puoi eseguire build/lint/test ma NON modificare i file.

=== PIANO ===
${PLAN:-Richiesta: $CLEAN_PROMPT}

Scrivi come ULTIMA riga ESATTAMENTE una di queste:
- 'VERDICT: PASS'  se tutti i criteri sono soddisfatti
- 'VERDICT: FAIL'  altrimenti, seguita da un elenco puntato dei criteri NON
  soddisfatti e di cosa manca." | tee /tmp/review.txt
  echo "::endgroup::"

  if grep -q 'VERDICT: PASS' /tmp/review.txt; then
    echo "✅ Acceptance criteria soddisfatti all'iterazione $i."
    VERDICT="PASS"
    break
  fi
  REVIEW_FEEDBACK="$(cat /tmp/review.txt)"
  echo "⚠️ Criteri non soddisfatti: procedo con iterazione $((i+1))."
done

echo "VERDICT=$VERDICT" >> "${GITHUB_OUTPUT:-/tmp/runner_output.env}"
echo "🏁 Ciclo completato con esito: $VERDICT"
