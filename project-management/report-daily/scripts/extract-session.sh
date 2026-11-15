#!/usr/bin/env bash
# ${CLAUDE_SKILL_DIR}/scripts/extract-session.sh
#
# Extrai o contexto das sessões do Claude Code do dia atual:
#   - Mensagens da conversa (usuário + assistente)
#   - Tarefas registradas via TodoWrite
#   - Planos e execuções identificados
#
# Uso direto : bash ${CLAUDE_SKILL_DIR}/scripts/extract-session.sh
# No comando : !`bash ${CLAUDE_SKILL_DIR}/scripts/extract-session.sh 2>/dev/null || echo "(sessão indisponível)"`
#
# Pré-requisito: jq  →  brew install jq  |  sudo apt install jq

TODAY=$(date +%Y-%m-%d)
CLAUDE_DIR="$HOME/.claude/projects"
MAX_SESSIONS=8        # quantas sessões JSONL verificar (as mais recentes)
MAX_MSG_CHARS=700     # tamanho máximo de cada mensagem exibida
MAX_LINES_PER=120     # linhas máximas de conversa por sessão

# ── Cabeçalho ─────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
printf  "║  CONTEXTO DAS SESSÕES DO CLAUDE CODE — %-22s ║\n" "$TODAY"
echo   "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Dependências ──────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️  jq não encontrado. Instale:"
    echo "   macOS : brew install jq"
    echo "   Linux : sudo apt install jq"
    exit 1
fi

if [ ! -d "$CLAUDE_DIR" ]; then
    echo "ℹ️  Diretório de sessões não encontrado: $CLAUDE_DIR"
    exit 0
fi

# ── Localiza arquivos JSONL modificados hoje ──────────────────────────────────
FOUND_SESSIONS=0
TODO_ACCUMULATOR=""

echo "┌─ CONVERSAS ────────────────────────────────────────────────────────────"
echo ""

while IFS= read -r f; do
    # Confirma que o arquivo tem mensagens de hoje (campo .timestamp)
    HAS_TODAY=$(jq -r --arg t "$TODAY" \
        'select(.timestamp and (.timestamp | startswith($t))) | .type' \
        "$f" 2>/dev/null | head -1)

    [ -z "$HAS_TODAY" ] && continue
    FOUND_SESSIONS=$((FOUND_SESSIONS + 1))

    # Derivar nome legível a partir do caminho
    PROJECT_PART=$(basename "$(dirname "$f")" | cut -c1-30)
    SESSION_PART=$(basename "$f" .jsonl | cut -c1-20)
    echo "  ┌── Sessão ${FOUND_SESSIONS}: ${PROJECT_PART}/${SESSION_PART}"
    echo ""

    # ── Extrai mensagens de conversa ─────────────────────────────────────────
    jq -r --arg t "$TODAY" --argjson max "$MAX_MSG_CHARS" '
        select(.timestamp and (.timestamp | startswith($t))) |
        if .type == "user" then
            "  👤  " + (
                .message.content |
                if type == "string" then .
                elif type == "array" then
                    ([.[] | select(.type == "text") | .text] | join(" "))
                else "(conteúdo binário/não textual)" end
                | .[:$max]
            )
        elif .type == "assistant" then
            "  🤖  " + (
                .message.content |
                if type == "array" then
                    ([.[] | select(.type == "text") | .text] | join(" "))
                elif type == "string" then .
                else "(conteúdo não textual)" end
                | .[:$max]
            )
        else empty end |
        select(length > 6)
    ' "$f" 2>/dev/null | head -"$MAX_LINES_PER"

    # ── Acumula tarefas TodoWrite desta sessão ────────────────────────────────
    NEW_TODOS=$(jq -r --arg t "$TODAY" '
        select(.timestamp and (.timestamp | startswith($t))) |
        select(.type == "assistant") |
        .message.content[]? |
        select(.type == "tool_use" and .name == "TodoWrite") |
        .input.todos[]? |
        "[" + (.status // "?") + "] " + (.content // .description // "(sem descrição)")
    ' "$f" 2>/dev/null)

    [ -n "$NEW_TODOS" ] && TODO_ACCUMULATOR="$TODO_ACCUMULATOR"$'\n'"$NEW_TODOS"

    echo ""
    echo "  └──────────────────────────────────────────────────────────────"
    echo ""

done < <(find "$CLAUDE_DIR" -name "*.jsonl" -mtime 0 2>/dev/null | sort | tail -"$MAX_SESSIONS")

echo "└───────────────────────────────────────────────────────────────────────"
echo ""

if [ "$FOUND_SESSIONS" -eq 0 ]; then
    echo "ℹ️  Nenhuma sessão com mensagens de hoje ($TODAY) foi encontrada."
    echo "   Verifique se o Claude Code foi usado hoje ou se o clock está correto."
    echo ""
fi

# ── Tarefas / TodoWrite ───────────────────────────────────────────────────────
echo "┌─ TAREFAS REGISTRADAS HOJE (TodoWrite) ────────────────────────────────"
echo ""

if [ -n "$TODO_ACCUMULATOR" ]; then
    # Mostra estado final de cada tarefa (deduplicado, prioriza último estado)
    # Agrupa por descrição e pega a última ocorrência de cada uma
    echo "$TODO_ACCUMULATOR" \
        | grep -v '^[[:space:]]*$' \
        | awk '!seen[$0]++' \
        | while IFS= read -r line; do
            status_icon="⬜"
            case "$line" in
                "[completed]"*) status_icon="✅" ;;
                "[in_progress]"*) status_icon="🔄" ;;
                "[pending]"*) status_icon="⏳" ;;
            esac
            echo "  $status_icon $line"
        done
else
    echo "  (nenhuma tarefa TodoWrite registrada hoje)"
fi

echo ""
echo "└───────────────────────────────────────────────────────────────────────"
echo ""

# ── Resumo rápido ─────────────────────────────────────────────────────────────
TOTAL_TODOS=$(echo "$TODO_ACCUMULATOR" | grep -c '\[' 2>/dev/null || echo 0)
DONE_TODOS=$(echo "$TODO_ACCUMULATOR" | grep -c '\[completed\]' 2>/dev/null || echo 0)
echo "📊 Resumo da sessão: ${FOUND_SESSIONS} sessão(ões) · ${TOTAL_TODOS} tarefa(s) registrada(s) · ${DONE_TODOS} concluída(s)"
echo ""