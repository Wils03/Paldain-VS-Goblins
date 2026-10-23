# Paladin VS Goblins

## Descrição
Paladin VS Goblins é um emocionante jogo que desafia os jogadores a eliminar o máximo possível de hordas de goblins e outros inimigos que surgem pelo caminho. Mergulhe em um ambiente dinâmico e teste suas habilidades e estratégias enquanto enfrenta inimigos desafiadores!

### Destaques
- Hordas que crescem com o tempo, em ondas.
- Goblins com tocha, goblins TNT que arremessam dinamite à distância, pawns e ovelhas.
- **Casas dos goblins** que soltam inimigos sem parar: destrua-as para frear a horda, mas cuidado com os **reparadores**, que tentam reconstruí-las.
- Ritual sagrado (dano em área) com tempo de recarga.
- Ouro, bifes de cura e bife dourado deixados pelos inimigos.
- Se o paladino se descuidar, pode ficar **cercado** pela horda.

## Desenvolvimento
Este jogo foi desenvolvido utilizando a Godot Engine e programação em GDScript, garantindo uma jogabilidade fluída e envolvente.

- **Engine:** Godot Engine 4.6 (projeto iniciado na 4.2)
- **Linguagem:** GDScript

## Instalação
Não se preocupe com a instalação! Para jogar, basta acessar o link abaixo e clicar em "Run Game":
[Paladin VS Goblins](https://formigon.itch.io/paladins-vs-goblins)

### Rodar pelo código-fonte
1. Instale a [Godot Engine 4.6](https://godotengine.org/download).
2. Clone este repositório.
3. **Baixe a arte do jogo** (não vem no repositório, veja abaixo).
4. Abra o arquivo `project.godot` no Godot e aperte **F5** para jogar.

#### Arte do Tiny Swords (obrigatório)
A licença do [Tiny Swords](https://pixelfrog-assets.itch.io/tiny-swords) não permite redistribuir os arquivos, então eles não estão neste repositório:
1. Baixe o pacote grátis em [pixelfrog-assets.itch.io/tiny-swords](https://pixelfrog-assets.itch.io/tiny-swords).
2. Extraia e copie o **conteúdo** da pasta `Tiny Swords (Update 010)` para `Addons/Tiny Swords/` dentro do projeto. Devem ficar as pastas `Deco`, `Effects`, `Factions`, `Resources`, `Terrain` e `UI` diretamente dentro de `Addons/Tiny Swords/`.
3. Abra o projeto no Godot: ele importa as imagens sozinho.

### Gerar o executável
No Godot: **Projeto > Exportar > Windows Desktop > Exportar Projeto**. O executável sai em `exports/windows/PaladinVsGoblins.exe` (a pasta `exports/` não vai para o repositório). É preciso ter os *modelos de exportação* da versão 4.6.2 instalados (**Editor > Gerenciar Modelos de Exportação**).

## Uso
### Controles
| Ação | Teclado / mouse | Controle |
|---|---|---|
| Mover | WASD ou setas | Direcional / analógico esquerdo |
| Atacar com a espada | Clique esquerdo | — |
| Ritual sagrado | Q | — |
| Pausar / continuar | ESC | — |

### Volume
No menu principal (botão **Volume**) ou na pausa (**ESC**) é possível ajustar separadamente: **Geral, Música, Efeitos, Ambiente e Diálogo**. Os valores ficam salvos entre as sessões.

## Créditos e fontes

### Criação
- **Wilson Lemos (Formigon)** — criação, game design e programação.
  [itch.io](https://formigon.itch.io/paladins-vs-goblins) · [LinkedIn](https://www.linkedin.com/in/wil-lemos)

### Engine
- **[Godot Engine](https://godotengine.org)** — Juan Linietsky, Ariel Manzur e os contribuidores da Godot. Licença MIT.

### Arte
- **[Tiny Swords](https://pixelfrog-assets.itch.io/tiny-swords)** — por **Pixel Frog**. Personagens (paladino, goblins com tocha, goblins TNT, pawns, ovelhas), construções, terreno, árvores, pedras na água, recursos (ouro, bife), efeitos (explosão, fogo, caveira) e elementos de interface (botões, banners, fitas). Pacotes usados: *Tiny Swords (Update 010)*; o *Tiny Swords (Free Pack)* foi consultado como referência.
  Consulte a página do pacote para os termos de uso: o pacote pode ser usado em projetos, mas os arquivos de arte em si não devem ser revendidos ou redistribuídos como pacote de assets.
- **[Particle Pack](https://kenney.nl/assets/particle-pack)** — por **Kenney** (kenney.nl). Licença **CC0** (domínio público). Texturas `circle_03`, `light_02` e `magic_02`, usadas no efeito do ritual sagrado.

### Música
Todas as músicas foram **geradas por inteligência artificial com o [Suno](https://suno.com)** (Suno, Inc.), a partir de prompts escritos para o jogo (veja [`docs/prompts_suno.md`](docs/prompts_suno.md)):

| Faixa | Arquivo | Uso |
|---|---|---|
| Tema do menu | `Audio/music/title_theme.mp3` | Menu principal |
| Loop principal (2 variações) | `Audio/music/gameplay_loop_1.mp3`, `gameplay_loop_2.mp3` | Durante a partida |
| Onda intensa | `Audio/music/wave_intense.mp3` | Quando a horda fica grande |
| Game Over | `Audio/music/game_over.mp3` | Tela de derrota |

> Os direitos de uso das músicas seguem os [termos do Suno](https://suno.com/terms) e o plano da conta usada na geração (o uso comercial depende do plano).

### Efeitos sonoros
Os efeitos sonoros (espada, impactos, morte dos goblins e da ovelha, dinamite, explosões, casas, ritual, ouro, cura e interface) foram **sintetizados por código dentro do próprio projeto**, em estilo retrô 8-bit, pelo script [`tools/gerar_sfx.gd`](tools/gerar_sfx.gd). **Nenhuma biblioteca externa de sons foi usada.** Para recriá-los, dê dois cliques em [`tools/gerar_sfx.bat`](tools/gerar_sfx.bat).

### Fontes (tipografia)
- Interface do jogo: fontes do sistema (*Berlin Sans FB*, *Cursive*, *Sans-Serif*) e a fonte padrão da Godot. Nenhum arquivo de fonte está incluído no projeto; se a fonte não existir no computador, a Godot usa uma substituta.

### Ferramentas e assistência
- **[Claude](https://claude.com) (Anthropic)**, via Claude Code — assistência no desenvolvimento: recuperação das cenas a partir da build publicada, sistema de spawn, goblin TNT, casas destrutíveis e reparador, colisões, menus, sistema de áudio e síntese dos efeitos sonoros.

## Contribuição
Sua contribuição é muito importante! Agradecemos por suas sugestões e feedback, que são essenciais para o aprimoramento do jogo.

## Licença
O código deste projeto está licenciado sob a Licença Pública, permitindo que você jogue e compartilhe à vontade!

Os recursos de terceiros mantêm as suas próprias licenças (veja **Créditos e fontes** acima): Tiny Swords (Pixel Frog), Particle Pack (Kenney, CC0), músicas geradas no Suno e a Godot Engine (MIT).

## Contato
Para mais informações ou feedback, sinta-se à vontade para entrar em contato pelo LinkedIn:  
[Wilson Lemos](https://www.linkedin.com/in/wil-lemos)

Divirta-se jogando!
