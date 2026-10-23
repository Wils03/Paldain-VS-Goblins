extends Label

@onready var player:Player = GameManager.player;
@onready var cooldownRitual: Label = %CooldownRitualLabel
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_cooldown_ritual();

func update_cooldown_ritual():
	if (player == null):
		cooldownRitual.text = str("---");
	else:
		if player.ritual_cooldown == 0:
			print("SACRED SPELL PRONTO");
		if player.ritual_cooldown < 0:
			cooldownRitual.text = str(0)
		else:
			cooldownRitual.text = str(roundi(player.ritual_cooldown))
	
