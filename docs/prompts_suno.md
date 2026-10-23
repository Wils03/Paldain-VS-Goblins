# Prompts de áudio e arte — Paladin vs Goblins

Estilo do jogo: pixel art medieval (Tiny Swords), visão de cima, sobrevivência contra hordas de goblins.

## Como usar no Suno

1. Abra **Create** e ligue o **Custom Mode**.
2. Cole o texto de **Style** no campo *Style of Music*.
3. Cole o texto de **Lyrics** no campo *Lyrics* (sempre `[Instrumental]` para não ter voz).
4. Marque **Instrumental**.
5. Gere 2 ou 3 variações e escolha a melhor. Baixe em **WAV** se o seu plano permitir (melhor para loop); senão MP3.
6. No Godot, músicas vão para `res://Audio/music/` e efeitos para `res://Audio/sfx/`. Para música em loop, no painel *Import* do arquivo marque **Loop** e reimporte.

> O Suno é bom para música. Para efeitos curtos (espada, moeda, explosão) ele funciona, mas costuma gerar áudios longos: corte o trecho útil num editor (Audacity é grátis). Se algum efeito não ficar bom, alternativas focadas em SFX: **ElevenLabs Sound Effects** (texto → efeito) ou **jsfxr** (efeitos retrô 8-bit, grátis).

---

## Músicas

### 1. Tema do menu / título — `music/title_theme`
**Style:**
```
medieval fantasy, heroic, orchestral chiptune hybrid, 16-bit RPG title theme, brass fanfare, lute, snare march, noble and adventurous, 100 bpm, loopable
```
**Lyrics:**
```
[Instrumental]
[Intro: brass fanfare]
[Main theme: heroic melody on lute and flute]
[Bridge: soft strings]
[Outro: fanfare returns, ends on sustained chord]
```

### 2. Música de gameplay (loop principal) — `music/gameplay_loop`
**Style:**
```
energetic medieval battle music, 16-bit chiptune with orchestral drums, driving percussion, fiddle and flute lead, tense but fun, roguelike survivor game, 130 bpm, seamless loop, no vocals
```
**Lyrics:**
```
[Instrumental]
[Intro: war drums]
[Verse: fast fiddle melody over driving drums]
[Chorus: full band, heroic brass]
[Verse: flute variation]
[Chorus]
[Outro: drums only, fade to loop point]
```

### 3. Onda intensa (quando a dificuldade sobe) — `music/wave_intense`
**Style:**
```
intense dark medieval combat music, fast taiko and war drums, low brass stabs, distorted chiptune bass, goblin horde attack, urgent, 150 bpm, loopable, no vocals
```
**Lyrics:**
```
[Instrumental]
[Intro: goblin war horns]
[Build-up: accelerating drums]
[Drop: heavy brass and chiptune bass]
[Breakdown: drums and choir pads]
[Drop]
```

### 4. Game Over — `music/game_over`
**Style:**
```
sad medieval defeat jingle, slow lute and soft strings, minor key, 8-bit chime, short, 70 bpm, ends cleanly
```
**Lyrics:**
```
[Instrumental]
[Short melancholic phrase on lute]
[Final low chord, fade out]
```

---

## Efeitos sonoros

Para cada efeito use o **Style** abaixo e em *Lyrics* coloque `[Instrumental] [Sound effect only, very short]`. Depois corte o trecho útil (normalmente 0,2–1,5 s).

### Como colocar no jogo (já está ligado no código)
1. Salve o arquivo em **`Audio/sfx/`** dentro do projeto, com o **nome exato** da tabela e extensão `.wav`, `.ogg` ou `.mp3`. Ex.: `Audio/sfx/explosion.wav`.
2. **Variações** são sorteadas automaticamente: `sword_swing_1.wav`, `sword_swing_2.wav`, `sword_swing_3.wav`…
3. Abra o projeto no Godot (ele importa sozinho) e pronto. Enquanto um arquivo não existir, aquele som simplesmente não toca.
4. Volume geral dos efeitos: `systems/sfx_manager.gd` (`volume_db`). Cada inimigo tem o campo **death_sound** no Inspector (categoria "Som").

| Nome do arquivo | Onde toca no jogo | Style para o Suno |
|---|---|---|
| `sword_swing` | Ataque do paladino | `single sword swing whoosh, fast metal blade through air, retro game sound effect, short, no music` |
| `sword_hit` | Espada acerta um inimigo | `sword slash hitting flesh and leather armor, impact, retro game sound effect, short, no music` |
| `player_hurt` | Paladino recebe dano | `armored knight grunt of pain, metal armor clank, retro game hurt sound, short, no music` |
| `player_death` | Morte do paladino | `knight falling defeated, armor crashing to the ground, low dramatic hit, short, no music` |
| `goblin_death` | Morte de goblin (tocha, TNT, pawn, reparador) | `small goblin creature death squeak, cartoonish, retro game sound effect, short, no music` |
| `sheep_death` | Morte da ovelha | `funny sheep bleat cut short, cartoon, retro game sound effect, short, no music` |
| `dynamite_fuse` | Goblin TNT arremessa a dinamite | `lit fuse sizzling, hissing spark, short, no music` |
| `explosion` | Dinamite explode | `cartoon bomb explosion, punchy boom with debris, retro 16-bit game sound effect, short, no music` |
| `house_hit` | Casa dos goblins leva dano | `axe chopping wood, wooden plank crack, retro game impact sound, short, no music` |
| `house_destroyed` | Casa dos goblins destruída | `wooden hut collapsing, planks breaking and falling, dust, retro game sound effect, short, no music` |
| `house_repaired` | Reparador termina o conserto | `hammer final nail and construction complete jingle, retro game build finished sound, short, no music` |
| `ritual_cast` | Ritual sagrado (tecla Q) | `holy magic spell cast, angelic choir swell, shimmering bells, divine power burst, short, no music` |
| `gold_pickup` | Pegar ouro | `coin pickup clink, bright metallic jingle, retro game collect sound, very short, no music` |
| `meat_pickup` | Pegar bife (cura) | `eating crunch and healing sparkle, retro game health pickup, short, no music` |
| `ui_click` | Passar o mouse/clicar em botão do menu | `soft wooden UI button click, medieval, very short, no music` |
| `ui_confirm` | Botão **Jogar** (confirmar) | `medieval confirm sound, short heroic brass stab with chime, retro game menu select, very short, no music` |

**Ainda não ligados** (crie quando quiser, aviso para ligar): `ritual_ready` (ritual pronto), `golden_meat_pickup` (bife dourado), `wave_horn` (início de onda forte).

---

## Arte (o Suno não gera imagens)

Use estes prompts num gerador de imagens (Midjourney, Leonardo, DALL·E, Ideogram, Bing Image Creator…). O estilo segue o pacote Tiny Swords para combinar com o jogo.

### Capa do itch.io (630×500)
```
pixel art game cover, top-down medieval fantasy, a brave knight in blue and gold armor with sword and shield standing on a grassy island, surrounded by a horde of green goblins with torches and dynamite, wooden bridge, pine trees, turquoise water, bright cheerful colors, Tiny Swords art style, clean outlines, title space at the top
```

### Logo "Paladin vs Goblins"
```
pixel art game logo text "PALADIN VS GOBLINS", medieval wooden sign with gold metal trim, sword crossing behind the letters, small goblin peeking from the side, transparent background, 16-bit style
```

### Ícone do jogo (512×512)
```
pixel art game icon, knight helmet with golden plume and a crossed sword, small goblin silhouette behind, bold outline, simple background, readable at small size, 16-bit style
```

### Tela de fundo do menu (1920×1080)
```
pixel art landscape, top-down medieval village on grassy islands, thatched houses, pine forest, wooden bridges over turquoise water, goblin huts on the far side, calm morning light, Tiny Swords style, wide composition with empty center for menu buttons
```
