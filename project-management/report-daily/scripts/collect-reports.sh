#!/usr/bin/env bash
# ${CLAUDE_SKILL_DIR}/scripts/collect-reports.sh
#
# Coleta o contexto de relatórios do dia para o Report:
#   - Pasta do dia e caminho da Report de hoje
#   - Conteúdo completo dos resume-NN.md de hoje
#   - Texto já gravado no arquivo do dia (para não sobrescrever)
#
# Uso direto : bash ${CLAUDE_SKILL_DIR}/scripts/collect-reports.sh
# No comando : !`bash ${CLAUDE_SKILL_DIR}/scripts/collect-reports.sh`
#
# Existe como script (e não inline no .md) porque o verificador de permissões
# do Claude Code recusa blocos !`...` com atribuição de variável, pipe e while
# — não consegue analisá-los estaticamente. O allowed-tools do comando já
# libera Bash(bash .claude/scripts:*).

set -uo pipefail

MONTH=$(LC_TIME=C date "+%B" | tr "[:upper:]" "[:lower:]")
DAY=$(date "+%d")
TODAY=$(date "+%d/%m/%Y")
MONTH_DIR="docs/report/$MONTH"
DIR="$MONTH_DIR/$DAY"

echo "Pasta do dia: $DIR | Report de hoje: $DIR/$DAY.md | Data: $TODAY"

echo "--- Conteúdo da pasta do dia ---"
ls -1 "$DIR" 2>/dev/null || echo "(a pasta do dia ainda não existe, crie com mkdir -p $DIR)"

echo "--- Resumos de tarefa de hoje ---"
HOJE=$(ls -1 "$DIR"/resume-*.md 2>/dev/null | sort)
if [ -n "$HOJE" ]; then
	printf '%s\n' "$HOJE" | while IFS= read -r f; do
		echo "▸ $f"
		cat "$f"
	done
else
	echo "(nenhum resumo de tarefa hoje)"
fi

echo "--- Dias já registrados no mês ---"
ls -1 "$MONTH_DIR" 2>/dev/null || echo "(a pasta do mês ainda não existe)"

echo "--- Texto já existente no arquivo de hoje ---"
cat "$DIR/$DAY.md" 2>/dev/null || echo "(o arquivo de hoje ainda não existe)"
