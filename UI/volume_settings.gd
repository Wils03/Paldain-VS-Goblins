extends VBoxContainer

#Painel com os controles de volume (usado no menu principal e na pausa).
#Cria uma linha por categoria de Settings.CATEGORIES: nome, slider e porcentagem.

#Evita tocar o som de teste a cada passinho do slider
var preview_cooldown: float = 0.0;

func _ready():
	var grid = GridContainer.new();
	grid.name = "Grid";
	grid.columns = 3;
	grid.add_theme_constant_override("h_separation", 16);
	grid.add_theme_constant_override("v_separation", 10);
	add_child(grid);

	for category in Settings.CATEGORIES:
		add_row(grid, category[0], category[1]);

func _process(delta):
	preview_cooldown -= delta;

func add_row(grid: GridContainer, bus: String, title: String):
	var label = Label.new();
	label.text = title;
	label.custom_minimum_size = Vector2(110, 0);
	grid.add_child(label);

	var slider = HSlider.new();
	slider.name = bus + "Slider";
	slider.min_value = 0;
	slider.max_value = 100;
	slider.step = 5;
	slider.custom_minimum_size = Vector2(220, 28);
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER;
	slider.value = Settings.get_volume(bus) * 100.0;
	grid.add_child(slider);

	var value_label = Label.new();
	value_label.custom_minimum_size = Vector2(56, 0);
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT;
	value_label.text = "%d%%" % slider.value;
	grid.add_child(value_label);

	slider.value_changed.connect(func(value): on_volume_changed(bus, value, value_label));

func on_volume_changed(bus: String, value: float, value_label: Label):
	Settings.set_volume(bus, value / 100.0);
	Settings.save_settings();
	value_label.text = "%d%%" % value;
	#Som de teste para o jogador ouvir o novo volume
	if (bus == Settings.BUS_SFX or bus == Settings.BUS_MASTER) and preview_cooldown <= 0.0:
		preview_cooldown = 0.15;
		Sfx.play("ui_click");
