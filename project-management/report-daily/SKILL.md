---
name: report-daily
description: Preenche a Bússola do dia — o que foi feito, o que travou, o que vem amanhã; lê commits, PRs, sessões do Claude Code e o contexto da conversa atual
argument-hint: '[observação opcional — ex: "foco em debugging", "dia de reuniões", "pendência do Instagram arrastando"]'
allowed-tools: Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(gh pr list:*), Bash(bash ${CLAUDE_SKILL_DIR}/scripts/*), Bash(find:*), Bash(jq:*), Bash(date:*), Bash(ls:*), Bash(cat:*), Bash(mkdir:*), Read, Write, Edit
---

# Bússola do Dia

Preencha minha Bússola diária no formato abaixo.

> **O que é a Bússola.** É o pulso do meu dia, não controle de ponto. Quem lê (meu líder, a P&C) precisa entender **em 30 segundos**: o que entreguei, o que travou e onde preciso de ajuda. Bem preenchida, ela puxa apoio mais rápido — trabalha a meu favor.

**Público-alvo:** tech lead + Pessoas & Cultura.
A escrita equilibra precisão técnica e linguagem acessível — o tech lead reconhece a abordagem; quem não é dev entende a ideia.

Observação livre passada na chamada (pode estar vazia): `$ARGUMENTS`

## O fluxo em quatro fases

| Fase | O que acontece | Seções |
|---|---|---|
| 1 · Coletar | Ler commits, PRs e sessões do dia | §1, §2 |
| 2 · Rascunhar | Escrever os três campos seguindo a régua, o limite de tamanho e os cortes obrigatórios | §3, §4, §5, §6 |
| 3 · Reescrever | **Passo obrigatório.** Passar o rascunho pelas regras de escrita | §7 |
| 4 · Verificar e gravar | Checklist, depois gravar o arquivo do dia sem apagar o que já estava nele | §8, §9, §9.1 |

Nenhuma fase é opcional. O texto que vai para o arquivo é sempre a saída da fase 3, nunca o rascunho da fase 2.

A Bússola é sobre **hoje**. Não leia, não procure e não compare com relatos de dias anteriores.

Os arquivos de **hoje** são exceção e leitura obrigatória: os resumos de tarefa
(`resume-NN.md`) e a Bússola que já esteja gravada no arquivo do dia. Eles entram
na coleta da §1.

---

## 1. Coleta de Contexto

### Data atual
!`date "+%d/%m/%Y"`

### Branch em uso e status do working tree
!`echo "Branch: $(git branch --show-current)" && echo "--- Arquivos modificados ---" && git status --short`

### Commits do dia — visão geral (todas as branches, sem merges)
!`git log --all --since=midnight --oneline --no-merges`

### Commits do dia — detalhes com arquivos alterados
!`git log --all --since=midnight --stat --no-merges --format="▸ %s%n  Data: %ad | Autor: %an%n%b" --date=short`

### Pull Requests abertas ou atualizadas recentemente
!`gh pr list --json number,title,state,updatedAt,headRefName,body --limit 20 2>/dev/null || echo "gh CLI indisponível — configure com: gh auth login"`

### Sessões do Claude Code — conversas e tarefas de hoje
!`bash ${CLAUDE_SKILL_DIR}/scripts/extract-session.sh 2>/dev/null || echo "(script não encontrado — execute: chmod +x ${CLAUDE_SKILL_DIR}/scripts/extract-session.sh)"`

### Pasta do mês, resumos de tarefa e Bússola já gravada hoje
!`bash ${CLAUDE_SKILL_DIR}/scripts/collect-reports.sh`

### Quando a coleta vier vazia

Dia sem commit e sem PR é comum (trabalho em arquivos ignorados pelo git, documentação, pesquisa, configuração). Não é sinal de dia parado.

- Sem commits e sem PRs → o relato sai das **sessões** e do **inventário de arquivos** (`find . -newermt "$(date +%F)" -type f -not -path "./node_modules/*"`, contagem de arquivos por pasta).
- Sessão longa demais para ler inteira → mapeie a estrutura primeiro (`grep -n "Sessão\|👤\|🤖"`), depois leia os trechos que importam.
- Se a Bússola sair sem commit nenhum, **diga isso no fechamento** (§9), não dentro do texto da Bússola.

---

## 2. Como interpretar as fontes

**Os commits são um norte, não o texto.** Servem para lembrar o que aconteceu e destravar o relato — nunca para virar bullet. Um commit lido não obriga a nada: se o que ele fez não interessa a quem lê, fica de fora.

| Fonte | Para que serve |
|---|---|
| **Commits** | Gatilho de memória: o que foi mexido hoje. Descartáveis depois de lembrar. |
| **PRs** | O que está em revisão ou aguardando merge → entra como entrega ou como bloqueio |
| **Sessões Claude Code** | O **porquê** das decisões, alternativas avaliadas, trabalho que ainda não virou commit |
| **Contexto desta conversa** | Planos e decisões desta sessão atual |
| **Resumos de tarefa de hoje** (`resume-NN.md`) | Fonte mais confiável do que foi entregue: cada arquivo registra uma tarefa fechada, escrita com o trabalho fresco |
| **Texto já existente no arquivo de hoje** | O que eu anotei à mão ou o que uma rodada anterior gravou. É contexto de entrada, não rascunho descartável |

**Regras de prioridade:**
- Se commits e sessão divergem → **a sessão prevalece** (tem mais contexto).
- Plano discutido mas sem commit → "avancei no desenho de X", nunca *"implementei X"*.
- PRs: filtre pelos atualizados hoje (campo `updatedAt`) — ignore os antigos.
- Conversa que **não chegou ao fim** na sessão (a issue não foi criada, o PR não foi aberto) → escreva o que foi decidido, não o desfecho presumido. Se precisar afirmar o desfecho, verifique antes; se não der para verificar, sinalize a lacuna no fechamento.
- Resumo de tarefa (`resume-NN.md`) tem mais peso que commit: foi escrito com a tarefa fresca e já checado. Se o resumo e o commit divergem, **o resumo prevalece**.
- Resumo de tarefa não vira bullet por existir. Três resumos podem virar um bullet só, e o resumo que não interessa a quem lê fica de fora como qualquer outra fonte.
- O número em `resume-NN.md` corre pelo dia: todos os resumos dentro de `docs/report/<mês>/<DD>/` são de hoje, e `resume-03.md` é o terceiro resumo de hoje. A coleta pega a pasta do dia inteira — não há o que filtrar por data. A primeira linha (`# Resumo NN - DD/MM/AAAA`) segue lá como conferência, mas quem define o dia é a pasta.
- Já existe texto no arquivo de hoje → **edite, não substitua** (§9.1).
- Vinte commits podem virar dois bullets, e um dia sem commit nenhum pode render cinco. A quantidade de commit não dita o tamanho do relato.

---

## 3. A régua da Bússola

### Calibragem técnica

Para cada conceito técnico: cite o termo **e** explique em linguagem comum logo em seguida.

| ❌ Evitar | ✅ Preferir |
|---|---|
| "usei TanStack Query" | "usei TanStack Query (biblioteca que gerencia chamadas à API com cache automático)" |
| "estado no Zustand" | "estado global gerenciado com Zustand (dados compartilhados entre telas)" |
| "animação em Skia" | "animação renderizada direto na GPU via Skia (60fps sem travar a UI)" |

Quando o termo técnico não acrescenta nada para quem lê, **descreva o efeito e omita o termo**. "Um monitor que fotografa a tela sozinha quando ela para de mudar" informa mais do que o nome da ferramenta que faz isso.

**Nunca inclua:** nomes de variáveis · hashes de commit · caminhos de arquivo (`src/components/Foo.tsx`) · trechos de código · jargão interno não explicado.

**Tom:** primeira pessoa · profissional sem ser corporativo · português do Brasil.

---

## 4. Tamanho: a Bússola é um resumo, não um relatório

Alvo: **3 a 6 linhas no total.** Uma frase de resumo, 1 a 3 bullets em "O que foi feito", 0 a 2 em "Pendência".

Quem lê tem 30 segundos. Texto longo não é mais informativo — é mais difícil de ler, e o item que importa afunda no meio dos outros. Se o dia rendeu muito, escolha o que mudou de estado e descarte o resto; não existe obrigação de relatar tudo o que aconteceu.

Um bullet por **assunto**, nunca um por commit, por arquivo ou por descoberta.

---

## 5. Os três campos, sem mistério

### O que foi feito hoje
O que passou a existir hoje: o artigo escrito, a tela entregue, a issue criada, o PR aberto, o que foi publicado. Com número ou evidência quando houver. O que ficou parcial entra como parcial.

| ❌ Evita | ✅ Prefere |
|---|---|
| "fiz o que dava" · "trabalhei" · "3 commits na branch X" | "lógica de dependência entregue e em revisão (PR aberto); 3 das 4 telas configuradas, falta o caso de erro" |

### Pendência
Trabalho travado, ou que precisa de outra pessoa, ou decisão que não é sua. Bloqueio real.

| ❌ Evita | ✅ Prefere |
|---|---|
| "." · "nenhum" · "sem desafios" · "reuniões" | "o crash só reproduz no Fire 7 e não tenho o device em mãos; perdi a tarde tentando isolar" |

**Pendência vazia é uma resposta legítima.** Dia sem bloqueio existe. Deixar o campo vazio é melhor do que preenchê-lo com resíduo, porque enche o campo de ruído e afoga o dia em que a pendência é de verdade. Não trate este campo como cota a cumprir.

### Próximos Passos
O que a pendência de hoje vira amanhã. Omita se não houver.

---

## 6. O que NUNCA entra na Bússola

**Não confunda o seu processo com o trabalho.** A Bússola relata o que mudou de estado no mundo. O caminho até lá — o raciocínio, o meio, o que você aprendeu — não entra.

Fora de "O que foi feito hoje":

| ❌ Nunca | Por quê |
|---|---|
| Descoberta sobre o produto ("na v3 o saldo aparece antes do menu") | É conteúdo do artigo/da issue, não entrega do dia. Quem lê não precisa aprender o fluxo. |
| Ferramenta ou script que você construiu para se apoiar | Ninguém pediu, não aparece no produto. Entra no dia em que provar que funcionou, se entrar. |
| Detalhe de implementação ("comparar pixels crus em vez de PNG") | Não informa nem o tech lead nem P&C. É exibição da investigação. |
| Sub-decisões de uma issue que já existe | Vivem na issue. Na Bússola cabe o nome dela, no resumo. |

Fora de "Pendência":

| ❌ Nunca | Por quê |
|---|---|
| Resíduo que você mesmo produziu (arquivo solto, captura sem nome, pasta a limpar) | É a sua faxina, não pendência de projeto. |
| Sua ferramenta que ainda não rodou de ponta a ponta | Ver acima: a ferramenta não é o trabalho. |
| Escopo que já está numa issue ("faltam 7 artigos") | A issue carrega isso. Repetir todo dia é ruído. |
| Incerteza sua sobre um dado que o usuário tem na frente | Contagem que você leu mal não é item de gestão. Verifique ou cale. |
| Problema que você inferiu de um critério e aplicou contra o trabalho do usuário | Ele não estava em dúvida. Você criou o bloqueio. |

Outros vícios:

| Vício | Por que mata o relato |
|---|---|
| O "ponto" e o "nenhum" em Pendência | Diferente de vazio: finge que respondeu. |
| O par fixo copiado | "Organizei minhas demandas / Sem desafios" todo dia não conta nada. |
| Commit traduzido literalmente | "Refatorei o hook de autenticação" é o commit. Diga o que mudou. |
| Resposta só de astral | "Saí feliz hoje" não informa gestão nenhuma. |

**Repetir é normal.** Tarefa que se arrasta segue no relato como está hoje. Não invente novidade nem maquie.

---

## 6.1. Template obrigatório de saída

Use **exatamente** esta estrutura. Ordem fixa.

```
Bússola - [Data: DD/MM/AAAA]

Resumo Geral
[Uma frase: o que saiu e, se houver, o que travou.]

O que foi feito hoje
• [1 a 3 bullets. O que passou a existir, com número quando houver.]

Pendência
• [0 a 2 bullets. Só bloqueio real. Vazio é resposta válida.]
```

O texto **dentro** dos campos segue as regras da §7. As instruções de formatação deste comando (negrito nas tabelas, travessões nesta página) valem para o comando, não para a Bússola.

---

## 7. Escrita — como a Bússola soa

O rascunho da fase 2 **não vai direto para o arquivo**. Reescreva-o com as regras abaixo antes de gravar.

**Voz:** primeira pessoa, português do Brasil, relato de trabalho. Frases de comprimento variado, curtas e longas alternadas. Opinião e incerteza suas são bem-vindas ("não sei se vale refazer"). Afirmação factual sem fonte na coleta, não.

**Regra que governa todas as outras:** cada frase precisa acrescentar um fato que o leitor ainda não tinha. Frase que só dá ênfase ao que a anterior já disse sai.

### Proibido

| ❌ | Em vez disso |
|---|---|
| Travessão (— ou –) | Ponto, vírgula, dois-pontos ou parênteses |
| Negrito e itálico dentro da Bússola | Texto corrido. O negrito das tabelas é deste comando, não do relato |
| Frase de efeito, fecho que repete o parágrafo, fragmento dramático | Corte. Termine no último fato concreto |
| "não foi só X, foi Y" · "mais do que X, é Y" | Diga o que é, direto |
| Abertura encenada: "Vamos ao que interessa", "Olha", "Sinceramente" | Comece pelo fato |
| Discutir com ninguém: "não é que eu não tenha feito X, mas" | Afirme o que fez |
| Grupo de três por ritmo ("rápido, simples e confiável") | Use quantos itens a informação tiver: um ou dois costumam bastar |
| Inflar o comum: "marco importante", "avanço significativo", "base sólida" | O fato sozinho. Se é importante, o leitor vê |
| Vender: "robusto", "poderoso", "experiência aprimorada" | O que a coisa é ou faz |
| Autoridade emprestada: "sabemos que", "todo mundo concorda" | A fonte real, ou nada |
| Vago: "relacionado a", "ligado a", "associado a" | Diga qual é a relação |
| "serve como", "representa", "constitui", "consiste em" | É, tem, faz |
| Rabicho explicativo: "…, evidenciando a importância de", "…, garantindo mais qualidade" | Ponto final antes do rabicho |
| Empilhar ressalvas: "talvez possa eventualmente" | Uma ressalva, se o dado pedir |
| Voz passiva que esconde quem fez | Quem fez, fez |
| Resíduo de chat: "espero que ajude", "posso detalhar se quiser" | Nada. A Bússola se sustenta sozinha |
| Aviso de limite: "com base nas informações disponíveis", "aparentemente" | Diga o que a coleta não mostra, ou omita a frase |
| Emoji, seta decorativa, título em Caixa Alta | Texto simples |

### Chute travestido de fato

Nunca preencha lacuna com o que é plausível. Se a coleta não mostra o desfecho, escreva o que foi decidido, não o que provavelmente aconteceu — e leve a lacuna para o fechamento da §9, fora da Bússola.

### Antes de gravar

Leia em voz alta. Depois procure os cinco que mais sobrevivem a uma revisão: travessão, negrito, fecho que repete, grupo de três, frase de efeito.

E confira que a reescrita não perdeu nada: número, data, nome de issue, bloqueio. Se perdeu, restaure e reescreva.

## 8. Checklist de 20 segundos — antes de salvar

Tamanho:
- [ ] O total cabe em 3 a 6 linhas? Se passou, cortei o que é processo meu, não o que é entrega.
- [ ] Cada bullet é um assunto, não um commit, arquivo ou descoberta?

Conteúdo:
- [ ] Todo bullet de "O que foi feito" é algo que passou a existir — não uma descoberta, um script de apoio ou um detalhe de implementação? (§6)
- [ ] Toda pendência é bloqueio real — não resíduo meu, não escopo de issue, não incerteza minha? (§6)
- [ ] Se não há bloqueio real, deixei "Pendência" vazio em vez de preencher por obrigação?
- [ ] Toda afirmação tem fonte na coleta? Nada de desfecho presumido.

Forma (pós-reescrita):
- [ ] Apliquei as regras da §7 e estou gravando a versão reescrita, não o rascunho.
- [ ] Nenhum fato ou número se perdeu na reescrita.
- [ ] Zero travessão, zero negrito e zero frase de efeito dentro da Bússola.

Gravação:
- [ ] Li os resumos de tarefa de hoje e o texto que já estava no arquivo do dia?
- [ ] O caminho é `docs/report/<mês em inglês, minúsculo>/<DD>/<DD>.md`, com a pasta do dia criada se ela não existia?
- [ ] Se o arquivo já tinha texto, incorporei em vez de apagar? Nenhuma anotação minha desapareceu.

---

## 9. Saída final

1. Escreva o rascunho seguindo o template da §6.1, dentro do limite de tamanho da §4 e respeitando os cortes da §6.
2. Reescreva-o com as regras da §7 — passo obrigatório.
3. Rode o checklist da §8 sobre a versão reescrita.
4. Grave em `docs/report/<mês-corrente>/<DD>/<DD>.md`, seguindo a §9.1 se o arquivo já tiver conteúdo.
   - `<mês-corrente>` é o nome do mês **em inglês e minúsculo**, derivado da data de hoje: `september`, `october`, `november`. Nada de número (`2026-09`) e nada de português (`setembro`).
   - `<DD>` é o dia com dois dígitos, e nomeia **a pasta e o arquivo**: `05/05.md`, `10/10.md`, `31/31.md`.
   - A pasta do dia guarda tudo daquele dia: a Bússola (`<DD>.md`) e os resumos de tarefa (`resume-NN.md`).
   - A pasta do dia — e a do mês, quando o mês virar — pode não existir ainda. Crie com `mkdir -p docs/report/<mês-corrente>/<DD>` e grave lá. Nunca escreva na pasta de outro dia, nem na do mês anterior no dia 1.
   - Exemplo para 10 de setembro: `docs/report/september/10/10.md`.
5. Mostre a Bússola na resposta, começando direto pelo conteúdo — sem preâmbulo do tipo "aqui está a sua Bússola".
6. **Depois do texto**, e separado dele, registre em uma ou duas frases: de onde veio o relato quando não houve commit, e qualquer afirmação que não deu para verificar. Esse fechamento é para mim, não entra no que eu colo no Wizard.

O texto da Bússola deve estar pronto para colar no Wizard, Notion ou Slack sem edição.

---

## 9.1. Quando o arquivo de hoje já tem texto

O arquivo do dia é meu, não é saída descartável do comando. Pode chegar nele
texto de três origens: anotação que eu escrevi à mão, Bússola gravada por uma
rodada anterior deste comando, ou resumo colado ali por engano.

**Leia o arquivo inteiro antes de escrever.** Depois:

| Situação | O que fazer |
|---|---|
| Anotação minha (lembrete, link, observação solta, item que eu quero no relato) | Trate como fonte da §1 e incorpore no relato. Se não couber nos três campos, preserve o texto no fim do arquivo, abaixo de um separador `---`, fora do bloco que eu colo no Wizard |
| Bússola de uma rodada anterior de hoje | Atualize os campos com o que mudou desde então. Bullet que continua verdadeiro fica com a mesma redação: não reescreva por gosto |
| Pendência que foi resolvida ao longo do dia | Mova para "O que foi feito hoje". Não apague |
| Texto que eu claramente pedi para tirar | Só nesse caso remova, e diga no fechamento (§9, passo 6) o que saiu |

**Nada de conteúdo pré-existente desaparece sem eu ter pedido.** Rodar este
comando duas vezes no mesmo dia não zera a primeira rodada: a segunda parte da
primeira. Em dúvida entre apagar e preservar, preserve e sinalize no fechamento.

> A Bússola leva 2 minutos e é o meu porta-voz quando não estou na sala. Caprichar nela faz ela trabalhar por mim.
