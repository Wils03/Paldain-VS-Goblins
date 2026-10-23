class_name MobSpawner
extends Node2D

#PROGRESSÃO: fases por tempo de partida. Cada fase diz, a partir de um minuto,
#o máximo de inimigos vivos NO MAPA e a cota de cada tipo (veja systems/spawn_fase.gd).
#Contam os inimigos deste spawner E os das casas dos goblins (reparadores não contam).
#Quando o player mata uma criatura, abre vaga e nasce outra do tipo que está faltando.
@export var fases: Array[SpawnFase];
#TileMap do mapa, usado para saber onde existe chão
@export var solo: TileMap;
#Tentativas de achar um ponto válido a cada spawn
@export var max_attempts: int = 10;
@export_category("Divisão da cota (spawner x casas)")
#% da cota de cada tipo RESERVADA para nascer ao redor do player (arredonda para cima)
@export_range(0, 100, 5, "suffix:%") var porcentagem_ao_redor: int = 50;
#% MÁXIMA da cota de cada tipo que as casas dos goblins podem ocupar (arredonda para baixo).
#Se as duas somarem menos de 100%, a sobra fica livre para quem chegar primeiro;
#se passarem de 100%, a reserva ao redor do player tem prioridade.
@export_range(0, 100, 5, "suffix:%") var porcentagem_casas: int = 50;

var mobs_per_minute: float = 20.0;

@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D

var cooldown: float = 0.0;

#Origens que entram no limite e nas cotas
const ORIGENS_CONTADAS = [Enemy.ORIGEM_MOB_SPAWNER, Enemy.ORIGEM_CASA];
const GROUP = "mob_spawner";

func _ready():
	#As casas dos goblins consultam este spawner para saber se há vaga
	add_to_group(GROUP);

func _process(delta):
	#Iginorar GameOver
	if GameManager.is_game_over: return;
	#Temporizador (cooldown)
	cooldown -= delta
	if cooldown > 0 : return

	#Frrequencia ( quantos monstros por minuto;
	var interval = 60.0 / mobs_per_minute
	cooldown = interval

	#FASE ATUAL e LIMITE (inimigos do spawner + das casas)
	var fase = fase_atual();
	if not fase: return
	var vivos = contar_vivos_por_tipo();
	if total_vivos(vivos) >= fase.limite_total(): return

	#Escolher um tipo que ainda tem vaga na cota da fase
	var scene = pegar_mob(fase, vivos);
	if not scene: return
	var creature = scene.instantiate();

	#PROCURAR UM PONTO VÁLIDO (fora de paredes e da água)
	var point = pegar_posicao_valida(creature);
	if point == Vector2.INF:
		creature.queue_free();
		return

	#Posicionar NO PONTO VALIDADO
	creature.global_position = point;
	creature.set_origem(Enemy.ORIGEM_MOB_SPAWNER);
	get_parent().add_child(creature);

#Última fase cujo minuto de início já passou
func fase_atual() -> SpawnFase:
	var minutos = GameManager.time_elapsed / 60.0;
	var atual: SpawnFase = null;
	for fase in fases:
		if fase and minutos >= fase.a_partir_do_minuto:
			if atual == null or fase.a_partir_do_minuto >= atual.a_partir_do_minuto:
				atual = fase;
	return atual;

#Máximo de criaturas vivas do spawner no tempo atual
func limite_atual() -> int:
	var fase = fase_atual();
	return fase.limite_total() if fase else 0;

#Caminho da cena -> quantidade viva (spawner + casas)
func contar_vivos_por_tipo() -> Dictionary:
	var vivos = {};
	for origem in ORIGENS_CONTADAS:
		for enemy in get_tree().get_nodes_in_group("origem_" + origem):
			if enemy.is_queued_for_deletion(): continue
			vivos[enemy.scene_file_path] = vivos.get(enemy.scene_file_path, 0) + 1;
	return vivos;

func total_vivos(vivos: Dictionary) -> int:
	var total = 0;
	for path in vivos:
		total += vivos[path];
	return total;

#Usado pelas casas: este tipo ainda cabe no limite, na cota da fase atual
#e na parte da cota que NÃO está reservada para o spawner?
func casa_pode_soltar(scene: PackedScene) -> bool:
	var fase = fase_atual();
	if not fase: return false
	var vivos = contar_vivos_por_tipo();
	if total_vivos(vivos) >= fase.limite_total(): return false
	var cota = fase.cotas.get(scene, 0);
	if cota - vivos.get(scene.resource_path, 0) <= 0: return false
	return contar_vivos_da_origem(scene, Enemy.ORIGEM_CASA) < cota_das_casas(cota);

#Quantos de uma cota as casas podem ocupar, respeitando as duas porcentagens
func cota_das_casas(cota: int) -> int:
	var reservado_ao_redor = ceili(cota * porcentagem_ao_redor / 100.0);
	var maximo_casas = floori(cota * porcentagem_casas / 100.0);
	return clampi(min(maximo_casas, cota - reservado_ao_redor), 0, cota);

func contar_vivos_da_origem(scene: PackedScene, origem: String) -> int:
	var total = 0;
	for enemy in get_tree().get_nodes_in_group("origem_" + origem):
		if not enemy.is_queued_for_deletion() and enemy.scene_file_path == scene.resource_path:
			total += 1;
	return total;

#Sorteia entre os tipos com vaga; quem está mais longe da cota tem mais chance
func pegar_mob(fase: SpawnFase, vivos: Dictionary) -> PackedScene:
	var candidatos = [];
	var total_vagas = 0;
	for scene in fase.cotas:
		var vagas = fase.cotas[scene] - vivos.get(scene.resource_path, 0);
		if vagas > 0:
			candidatos.append([scene, vagas]);
			total_vagas += vagas;
	if candidatos.is_empty(): return null
	var roll = randi_range(1, total_vagas);
	for candidato in candidatos:
		roll -= candidato[1];
		if roll <= 0:
			return candidato[0];
	return candidatos.back()[0];

func pegar_posicao_valida(creature: Node2D) -> Vector2:
	for i in max_attempts:
		var point = pegar_posicao();
		if SpawnUtils.ponto_valido(self, point, creature, solo):
			return point;
	return Vector2.INF;

func pegar_posicao() -> Vector2:
	path_follow_2d.progress_ratio = randf() #Random Float
	return path_follow_2d.global_position;
