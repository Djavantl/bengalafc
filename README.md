# BengalaFC Fantasy

Aplicação Flutter de fantasy game baseada na Copa do Mundo 2026.

## Sprint 3 — Temas

Nesta etapa foi implementada a base visual da aplicação com foco em organização do tema e responsividade.

### O que foi feito

- Tema centralizado em `AppColors`.
- `ThemeData` separado para modo claro e escuro.
- Alternância de tema via `ThemeNotifier`.
- Home responsiva com `LayoutBuilder`.
- Tela inicial simples para demonstração visual da sprint.

## Design Tokens

As cores da aplicação ficam centralizadas no arquivo `lib/core/theme/app_colors.dart`.

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

## Estrutura visual

A tela inicial foi criada para mostrar, de forma simples, os entregáveis da Sprint 3:

- cartão principal com pontuação da rodada;
- cards de conteúdo vazios para demonstrar o layout;
- adaptação entre 1 e 2 colunas de acordo com a largura da tela;
- botão de alternância entre claro e escuro.

## Como validar

```bash
flutter pub get
flutter run 
```

Depois disso:

1. Clique no ícone de tema na `AppBar` para alternar entre claro e escuro.
2. Redimensione a janela do navegador.
3. Verifique que a Home muda entre layout em coluna única e duas colunas quando a largura passa de 600px.
4. Confirme que as cores seguem os tokens definidos em `AppColors`.

## Sprint seguinte

As próximas etapas do projeto vão incluir as telas e funcionalidades do fantasy game, como escalação, busca de jogadores, ranking, fase/jogos e pontuação do usuário.
