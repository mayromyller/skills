---
name: commit
description: Cria um commit em Conventional Commits com a mensagem em português do Brasil, analisando o diff e o status do repositório. Use quando o usuário pedir para commitar, fazer commit ou gerar a mensagem de commit das mudanças.
---

# Commit

Analise todas as mudanças em staged e somente em arquivos em staged para criar um commit seguindo as regras abaixo.

## Fluxo

1. Execute `git diff HEAD` para ver todas as mudanças
2. Execute `git status` para ver arquivos novos/deletados
3. Faça o stage de todos os arquivos relevantes com `git add`
4. Gere a mensagem de commit seguindo as convenções abaixo
5. Execute o commit

## Convenções

**Formato:**
```
<tipo>: <descrição curta em PT-BR>

<corpo opcional em PT-BR>
```

**Tipos permitidos:**
- `feat` — nova funcionalidade
- `fix` — correção de bug
- `style` — formatação, sem mudança de lógica
- `refactor` — refatoração sem feat nem fix
- `chore` — tarefas de manutenção, dependências
- `docs` — documentação
- `test` — testes
- `perf` — melhoria de performance
- `ci` — mudanças de CI/CD
- `revert` — reversão de commit anterior

**Regras:**
- A descrição deve ser em **português do Brasil**
- Use o imperativo: "adiciona", "corrige", "remove" (não "adicionado", "corrigido")
- Máximo de 72 caracteres na primeira linha
- Se houver mudanças em múltiplos escopos distintos, prefira múltiplos commits
- Não inclua "Co-authored-by" ou atribuições ao Claude