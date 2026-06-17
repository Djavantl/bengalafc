# BengalaFC Fantasy

Aplicação Flutter de fantasy game baseada na Copa do Mundo 2026.

## Sprint 6 — Acessibilidade

Nesta etapa foi implementado suporte completo a acessibilidade na aplicação, com foco em leitores de tela (TalkBack/VoiceOver) e fonte dinâmica.

### O que foi feito

- Semantics adicionados em todas as telas da aplicação.
- Suporte a TalkBack (Android) e VoiceOver (iOS) validado manualmente.
- Localização configurada para Português (Brasil) — labels do sistema lidos em PT-BR.
- Fonte dinâmica respeitada — o app acompanha o tamanho de fonte definido nas configurações do dispositivo.

### Telas cobertas

| Tela | Principais ajustes |
|---|---|
| Login | Ícone decorativo excluído, título+subtítulo agrupados, loading anunciado via `liveRegion` |
| Home | Label do `RichText` da AppBar, métricas agrupadas com `MergeSemantics`, partidas lidas como frase completa |
| Ranking | Cada linha lida como "Posição X, Nome, Y pontos", elementos visuais redundantes excluídos |
| Fases | `ExpansionTile` anuncia estado expandido/recolhido, loading dos jogos anunciado por fase |
| Perfil | Avatar com label dinâmico por estado, campo e-mail com hint de não editável, botão salvar anuncia loading |
| Escalação | Jogadores lidos com nome, posição e pontuação, ações de capitão e remoção com labels descritivos |

### Padrões aplicados

- **`Semantics(excludeSemantics: true)`** — ícones e elementos puramente decorativos.
- **`ExcludeSemantics`** — filhos redundantes quando o pai já tem label completo.
- **`MergeSemantics`** — agrupa label + valor para leitura como frase única.
- **`Semantics(liveRegion: true)`** — anuncia mudanças de estado (loading, erros) automaticamente.
- **`tooltip`** em `IconButton` — já serve como label acessível nativo do Flutter.
- Labels dinâmicos em botões que mudam de estado (salvar, editar, montar time).

### Como validar

```bash
flutter pub get
flutter run
```

Depois disso:

1. Ative o **TalkBack** no Android: Configurações → Acessibilidade → TalkBack.
2. Navegue com **swipe para direita** (próximo elemento) e **swipe para esquerda** (anterior).
3. Verifique que cada elemento interativo é anunciado com contexto completo.
4. Aumente o tamanho da fonte em Configurações → Acessibilidade → Tamanho da fonte e confirme que o layout não quebra.

---

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
