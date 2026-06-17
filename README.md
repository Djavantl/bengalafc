# BengalaFC Fantasy

Aplicação Flutter de fantasy game baseada na Copa do Mundo 2026, desenvolvida por **Sávio Lopes**, **Djavan** e **Jader** para a disciplina de **Programação para Dispositivos Móveis**.

O jogador monta sua escalação com atletas reais da Copa, acompanha as partidas, acumula pontos e compete no ranking geral contra outros usuários.

---

## Funcionalidades

- Autenticação com e-mail e senha (Firebase Auth)
- Escalação de jogadores por fase com definição de capitão
- Pontuação automática baseada no desempenho real dos atletas
- Histórico de pontos por fase
- Ranking geral entre todos os usuários
- Acompanhamento de partidas e resultados por fase
- Perfil de usuário com foto personalizável
- Tema claro e escuro
- Suporte completo a acessibilidade (TalkBack/VoiceOver)

---

## Telas

| Tela | Descrição |
|---|---|
| Login / Cadastro | Autenticação com e-mail e senha |
| Home | Resumo da rodada atual, escalação e partidas |
| Escalação | Montagem e edição do time por fase |
| Fases | Lista de fases e partidas da competição |
| Ranking | Classificação geral com pontuação de todos os usuários |
| Perfil | Edição de nome e foto de perfil |

---

## Design Tokens

As cores da aplicação ficam centralizadas em `lib/core/theme/app_colors.dart`.

| Token | Light | Dark |
|---|---:|---:|
| Primary | `#1B6B28` | `#3FA855` |
| Accent | `#F5C518` | `#F5C518` |
| Background | `#F5F5F0` | `#111812` |
| Surface | `#F9F9F5` | `#172018` |
| Text | `#1A221A` | `#D8EAD5` |
| Text muted | `#5A6657` | `#7A9475` |
| Win | `#1B6B28` | `#1B6B28` |
| Draw | `#9E9E9E` | `#9E9E9E` |
| Lose | `#C0392B` | `#C0392B` |

---

## Acessibilidade

O app tem suporte completo a leitores de tela e fonte dinâmica.

### O que foi implementado

- **Semantics** em todas as telas com labels descritivos e contextuais
- **Localização em PT-BR** — labels do sistema lidos em português pelo TalkBack
- **Fonte dinâmica** — respeita o tamanho de fonte definido nas configurações do dispositivo
- **TalkBack (Android)** e **VoiceOver (iOS)** validados manualmente

### Padrões aplicados

| Padrão | Uso |
|---|---|
| `Semantics(excludeSemantics: true)` | Ícones e elementos decorativos |
| `ExcludeSemantics` | Filhos redundantes quando o pai já tem label completo |
| `MergeSemantics` | Agrupa label + valor para leitura como frase única |
| `Semantics(liveRegion: true)` | Anuncia mudanças de estado (loading, erros) |
| `tooltip` em `IconButton` | Label acessível nativo do Flutter |
| Labels dinâmicos | Botões que mudam de estado (salvar, editar, montar time) |

### Como testar com TalkBack

1. Ative o TalkBack: **Configurações → Acessibilidade → TalkBack**
2. Navegue com **swipe para direita** (próximo elemento) e **swipe para esquerda** (anterior)
3. **Toque duplo** para ativar um elemento
4. Verifique que cada elemento interativo é anunciado com contexto completo
5. Aumente a fonte em **Configurações → Acessibilidade → Tamanho da fonte** e confirme que o layout não quebra

---

## Como rodar

```bash
flutter pub get
flutter run
```

### Pré-requisitos

- Flutter 3.x
- Android SDK ou dispositivo físico conectado
- Arquivo `.env` com as variáveis de ambiente da API
- Projeto Firebase configurado (`firebase_options.dart`)

---

## Estrutura do projeto

```
lib/
  core/
    services/       # ApiClient, ScoringService, RankingService
    theme/          # AppColors, AppTheme, ThemeNotifier
  features/
    auth/           # Login, cadastro, AuthGate
    home/           # Tela principal
    lineup/         # Escalação
    phases/         # Fases e partidas
    scoring/        # Pontuação e ranking
    settings/       # Perfil do usuário
```
