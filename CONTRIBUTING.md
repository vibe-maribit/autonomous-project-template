# Contributing Guide

Grazie per il tuo interesse nel contribuire a questo progetto!

## Ciclo di Sviluppo Autonomo con OpenCode

Questo repository è dotato di un ciclo di vita di sviluppo autonomo gestito da **OpenCode**:

1. **Apri una Issue**: descrivi il bug da risolvere o la funzionalità da implementare.
2. **Assegna o commenta con `/oc`**:
   - Esempio: `/oc Implementa la gestione dell'ordinamento per data nella vista documenti`
3. **OpenCode si attiva automaticamente**:
   - Se includi immagini o screenshot, viene impiegato il modello visivo (`opencode/space-bunny-free` o custom).
   - Genera prima un piano di lavoro verificabile (`issue_plans/`).
   - Sviluppa il codice ed esegue i test in loop finché non riceve `VERDICT: PASS`.
   - Apre la Pull Request, esegue il merge automatico e chiude la Issue associata.

## Convenzioni di Commit

Utilizziamo [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` Nuove funzionalità
- `fix:` Risoluzione di bug
- `docs:` Modifiche alla documentazione
- `refactor:` Rifattorizzazione del codice
- `test:` Aggiunta o modifica di test
- `chore:` Manutenzione ordinaria
