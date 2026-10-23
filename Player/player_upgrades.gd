class_name PlayerUpgrades
extends Node

#BLOCO DE UPGRADES do player (nó "Upgrades" dentro do Player).
#Guarda os níveis comprados na loja e soma os bônus aos atributos base do player.
#Os níveis valem só na partida: no Game Over a cena recarrega e tudo volta ao zero.

const VIDA = "vida";
const ATAQUE = "ataque";
const RITUAL = "ritual";
const VELOCIDADE = "velocidade";

#Ordem em que aparecem na loja
const ORDEM = [VIDA, ATAQUE, RITUAL, VELOCIDADE];

#Definição de cada upgrade: nome, texto do efeito, nível máximo e ícone
const DEFINICOES = {
	VIDA: {"nome": "Vida máxima", "efeito": "vida máxima", "max": 10, "icone": "res://UI/icons/heart.png"},
	ATAQUE: {"nome": "Dano de ataque", "efeito": "dano da espada", "max": 10, "icone": "res://Addons/Tiny Swords/UI/Icons Loja/sword.png"},
	RITUAL: {"nome": "Dano do ritual", "efeito": "dano do ritual", "max": 10, "icone": "res://UI/icons/magic_star.png"},
	VELOCIDADE: {"nome": "Velocidade", "efeito": "velocidade", "max": 10, "icone": "res://Addons/Tiny Swords/UI/Icons Loja/speed.png"},
};

@export_category("Bônus por nível (% do valor base)")
@export_range(0, 100, 1, "suffix:%") var bonus_vida: int = 5;
@export_range(0, 100, 1, "suffix:%") var bonus_ataque: int = 5;
@export_range(0, 100, 1, "suffix:%") var bonus_ritual: int = 5;
@export_range(0, 100, 1, "suffix:%") var bonus_velocidade: int = 5;

@export_category("Ritual: recarga")
#A cada X níveis do upgrade de ritual, a recarga diminui Y segundos
@export var niveis_por_reducao_recarga: int = 2;
@export var reducao_recarga: float = 2.0;
#Recarga mínima do ritual (segundos)
@export var recarga_minima: float = 10.0;

@export_category("Preço (ouro)")
#Preço do primeiro nível de cada upgrade
@export var preco_inicial: int = 5;
#Quanto o preço aumenta a cada nível comprado: 5, 7, 9, 11...
@export var aumento_por_nivel: int = 2;

var niveis: Dictionary = {};
#Atributos do player antes dos upgrades
var base: Dictionary = {};
#Recarga do ritual antes dos upgrades (segundos)
var recarga_base: float = 30.0;

@onready var player: Node = get_parent();

func _ready():
	base = {
		VIDA: float(player.max_health),
		ATAQUE: float(player.attack_player),
		RITUAL: float(player.ritual_damage),
		VELOCIDADE: float(player.speed),
	};
	recarga_base = float(player.ritual_interval);
	aplicar();

func nivel(id: String) -> int:
	return niveis.get(id, 0);

func no_maximo(id: String) -> bool:
	return nivel(id) >= DEFINICOES[id].max;

func preco(id: String) -> int:
	return preco_inicial + aumento_por_nivel * nivel(id);

#Bônus de um nível, em fração (5% = 0.05)
func bonus(id: String) -> float:
	match id:
		VIDA: return bonus_vida / 100.0;
		ATAQUE: return bonus_ataque / 100.0;
		RITUAL: return bonus_ritual / 100.0;
		VELOCIDADE: return bonus_velocidade / 100.0;
	return 0.0;

#Texto do efeito de um nível, ex.: "+5% de dano da espada"
func texto_efeito(id: String) -> String:
	return "+%d%% de %s" % [roundi(bonus(id) * 100.0), DEFINICOES[id].efeito];

func pode_comprar(id: String) -> bool:
	return not no_maximo(id) and GameManager.gold_counter >= preco(id);

#Compra um nível: desconta o ouro e atualiza os atributos do player
func comprar(id: String) -> bool:
	if not pode_comprar(id): return false
	GameManager.gold_counter -= preco(id);
	var vida_antes = player.max_health;
	niveis[id] = nivel(id) + 1;
	aplicar();
	if id == VIDA:
		#A vida ganha também é curada
		player.health = min(player.health + (player.max_health - vida_antes), player.max_health);
	return true;

#ATRIBUTO FINAL = base x (1 + bônus por nível x nível)
func valor_com_bonus(id: String) -> float:
	return base[id] * (1.0 + bonus(id) * nivel(id));

func aplicar():
	player.max_health = roundf(valor_com_bonus(VIDA));
	player.attack_player = valor_com_bonus(ATAQUE);
	player.ritual_damage = roundi(valor_com_bonus(RITUAL));
	player.speed = valor_com_bonus(VELOCIDADE);
	player.ritual_interval = recarga_ritual();
	player.health = min(player.health, player.max_health);

#Recarga do ritual: a cada X níveis de ritual, Y segundos a menos (até o mínimo)
func recarga_ritual() -> float:
	if niveis_por_reducao_recarga <= 0: return recarga_base
	var reducoes = nivel(RITUAL) / niveis_por_reducao_recarga;
	return max(recarga_base - reducao_recarga * reducoes, recarga_minima);

#Texto do valor atual de cada atributo, para mostrar na loja
func valor_atual(id: String) -> String:
	match id:
		VIDA: return "%d de vida" % roundi(player.max_health);
		ATAQUE: return "%.1f de dano" % float(player.attack_player);
		RITUAL: return "%d de dano  •  recarga %ds" % [player.ritual_damage, roundi(player.ritual_interval)];
		VELOCIDADE: return "%d%% da velocidade" % roundi(100.0 * player.speed / base[VELOCIDADE]);
	return "";
