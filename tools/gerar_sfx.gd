extends SceneTree

# Gera os efeitos sonoros retrô (8-bit) do jogo em res://Audio/sfx/.
# Rodar pelo terminal, na pasta do projeto:
#   godot --headless --path . --script res://tools/gerar_sfx.gd
# Para trocar um som por um definitivo, basta substituir o .wav com o mesmo nome.

const RATE = 22050
const OUT_DIR = "res://Audio/sfx/"

var rng = RandomNumberGenerator.new()

func _initialize():
	rng.seed = 2024
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	for i in 3: save("sword_swing_%d" % (i + 1), sword_swing(i), 0.7)
	for i in 2: save("sword_hit_%d" % (i + 1), sword_hit(i), 0.85)
	save("player_hurt", player_hurt(), 0.8)
	save("player_death", player_death(), 0.85)
	for i in 3: save("goblin_death_%d" % (i + 1), goblin_death(i), 0.6)
	save("sheep_death", sheep_death(), 0.6)
	save("dynamite_fuse", dynamite_fuse(), 0.35)
	for i in 2: save("explosion_%d" % (i + 1), explosion(i), 0.95)
	for i in 2: save("house_hit_%d" % (i + 1), house_hit(i), 0.7)
	save("house_destroyed", house_destroyed(), 0.9)
	save("house_repaired", house_repaired(), 0.55)
	save("ritual_cast", ritual_cast(), 0.7)
	save("gold_pickup", gold_pickup(), 0.45)
	save("meat_pickup", meat_pickup(), 0.55)
	save("ui_click", ui_click(), 0.4)
	save("ui_confirm", ui_confirm(), 0.5)
	quit()

#region SÍNTESE BÁSICA
func n_samples(seconds: float) -> int:
	return int(seconds * RATE)

func buffer(seconds: float) -> PackedFloat32Array:
	var b = PackedFloat32Array()
	b.resize(n_samples(seconds))
	return b

# Oscilador com frequência variando de f0 a f1 (curva exponencial)
func tone(seconds: float, f0: float, f1: float, wave: String, vibrato_hz := 0.0, vibrato_depth := 0.0, duty := 0.5) -> PackedFloat32Array:
	var b = buffer(seconds)
	var phase = 0.0
	var count = b.size()
	for i in count:
		var t = float(i) / count
		var f = f0 * pow(f1 / f0, t)
		if vibrato_hz > 0.0:
			f *= 1.0 + vibrato_depth * sin(TAU * vibrato_hz * i / RATE)
		phase = fmod(phase + f / RATE, 1.0)
		match wave:
			"square": b[i] = 1.0 if phase < duty else -1.0
			"saw": b[i] = phase * 2.0 - 1.0
			"triangle": b[i] = 4.0 * absf(phase - 0.5) - 1.0
			_: b[i] = sin(TAU * phase)
	return b

func noise(seconds: float) -> PackedFloat32Array:
	var b = buffer(seconds)
	for i in b.size():
		b[i] = rng.randf_range(-1.0, 1.0)
	return b

# Passa-baixa de um polo com corte variando de c0 a c1 (Hz)
func lowpass(b: PackedFloat32Array, c0: float, c1: float) -> PackedFloat32Array:
	var y = 0.0
	var count = b.size()
	for i in count:
		var cutoff = lerp(c0, c1, float(i) / count)
		var a = 1.0 - exp(-TAU * cutoff / RATE)
		y += a * (b[i] - y)
		b[i] = y
	return b

func highpass(b: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var low = lowpass(b.duplicate(), cutoff, cutoff)
	for i in b.size():
		b[i] -= low[i]
	return b

# Envelope: ataque linear e decaimento exponencial
func envelope(b: PackedFloat32Array, attack: float, decay_curve := 3.0) -> PackedFloat32Array:
	var count = b.size()
	var attack_n = max(1, n_samples(attack))
	for i in count:
		var g = 1.0
		if i < attack_n:
			g = float(i) / attack_n
		else:
			g = pow(1.0 - float(i - attack_n) / max(1, count - attack_n), decay_curve)
		b[i] *= g
	return b

func gain(b: PackedFloat32Array, g: float) -> PackedFloat32Array:
	for i in b.size():
		b[i] *= g
	return b

# Soma b em a a partir de "offset" segundos
func mix(a: PackedFloat32Array, b: PackedFloat32Array, offset := 0.0) -> PackedFloat32Array:
	var start = n_samples(offset)
	if a.size() < start + b.size():
		a.resize(start + b.size())
	for i in b.size():
		a[start + i] += b[i]
	return a

func concat(parts: Array) -> PackedFloat32Array:
	var out = PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out

# Normaliza o pico, aplica fade curto nas pontas e salva em 16 bits
func save(file_name: String, b: PackedFloat32Array, peak: float):
	var max_abs = 0.0
	for v in b:
		max_abs = max(max_abs, absf(v))
	var scale = peak / max_abs if max_abs > 0.0 else 1.0
	var fade = n_samples(0.004)
	var data = PackedByteArray()
	data.resize(b.size() * 2)
	for i in b.size():
		var v = b[i] * scale
		if i < fade: v *= float(i) / fade
		if i > b.size() - fade: v *= float(b.size() - i) / fade
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 32767.0))
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	var path = ProjectSettings.globalize_path(OUT_DIR + file_name + ".wav")
	var err = wav.save_to_wav(path)
	print("%s %s (%.2fs)" % ["salvo" if err == OK else "ERRO", file_name, float(b.size()) / RATE])
#endregion

#region EFEITOS
func sword_swing(v: int) -> PackedFloat32Array:
	# Whoosh: ruído com filtro que abre e fecha
	var d = 0.17 + v * 0.03
	var b = noise(d)
	var count = b.size()
	var y = 0.0
	for i in count:
		var t = float(i) / count
		var cutoff = 300.0 + 3800.0 * sin(PI * t) * (0.8 + 0.15 * v)
		var a = 1.0 - exp(-TAU * cutoff / RATE)
		y += a * (b[i] - y)
		b[i] = y * sin(PI * t)
	return highpass(b, 250.0)

func sword_hit(v: int) -> PackedFloat32Array:
	# Estalo + baque grave
	var crack = envelope(highpass(noise(0.06), 1200.0), 0.001, 2.0)
	var thump = envelope(tone(0.14, 190.0 - v * 25.0, 55.0, "square", 0, 0, 0.35), 0.002, 2.5)
	return mix(gain(crack, 0.9), gain(thump, 0.7))

func player_hurt() -> PackedFloat32Array:
	var t = envelope(tone(0.22, 420.0, 140.0, "square", 30.0, 0.05), 0.003, 1.5)
	var n = envelope(lowpass(noise(0.08), 3000.0, 800.0), 0.001, 2.0)
	return mix(t, gain(n, 0.4))

func player_death() -> PackedFloat32Array:
	# Arpejo descendente + queda
	var notes = [440.0, 370.0, 311.0, 262.0, 196.0, 131.0]
	var parts = []
	for f in notes:
		parts.append(envelope(tone(0.11, f, f * 0.97, "square"), 0.002, 1.2))
	var b = concat(parts)
	var fall = envelope(lowpass(noise(0.35), 1500.0, 200.0), 0.005, 2.0)
	return mix(b, gain(fall, 0.5), 0.5)

func goblin_death(v: int) -> PackedFloat32Array:
	# Guincho agudo descendente com vibrato
	var start = [950.0, 1150.0, 820.0][v]
	return envelope(tone(0.26, start, start * 0.3, "square", 22.0 + v * 4.0, 0.08, 0.3), 0.003, 1.8)

func sheep_death() -> PackedFloat32Array:
	# "Béé": dente-de-serra com vibrato forte, filtrado
	var b = tone(0.45, 320.0, 260.0, "saw", 9.0, 0.12)
	b = lowpass(b, 1800.0, 900.0)
	return envelope(b, 0.03, 1.4)

func dynamite_fuse() -> PackedFloat32Array:
	# Chiado com estalinhos
	var b = highpass(noise(0.5), 3000.0)
	for i in b.size():
		if rng.randf() < 0.004:
			b[i] *= 6.0
	return envelope(b, 0.02, 0.8)

func explosion(v: int) -> PackedFloat32Array:
	var d = 0.7 + v * 0.15
	var n = envelope(lowpass(noise(d), 5000.0, 150.0), 0.002, 2.2)
	var boom = envelope(tone(d * 0.7, 90.0 - v * 15.0, 35.0, "sine"), 0.002, 1.8)
	return mix(n, gain(boom, 0.9))

func house_hit(v: int) -> PackedFloat32Array:
	# Batida em madeira
	var knock = envelope(tone(0.12, 240.0 - v * 40.0, 120.0, "triangle"), 0.001, 3.0)
	var click = envelope(lowpass(noise(0.03), 4000.0, 1500.0), 0.001, 2.0)
	return mix(knock, gain(click, 0.6))

func house_destroyed() -> PackedFloat32Array:
	# Várias tábuas quebrando + estrondo
	var b = envelope(lowpass(noise(1.0), 2500.0, 120.0), 0.01, 1.6)
	for k in 6:
		var crack = envelope(tone(0.1, rng.randf_range(160, 320), 80.0, "triangle"), 0.001, 3.0)
		b = mix(b, gain(crack, 0.8), k * 0.11 + rng.randf_range(0, 0.05))
	return b

func house_repaired() -> PackedFloat32Array:
	# Martelada + arpejo ascendente
	var hammer = envelope(tone(0.06, 900.0, 600.0, "square", 0, 0, 0.25), 0.001, 3.0)
	var notes = [523.0, 659.0, 784.0, 1047.0]
	var parts = []
	for f in notes:
		parts.append(envelope(tone(0.08, f, f, "square", 0, 0, 0.25), 0.002, 0.8))
	return mix(hammer, concat(parts), 0.08)

func ritual_cast() -> PackedFloat32Array:
	# Arpejo brilhante com "coral" (vozes levemente desafinadas)
	var b = buffer(0.95)
	var notes = [523.0, 659.0, 784.0, 1047.0, 1319.0]
	for k in notes.size():
		var f = notes[k]
		var voice = tone(0.6, f, f, "sine", 6.0, 0.006)
		voice = mix(voice, gain(tone(0.6, f * 1.006, f * 1.006, "triangle"), 0.5))
		b = mix(b, envelope(voice, 0.04, 1.5), k * 0.07)
	var shimmer = envelope(highpass(noise(0.9), 6000.0), 0.2, 1.5)
	return mix(b, gain(shimmer, 0.15))

func gold_pickup() -> PackedFloat32Array:
	# Moeda clássica: duas notas
	var a = envelope(tone(0.05, 988.0, 988.0, "square"), 0.001, 0.3)
	var b = envelope(tone(0.18, 1319.0, 1319.0, "square"), 0.001, 1.8)
	return concat([a, b])

func meat_pickup() -> PackedFloat32Array:
	var crunch = envelope(lowpass(noise(0.07), 3500.0, 1200.0), 0.001, 2.0)
	var heal = envelope(tone(0.22, 400.0, 900.0, "triangle", 12.0, 0.03), 0.01, 1.2)
	return mix(crunch, heal, 0.05)

func ui_click() -> PackedFloat32Array:
	return envelope(tone(0.035, 1300.0, 1100.0, "square", 0, 0, 0.25), 0.001, 2.0)

func ui_confirm() -> PackedFloat32Array:
	var a = envelope(tone(0.07, 660.0, 660.0, "square"), 0.002, 0.6)
	var b = envelope(tone(0.16, 990.0, 990.0, "square"), 0.002, 1.5)
	return concat([a, b])
#endregion
