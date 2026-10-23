# Ideias para implementação — Paladin vs Goblins

Documento vivo: ideias ainda em discussão. Marque `[x]` quando algo for implementado.

---

## 1. Fases com tempo limitado

O jogo deixa de ser uma sobrevivência infinita e vira uma sequência de fases cronometradas, intercaladas com a loja.

| Fase | Duração | Observação |
|---|---|---|
| 1 | 3:00 | Introdução: só o mob spawner + casas lentas |
| 2 | 4:30 | |
| 3 | 6:00 | |
| 4+ | +1:30 por fase (ou fixo em 6:00) | A definir |

**Fluxo:**
```
Fase N (tempo corre) ──tempo acabou──► Fim da fase
   │                                       │
   └─ player morre ─► Game Over            ▼
                                  Player volta ao ponto de spawn
                                  Inimigos somem / param
                                           │
                                           ▼
                                  LOJA (30 s a 1 min)
                                  [botão "Próxima fase"]
                                           │
                                           ▼
                                      Fase N + 1
```

**Ao terminar a fase:**
- [ ] Parar todos os spawners (mob spawner e casas).
- [ ] Remover os inimigos vivos (talvez com uma animação de fuga/fumaça) ou deixá-los congelados.
- [ ] Levar o player de volta ao ponto onde ele nasceu (guardar a posição inicial no `_ready` do player).
- [ ] Mostrar "Fase concluída!" com o resumo: tempo, abates, ouro ganho na fase.

**Ideias em aberto:**
- A loja abre automaticamente ou o player precisa andar até ela (ex.: a casa dos cavaleiros perto do spawn vira a loja)?
- O ritual recarrega entre fases?
- A vida é restaurada entre fases (total, parcial, ou só comprando)?

---

## 2. Loja (entre as fases)

- **Tempo:** de 30 s a 1 min, com um contador na tela. Ao zerar, a próxima fase começa sozinha.
- **Botão "Próxima fase":** para quem já terminou as compras.
- **Moeda:** o ouro (`GameManager.gold_counter`), que já cai dos inimigos.
- **Pausa:** durante a loja não há inimigos; o tempo da loja não conta para o tempo da fase.

### Upgrades do player (rascunho)

| Atributo | O que muda no código | Valor base atual | Por nível (sugestão) |
|---|---|---|---|
| **Ataque** | `attack_player` (dano da espada) | 15 (no `main.tscn`) | +20% |
| **Vida** | `max_health` (e cura o valor ganho) | 100 | +20 |
| **Agilidade** | `speed` (movimento) e talvez o tempo do ataque (`attack_cooldown`) | 3 | +8% |
| **Resistência** | novo: reduz o dano recebido em `damage()` | 0% | +5% (teto de 50%) |
| **Ritual** (extra) | `ritual_damage` / `ritual_interval` | 20 / 30 s | +dano ou −2 s |

**Preço:** cresce a cada nível comprado, por exemplo `preço = base × 1,5^nível` (10, 15, 22, 33, 50…).

**Itens consumíveis (ideia):** poção de vida cheia, escudo temporário, "isca" que atrai goblins.

---

## 3. Dificuldade por fase e por evolução do player

A dificuldade deve subir com **o tempo de jogo** e com **a força do player**, para os upgrades não deixarem o jogo fácil demais.

- **Por fase:** cada fase aumenta
  - o limite do mob spawner (`limite_inicial` / `limite_maximo`, já existem),
  - a frequência das casas (`spawn_interval`),
  - a vida e o dano dos inimigos (multiplicador aplicado no spawn),
  - a proporção de goblins TNT.
- **Por evolução:** um "poder do player" (soma dos níveis comprados) aumenta levemente a vida dos inimigos, por exemplo +5% por nível total.
- **Dentro da fase:** o `DificultySystem` continua controlando as ondas, reiniciando o tempo a cada fase.

---

## 4. Casas dos goblins destrutíveis + mob reparador

As casas (spawners fixos) passam a ser alvos: o player pode destruí-las para frear o spawn, e os goblins tentam consertá-las. Isso cria uma decisão constante: lutar contra a horda ou ir atrás das casas.

> **Implementado (versão 1):** vida 100 com barra (vermelha = vida, amarela = conserto), dano da espada e do ritual, sprite destruído, 3 moedas de recompensa, reparador (Pawn roxo com marreta) enviado pelas casas inteiras a cada 10 s enquanto houver mais casas destruídas do que reparadores, conserto de 8 de vida/s, dano durante o conserto desfaz o progresso, e reconstrução automática após 90 s como reserva (caso todas as casas caiam). Tudo ajustável no Inspector da casa (`systems/house_spawner.gd`) e do reparador (`Enimes/repairer.tscn`, nó "Repair House").

### Vida da casa
- [ ] Barra de vida em cima de cada casa (mesmo estilo da barra do player).
- [ ] A espada e o ritual causam dano na casa (a casa entra num grupo próprio, ex. `"spawners"`, e o `deal_damage_to_enemies()` / ritual passam a considerá-lo).
- [ ] Feedback de dano: piscar vermelho (igual aos inimigos) e o dígito de dano (`damage_digit.tscn`).
- [ ] Vida sugerida: 150 (≈ 10 golpes com o ataque base).

### Casa destruída
- [ ] Ao zerar a vida, troca o sprite por `Goblin_House_Destroyed.png` (já existe no Tiny Swords) e para de soltar goblins.
- [ ] Efeitos: explosão/fumaça (`Effects/Explosion`, `Effects/Fire`) e talvez um drop de ouro maior como recompensa.
- [ ] A colisão continua (os escombros ainda bloqueiam), ou fica menor — a decidir.

### Como ela volta a funcionar (duas opções, podem coexistir)
1. **Por tempo:** depois de X segundos (ex.: 45 s) a casa se reconstrói sozinha com a vida cheia.
2. **Por conserto (preferida):** um **mob reparador** vai até a casa e a conserta.
   - Enquanto conserta, a vida da casa sobe aos poucos (ex.: +10/s); uma barra mostra o progresso.
   - Se o player matar o reparador, o conserto para (e a vida reconstruída até ali fica, ou se perde — a decidir).
   - Ao chegar à vida cheia, a casa volta a soltar goblins.

### Mob reparador
- **Comportamento:** em vez de seguir o player, procura a casa destruída mais próxima, anda até ela e fica "martelando". Se não houver casa destruída, fica perto da vila (ou foge do player).
- **Origem:** sai de uma casa ainda inteira, ou de um ponto fixo da vila (ex.: uma torre/acampamento), a cada X segundos enquanto existir alguma casa destruída.
- **Fraco em combate:** pouca vida e quase nenhum dano; o perigo é deixá-lo trabalhar.
- **Sprite (preferido): Pawn com marreta**, já no projeto em `Addons/Tiny Swords/Factions/Knights/Troops/Pawn/<Cor>/Pawn_<Cor>.png` (é a mesma folha usada pelo inimigo `Enimes/pawn.tscn`). Folha 1152×1152, quadros de 192 px, 6 por linha:
  - linha 0 — parado
  - linha 1 — andando
  - **linha 2 — golpe de marreta** (para o conserto)
  - linha 3 — golpe de machado
  - linhas 4 e 5 — carregando recurso (parado / andando)
  - Cores disponíveis: Red, Blue, Purple, Yellow. Para diferenciar do Pawn inimigo comum, usar outra cor (ex.: Purple) ou um `modulate`.
- **Alternativa:** o *Tiny Swords (Free Pack)* (em `GODOT/Assets`, fora do projeto) tem um Pawn com martelo pequeno em 5 cores (inclusive **preto**), com arquivos separados: `Pawn_Run Hammer.png` (6 quadros), `Pawn_Idle Hammer.png` (8) e `Pawn_Interact Hammer.png` (3).
- **Sprites de construção (opcional):** o Update 010 tem `Wood_Tower_InConstruction.png` (torre goblin em obra) e `House_Construction.png` (casa dos cavaleiros); a casa goblin não tem versão "em obra", então durante o conserto dá para usar a casa destruída com a barra de progresso, ou alternar entre destruída e inteira.
- **Código:** cabe no padrão de componentes já usado nos inimigos: um novo comportamento `comportamentos/repair_house.gd` no lugar do `Follow Player`, e a tag `origem = "reparador"`.

### Pontos de balanceamento
- Quantos reparadores podem existir ao mesmo tempo (1 por casa destruída?).
- Se destruir todas as casas dá algum bônus (ex.: fim antecipado da fase, ouro extra).
- Com as fases (seção 1), as casas podem começar a fase seguinte reconstruídas.

---

## 5. Ideias para depois (não implementar ainda)

### Mina de ouro
Sprites em `Addons/Tiny Swords/Resources/Gold Mine/` (192×128): `GoldMine_Active.png`, `GoldMine_Inactive.png`, `GoldMine_Destroyed.png`.
- **Fonte de ouro do player:** ficar perto da mina (ou interagir) gera ouro com o tempo, enquanto a horda pressiona. Um ponto de risco/recompensa no mapa.
- **Ou objetivo dos goblins:** goblins tentam tomar/destruir a mina; se ela for destruída, o player perde a renda até consertá-la (espelho das casas dos goblins).
- **Estados:** ativa (gerando), inativa (esgotada/esperando), destruída.
- Combina com a loja entre fases (seção 2): mais ouro = mais upgrades.

### Goblin do barril explosivo (kamikaze)
Sprite em `Addons/Tiny Swords/Factions/Goblins/Troops/Barrel/<Cor>/Barrel_<Cor>.png` (768×768, quadros de 128 px):
- linha 0 — barril fechado, parado (disfarçado)
- linhas 1 a 3 — o goblin espia/sai do barril e volta a se esconder
- linha 4 — andando com o barril
- linha 5 — pavio aceso, prestes a explodir
- **Comportamento:** fica disfarçado de barril comum pelo mapa; quando o player chega perto, acorda, corre até ele, acende o pavio e explode (dano em área, como a dinamite do goblin TNT). Matar antes que chegue evita a explosão.
- **Variações:** a explosão também fere outros goblins (dá para usar a favor do player); barris "falsos" decorativos misturados aos reais.

### Companions (aliados que seguem o player)
Sprites em `Addons/Tiny Swords/Factions/Knights/Troops/`: `Pawn`, `Archer`, `Warrior`.
- **Ideia:** aliados que seguem o paladino e ajudam na batalha.
  - **Peão aliado:** coleta ouro/carne do chão e traz para o player; pode consertar coisas (espelho do goblin reparador).
  - **Arqueiro:** fica um pouco atrás do player e atira flechas no goblin mais próximo.
  - **Guerreiro:** fica perto do player e ataca corpo a corpo, segurando o cerco.
- **Como conseguir:** comprar na loja entre as fases (ex.: contratar 1 aliado por vez, com limite), ou resgatar aliados presos no mapa.
- **Comportamento base:** seguir o player mantendo distância (formação simples em volta dele), escolher alvo, ter vida própria e poder morrer; os goblins também passam a mirar neles.
- **Upgrades possíveis:** vida/dano dos aliados, quantidade máxima, reviver na loja.

### Novos inimigos e inimigos de elite
- **Novos tipos:** o goblin do barril (acima) e outros que fujam do "andar até o player e bater" (ex.: atirador à distância, goblin que rouba ouro do chão e foge).
- **Elite:** versão mais forte de um inimigo comum — mais vida, mais dano, um pouco maior, com cor/brilho diferente — e com loot melhor (mais ouro, chance maior de poção/carne dourada). Aparece com mais frequência nas fases avançadas.

### Chefes (bosses)
- **Regra:** a cada X fases concluídas aparece um chefe para tentar acabar com o player.
- **Já existe a base:** o `PhaseManager` tem `fases_boss` (lista das fases de chefe) e `duracao_fase_boss` (até 5 min), e o HUD já mostra "Fase N - BOSS". Falta o chefe em si.
- **Ideias de chefe:** goblin gigante com barra de vida no topo da tela, ataques com padrão (investida, chuva de dinamite, chamar reforços), fases do chefe conforme a vida cai.
- **Recompensa:** muito ouro e/ou um upgrade especial ao derrotar.

### Usar os efeitos de explosão e fogo
Sprites em `Addons/Tiny Swords/Effects/Explosion/Explosions.png` (já usado na dinamite do goblin TNT) e `Addons/Tiny Swords/Effects/Fire/Fire.png` (ainda sem uso).
- **Casa do goblin pegando fogo:** quando a vida da casa fica baixa, fogo em cima dela; ao ser destruída, explosão + fogo que vai apagando.
- **Chão em chamas:** a dinamite deixa uma área com fogo por alguns segundos que dá dano a quem passar (player e goblins).
- **Goblin da tocha:** o ataque pode acender fogo no chão às vezes (inimigo de elite).
- **Barril explosivo:** a explosão do goblin kamikaze (acima).
- **Ritual/upgrade de fogo:** um upgrade da loja que faz o ritual do paladino deixar fogo no chão ou explodir inimigos que morrem nele.
- **Ataque de chefe:** chuva de explosões marcadas no chão antes de cair.

---

## 6. Como organizar no código (proposta)

- **`PhaseManager`** (novo nó no `main.tscn` ou autoload): controla o estado `FASE` → `FIM_DA_FASE` → `LOJA` → `FASE`, o cronômetro, a duração de cada fase e liga/desliga os spawners.
- **`PlayerStats`** (novo `Resource` guardado no `GameManager`): níveis de cada upgrade. Precisa sobreviver entre fases; no Game Over volta ao zero.
- **`ShopUI`** (nova cena em `UI/`): botões de upgrade com preço, contador de tempo e o botão "Próxima fase". Pode reaproveitar os banners e botões do Tiny Swords que já estão no projeto (`UI/Buttons`, `UI/Banners`).
- **Player:** ao entrar na fase, aplica os `PlayerStats` sobre os valores base (`attack_player`, `max_health`, `speed`, resistência).
- **Spawners:** recebem da fase o multiplicador de dificuldade (vida/dano dos inimigos, limite, intervalo).
- **GameManager:** hoje o `time_elapsed` é o tempo total; vai precisar também de um tempo **da fase**, e o `reset()` deve zerar os `PlayerStats`.

---

## 7. Regras de spawn já implementadas (referência)

- **Mob spawner em volta do player — progressão por tempo (fases com cotas):** matar um libera a vaga, então o spawn é contínuo. Editável no Inspector do `MobSpawner` (lista **Fases**, recurso `systems/spawn_fase.gd`).

  | Fase | Máximo | Ovelhas | Pawns | Goblins com tocha | Goblins TNT |
  |---|---|---|---|---|---|
  | 0:00 – 1:00 | 10 | 6 | 4 | — | — |
  | 1:00 – 3:00 | 10 | 3 | 3 | 4 | — |
  | 3:00 em diante | 12 | 2 | 3 | 5 | 2 |

- **Casas dos goblins — liberação por tempo:** quietas até 1:00; goblin com tocha a partir de 1:00 e TNT a partir de 3:00 (pesos 2:1).
- **Limite compartilhado:** o máximo e as cotas de cada fase valem para **todos os inimigos no mapa** (spawner + casas). Uma casa só solta um tipo se ainda houver vaga na cota da fase. Reparadores não contam no limite.
- **Divisão da cota de cada goblin** (Inspector do `MobSpawner`, "Divisão da cota"): `porcentagem_ao_redor` = parte reservada para nascer perto do player (padrão 50%, arredonda para cima); `porcentagem_casas` = máximo que as casas podem ocupar (padrão 50%, arredonda para baixo). Com 50/50: fase 1:00–3:00 → casas até 2 tochas; fase 3:00+ → casas até 2 tochas e 1 TNT.
- **Casas dos goblins:** spawners fixos, soltam um goblin (tocha ou TNT) a cada 8 s pela porta, sem limite. (`systems/house_spawner.gd`.)
- **Tag de origem:** todo inimigo sabe quem o criou (`origem = "mob_spawner"` ou `"casa"`) e entra no grupo `origem_<nome>`.
- **Cerco:** os inimigos param ao encostar no player e o player não atravessa a horda; se ele se descuidar, fica preso.
- **Spawn seguro:** nunca na água nem dentro de paredes, árvores ou casas (`systems/spawn_utils.gd`).

> Com as fases de jogo (seção 1), as fases do spawner podem passar a contar o tempo **da fase** em vez do tempo total.

---

## 8. Ajustes pendentes notados no código original

Pequenos bugs encontrados durante a recuperação do projeto; vale corrigir antes de balancear as fases:

- [ ] **Inimigo só morre no golpe seguinte:** em `enemy.gd`, a checagem `health <= 0` acontece *antes* de subtrair o dano, então um inimigo com 0 de vida precisa levar mais um golpe para morrer.
- [ ] **Ondas do DificultySystem:** a fórmula `sin(wave_duration / ((time/60) * TAU))` divide pelo tempo, então a onda fica caótica no começo e quase parada depois. O esperado é `sin((time * TAU) / wave_duration)`.
- [ ] **Sorteio de loot:** em `loot.gd`, `max_chance =+ drop_chance` (deveria ser `+=`) faz o sorteio usar só a última chance da lista.
- [ ] **Dano aleatório pode ser 0:** espada e ritual usam `dano * randf()`, que às vezes dá 0 ao converter para inteiro. Sugestão: `randf_range(0.7, 1.0)`.
