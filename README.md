# skills

Skills para assistentes de código, testadas e utilizadas no meu dia a dia.

## Skills

### Controle de versão

| Skill | Use para |
| --- | --- |
| [commit](./version-control/git/commit/) | Criar commits em Conventional Commits com a mensagem em português, a partir do diff |
| [pull-request](./version-control/github/pull-request/) | Redigir a descrição de um PR em português a partir da branch, dos commits e do diff |

### Gestão de projeto

| Skill | Use para |
| --- | --- |
| [linear-issue](./project-management/linear/linear-issue/) | Transformar uma ideia em uma issue atômica e executável no Linear, por meio de uma entrevista guiada |
| [report-daily](./project-management/report-daily/) | Preencher a Bússola do dia com o que foi feito, o que travou e os próximos passos |

## Instalação

Instale todas as skills com a [skills CLI](https://skills.sh/docs/cli):

```bash
npx skills@latest add mayromyller/skills --skill '*'
```

Para instalar só uma, passe o nome dela:

```bash
npx skills@latest add mayromyller/skills --skill commit
```

## Como usar

Chame a skill pelo comando ou peça em linguagem natural. O assistente escolhe a skill certa pelo contexto da tarefa.

| Skill | Comando | Ou peça assim |
| --- | --- | --- |
| commit | `/commit` | "Faz o commit dessas mudanças." |
| pull-request | `/pull-request` | "Escreve a descrição do PR dessa branch." |
| linear-issue | `/linear-issue` | "Cria uma issue no Linear para o bug do login." |
| report-daily | `/report-daily [observação]` | "Preenche minha Bússola de hoje." |
