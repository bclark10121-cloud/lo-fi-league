extends Node3D
# Lo-Fi League: the pitch, the rules, the computer players, the camera and the test bot.
# Pitch units are yards. The pitch runs along X. Goal lines sit at x = -30 and x = +30. Sidelines sit at z = -20 and z = +20.
# Side 0 (the player) always attacks +X, the right of the screen. The camera sits on the +Z sideline.
# Players move with plain maths, not physics bodies. This file sets `want` and each player eases toward it.

const PlayerModel := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/hud.gd")
const League := preload("res://scripts/league.gd")
const SaveStore := preload("res://addons/bc_common/save_store.gd")
const TestBridge := preload("res://addons/bc_common/test_bridge.gd")
const InputSetup := preload("res://addons/bc_common/input_setup.gd")

const VERSION := "0.2.3"
const HL := 30.0
const HW := 20.0
const GOAL_HW := 3.0
const GOAL_H := 2.2
const BOX_D := 10.0
const BOX_HW := 10.0
const BALL_R := 0.25
const GRAV := 17.0
const ROLL := 7.0
const HALF_SECS := 180.0
const RUN := 6.4
const SPRINT := 1.28
const SAVE_PATH := "user://lofi_league.json"

enum {S_TITLE, S_TEAMS, S_PLAY, S_MODES, S_LEAGUE}
enum {RESTART, LIVE, GOAL, HALFTIME, OVER}

class P extends RefCounted:
	var side := 0
	var gk := false
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var want := Vector2.ZERO
	var face := Vector2.RIGHT
	var home := Vector2(0.5, 0.5)
	var spd := 1.0
	var pas := 1.0
	var sht := 1.0
	var tck := 1.0
	var ctl := 1.0
	var stun := 0.0
	var tackle_cd := 0.0
	var kick_cd := 0.0
	var dive_cd := 0.0
	var dive_t := 0.0
	var dive_v := Vector2.ZERO
	var react := 0.0
	var think := 0.0
	var hold := 0.0
	var burst := 1.0
	var sprint := false
	var jit := Vector2.ZERO
	var jit_t := 0.0
	var itime := 9.0
	var ipt := Vector2.ZERO
	var pname := ""
	var num := 0
	var node: Node3D

var teams: Array = []
var by_id := {}
var league_cfg := {}
var mode := "attract"          # attract, exhibition, practice or league
var pick_for := "exhibition"   # what the club picker is choosing for
var bot_season := false
var forms := {}
var hud
var cam: Camera3D
var cam_x := 0.0
var cam_z := 0.0
var ball_node: MeshInstance3D
var players_root: Node3D

var screen := S_TITLE
var state := RESTART
var state_t := 0.0
var human := false
var attract := true
var practice := false
var paused := false
var bot := false
var bot_games := 6
var bot_done := 0
var verbose := false
var test_hook := false
var store: SaveStore
var bridge: TestBridge

var pl: Array = [[], []]
var all: Array = []
var team_ix := [0, 1]
var score := [0, 0]
var shots := [0, 0]
var saves := [0, 0]
var poss_t := [0.0, 0.0]
var counts := {"throw": 0, "corner": 0, "goalkick": 0, "kickoff": 0}
var half := 1
var clock := 0.0

var bpos := Vector3(0, BALL_R, 0)
var bvel := Vector3.ZERO
var carrier: P = null
var gk_hands := false
var last_touch := 0
var last_kicker: P = null
var kick_lock := 0.0
var pass_to: P = null
var poss := -1
var protect := 0.0
var ctrl: P = null
var charge := -1.0
var fut: Array = []
var chaser: Array = [null, null]
var second: Array = [null, null]
var gk_claim: Array = [false, false]

var rs_kind := ""
var rs_side := 0
var rs_spot := Vector2.ZERO
var rs_taker: P = null
var rs_t := 0.0
var rs_fly := 0.0

var in_mv := Vector2.ZERO
var in_a := false
var in_b := false
var in_c := false
var in_sw := false
var a_just := false
var b_just := false
var sw_just := false
var _pa := false
var _pb := false
var _psw := false

var save := {"v": 1, "sound": true, "music": true, "wins": 0, "draws": 0, "losses": 0, "goals_for": 0, "goals_against": 0, "team": "",
	"league": {}, "seasons": 0, "titles": 0, "best_finish": 0, "last_mode": "", "text": -1}
# v0.2.3 added last_mode (the last mode played) and text (-1 automatic, 0 normal, 1 large)
var goals: Array = []   # this match: {"side", "name", "min"} for each goal, for the full time screen
var snd := {}
var music: AudioStreamPlayer
var tracks: Array = []
var track_i := 0
var audio_started := false

# ---------- setup ----------

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--bot": bot = true
		elif a == "--verbose": verbose = true
		elif a.begins_with("--games="): bot_games = int(a.substr(8))
		elif a == "--season": bot_season = true
	InputSetup.add_controller_ui()   # G5.8: Xbox A picks the focused button in every menu, B goes back
	store = SaveStore.new(SAVE_PATH); store.disabled = bot
	# E6.7: clamp the counters so an edited or broken save can never load a silly number
	store.limits = {"wins": [0, 1000000], "draws": [0, 1000000], "losses": [0, 1000000], "goals_for": [0, 10000000],
		"goals_against": [0, 10000000], "seasons": [0, 100000], "titles": [0, 100000], "best_finish": [0, 8], "text": [-1, 1]}
	bridge = TestBridge.new("lofi"); test_hook = bridge.enabled
	teams = _load_json("res://data/teams.json")
	for t in teams: by_id[t.id] = t
	league_cfg = _load_json("res://data/league.json")
	for f in _load_json("res://data/formations.json"): forms[f.id] = f.spots
	_load_save()
	_build_world()
	hud = HudScript.new(); add_child(hud); hud.build(VERSION, teams)
	hud.start_pressed.connect(_on_start)
	hud.team_chosen.connect(_on_team)
	hud.menu_action.connect(_on_menu)
	_build_audio()
	_apply_audio_labels()
	_apply_text()
	if bot:
		if OS.get_cmdline_user_args().has("--rules"):
			_rules_test(); get_tree().quit(); return
		if bot_season:
			_bot_season_start(); return
		_bot_next()
	else:
		_to_title()

func _load_json(path: String):
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if d == null:
		push_error("could not read " + path); return []
	return d

func _load_save() -> void:
	# shared save (G10): fills only known fields, keeps number fields as numbers across a reload
	if store.load_into(save) and not save.league.is_empty() and int(save.league.get("v", 0)) != 1: save.league = {}

func _write_save() -> void:
	# shared save (G10, E6.4): browser syncs to IndexedDB at once, Android writes a temp file and renames it
	if bot: return
	store.write(save)

func dirx(side: int) -> float:
	return 1.0 if side == 0 else -1.0

func ball2() -> Vector2:
	return Vector2(bpos.x, bpos.z)

func style(side: int, key: String) -> float:
	return float(teams[team_ix[side]].style[key]) / 100.0

func _rate(v) -> float:
	return 0.85 + float(v) / 100.0 * 0.3

# ---------- world ----------

func _mesh(m: Mesh, pos: Vector3, c: Color, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.mesh = m; mi.position = pos; mi.material_override = PlayerModel.mat(c)
	(parent if parent else self).add_child(mi)
	return mi

func _boxm(size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var b := BoxMesh.new(); b.size = size
	return _mesh(b, pos, c)

func _build_world() -> void:
	var env := Environment.new()
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.33, 0.62); sm.sky_horizon_color = Color(1.0, 0.72, 0.62); sm.sky_curve = 0.25
	sm.ground_bottom_color = Color(0.5, 0.42, 0.55); sm.ground_horizon_color = Color(1.0, 0.72, 0.62); sm.sun_angle_max = 0.0
	sky.sky_material = sm; env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.78, 0.7, 0.9); env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.light_color = Color(1.0, 0.86, 0.76); sun.light_energy = 1.05
	sun.rotation_degrees = Vector3(-50, -32, 0); sun.shadow_enabled = not bot
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL; sun.directional_shadow_max_distance = 90.0; add_child(sun)
	cam = Camera3D.new(); cam.fov = 36.0; cam.far = 300.0; add_child(cam); cam.position = Vector3(0, 25, 35); cam.look_at(Vector3(0, 0, 1.5))
	players_root = Node3D.new(); add_child(players_root)
	if bot: return
	# ground far below the pitch so the two never share a depth
	var gp := PlaneMesh.new(); gp.size = Vector2(400, 300)
	_mesh(gp, Vector3(0, -0.6, 0), Color(0.36, 0.4, 0.42))
	# the pitch: stripes, lines and marks are painted into one texture
	var pm := PlaneMesh.new(); pm.size = Vector2(76, 54)
	var pitch := MeshInstance3D.new(); pitch.mesh = pm; add_child(pitch)
	var pmat := StandardMaterial3D.new(); pmat.albedo_texture = _pitch_tex(); pmat.roughness = 1.0; pitch.material_override = pmat
	# skirt so the pitch reads as a raised slab
	for s in [-1.0, 1.0]:
		_boxm(Vector3(76, 0.6, 0.4), Vector3(0, -0.3, s * 27.2), Color(0.13, 0.27, 0.19))
		_boxm(Vector3(0.4, 0.6, 54.8), Vector3(s * 38.2, -0.3, 0), Color(0.13, 0.27, 0.19))
	# goals
	var post_c := Color(0.97, 0.95, 0.9)
	for s in [-1.0, 1.0]:
		for zz in [-GOAL_HW, GOAL_HW]:
			var c := CylinderMesh.new(); c.top_radius = 0.1; c.bottom_radius = 0.1; c.height = GOAL_H; c.radial_segments = 8
			_mesh(c, Vector3(s * HL, GOAL_H / 2, zz), post_c)
			_boxm(Vector3(1.7, 0.08, 0.08), Vector3(s * (HL + 0.85), GOAL_H, zz), post_c)
		_boxm(Vector3(0.18, 0.18, GOAL_HW * 2 + 0.2), Vector3(s * HL, GOAL_H, 0), post_c)
		var net := StandardMaterial3D.new(); net.albedo_color = Color(1, 1, 1, 0.3); net.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; net.cull_mode = BaseMaterial3D.CULL_DISABLED
		var nb := BoxMesh.new(); nb.size = Vector3(0.06, GOAL_H, GOAL_HW * 2)
		var n1 := MeshInstance3D.new(); n1.mesh = nb; n1.position = Vector3(s * (HL + 1.7), GOAL_H / 2, 0); n1.material_override = net; add_child(n1)
		var nt := BoxMesh.new(); nt.size = Vector3(1.7, 0.06, GOAL_HW * 2)
		var n2 := MeshInstance3D.new(); n2.mesh = nt; n2.position = Vector3(s * (HL + 0.85), GOAL_H, 0); n2.material_override = net; add_child(n2)
		for zz in [-GOAL_HW, GOAL_HW]:
			var ns := BoxMesh.new(); ns.size = Vector3(1.7, GOAL_H, 0.06)
			var n3 := MeshInstance3D.new(); n3.mesh = ns; n3.position = Vector3(s * (HL + 0.85), GOAL_H / 2, zz); n3.material_override = net; add_child(n3)
	# stands with a painted crowd, far side and both ends
	var cmat := StandardMaterial3D.new(); cmat.albedo_texture = _crowd_tex(); cmat.roughness = 1.0; cmat.uv1_scale = Vector3(3 * 6, 2 * 2, 1)
	var far := BoxMesh.new(); far.size = Vector3(90, 0.8, 18)
	var fs := MeshInstance3D.new(); fs.mesh = far; fs.material_override = cmat; fs.position = Vector3(0, 5.6, -37.5); fs.rotation_degrees.x = 33; add_child(fs)
	_boxm(Vector3(90, 12, 1), Vector3(0, 5.0, -45.5), Color(0.33, 0.29, 0.45))
	var cmat2 := cmat.duplicate(); cmat2.uv1_scale = Vector3(3 * 2, 2 * 5, 1)
	for s in [-1.0, 1.0]:
		var eb := BoxMesh.new(); eb.size = Vector3(16, 0.8, 62)
		var es := MeshInstance3D.new(); es.mesh = eb; es.material_override = cmat2; es.position = Vector3(s * 47.5, 5.0, -4); es.rotation_degrees.z = s * 33; add_child(es)
		_boxm(Vector3(1, 11, 62), Vector3(s * 54.5, 4.5, -4), Color(0.33, 0.29, 0.45))
	# boards along the far side in soft colors
	var bc := [Color("e07a5f"), Color("f2cc8f"), Color("81b29a"), Color("9c89b8"), Color("ef8fa3"), Color("7fb7be")]
	for i in 12:
		_boxm(Vector3(6.2, 1.1, 0.3), Vector3(-35.75 + i * 6.5, 0.55, -27.6), bc[i % bc.size()])
	# floodlights
	for s in [-1.0, 1.0]:
		var pole := CylinderMesh.new(); pole.top_radius = 0.25; pole.bottom_radius = 0.35; pole.height = 22; pole.radial_segments = 6
		_mesh(pole, Vector3(s * 42, 11, -47), Color(0.3, 0.28, 0.4))
		var lamp := _boxm(Vector3(6, 3, 0.6), Vector3(s * 42, 22.5, -46.6), Color(1, 0.95, 0.8))
		var lm := StandardMaterial3D.new(); lm.albedo_color = Color(1, 0.95, 0.82); lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; lamp.material_override = lm
	# a quiet skyline behind the far stand
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	var wmat := StandardMaterial3D.new(); wmat.albedo_texture = _window_tex(); wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 16:
		var w := rng.randf_range(7, 13); var hgt := rng.randf_range(16, 38)
		var bm := BoxMesh.new(); bm.size = Vector3(w, hgt, 8)
		var b := MeshInstance3D.new(); b.mesh = bm; b.position = Vector3(-82 + i * 11 + rng.randf_range(-2, 2), hgt / 2 - 1, -70 - rng.randf_range(0, 14))
		var m2 := wmat.duplicate(); m2.uv1_scale = Vector3(3 * w / 8.0, 2 * hgt / 8.0, 1); b.material_override = m2; add_child(b)
	# ball
	var bs := SphereMesh.new(); bs.radius = BALL_R; bs.height = BALL_R * 2; bs.radial_segments = 12; bs.rings = 8
	ball_node = MeshInstance3D.new(); ball_node.mesh = bs; add_child(ball_node)
	var bmat := StandardMaterial3D.new(); bmat.albedo_texture = _ball_tex(); bmat.roughness = 0.8; ball_node.material_override = bmat

func _pitch_tex() -> ImageTexture:
	var S := 16
	var img := Image.create(76 * S, 54 * S, false, Image.FORMAT_RGB8)
	img.fill(Color(0.15, 0.32, 0.22))
	for i in 10:
		img.fill_rect(Rect2i((8 + i * 6) * S, 7 * S, 6 * S, 40 * S), Color(0.2, 0.42, 0.27) if i % 2 == 0 else Color(0.175, 0.385, 0.245))
	var L := Color(0.97, 0.94, 0.86)
	var t := 0.11
	var rect := func(x0: float, z0: float, x1: float, z1: float) -> void:
		img.fill_rect(Rect2i(int(round((x0 + 38.0) * S)), int(round((z0 + 27.0) * S)), maxi(1, int(round((x1 - x0) * S))), maxi(1, int(round((z1 - z0) * S)))), L)
	var arc := func(cx: float, cz: float, r: float, a0: float, a1: float) -> void:
		var n := int(r * 60.0) + 8
		for i in n + 1:
			var a := lerpf(a0, a1, float(i) / n)
			var x := cx + cos(a) * r; var z := cz + sin(a) * r
			img.fill_rect(Rect2i(int(round((x - t + 38.0) * S)), int(round((z - t + 27.0) * S)), 4, 4), L)
	rect.call(-HL - t, -HW - t, HL + t, -HW + t); rect.call(-HL - t, HW - t, HL + t, HW + t)
	rect.call(-HL - t, -HW, -HL + t, HW); rect.call(HL - t, -HW, HL + t, HW); rect.call(-t, -HW, t, HW)
	arc.call(0.0, 0.0, 5.0, 0.0, TAU); arc.call(0.0, 0.0, 0.2, 0.0, TAU)
	for s in [-1.0, 1.0]:
		var gx: float = s * HL; var bx: float = s * (HL - BOX_D); var sx: float = s * (HL - 3.5)
		rect.call(minf(gx, bx), -BOX_HW - t, maxf(gx, bx), -BOX_HW + t); rect.call(minf(gx, bx), BOX_HW - t, maxf(gx, bx), BOX_HW + t)
		rect.call(bx - t, -BOX_HW, bx + t, BOX_HW)
		rect.call(minf(gx, sx), -5.0 - t, maxf(gx, sx), -5.0 + t); rect.call(minf(gx, sx), 5.0 - t, maxf(gx, sx), 5.0 + t)
		rect.call(sx - t, -5.0, sx + t, 5.0)
		arc.call(s * (HL - 7.0), 0.0, 0.18, 0.0, TAU)
		for zz in [-1.0, 1.0]:
			var a0: float = atan2(-zz, -s)
			arc.call(gx, zz * HW, 1.0, a0 - PI / 4, a0 + PI / 4)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _crowd_tex() -> ImageTexture:
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var img := Image.create(128, 64, false, Image.FORMAT_RGB8); img.fill(Color(0.25, 0.22, 0.36))
	var cols := [Color("e07a5f"), Color("f2cc8f"), Color("81b29a"), Color("9c89b8"), Color("ef8fa3"), Color("7fb7be"), Color("f4f1de"), Color("3d405b")]
	for y in range(2, 64, 5):
		for x in range(1, 128, 4):
			if rng.randf() < 0.82:
				img.fill_rect(Rect2i(x + rng.randi_range(0, 1), y, 2, 3), cols[rng.randi() % cols.size()].darkened(0.12))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _window_tex() -> ImageTexture:
	var rng := RandomNumberGenerator.new(); rng.seed = 5
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8); img.fill(Color(0.43, 0.36, 0.55))
	for y in range(4, 60, 8):
		for x in range(4, 60, 8):
			img.fill_rect(Rect2i(x, y, 4, 5), Color(1.0, 0.86, 0.62) if rng.randf() < 0.4 else Color(0.5, 0.43, 0.62))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _ball_tex() -> ImageTexture:
	var img := Image.create(32, 16, false, Image.FORMAT_RGB8); img.fill(Color(0.98, 0.96, 0.9))
	for i in 4:
		img.fill_rect(Rect2i(i * 8 + 1, 5, 4, 5), Color(0.24, 0.22, 0.36))
		img.fill_rect(Rect2i(i * 8 + 5, 0, 3, 3), Color(0.24, 0.22, 0.36)); img.fill_rect(Rect2i(i * 8 + 5, 13, 3, 3), Color(0.24, 0.22, 0.36))
	return ImageTexture.create_from_image(img)

# ---------- audio ----------

func _build_audio() -> void:
	if bot: return
	for n in ["whistle", "crowd", "cheer", "kick", "click", "tackle"]:
		var p := AudioStreamPlayer.new(); add_child(p); snd[n] = p
		var path := "res://audio/%s.ogg" % n
		if ResourceLoader.exists(path):
			var s = load(path)
			if n == "crowd": s.loop = true
			p.stream = s
	snd["crowd"].volume_db = -15.0; snd["cheer"].volume_db = -5.0; snd["click"].volume_db = -8.0; snd["kick"].volume_db = -4.0; snd["whistle"].volume_db = -9.0
	music = AudioStreamPlayer.new(); add_child(music); music.volume_db = -7.0
	for i in range(1, 6):
		var path := "res://audio/lofi%d.ogg" % i
		if ResourceLoader.exists(path): tracks.append(load(path))
	music.finished.connect(_next_track)

func _next_track() -> void:
	if tracks.is_empty() or not save.music: return
	track_i = (track_i + 1) % tracks.size()
	music.stream = tracks[track_i]; music.play()

func _start_audio() -> void:
	# browsers only allow sound after the first press
	if bot or audio_started: return
	audio_started = true
	if not tracks.is_empty():
		track_i = randi() % tracks.size(); music.stream = tracks[track_i]
		if save.music: music.play()
	if save.sound and snd["crowd"].stream: snd["crowd"].play()

func sfx(n: String) -> void:
	if bot or attract or not save.sound or not snd.has(n) or snd[n].stream == null: return
	snd[n].play()

## Text size (v0.2.3). Large draws every panel, button and label 25 percent bigger. Automatic picks Large on a
## touch screen (phones and tablets) and Normal elsewhere. The player can switch it in the Menu.
func _text_large() -> bool:
	var t := int(save.text)
	return t == 1 or (t == -1 and DisplayServer.is_touchscreen_available())

func _apply_text() -> void:
	get_tree().root.content_scale_factor = 1.25 if _text_large() else 1.0
	hud.text_btn.text = "Text: Large" if _text_large() else "Text: Normal"

func _apply_audio_labels() -> void:
	hud.sound_btn.text = "Sound: On" if save.sound else "Sound: Off"
	hud.music_btn.text = "Music: On" if save.music else "Music: Off"

# ---------- screens ----------

func _hide_panels() -> void:
	hud.over_panel.visible = false; hud.show_team(false); hud.show_help(false); hud.show_modes(false); hud.show_league(false)
	hud.title_panel.visible = false

func _to_title() -> void:
	screen = S_TITLE; paused = false; hud.set_menu(false); _hide_panels()
	hud.title_panel.visible = true; hud.focus_start()
	_attract()

func _attract() -> void:
	var a := randi() % teams.size(); var b := (a + 1 + randi() % (teams.size() - 1)) % teams.size()
	mode = "attract"
	start_match(a, b, false, false)
	attract = true

func _team_ix(id: String) -> int:
	for i in teams.size():
		if teams[i].id == id: return i
	return 0

func _on_start() -> void:
	_start_audio()
	_to_modes()

func _to_modes() -> void:
	screen = S_MODES; _hide_panels()
	var lt := "League"
	var lg: Dictionary = save.league
	if League.is_over(lg): lt = "League: season over"
	elif not lg.is_empty(): lt = "League: matchday %d of %d" % [int(lg.md) + 1, League.rounds(lg)]
	hud.show_modes(true, lt, "mode_" + (str(save.last_mode) if str(save.last_mode) in ["exhibition", "league", "practice"] else "exhibition"))

func _to_teams(for_what: String) -> void:
	pick_for = for_what; screen = S_TEAMS; _hide_panels()
	match for_what:
		"league": hud.show_team(true, "Pick your club for the season", "7 matchdays. Every club plays every other club once.", _team_ix(save.team))
		"practice": hud.show_team(true, "Pick your club for practice", "No clock and no score. Only a keeper defends.", _team_ix(save.team))
		_: hud.show_team(true, "Pick your club", "Exhibition: two 3-minute halves against the computer.", _team_ix(save.team))

func _on_team(idx: int) -> void:
	_start_audio()
	save.team = teams[idx].id
	if pick_for == "league":
		_new_season(teams[idx].id); _write_save(); _to_league(); return
	_write_save()
	var opp := (idx + 1 + randi() % (teams.size() - 1)) % teams.size()
	_hide_panels(); screen = S_PLAY
	mode = pick_for
	start_match(idx, opp, pick_for == "practice", true)
	get_viewport().gui_release_focus()

# ---------- league ----------

func _new_season(club: String) -> void:
	var n := int(save.seasons) + 1
	save.league = League.new_season(league_cfg.clubs, club, n, randi())

func _table() -> Array:
	return League.table(save.league, league_cfg.clubs, by_id, int(league_cfg.points_win), int(league_cfg.points_draw))

func _to_league() -> void:
	var lg: Dictionary = save.league
	if lg.is_empty():
		_to_teams("league"); return
	screen = S_LEAGUE; _hide_panels()
	var rows := _table()
	var rn := League.rounds(lg); var md := int(lg.md)
	var club: String = lg.club
	var info := ""
	var play_text := ""
	if League.is_over(lg):
		var pos := League.position(rows, club)
		info = "Season over.\nChampions: %s\nYou finished %s with %s.\n\n" % [rows[0].name, League.ordinal(pos), by_id[club].name]
		play_text = "New season"
	else:
		var f := League.user_fixture(lg)
		info = "Matchday %d of %d\nNext: %s  v  %s\n\n" % [md + 1, rn, by_id[f[0]].name, by_id[f[1]].name]
		play_text = "Play matchday %d" % (md + 1)
	if md > 0:
		info += "Matchday %d results\n" % md
		for r in lg.results[md - 1]:
			info += "%s %d - %d %s\n" % [by_id[r[0]].abbr, int(r[2]), int(r[3]), by_id[r[1]].abbr]
		info += "\n"
	var best := int(save.best_finish)
	info += "Best finish: %s.  Titles: %d" % [League.ordinal(best) if best > 0 else "none yet", int(save.titles)]
	hud.show_league(true, "%s, season %d" % [league_cfg.name, int(lg.season)], rows, club, info, play_text, not League.is_over(lg))

func _league_play() -> void:
	var lg: Dictionary = save.league
	if League.is_over(lg):
		_to_teams("league"); return
	var f := League.user_fixture(lg)
	var opp: String = f[1] if f[0] == lg.club else f[0]
	_hide_panels(); screen = S_PLAY; mode = "league"
	start_match(_team_ix(lg.club), _team_ix(opp), false, true)
	if human: hud.say("Matchday %d:  %s  v  %s" % [int(lg.md) + 1, by_id[lg.club].name, by_id[opp].name], 2.8)
	get_viewport().gui_release_focus()

func _league_after_match() -> Array:
	# records the player's match, plays the rest of the matchday and closes the season after the last one
	var lg: Dictionary = save.league
	var res := League.play_round(lg, [score[0], score[1]], by_id, float(league_cfg.sim_goals))
	if League.is_over(lg):
		var pos := League.position(_table(), lg.club)
		save.seasons = int(save.seasons) + 1
		if pos == 1: save.titles = int(save.titles) + 1
		if int(save.best_finish) == 0 or pos < int(save.best_finish): save.best_finish = pos
	_write_save()
	return res

func _on_menu(action: String) -> void:
	match action:
		"click": sfx("click")
		"toggle": _set_menu(not hud.menu_open)
		"resume": _set_menu(false)
		"help": hud.show_help(true)
		"help_close":
			hud.show_help(false)
			if hud.menu_open: hud.set_menu(true)
		"sound":
			save.sound = not save.sound; _write_save(); _apply_audio_labels()
			if audio_started and snd["crowd"].stream:
				if save.sound: snd["crowd"].play()
				else: snd["crowd"].stop()
		"music":
			save.music = not save.music; _write_save(); _apply_audio_labels()
			if audio_started and not tracks.is_empty():
				if save.music:
					if music.stream == null: music.stream = tracks[track_i]
					music.play()
				else: music.stop()
		"text":
			save.text = 0 if _text_large() else 1; _write_save(); _apply_text()
		"restart":
			if screen == S_PLAY:
				_set_menu(false); hud.over_panel.visible = false
				start_match(team_ix[0], team_ix[1], practice, true); get_viewport().gui_release_focus()
		"title":
			# a league match only ends early on a second press, because a quit match does not count
			if screen == S_PLAY and mode == "league" and state != OVER and not hud.quit_armed:
				hud.arm_quit(true); return
			_set_menu(false); _to_title()
		"mode_exhibition": save.last_mode = "exhibition"; _to_teams("exhibition")
		"mode_practice": save.last_mode = "practice"; _to_teams("practice")
		"mode_league": save.last_mode = "league"; _write_save(); _to_league()
		"modes_back": _to_title()
		"team_back": _to_modes()
		"league": _to_league()
		"league_play": _league_play()
		"league_new":
			save.league = {}; _write_save(); _to_teams("league")
		"league_back": _to_modes()
		"test_goal":   # ?test only: the controlled player scores, so the full time scorers can be checked
			if test_hook and screen == S_PLAY and state == LIVE and ctrl != null:
				last_kicker = ctrl; _goal(0)
		"end_match":
			if test_hook and screen == S_PLAY and state == LIVE:
				half = 2; clock = HALF_SECS - 0.3

func _set_menu(open: bool) -> void:
	hud.set_menu(open); paused = open and screen == S_PLAY
	if not open:
		hud.show_help(false); hud.reset_touch()
		if screen == S_PLAY and state != OVER: get_viewport().gui_release_focus()
		elif screen == S_TITLE: hud.focus_start()
		elif screen == S_LEAGUE: hud.lg_play.grab_focus()
		elif screen == S_MODES: (hud.mode_panel.find_child("mode_exhibition", true, false) as Button).grab_focus()

func _input(e: InputEvent) -> void:
	var toggle := false
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE: toggle = true
	if e is InputEventJoypadButton and e.pressed and (e.button_index == JOY_BUTTON_BACK or e.button_index == JOY_BUTTON_START): toggle = true
	if toggle:
		if hud.help_panel.visible: _on_menu("help_close")
		else: _set_menu(not hud.menu_open)
		get_viewport().set_input_as_handled()
		return
	# G5.8: the Xbox B button goes back. In play with the Menu closed, B shoots or tackles instead
	if e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_B:
		var back := ""
		if hud.help_panel.visible: back = "help_close"
		elif hud.menu_open: back = "toggle"
		elif screen == S_MODES: back = "modes_back"
		elif screen == S_TEAMS: back = "team_back"
		elif screen == S_LEAGUE: back = "league_back"
		if back != "":
			_on_menu(back)
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and hud != null:
		_set_menu(not hud.menu_open)
	# E6.5: save at once when the app is paused, loses focus or closes
	if SaveStore.is_save_moment(what) and store != null and teams.size() > 0: _write_save()   # E6.5
	# v0.2.3: a match pauses itself when the game loses focus (a call, another app, another tab)
	var lost := what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT
	if lost and hud != null and not bot \
			and screen == S_PLAY and not attract and state != OVER and not hud.menu_open:
		_set_menu(true)

# ---------- match setup ----------

func _kit_clash(a: Dictionary, b: Dictionary) -> bool:
	var c1 := Color(str(a.shirt)); var c2 := Color(str(b.shirt))
	return Vector3(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b).length() < 0.4

func start_match(t0: int, t1: int, prac: bool, is_human: bool) -> void:
	for c in players_root.get_children(): c.queue_free()
	team_ix = [t0, t1]; practice = prac; human = is_human; attract = false; goals = []
	pl = [[], []]; all = []
	var kits := [teams[t0].home, teams[t1].home]
	if _kit_clash(kits[0], kits[1]): kits[1] = teams[t1].away
	for side in 2:
		var tm: Dictionary = teams[team_ix[side]]
		var spots: Array = forms[tm.formation]
		for i in 7:
			if practice and side == 1 and i > 0: break
			var d: Dictionary = tm.players[i]
			var p := P.new(); p.side = side; p.gk = i == 0
			p.spd = _rate(d.speed); p.pas = _rate(d["pass"]); p.sht = _rate(d.shot); p.tck = _rate(d.tackle); p.ctl = _rate(d.control)
			p.pname = str(d.name); p.num = int(d.num)
			if i > 0: p.home = Vector2(spots[i - 1][0], spots[i - 1][1])
			else: p.home = Vector2(0.03, 0.5)
			if not bot:
				var n := PlayerModel.new(); players_root.add_child(n)
				n.build(tm.keeper if p.gk else kits[side], Color(str(d.skin)), Color(str(d.hair)), p.num)
				p.node = n
			pl[side].append(p); all.append(p)
	score = [0, 0]; shots = [0, 0]; saves = [0, 0]; poss_t = [0.0, 0.0]; half = 1; clock = 0.0
	counts = {"throw": 0, "corner": 0, "goalkick": 0, "kickoff": 0}
	ctrl = null; carrier = null; pass_to = null; charge = -1.0; paused = false
	hud.over_panel.visible = false
	set_restart("kickoff", 0, Vector2.ZERO)
	if human:
		if practice: hud.say("Practice", 2.0)
		else: hud.say("%s  v  %s" % [teams[t0].name, teams[t1].name], 2.6)

func _outfield(side: int) -> Array:
	var out := []
	for p: P in pl[side]:
		if not p.gk: out.append(p)
	return out

func set_restart(kind: String, side: int, spot: Vector2) -> void:
	if practice:
		if side == 1 and kind != "kickoff":
			kind = "kickoff"; spot = Vector2.ZERO
		side = 0
	state = RESTART; state_t = 0.0; rs_kind = kind; rs_side = side; rs_spot = spot
	counts[kind] += 1
	carrier = null; gk_hands = false; pass_to = null; charge = -1.0; protect = 0.0; poss = side
	rs_fly = 0.0 if kind == "kickoff" else 0.7
	rs_t = 1.2 if kind == "kickoff" else 2.1
	if kind == "goalkick":
		rs_taker = pl[side][0]
	elif kind == "kickoff":
		rs_taker = null
		for p: P in _outfield(side):
			if rs_taker == null or p.home.x > rs_taker.home.x: rs_taker = p
	else:
		rs_taker = null
		for p: P in _outfield(side):
			if rs_taker == null or p.pos.distance_to(spot) < rs_taker.pos.distance_to(spot): rs_taker = p
	if kind == "kickoff":
		bpos = Vector3(0, BALL_R, 0); bvel = Vector3.ZERO
		for p: P in all:
			var d := dirx(p.side)
			p.vel = Vector2.ZERO; p.want = Vector2.ZERO; p.stun = 0.0; p.dive_t = 0.0; p.burst = 1.0
			if p.gk: p.pos = Vector2(-(HL - 1.2) * d, 0)
			else:
				var fx := lerpf(-HL + 5.0, -1.5 if p.side == side else -6.5, p.home.x)
				p.pos = Vector2(fx * d, (p.home.y - 0.5) * 2.0 * HW * 0.8 * d)
			p.face = Vector2(d, 0)
		rs_taker.pos = Vector2(-0.7 * dirx(side), 0)
	if human and screen == S_PLAY: sfx("whistle")

# ---------- frame ----------

func _process(dt: float) -> void:
	if bot:
		for i in 40:
			_step(1.0 / 60.0)
			if state == OVER:
				_bot_report(); bot_done += 1
				if bot_season: _bot_season_next()
				else: _bot_next()
				break
		return
	_read_input()
	if not paused:
		dt = minf(dt, 0.1)
		# slow devices: take up to three smaller steps so the match stays in real time
		var n := clampi(int(ceil(dt * 60.0 - 0.05)), 1, 3)
		for i in n:
			_step(dt / n)
			a_just = false; b_just = false; sw_just = false
	hud.clear_just()
	_sync_view(dt)
	_hud_update()
	var cmd := bridge.tick(dt, _test_state)   # shared test bridge (G10): window.lofi and window.lofi_cmd in ?test only
	if cmd != "": _on_menu(cmd)

func _key(k: int) -> bool:
	return Input.is_physical_key_pressed(k)

func _read_input() -> void:
	var v := Vector2.ZERO
	if _key(KEY_A) or _key(KEY_LEFT): v.x -= 1.0
	if _key(KEY_D) or _key(KEY_RIGHT): v.x += 1.0
	if _key(KEY_W) or _key(KEY_UP): v.y -= 1.0
	if _key(KEY_S) or _key(KEY_DOWN): v.y += 1.0
	var a := _key(KEY_SPACE) or _key(KEY_J)
	var b := _key(KEY_F) or _key(KEY_K)
	var c := _key(KEY_SHIFT)
	var sw := _key(KEY_TAB) or _key(KEY_Q)
	for id in Input.get_connected_joypads():
		var jv := Vector2(Input.get_joy_axis(id, JOY_AXIS_LEFT_X), Input.get_joy_axis(id, JOY_AXIS_LEFT_Y))
		if jv.length() > 0.22: v += jv
		if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_LEFT): v.x -= 1.0
		if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_RIGHT): v.x += 1.0
		if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_UP): v.y -= 1.0
		if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_DOWN): v.y += 1.0
		a = a or Input.is_joy_button_pressed(id, JOY_BUTTON_A)
		b = b or Input.is_joy_button_pressed(id, JOY_BUTTON_X) or Input.is_joy_button_pressed(id, JOY_BUTTON_B)
		c = c or Input.get_joy_axis(id, JOY_AXIS_TRIGGER_RIGHT) > 0.4 or Input.is_joy_button_pressed(id, JOY_BUTTON_RIGHT_SHOULDER)
		sw = sw or Input.is_joy_button_pressed(id, JOY_BUTTON_LEFT_SHOULDER)
	v += hud.stick
	a = a or hud.btn_held["A"]; b = b or hud.btn_held["B"]; c = c or hud.btn_held["C"]
	in_mv = v.limit_length(1.0); in_a = a; in_b = b; in_c = c; in_sw = sw
	a_just = (a and not _pa) or hud.btn_just["A"]; b_just = (b and not _pb) or hud.btn_just["B"]; sw_just = sw and not _psw
	_pa = a; _pb = b; _psw = sw

func _step(h: float) -> void:
	state_t += h
	kick_lock = maxf(0.0, kick_lock - h); protect = maxf(0.0, protect - h)
	for p: P in all:
		p.stun = maxf(0.0, p.stun - h); p.tackle_cd = maxf(0.0, p.tackle_cd - h); p.kick_cd = maxf(0.0, p.kick_cd - h)
		p.dive_cd = maxf(0.0, p.dive_cd - h); p.react = maxf(0.0, p.react - h)
	match state:
		RESTART: _step_restart(h)
		LIVE: _step_live(h)
		GOAL:
			var r := _ball_adv(bpos, bvel, h); bpos = r[0]; bvel = r[1] * (1.0 - minf(1.0, h * 5.0))
			bpos.x = clampf(bpos.x, -HL - 1.5, HL + 1.5)
			for p: P in all: p.want = Vector2.ZERO
			_integrate(h)
			if state_t > 2.6:
				set_restart("kickoff", 0 if practice else rs_side, Vector2.ZERO)
		HALFTIME:
			for p: P in all: p.want = Vector2.ZERO
			_integrate(h)
			if state_t > 2.6:
				half = 2; clock = 0.0; set_restart("kickoff", 1, Vector2.ZERO)
		OVER:
			for p: P in all: p.want = Vector2.ZERO
			_integrate(h)
			if attract and state_t > 4.0: _attract()

func _step_restart(h: float) -> void:
	rs_t -= h
	if rs_fly > 0.0:
		rs_fly -= h
		var r := _ball_adv(bpos, bvel, h); bpos = r[0]; bvel = r[1]
	else:
		bpos = Vector3(rs_spot.x, BALL_R, rs_spot.y); bvel = Vector3.ZERO
	var d := dirx(rs_side)
	for p: P in all:
		var tgt: Vector2
		if p == rs_taker: tgt = rs_spot - Vector2(d * 0.5, 0) if rs_kind == "kickoff" else rs_spot
		elif p.gk: tgt = Vector2(-(HL - 1.2) * dirx(p.side), 0)
		elif rs_kind == "kickoff": tgt = p.pos
		else:
			tgt = _shape(p, rs_spot, rs_side)
			if p.side != rs_side:
				var dv := tgt - rs_spot
				if dv.length() < 7.0:
					var n := dv.normalized() if dv.length() > 0.2 else Vector2(-d, 0)
					tgt = rs_spot + n * 7.0
		_go(p, tgt, true)
	_integrate(h)
	if rs_t <= 0.0 and rs_fly <= 0.0:
		var spot := rs_spot - Vector2(d * 0.5, 0) if rs_kind == "kickoff" else rs_spot
		if rs_taker.pos.distance_to(spot) > 0.9:
			rs_taker.pos = spot; rs_taker.vel = Vector2.ZERO
		var inward := -rs_spot
		rs_taker.face = inward.normalized() if inward.length() > 2.0 else Vector2(d, 0)
		if rs_kind == "goalkick": rs_taker.face = Vector2(d, 0)
		state = LIVE; state_t = 0.0
		_gain(rs_taker)
		gk_hands = false; protect = 2.4; rs_taker.think = 0.6
		if human and rs_side == 1: _auto_ctrl()

func _step_live(h: float) -> void:
	if not practice: clock += h
	if carrier != null: poss_t[carrier.side] += h
	_predict(); _assign()
	for p: P in all:
		p.jit_t -= h
		if p.jit_t <= 0.0:
			p.jit_t = randf_range(1.2, 2.8); p.jit = Vector2(randf_range(-1.5, 5.0) * dirx(p.side), randf_range(-3.0, 3.0))
		if human and p == ctrl: _human(p, h)
		elif p.gk: _ai_gk(p, h)
		else: _ai(p, h)
	_integrate(h)
	_ball(h)
	if state == LIVE: _rules()
	if state == LIVE and not practice and clock >= HALF_SECS:
		if human: sfx("whistle")
		if half == 1:
			state = HALFTIME; state_t = 0.0; carrier = null
			if human: hud.say("Half time", 2.4)
		else:
			_full_time()

# ---------- ball ----------

func _ball_adv(p: Vector3, v: Vector3, h: float) -> Array:
	if p.y > BALL_R + 0.01 or v.y > 0.5:
		v.y -= GRAV * h
		p += v * h
		if p.y < BALL_R:
			p.y = BALL_R
			if v.y < -2.5:
				v.y = -v.y * 0.5; v.x *= 0.8; v.z *= 0.8
			else: v.y = 0.0
	else:
		p.y = BALL_R; v.y = 0.0
		var hv := Vector2(v.x, v.z); var s := hv.length()
		if s > 0.0:
			var ns := maxf(0.0, s - ROLL * h)
			hv = hv * (ns / s); v.x = hv.x; v.z = hv.y
		p += v * h
	return [p, v]

func _predict() -> void:
	fut.clear()
	if carrier != null:
		for i in 26: fut.append(bpos)
		return
	var p := bpos; var v := bvel
	for i in 26:
		fut.append(p)
		for k in 2:
			var r := _ball_adv(p, v, 0.05); p = r[0]; v = r[1]

func _maxspeed(p: P, sprint: bool) -> float:
	var s := RUN * p.spd
	if sprint and p.burst > 0.03: s *= SPRINT
	if carrier == p: s *= 0.88
	return s

func _itime(p: P) -> float:
	var sp := _maxspeed(p, true)
	if carrier != null:
		p.ipt = ball2(); return p.pos.distance_to(p.ipt) / sp
	var reach_h := 2.3 if p.gk else 1.3
	for i in fut.size():
		var f: Vector3 = fut[i]
		if f.y > reach_h: continue
		var d := p.pos.distance_to(Vector2(f.x, f.z))
		if d <= sp * (i * 0.1) + 0.7:
			p.ipt = Vector2(clampf(f.x, -HL - 1.0, HL + 1.0), clampf(f.z, -HW - 1.0, HW + 1.0)); return i * 0.1
	var l: Vector3 = fut[fut.size() - 1]
	p.ipt = Vector2(clampf(l.x, -HL - 1.0, HL + 1.0), clampf(l.z, -HW - 1.0, HW + 1.0))
	return 2.6 + p.pos.distance_to(p.ipt) / sp

func _in_own_box(p: P, pt = null) -> bool:
	var q: Vector2 = p.pos if pt == null else pt
	return (q.x * dirx(p.side)) < -(HL - BOX_D) and absf(q.y) < BOX_HW

func _assign() -> void:
	poss = carrier.side if carrier != null else (pass_to.side if pass_to != null else -1)
	var best_t := [9.0, 9.0]
	for side in 2:
		var a: P = null; var b: P = null
		for p: P in pl[side]:
			p.itime = _itime(p)
			if p.gk: continue
			if a == null or p.itime < a.itime:
				b = a; a = p
			elif b == null or p.itime < b.itime: b = p
		if pass_to != null and pass_to.side == side and not pass_to.gk and pass_to != a:
			b = a; a = pass_to
		chaser[side] = a; second[side] = b
		best_t[side] = a.itime if a != null else 9.0
	for side in 2:
		var g: P = pl[side][0]
		gk_claim[side] = carrier == null and _in_own_box(g, g.ipt) and g.itime <= best_t[1 - side] + 0.05 and g.itime < 1.6

func _gain(p: P) -> void:
	var lost := carrier != null and carrier.side != p.side
	carrier = p; pass_to = null; last_touch = p.side; p.hold = 0.0; p.think = randf_range(0.12, 0.3); charge = -1.0
	gk_hands = p.gk and _in_own_box(p)
	if gk_hands:
		protect = 3.0; p.think = randf_range(0.7, 1.1)
	if human and p.side == 0 and not p.gk: ctrl = p
	elif human and (p.side == 1 or lost): _auto_ctrl(true)

func _auto_ctrl(only_if_far := false) -> void:
	# hand the player the defender nearest the ball
	var best: P = null
	for p: P in _outfield(0):
		if best == null or p.pos.distance_to(ball2()) < best.pos.distance_to(ball2()): best = p
	if best == null: return
	if only_if_far and ctrl != null and ctrl.pos.distance_to(ball2()) < 12.0: return
	ctrl = best

func _kick(p: P, v: Vector3) -> void:
	carrier = null; gk_hands = false; pass_to = null; protect = 0.0; charge = -1.0
	var hv := Vector2(v.x, v.z)
	if hv.length() > 0.5: p.face = hv.normalized()
	bpos = Vector3(p.pos.x + p.face.x * 0.6, BALL_R + (0.12 if v.y > 0.0 else 0.0), p.pos.y + p.face.y * 0.6)
	bvel = v; last_kicker = p; kick_lock = 0.3; last_touch = p.side; p.kick_cd = 0.35
	for s in 2: pl[s][0].react = randf_range(0.16, 0.34) / pl[s][0].ctl
	sfx("kick")

func _pass(p: P, m: P) -> void:
	var tgt := m.pos + m.vel * 0.35
	var to := tgt - p.pos; var dist := to.length()
	var v0 := minf(sqrt(64.0 + 2.0 * ROLL * dist), 23.0)
	var dir2 := to.normalized().rotated(randfn(0.0, 0.06) / p.pas)
	_kick(p, Vector3(dir2.x * v0, 0.0, dir2.y * v0))
	pass_to = m
	if human and p.side == 0 and not m.gk: ctrl = m

func _loft(p: P, tgt: Vector2, m: P = null) -> void:
	var to := tgt - p.pos; var dist := maxf(to.length(), 4.0)
	var t := clampf(dist / 17.0, 0.7, 1.9)
	var hv := to / t * 0.92
	_kick(p, Vector3(hv.x, GRAV * t * 0.5, hv.y))
	pass_to = m
	if human and m != null and p.side == 0 and not m.gk: ctrl = m

func _shoot(p: P, power: float, aimz: float) -> void:
	var d := dirx(p.side); var gx := HL * d
	var keeper: P = pl[1 - p.side][0]
	var tz: float
	if is_nan(aimz):
		tz = (GOAL_HW - 0.7) * (-1.0 if keeper.pos.y > 0.0 else 1.0)
		if absf(keeper.pos.y) < 0.4: tz = (GOAL_HW - 0.7) * (1.0 if randf() < 0.5 else -1.0)
		elif randf() < 0.2: tz = -tz
	else:
		tz = aimz * (GOAL_HW - 0.6)
	var dist := p.pos.distance_to(Vector2(gx, tz))
	tz += randfn(0.0, 1.0) * (0.05 + 0.075 * power) * dist / p.sht
	var dir2 := (Vector2(gx, tz) - p.pos).normalized()
	var sp := 21.0 + 12.0 * power
	var vy := 1.5 + power * randf_range(1.0, 6.5) + dist * 0.08
	shots[p.side] += 1
	_kick(p, Vector3(dir2.x * sp, vy, dir2.y * sp))

func _ball(h: float) -> void:
	if carrier != null:
		var c := carrier
		var t2 := c.pos + c.face * (0.42 if gk_hands else 0.72)
		bpos = bpos.lerp(Vector3(t2.x, 1.05 if gk_hands else BALL_R, t2.y), minf(1.0, h * 22.0))
		bvel = Vector3(c.vel.x, 0, c.vel.y)
		return
	var r := _ball_adv(bpos, bvel, h); bpos = r[0]; bvel = r[1]
	var b2 := ball2(); var sp := bvel.length()
	var best: P = null; var bd := 9.0
	for p: P in all:
		if p.stun > 0.0 or p.kick_cd > 0.0: continue
		if p == last_kicker and kick_lock > 0.0: continue
		var reach := 0.95; var maxh := 1.35
		if p.gk and _in_own_box(p):
			reach = 1.5 if p.dive_t > 0.0 else 1.15; maxh = 2.4
		if bpos.y > maxh: continue
		var dd := (p.pos + p.face * 0.25).distance_to(b2)
		if dd < reach and dd < bd:
			bd = dd; best = p
	if best == null: return
	if best.gk and _in_own_box(best):
		if sp > 20.0 and last_touch != best.side: saves[best.side] += 1
		if sp > 25.0 and randf() < 0.55:
			var away := Vector2(dirx(best.side), randf_range(-1.3, 1.3)).normalized()
			bvel = Vector3(away.x * sp * 0.35, randf_range(2.0, 5.0), away.y * sp * 0.35)
			last_touch = best.side; last_kicker = best; kick_lock = 0.4; pass_to = null; sfx("tackle")
		else: _gain(best)
	elif sp > 23.0 and randf() > 0.25 * best.ctl:
		var n := b2 - best.pos
		n = n.normalized() if n.length() > 0.01 else -best.face
		var hv := Vector2(bvel.x, bvel.z).bounce(n) * 0.35
		bvel = Vector3(hv.x, randf_range(1.0, 4.0), hv.y)
		last_touch = best.side; last_kicker = best; kick_lock = 0.3; pass_to = null; sfx("tackle")
	else: _gain(best)

func _rules() -> void:
	var x := bpos.x; var z := bpos.z
	if carrier != null: last_touch = carrier.side
	if absf(x) > HL:
		var end_side := 1 if x > 0.0 else 0
		# posts and crossbar knock the ball back into play
		if carrier == null and absf(x) < HL + 0.6 and ((absf(absf(z) - GOAL_HW) < 0.24 and bpos.y < GOAL_H + 0.2) or (absf(z) < GOAL_HW and absf(bpos.y - GOAL_H) < 0.22)):
			bpos.x = signf(x) * (HL - 0.05); bvel.x = -bvel.x * 0.55; bvel.z += randf_range(-2.0, 2.0)
			last_kicker = null; pass_to = null; sfx("tackle"); return
		if absf(z) < GOAL_HW and bpos.y < GOAL_H:
			_goal(1 - end_side); return
		var sz := 1.0 if z >= 0.0 else -1.0
		if last_touch == end_side: set_restart("corner", 1 - end_side, Vector2(signf(x) * (HL - 0.4), sz * (HW - 0.4)))
		else: set_restart("goalkick", end_side, Vector2(signf(x) * (HL - 5.0), sz * 3.5))
	elif absf(z) > HW:
		set_restart("throw", 1 - last_touch, Vector2(clampf(x, -HL + 1.0, HL - 1.0), signf(z) * (HW - 0.3)))

func _goal(side: int) -> void:
	score[side] += 1
	state = GOAL; state_t = 0.0; carrier = null; pass_to = null; charge = -1.0
	rs_side = 1 - side
	var scorer := last_kicker.pname if last_kicker != null and last_kicker.side == side else "Own goal"
	goals.append({"side": side, "name": scorer, "min": int(((half - 1) * HALF_SECS + clock) / 60.0) + 1})
	if bot and verbose: print("  goal side %d at %d:%02d of half %d" % [side, int(clock) / 60, int(clock) % 60, half])
	if human:
		sfx("cheer")
		var who := ""
		if last_kicker != null and last_kicker.side == side: who = "%s scores for %s" % [last_kicker.pname, teams[team_ix[side]].name]
		else: who = "Own goal. %s score" % teams[team_ix[side]].name
		hud.say("GOAL!  " + who, 2.5, Color(1.0, 0.86, 0.62))

func _full_time() -> void:
	state = OVER; state_t = 0.0; carrier = null
	if mode == "league": _league_after_match()
	if not human: return
	var a: int = score[0]; var b: int = score[1]
	if a > b: save.wins += 1
	elif a < b: save.losses += 1
	else: save.draws += 1
	save.goals_for += a; save.goals_against += b
	_write_save()
	var tot: float = maxf(0.1, poss_t[0] + poss_t[1])
	var head := "You win" if a > b else ("You lose this one" if a < b else "A draw")
	hud.over_title.text = "FULL TIME"
	var txt := "%s\n%s  %d - %d  %s\n" % [head, teams[team_ix[0]].name, a, b, teams[team_ix[1]].name]
	txt += _scorers_text()
	txt += "Shots %d - %d      Possession %d%% - %d%%\n" % [shots[0], shots[1], int(round(poss_t[0] / tot * 100.0)), int(round(poss_t[1] / tot * 100.0))]
	if mode == "league":
		var lg: Dictionary = save.league
		var rows := _table()
		txt += "Matchday %d of %d.  You are %s in the table." % [int(lg.md), League.rounds(lg), League.ordinal(League.position(rows, lg.club))]
		if League.is_over(lg): txt += "\nThat was the last matchday. %s are the champions." % rows[0].name
	else:
		txt += "Your record: %d wins, %d draws, %d losses" % [save.wins, save.draws, save.losses]
	hud.show_over(txt, mode == "league")

## Goal scorers with the minute of the match (1 to 6), one line per club that scored. Empty when nobody scored.
func _scorers_text() -> String:
	var out := ""
	for side: int in [0, 1]:
		var parts: Array[String] = []
		for g: Dictionary in goals:
			if int(g.side) == side: parts.append("%s %d'" % [g.name, int(g.min)])
		if not parts.is_empty(): out += "%s: %s\n" % [teams[team_ix[side]].abbr, ", ".join(parts)]
	return out

# ---------- movement ----------

func _go(p: P, tgt: Vector2, sprint: bool) -> void:
	var dv := tgt - p.pos; var dist := dv.length()
	if p.stun > 0.0 or dist < 0.25:
		p.want = Vector2.ZERO; p.sprint = false; return
	p.sprint = sprint and dist > 3.0
	p.want = dv / dist * minf(_maxspeed(p, p.sprint), dist * 4.0)

func _integrate(h: float) -> void:
	for p: P in all:
		if p.stun > 0.0: p.want = Vector2.ZERO
		if p.dive_t > 0.0:
			p.dive_t -= h; p.vel = p.dive_v
		else:
			p.vel = p.vel.move_toward(p.want, 34.0 * h)
		p.pos += p.vel * h
		p.pos.x = clampf(p.pos.x, -HL - 2.0, HL + 2.0); p.pos.y = clampf(p.pos.y, -HW - 2.0, HW + 2.0)
		var sp: float = p.vel.length()
		if sp > 0.8 and p.dive_t <= 0.0:
			var f: Vector2 = p.face.lerp(p.vel / sp, minf(1.0, h * 14.0))
			if f.length() > 0.01: p.face = f.normalized()
		if p.sprint and sp > RUN * 0.9: p.burst = maxf(0.0, p.burst - h * 0.3)
		else: p.burst = minf(1.0, p.burst + h * 0.2)
	for i in all.size():
		for j in range(i + 1, all.size()):
			var a: P = all[i]; var b: P = all[j]
			var d := b.pos - a.pos; var l := d.length()
			if l < 0.8 and l > 0.001:
				var push := d / l * (0.8 - l) * 0.5
				a.pos -= push; b.pos += push

func _shape(p: P, ball: Vector2, pside: int) -> Vector2:
	var d := dirx(p.side)
	var bx := ball.x * d
	var hx := lerpf(-HL, HL, p.home.x)
	var push := 0.0
	if pside == p.side: push = 6.0
	elif pside == 1 - p.side: push = -4.0
	var x := clampf(hx * 0.62 + bx * 0.5 + push, -HL + 4.0, HL - 3.0)
	var z := (p.home.y - 0.5) * 2.0 * HW * 0.62 * d + ball.y * 0.3
	return Vector2(x * d, clampf(z, -HW + 1.5, HW - 1.5))

# ---------- computer players ----------

func _lane_count(a: Vector2, b: Vector2, side: int, skip_gk: bool) -> int:
	var n := 0
	var ab := b - a; var l2 := ab.length_squared()
	if l2 < 0.01: return 0
	for o: P in pl[1 - side]:
		if skip_gk and o.gk: continue
		var t: float = (o.pos - a).dot(ab) / l2
		if t < 0.08 or t > 0.95: continue
		if (a + ab * t).distance_to(o.pos) < 1.5: n += 1
	return n

func _press(p: P) -> float:
	var m := 99.0
	for o: P in pl[1 - p.side]: m = minf(m, o.pos.distance_to(p.pos))
	return m

func _best_pass(p: P) -> Array:
	var best: P = null; var bs := -1e9
	var d := dirx(p.side); var goal := Vector2(HL * d, 0)
	for m: P in pl[p.side]:
		if m == p or m.gk: continue
		var to: Vector2 = m.pos - p.pos; var dist := to.length()
		if dist < 4.0 or dist > 36.0: continue
		var open := 8.0
		for o: P in pl[1 - p.side]: open = minf(open, o.pos.distance_to(m.pos))
		var blocked := _lane_count(p.pos, m.pos, p.side, false) > 0
		var s: float = to.x * d * 0.55 + open * 1.1 + (30.0 - m.pos.distance_to(goal)) * 0.25 - absf(dist - 13.0) * 0.12 - (12.0 if blocked else 0.0) + randf() * 2.0
		if s > bs:
			bs = s; best = m
	return [best, bs]

func _ai(p: P, h: float) -> void:
	if carrier == p:
		_ai_carrier(p, h); return
	var side := p.side
	var is_chaser: bool = p == chaser[side]
	if poss == side and not (carrier == null and is_chaser):
		_go(p, _shape(p, ball2(), poss) + p.jit, false); return
	var b2 := ball2()
	var g := Vector2(-HL * dirx(side), 0)
	if is_chaser:
		if carrier != null:
			if protect > 0.0:
				_go(p, b2 + (g - b2).normalized() * 6.5, false)
			else:
				_go(p, b2 + carrier.vel * 0.18, true)
				if p.tackle_cd <= 0.0 and p.pos.distance_to(b2) < 1.45 and randf() < h * (3.5 + 4.0 * style(side, "tackle")): _tackle(p)
		else:
			_go(p, p.ipt, true)
	elif p == second[side] and carrier != null:
		_go(p, b2 + (g - b2).normalized() * clampf(b2.distance_to(g) * 0.35, 3.0, 8.0), false)
	else:
		_go(p, _shape(p, b2, poss), false)

func _ai_carrier(p: P, h: float) -> void:
	p.hold += h; p.think -= h
	var d := dirx(p.side); var goal := Vector2(HL * d, 0); var dg := p.pos.distance_to(goal)
	var press := _press(p)
	if p.think <= 0.0:
		p.think = 0.22
		var in_range := dg < 17.0 and absf(p.pos.y) < 12.0
		if in_range and protect <= 0.0:
			var blockers := _lane_count(p.pos, goal, p.side, true)
			if dg < 7.5 or (blockers == 0 and randf() < 0.05 + 0.14 * style(p.side, "shoot")) or (press < 2.5 and dg < 14.0 and randf() < 0.3):
				_shoot(p, clampf(0.45 + dg / 30.0 + randf() * 0.2, 0.4, 1.0), NAN); return
		var best := _best_pass(p)
		var must := protect > 0.0 or p.hold > 3.5
		if best[0] != null and (must or (press < 3.2 and best[1] > 0.0) or (best[1] > 13.0 - 6.0 * style(p.side, "pass") and randf() < 0.35)):
			if rs_kind == "corner" and protect > 0.0: _loft(p, best[0].pos, best[0])
			else: _pass(p, best[0])
			return
		if best[0] == null and (must or press < 2.0) and p.hold > 0.4:
			_loft(p, Vector2(clampf(p.pos.x + d * 20.0, -HL + 6.0, HL - 6.0), randf_range(-8.0, 8.0))); return
	if protect > 0.0:
		p.want = Vector2.ZERO; return
	var dirv := (goal - p.pos).normalized()
	for o: P in pl[1 - p.side]:
		var to: Vector2 = o.pos - p.pos; var dd := to.length()
		if dd < 5.0 and to.dot(dirv) > 0.0:
			var perp := Vector2(-dirv.y, dirv.x)
			var sgn := -signf(to.dot(perp))
			if sgn == 0.0: sgn = 1.0
			dirv += perp * sgn * (5.0 - dd) * 0.35
	if absf(p.pos.y) > HW - 2.5: dirv.y -= signf(p.pos.y) * 0.9
	dirv = dirv.normalized()
	p.sprint = press < 6.0 and p.burst > 0.25 and style(p.side, "run") > 0.3
	p.want = dirv * _maxspeed(p, p.sprint)

func _tackle(p: P) -> void:
	p.tackle_cd = 1.0
	var c := carrier
	var b2 := ball2(); var dist := p.pos.distance_to(b2)
	if dist > 0.05: p.vel += (b2 - p.pos) / dist * 3.5
	if c == null or c.side == p.side or dist > 1.75 or protect > 0.0 or gk_hands:
		p.stun = 0.2; return
	var chance := 0.62 * p.tck / c.ctl
	var rel := (p.pos - c.pos).normalized().dot(c.face)
	chance *= 0.75 + 0.35 * rel
	if randf() < chance:
		c.stun = 0.5; sfx("tackle")
		if randf() < 0.6: _gain(p)
		else:
			carrier = null; last_touch = p.side; last_kicker = c; kick_lock = 0.25; pass_to = null
			var out := (b2 - p.pos).normalized().rotated(randf_range(-0.8, 0.8))
			bvel = Vector3(out.x * 9.0, 1.5, out.y * 9.0)
	else:
		p.stun = 0.55

func _ai_gk(p: P, h: float) -> void:
	var d := dirx(p.side); var gx := -(HL - 1.0) * d
	if carrier == p:
		p.want = Vector2.ZERO; p.think -= h; p.face = Vector2(d, 0)
		if p.think <= 0.0:
			var best := _best_pass(p)
			if best[0] != null and best[1] > 4.0 and _lane_count(p.pos, best[0].pos, p.side, false) == 0:
				_pass(p, best[0])
			else:
				var far: P = null; var fs := -1e9
				for m: P in _outfield(p.side):
					var open := 8.0
					for o: P in pl[1 - p.side]: open = minf(open, o.pos.distance_to(m.pos))
					var s: float = m.pos.x * d * 0.3 + open + randf() * 3.0
					if s > fs:
						fs = s; far = m
				if far != null: _loft(p, far.pos + Vector2(d * 2.0, 0), far)
				else: _loft(p, Vector2(0, randf_range(-8.0, 8.0)))
		return
	if p.dive_t > 0.0: return
	# is a shot on the way?
	if carrier == null and (bpos.x - gx) * d > 0.0 and bvel.x * d < -8.0:
		for i in fut.size():
			var f: Vector3 = fut[i]
			if (f.x - gx) * d <= 0.0:
				if absf(f.z) < GOAL_HW + 1.2 and f.y < GOAL_H + 0.6 and p.react <= 0.0:
					var need := f.z - p.pos.y
					if absf(need) > 0.9 and i * 0.1 < 0.6 and p.dive_cd <= 0.0:
						p.dive_t = 0.4; p.dive_cd = 1.3; p.dive_v = Vector2(0, signf(need) * 9.5 * p.ctl)
					else:
						_go(p, Vector2(gx, clampf(f.z, -GOAL_HW - 0.3, GOAL_HW + 0.3)), true)
					return
				break
	if gk_claim[p.side]:
		_go(p, p.ipt, true); return
	var own := Vector2(-HL * d, 0)
	var b2 := ball2(); var dist := b2.distance_to(own)
	# come out to smother a runner who is through
	if carrier != null and carrier.side != p.side and dist < 8.0 and _in_own_box(p, b2):
		_go(p, b2, true)
		if p.pos.distance_to(b2) < 1.2 and randf() < h * 7.0:
			carrier.stun = 0.4; _gain(p)
		return
	var adv := clampf(dist * 0.08, 0.9, 3.0)
	_go(p, Vector2(-HL * d + d * adv, clampf(b2.y * 0.24, -GOAL_HW + 0.5, GOAL_HW - 0.5)), false)
	if p.want.length() < 0.5:
		var to := b2 - p.pos
		if to.length() > 0.5: p.face = p.face.lerp(to.normalized(), minf(1.0, h * 8.0)).normalized()

# ---------- the player ----------

func _human(p: P, h: float) -> void:
	if p.stun > 0.0:
		p.want = Vector2.ZERO; return
	var mv := in_mv
	p.sprint = in_c and p.burst > 0.02 and mv.length() > 0.3
	p.want = mv * _maxspeed(p, p.sprint)
	if carrier == p and protect > 0.0 and rs_kind != "kickoff":
		# throw-in or corner: stand still, aim, then pass short or cross long
		p.want = Vector2.ZERO
		if mv.length() > 0.25: p.face = mv.normalized()
		if a_just: _human_pass(p, mv)
		elif b_just: _human_pass(p, mv, true)
		return
	if carrier == p:
		p.hold += h
		if mv.length() > 0.25:
			var f := p.face.lerp(mv.normalized(), minf(1.0, h * 16.0))
			if f.length() > 0.01: p.face = f.normalized()
		if charge >= 0.0:
			charge += h
			if not in_b or charge >= 0.95:
				_shoot(p, clampf(charge / 0.8, 0.2, 1.0), signf(mv.y) * clampf(absf(mv.y), 0.6, 1.0) if absf(mv.y) > 0.3 else NAN)
		elif b_just: charge = 0.0
		elif a_just: _human_pass(p, mv)
	else:
		charge = -1.0
		if pass_to == p and carrier == null and mv.length() < 0.2:
			_go(p, p.ipt, true)   # help the receiver meet the pass
		if b_just and p.tackle_cd <= 0.0: _tackle(p)
		if a_just or sw_just: _switch()

func _human_pass(p: P, mv: Vector2, lofted := false) -> void:
	var dirv := mv.normalized() if mv.length() > 0.25 else p.face
	var best: P = null; var bs := -1e9
	for m: P in pl[0]:
		if m == p: continue
		var to: Vector2 = m.pos - p.pos; var dist := to.length()
		if dist < 2.5: continue
		var s := to.normalized().dot(dirv) * 14.0 - dist * 0.14 - (5.0 if m.gk else 0.0)
		if s > bs:
			bs = s; best = m
	if best == null: return
	if lofted: _loft(p, best.pos + best.vel * 0.6, best)
	else: _pass(p, best)

func _switch() -> void:
	var best: P = null
	for p: P in _outfield(0):
		if p == ctrl: continue
		if best == null or p.itime < best.itime: best = p
	if best != null: ctrl = best

# ---------- view ----------

func _sync_view(dt: float) -> void:
	for p: P in all:
		if p.node == null: continue
		var lift := 0.0
		if p.dive_t > 0.0: lift = 0.35
		p.node.position = Vector3(p.pos.x, lift, p.pos.y)
		p.node.rotation.y = lerp_angle(p.node.rotation.y, -atan2(p.face.y, p.face.x), minf(1.0, dt * 14.0))
		var dv := 0.0
		if p.dive_t > 0.0: dv = signf(p.dive_v.y) * (1.0 if p.face.x >= 0.0 else -1.0)
		p.node.anim(dt, p.vel.length(), dv, p.stun > 0.3)
		p.node.ring.visible = human and p == ctrl and screen == S_PLAY and state != OVER
	ball_node.position = bpos
	var hs := Vector2(bvel.x, bvel.z).length()
	if hs > 0.2: ball_node.rotate(Vector3(bvel.z, 0, -bvel.x).normalized(), hs * dt / BALL_R * 0.5)
	cam_x = lerpf(cam_x, clampf(bpos.x * 0.85, -14.0, 14.0), minf(1.0, dt * 3.0))
	cam_z = lerpf(cam_z, clampf(bpos.z, -HW, HW), minf(1.0, dt * 2.5))
	cam.position = Vector3(cam_x, 25.0, 35.0 + cam_z * 0.3)
	cam.look_at(Vector3(cam_x, 0.0, 3.0 + cam_z * 0.35))

func _hud_update() -> void:
	var playing := screen == S_PLAY
	hud.score_panel.visible = playing
	hud.menu_btn.visible = screen != S_TITLE or hud.menu_open
	hud.pad_active = playing and state != OVER and not paused
	hud.meter.visible = playing and charge >= 0.0
	hud.meter_val = clampf(charge / 0.8, 0.0, 1.0)
	if not playing: return
	if practice:
		hud.score_lbl.text = "Practice"; hud.info_lbl.text = "Goals %d" % score[0]
	else:
		hud.score_lbl.text = "%s  %d - %d  %s" % [teams[team_ix[0]].abbr, score[0], score[1], teams[team_ix[1]].abbr]
		var c := int(minf(clock, HALF_SECS))
		hud.info_lbl.text = "%s half  %d:%02d" % ["1st" if half == 1 else "2nd", c / 60, c % 60]
	hud.burst_bar.value = ctrl.burst if ctrl != null else 1.0
	var mine := carrier != null and carrier == ctrl
	hud.pad.labels["A"] = "Pass" if mine else "Switch"
	hud.pad.labels["B"] = "Shoot" if mine else "Tackle"

func _test_state() -> Dictionary:
	var phase := 0
	if screen == S_TEAMS: phase = 1
	elif screen == S_PLAY: phase = 2 + state
	elif screen == S_MODES: phase = 20
	elif screen == S_LEAGUE: phase = 21
	var d := {"phase": phase, "half": half, "clock": snappedf(clock, 0.1), "score": score, "ball": [snappedf(bpos.x, 0.1), snappedf(bpos.y, 0.1), snappedf(bpos.z, 0.1)],
		"carrier": carrier.side if carrier != null else -1, "mine": carrier != null and carrier == ctrl, "practice": practice, "menu": hud.menu_open, "touch": hud.touch_seen, "quit_armed": hud.quit_armed, "text_large": _text_large(), "goals": goals.size(), "over_text": hud.over_lbl.text if hud.over_panel.visible else "",
		"focus": (str(get_viewport().gui_get_focus_owner().name) + "|" + str((get_viewport().gui_get_focus_owner() as Button).text)) if get_viewport().gui_get_focus_owner() is Button else "",
		"ctrl": [snappedf(ctrl.pos.x, 0.1), snappedf(ctrl.pos.y, 0.1)] if ctrl != null else [], "shots": shots, "counts": counts, "paused": paused, "mode": mode,
		"league_md": int(save.league.get("md", -1)), "league_results": (save.league.get("results", []) as Array).size(), "league_club": str(save.league.get("club", "")),
		"seasons": int(save.seasons), "best_finish": int(save.best_finish), "wins": int(save.wins), "draws": int(save.draws), "losses": int(save.losses)}
	return d

# ---------- test bot ----------

func _rules_test() -> void:
	# puts the ball out of play in each way and checks the restart the rules give
	var fails := 0
	var cases := [
		["sideline, last touch 0", Vector3(5, BALL_R, -HW - 0.5), 0, "throw", 1],
		["sideline, last touch 1", Vector3(-8, BALL_R, HW + 0.5), 1, "throw", 0],
		["right end line, attacker 0", Vector3(HL + 0.5, BALL_R, 9), 0, "goalkick", 1],
		["right end line, defender 1", Vector3(HL + 0.5, BALL_R, -9), 1, "corner", 0],
		["left end line, attacker 1", Vector3(-HL - 0.5, BALL_R, 9), 1, "goalkick", 0],
		["left end line, defender 0", Vector3(-HL - 0.5, BALL_R, 9), 0, "corner", 1],
		["goal at the right end", Vector3(HL + 0.5, 1.0, 0.5), 0, "goal", 0],
		["goal at the left end", Vector3(-HL - 0.5, 1.0, -0.5), 1, "goal", 1],
		["over the bar", Vector3(HL + 0.5, GOAL_H + 1.0, 0), 0, "goalkick", 1],
	]
	for c in cases:
		start_match(0, 1, false, false)
		state = LIVE; carrier = null; pass_to = null; bpos = c[1]; bvel = Vector3.ZERO; last_touch = c[2]
		var before: Array = score.duplicate()
		_rules()
		var got := ""; var side := -1
		if state == GOAL:
			got = "goal"; side = 0 if score[0] > before[0] else 1
		elif state == RESTART:
			got = rs_kind; side = rs_side
		var ok: bool = got == c[3] and side == c[4]
		if not ok: fails += 1
		print("RULES %s: %s side %d (%s)" % ["ok" if ok else "FAIL", got, side, c[0]])
	# a restart hands the ball to the taker and play goes on
	start_match(0, 1, false, false)
	set_restart("throw", 1, Vector2(4, HW - 0.3))
	for i in 400: _step(1.0 / 60.0)
	var live_ok := state == LIVE or state == RESTART
	print("RULES %s: throw-in taken and play goes on (state %d)" % ["ok" if live_ok else "FAIL", state])
	if not live_ok: fails += 1
	# practice: only a keeper on the other side, the clock stands still
	start_match(2, 3, true, false)
	for i in 3600: _step(1.0 / 60.0)
	var prac_ok: bool = pl[1].size() == 1 and clock == 0.0 and state != OVER
	print("RULES %s: practice runs 60 seconds with one keeper and no clock (goals %d)" % ["ok" if prac_ok else "FAIL", score[0]])
	if not prac_ok: fails += 1
	fails += _rules_league()
	print("RULES done, %d failed" % fails)

func _check(ok: bool, what: String) -> int:
	print("RULES %s: %s" % ["ok" if ok else "FAIL", what])
	return 0 if ok else 1

func _rules_league() -> int:
	var fails := 0
	var clubs: Array = league_cfg.clubs
	fails += _check(clubs.size() == 8 and clubs.all(func(c): return by_id.has(c)), "league has 8 clubs and each one is in teams.json")
	# the schedule: 7 rounds, 4 matches each, every club once a round, every pair exactly once
	for sd in [1, 2, 3, 99, 12345]:
		var lg := League.new_season(clubs, clubs[sd % clubs.size()], 1, sd)
		var ok := League.rounds(lg) == 7
		var pairs := {}
		for rnd in lg.fixtures:
			var seen := {}
			ok = ok and rnd.size() == 4
			for f in rnd:
				ok = ok and f[0] != f[1] and not seen.has(f[0]) and not seen.has(f[1])
				seen[f[0]] = true; seen[f[1]] = true
				var k: String = "|".join([f[0], f[1]] if f[0] < f[1] else [f[1], f[0]])
				ok = ok and not pairs.has(k)
				pairs[k] = true
			ok = ok and not League.user_fixture({"fixtures": lg.fixtures, "md": 0, "club": lg.club}).is_empty()
		fails += _check(ok and pairs.size() == 28, "schedule seed %d: 7 rounds of 4, every pair once (pairs %d)" % [sd, pairs.size()])
	# the table: points, goal difference and order
	var t := {"fixtures": [[["tapedeck", "vinyl"], ["rainy", "static"], ["cassette", "slowfade"], ["lamplight", "windowseat"]]], "md": 1, "club": "tapedeck",
		"results": [[["tapedeck", "vinyl", 3, 0], ["rainy", "static", 1, 1], ["cassette", "slowfade", 0, 2], ["lamplight", "windowseat", 2, 2]]]}
	var rows := League.table(t, clubs, by_id, 3, 1)
	var pts := 0
	for r in rows: pts += r.pts
	fails += _check(rows[0].id == "tapedeck" and rows[0].pts == 3 and rows[0].gd == 3 and rows[1].id == "slowfade" and rows[7].id == "vinyl" and pts == 3 + 3 + 2 + 2, "table: points, goal difference and order")
	fails += _check(League.ordinal(1) == "1st" and League.ordinal(2) == "2nd" and League.ordinal(3) == "3rd" and League.ordinal(11) == "11th" and League.ordinal(22) == "22nd", "ordinals")
	# simulated scores look like real matches
	var rng := RandomNumberGenerator.new(); rng.seed = 5
	var tot := 0; var mx := 0
	for i in 2000:
		var g := League.sim_score(rng, by_id[clubs[i % 8]], by_id[clubs[(i + 3) % 8]], float(league_cfg.sim_goals))
		tot += g[0] + g[1]; mx = maxi(mx, maxi(g[0], g[1]))
	var avg := float(tot) / 2000.0
	fails += _check(avg > 2.0 and avg < 4.5 and mx <= 9, "simulated matches average %.2f goals, most in one side %d" % [avg, mx])
	# a whole season through the same path a real match uses, then the save round trip
	var keep: Dictionary = save.duplicate(true)
	save.league = {}; save.seasons = 0; save.titles = 0; save.best_finish = 0
	_new_season("rainy")
	for i in 7:
		score = [2, 1] if i % 2 == 0 else [0, 0]
		_league_after_match()
	var lg2: Dictionary = save.league
	var rows2 := _table()
	var played := true
	var pts2 := 0; var gf := 0; var ga := 0
	for r in rows2:
		played = played and r.p == 7
		pts2 += r.pts; gf += r.gf; ga += r.ga
	var mine := 0
	for r in rows2:
		if r.id == "rainy": mine = r.pts
	fails += _check(League.is_over(lg2) and lg2.results.size() == 7 and played and gf == ga and mine == 4 * 3 + 3 * 1, "season: 7 matchdays, every club played 7, goals balance, your points %d" % mine)
	fails += _check(int(save.seasons) == 1 and int(save.best_finish) == League.position(rows2, "rainy") and int(save.titles) == (1 if save.best_finish == 1 else 0), "season end: seasons %d, best finish %d, titles %d" % [save.seasons, save.best_finish, save.titles])
	var back = JSON.parse_string(JSON.stringify(save))
	var rows3 := League.table(back.league, clubs, by_id, 3, 1)
	var same := rows3.size() == rows2.size()
	for i in rows3.size(): same = same and rows3[i].id == rows2[i].id and rows3[i].pts == rows2[i].pts
	fails += _check(same and League.is_over(back.league), "save file round trip keeps the season")
	# an old save without league fields loads with safe defaults
	save = keep.duplicate(true)
	save.league = {}; save.seasons = 0; save.titles = 0; save.best_finish = 0
	var old := {"v": 1, "sound": false, "wins": 2}
	for k in save:
		if old.has(k) and typeof(old[k]) == typeof(save[k]): save[k] = old[k]
	fails += _check(save.league.is_empty() and save.sound == false and int(save.wins) == 2 and save.has("best_finish"), "old save file loads with the new fields at their defaults")
	save = keep
	var st := SaveStore.new("user://rules_check_save.json")
	var src := {"v": 1, "wins": 3, "seasons": 2, "best_finish": 4, "sound": false, "team": "rainy", "league": {"md": 5, "club": "rainy"}}
	var wrote := st.write(src)
	var dst := {"v": 1, "wins": 0, "seasons": 0, "best_finish": 0, "sound": true, "team": "", "league": {}, "new_field": 7}
	var loaded := st.load_into(dst)
	fails += _check(wrote and loaded and typeof(dst.wins) == TYPE_INT and dst.wins == 3 and dst.seasons == 2 and dst.best_finish == 4 and dst.sound == false and dst.team == "rainy" and int(dst.league.md) == 5 and dst.new_field == 7,
		"save file round trip on disk keeps numbers as numbers and new fields at their defaults (%s)" % [dst])
	st.erase()   # E6.7: removes the check file and its .bak
	return fails

func _bot_season_start() -> void:
	seed(20261114)
	save.league = {}; save.seasons = 0; save.titles = 0; save.best_finish = 0
	_new_season(league_cfg.clubs[0])
	print("SEASON club %s" % by_id[save.league.club].name)
	_bot_season_next()

func _bot_season_next() -> void:
	var lg: Dictionary = save.league
	if int(lg.md) > 0 and lg.results.size() == int(lg.md):
		var line := ""
		for r in lg.results[int(lg.md) - 1]: line += "%s %d-%d %s   " % [by_id[r[0]].abbr, int(r[2]), int(r[3]), by_id[r[1]].abbr]
		print("MATCHDAY %d: %s" % [int(lg.md), line])
	if League.is_over(lg):
		var rows := _table()
		for i in rows.size():
			var r: Dictionary = rows[i]
			print("TABLE %d %-22s P%d W%d D%d L%d GF%d GA%d Pts%d" % [i + 1, r.name, r.p, r.w, r.d, r.l, r.gf, r.ga, r.pts])
		print("SEASON done: finished %s, best finish %d, titles %d" % [League.ordinal(League.position(rows, lg.club)), int(save.best_finish), int(save.titles)])
		get_tree().quit(); return
	var f := League.user_fixture(lg)
	var opp: String = f[1] if f[0] == lg.club else f[0]
	mode = "league"
	start_match(_team_ix(lg.club), _team_ix(opp), false, false)

func _bot_next() -> void:
	if bot_done >= bot_games:
		print("BOT done"); get_tree().quit(); return
	seed(20261114 + bot_done)
	var a := bot_done % teams.size(); var b := (a + 1 + (bot_done / teams.size()) % (teams.size() - 1)) % teams.size()
	start_match(a, b, false, false)

func _bot_report() -> void:
	var tot: float = maxf(0.1, poss_t[0] + poss_t[1])
	print("GAME %d: %s %d - %d %s | shots %d-%d | saves %d-%d | possession %d%%-%d%% | throws %d corners %d goal kicks %d kickoffs %d" % [bot_done + 1, teams[team_ix[0]].name, score[0], score[1], teams[team_ix[1]].name,
		shots[0], shots[1], saves[0], saves[1], int(round(poss_t[0] / tot * 100.0)), int(round(poss_t[1] / tot * 100.0)), counts.throw, counts.corner, counts.goalkick, counts.kickoff])
