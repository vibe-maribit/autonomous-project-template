#!/usr/bin/env bash
# ==============================================================================
# OpenCode Autonomous CI Runner
# Script di orchestrazione unificato compatibile con GitHub, Gitea e GitLab
# ==============================================================================
set -euo pipefail

PLAN_KEY="${PLAN_KEY:-${BRANCH_NAME:-plan}}"
CHOSEN_MODEL="${INPUT_MODEL:-${CHOSEN_MODEL:-${DEFAULT_MODEL:-opencode/big-pickle}}}"

# Rilevamento immagini per supporto visuale autonomo (GitHub, Gitea, GitLab)
FULL_TEXT="${ISSUE_BODY:-} ${ISSUE_TITLE:-} ${CLEAN_PROMPT:-}"
if [ -z "${INPUT_MODEL:-}" ] && echo "$FULL_TEXT" | grep -Eq '(!\[[^]]*\]\([^)]+\)|<img[[:space:]]|user-attachments|\.(png|jpe?g|gif|webp|bmp))'; then
  VISUAL_MODEL="${INPUT_VISUAL_MODEL:-${VISUAL_MODEL:-opencode/space-bunny-free}}"
  echo "🖼️ Immagini rilevate nel testo dell'issue: utilizzo del modello visivo $VISUAL_MODEL"
  CHOSEN_MODEL="$VISUAL_MODEL"
fi

if [[ "$CHOSEN_MODEL" != *"/"* ]]; then
  CHOSEN_MODEL="opencode/$CHOSEN_MODEL"
fi
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

  PLAN_PROMPT="Analizza la richiesta e crea il piano di lavoro.
Richiesta: $CLEAN_PROMPT
Contesto: ${ISSUE_TITLE:-} - ${ISSUE_BODY:-}
$CONTEXT"

  if ! opencode run --agent planner --model "$CHOSEN_MODEL" "$PLAN_PROMPT" | tee "$PLAN_FILE"; then
    if [ "$CHOSEN_MODEL" != "opencode/big-pickle" ]; then
      echo "⚠️ Fallimento con $CHOSEN_MODEL. Fallback a opencode/big-pickle..."
      CHOSEN_MODEL="opencode/big-pickle"
      opencode run --agent planner --model "$CHOSEN_MODEL" "$PLAN_PROMPT" | tee "$PLAN_FILE" || true
    fi
  fi

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
  BUILD_PROMPT="Sei in modalità BUILD. Implementa il piano completando TUTTI i task e
soddisfacendo TUTTI gli Acceptance Criteria. Applica le modifiche ai file.

=== PIANO ===
${PLAN:-Richiesta: $CLEAN_PROMPT}

=== CONTESTO ===
$CONTEXT

=== FEEDBACK REVIEW PRECEDENTE ===
$REVIEW_FEEDBACK"

  if ! opencode run --agent build --auto --model "$CHOSEN_MODEL" "$BUILD_PROMPT"; then
    if [ "$CHOSEN_MODEL" != "opencode/big-pickle" ]; then
      echo "⚠️ Fallimento con $CHOSEN_MODEL. Fallback a opencode/big-pickle..."
      CHOSEN_MODEL="opencode/big-pickle"
      opencode run --agent build --auto --model "$CHOSEN_MODEL" "$BUILD_PROMPT" || true
    fi
  fi
  echo "::endgroup::"

  # Checkpoint commit & push
  git add .
  git commit -m "OpenCode ($CHOSEN_MODEL): build progress (iterazione $i)" || true
  if [ -n "${BRANCH_NAME:-}" ]; then
    git push origin "$BRANCH_NAME" || true
  fi

  echo "::group::Iterazione $i — REVIEW ($CHOSEN_MODEL)"
  REVIEW_PROMPT="Verifica sul codice ATTUALE se OGNI Acceptance Criterion del piano è
soddisfatto. Puoi eseguire build/lint/test ma NON modificare i file.

=== PIANO ===
${PLAN:-Richiesta: $CLEAN_PROMPT}

Scrivi come ULTIMA riga ESATTAMENTE una di queste:
- 'VERDICT: PASS'  se tutti i criteri sono soddisfatti
- 'VERDICT: FAIL'  altrimenti, seguita da un elenco puntato dei criteri NON
  soddisfatti e di cosa manca."

  opencode run --agent reviewer --auto --model "$CHOSEN_MODEL" "$REVIEW_PROMPT" 2>&1 | tee /tmp/review.txt || true
  if grep -q "Unexpected server error" /tmp/review.txt || [ ! -s /tmp/review.txt ]; then
    if [ "$CHOSEN_MODEL" != "opencode/big-pickle" ]; then
      echo "⚠️ Fallimento con $CHOSEN_MODEL nella review. Fallback a opencode/big-pickle..."
      CHOSEN_MODEL="opencode/big-pickle"
      opencode run --agent reviewer --auto --model "$CHOSEN_MODEL" "$REVIEW_PROMPT" 2>&1 | tee /tmp/review.txt || true
    fi
  fi
  echo "::endgroup::"

  if grep -Eq 'VERDICT:[[:space:]]*PASS' /tmp/review.txt; then
    echo "✅ Acceptance criteria soddisfatti all'iterazione $i."
    VERDICT="PASS"
    break
  fi
  REVIEW_FEEDBACK="$(cat /tmp/review.txt)"
  echo "⚠️ Criteri non soddisfatti: procedo con iterazione $((i+1))."
done

echo "VERDICT=$VERDICT" >> "${GITHUB_OUTPUT:-/tmp/runner_output.env}"
echo "🏁 Ciclo completato con esito: $VERDICT"
