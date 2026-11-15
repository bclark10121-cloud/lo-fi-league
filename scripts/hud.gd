extends CanvasLayer
# All on-screen interface: scoreboard, messages, Menu button, shot meter, touch pad and panels.
# G5.1: one Menu button at the top right opens every option in a row across the top.

signal start_pressed
signal team_chosen(idx: int, practice: bool)
signal menu_action(name: String)

const ACCENT := Color(1.0, 0.78, 0.62)
const INK := Color(0.13, 0.11, 0.2, 0.9)

var root: Control
var score_lbl: Label
var info_lbl: Label
var banner: Label
var banner_t := 0.0
var hint: Label
var menu_btn: Button
var menu_row: HBoxContainer
var menu_open := false
var sound_btn: Button
var music_btn: Button
var title_panel: Control
var team_panel: Control
var over_panel: Control
var over_title: Label
var over_lbl: Label
var help_panel: Control
var meter: Control
var pad: Control
var burst_bar: ProgressBar
var score_panel: PanelContainer
var _practice_box: CheckBox

# touch state read by main.gd
var pad_active := false
var touch_seen := false
var stick := Vector2.ZERO
var btn_held := {"A": false, "B": false, "C": false}
var btn_just := {"A": false, "B": false, "C": false}
var _stick_id := -1
var _stick_origin := Vector2.ZERO
var _btn_ids := {}
var meter_val := 0.0

func _sb(c: Color, r := 10, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = c; s.set_corner_radius_all(r); s.set_content_margin_all(12)
	if border.a > 0: s.border_color = border; s.set_border_width_all(2)
	return s

func _lbl(t: String, size: int, col := Color.WHITE) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.14, 0.9)); l.add_theme_constant_override("outline_size", 6)
	return l

func _btn(t: String, size := 24) -> Button:
	var b := Button.new(); b.text = t; b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", _sb(Color(0.22, 0.19, 0.33, 0.96), 12, Color(1, 1, 1, 0.25)))
	b.add_theme_stylebox_override("hover", _sb(Color(0.3, 0.26, 0.44, 0.98), 12, ACCENT))
	b.add_theme_stylebox_override("focus", _sb(Color(0.3, 0.26, 0.44, 0.98), 12, ACCENT))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.45, 0.33, 0.42, 1), 12, ACCENT))
	b.pressed.connect(func(): menu_action.emit("click"))
	return b

func _panel(parent: Control, anchor := Control.PRESET_CENTER) -> PanelContainer:
	var p := PanelContainer.new(); p.add_theme_stylebox_override("panel", _sb(INK, 18, Color(1, 1, 1, 0.2)))
	parent.add_child(p); p.set_anchors_and_offsets_preset(anchor); p.grow_horizontal = Control.GROW_DIRECTION_BOTH; p.grow_vertical = Control.GROW_DIRECTION_BOTH
	return p

func _full() -> Control:
	var c := Control.new(); root.add_child(c); c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _centre(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func build(version: String, teams: Array) -> void:
	root = Control.new(); add_child(root); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# touch pad sits under everything else
	pad = Pad.new(); pad.hud = self; root.add_child(pad); pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# scoreboard, top left
	var sp := PanelContainer.new(); sp.add_theme_stylebox_override("panel", _sb(INK, 12)); root.add_child(sp); sp.position = Vector2(14, 12); score_panel = sp
	var sv := VBoxContainer.new(); sp.add_child(sv)
	score_lbl = _lbl("", 26); sv.add_child(score_lbl)
	info_lbl = _lbl("", 19, ACCENT); sv.add_child(info_lbl)
	burst_bar = ProgressBar.new(); burst_bar.custom_minimum_size = Vector2(160, 8); burst_bar.show_percentage = false; burst_bar.max_value = 1.0; sv.add_child(burst_bar)
	var bf := StyleBoxFlat.new(); bf.bg_color = ACCENT; bf.set_corner_radius_all(3)
	var bb := StyleBoxFlat.new(); bb.bg_color = Color(1, 1, 1, 0.15); bb.set_corner_radius_all(3)
	burst_bar.add_theme_stylebox_override("fill", bf); burst_bar.add_theme_stylebox_override("background", bb)
	# message, in the top third of the screen
	banner = _lbl("", 46, Color.WHITE); root.add_child(banner)
	banner.anchor_top = 0.2; banner.anchor_bottom = 0.2; banner.anchor_left = 0.0; banner.anchor_right = 1.0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; banner.add_theme_constant_override("outline_size", 12); banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint = _lbl("", 21, Color(1, 1, 1, 0.92)); root.add_child(hint); hint.anchor_left = 0; hint.anchor_right = 1; hint.anchor_top = 1; hint.anchor_bottom = 1
	hint.offset_top = -44; hint.offset_bottom = -10; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# shot power meter
	meter = Meter.new(); meter.hud = self; root.add_child(meter); meter.anchor_left = 0.5; meter.anchor_right = 0.5; meter.anchor_top = 0.8; meter.anchor_bottom = 0.8
	meter.offset_left = -180; meter.offset_right = 180; meter.offset_top = 0; meter.offset_bottom = 26; meter.visible = false; meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_title(version); _build_team(teams); _build_over(); _build_help()
	# Menu button and its row, top right (built last so it sits on top)
	menu_row = HBoxContainer.new(); root.add_child(menu_row); menu_row.anchor_left = 0; menu_row.anchor_right = 1; menu_row.offset_left = 300; menu_row.offset_right = -150; menu_row.offset_top = 12; menu_row.offset_bottom = 60
	menu_row.alignment = BoxContainer.ALIGNMENT_END; menu_row.add_theme_constant_override("separation", 8); menu_row.visible = false
	for item in [["Resume", "resume"], ["How to play", "help"], ["Sound: On", "sound"], ["Music: On", "music"], ["Restart match", "restart"], ["Quit to title", "title"]]:
		var b := _btn(item[0], 19); var act: String = item[1]
		b.pressed.connect(func(): menu_action.emit(act)); menu_row.add_child(b)
		if act == "sound": sound_btn = b
		if act == "music": music_btn = b
	menu_btn = _btn("Menu", 22); root.add_child(menu_btn); menu_btn.anchor_left = 1; menu_btn.anchor_right = 1; menu_btn.offset_left = -136; menu_btn.offset_right = -14; menu_btn.offset_top = 12; menu_btn.offset_bottom = 60
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.pressed.connect(func(): menu_action.emit("toggle"))

func set_menu(open: bool) -> void:
	menu_open = open; menu_row.visible = open; menu_btn.text = "Close" if open else "Menu"
	if open and menu_row.get_child_count() > 0: (menu_row.get_child(0) as Button).grab_focus()

func _build_title(version: String) -> void:
	title_panel = _full(); title_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var p := _panel(title_panel); var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 10)
	v.add_child(_centre(_lbl("LO-FI LEAGUE", 62, ACCENT)))
	v.add_child(_centre(_lbl("Version %s" % version, 18, Color(1, 1, 1, 0.7))))
	v.add_child(_centre(_lbl("Laid-back 7 a side soccer. Pass, shoot and take it easy.", 24)))
	v.add_child(_centre(_lbl("Keyboard: WASD or arrows move. Space passes or switches player. F shoots or tackles (hold for power). Shift sprints.\nController: left stick moves. A passes or switches. X shoots or tackles. RT sprints.\nTouch: drag on the left to move. Pass, Shoot and Sprint buttons on the right.", 17, Color(1, 1, 1, 0.85))))
	var b := _btn("Start", 32); b.custom_minimum_size = Vector2(260, 64); b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): start_pressed.emit()); v.add_child(b); b.name = "StartBtn"
	v.add_child(_centre(_lbl("Music by HoliznaCC0 (CC0), found through Patch.gg. Full credits in CREDITS.md.", 13, Color(1, 1, 1, 0.55))))

func focus_start() -> void:
	(title_panel.find_child("StartBtn", true, false) as Button).grab_focus.call_deferred()

func _build_team(teams: Array) -> void:
	team_panel = _full(); team_panel.mouse_filter = Control.MOUSE_FILTER_STOP; team_panel.visible = false
	var p := _panel(team_panel); var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 12)
	v.add_child(_centre(_lbl("Pick your club", 40, ACCENT)))
	var g := GridContainer.new(); g.columns = 2; g.add_theme_constant_override("h_separation", 12); g.add_theme_constant_override("v_separation", 12); v.add_child(g); g.name = "Teams"
	for i in teams.size():
		var tm: Dictionary = teams[i]
		var b := _btn(str(tm.name), 25); b.custom_minimum_size = Vector2(350, 66)
		var sw := ColorRect.new(); sw.color = Color(str(tm.home.shirt)); sw.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE); sw.offset_right = 18; sw.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(sw)
		var sw2 := ColorRect.new(); sw2.color = Color(str(tm.home.shorts)); sw2.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE); sw2.offset_left = -18; sw2.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(sw2)
		b.pressed.connect(func(): team_chosen.emit(i, _practice_box.button_pressed)); g.add_child(b)
	_practice_box = CheckBox.new(); _practice_box.text = "Practice (no clock, no score, keeper only)"; _practice_box.add_theme_font_size_override("font_size", 20); v.add_child(_practice_box)
	v.add_child(_centre(_lbl("Exhibition: two 3-minute halves against the computer.", 18, Color(1, 1, 1, 0.8))))

func show_team(on: bool) -> void:
	team_panel.visible = on
	if on: (team_panel.find_child("Teams", true, false).get_child(0) as Button).grab_focus.call_deferred()

func _build_over() -> void:
	over_panel = _full(); over_panel.mouse_filter = Control.MOUSE_FILTER_STOP; over_panel.visible = false
	var p := _panel(over_panel); var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 12)
	over_title = _centre(_lbl("FULL TIME", 44, ACCENT)); v.add_child(over_title)
	over_lbl = _centre(_lbl("", 24)); v.add_child(over_lbl)
	var h := HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER; h.add_theme_constant_override("separation", 12); v.add_child(h)
	var a := _btn("Play again", 26); a.pressed.connect(func(): menu_action.emit("restart")); h.add_child(a); a.name = "Again"
	var b := _btn("Title", 26); b.pressed.connect(func(): menu_action.emit("title")); h.add_child(b)

func show_over(text: String) -> void:
	over_lbl.text = text; over_panel.visible = true
	(over_panel.find_child("Again", true, false) as Button).grab_focus.call_deferred()

func _build_help() -> void:
	help_panel = _full(); help_panel.mouse_filter = Control.MOUSE_FILTER_STOP; help_panel.visible = false
	var p := _panel(help_panel); var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 10)
	v.add_child(_centre(_lbl("How to play", 36, ACCENT)))
	var txt := "You attack the goal on the right. You control the player with the ring.\n\nWith the ball\n  Pass: aim with the stick and press Pass. You take over the player who receives it.\n  Shoot: hold Shoot for power, then let go. Push up or down to aim at a corner.\n  Sprint: hold Sprint. The bar under the score shows how much is left.\n\nWithout the ball\n  Switch: press Pass to take the player nearest the ball.\n  Tackle: press Shoot when you are close to the ball.\n\nRules\n  Two 3-minute halves. Throw-ins, corners and goal kicks. No offside and no cards.\n  Keepers play by themselves.\n\nKeyboard: WASD or arrows, Space, F, Shift, Tab, Esc.   Controller: stick, A, X, RT, Back."
	v.add_child(_lbl(txt, 18))
	var b := _btn("Close", 24); b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; b.pressed.connect(func(): menu_action.emit("help_close")); v.add_child(b); b.name = "HelpClose"

func show_help(on: bool) -> void:
	help_panel.visible = on
	if on: (help_panel.find_child("HelpClose", true, false) as Button).grab_focus.call_deferred()

func say(text: String, secs := 2.2, col := Color.WHITE) -> void:
	banner.text = text; banner_t = secs; banner.add_theme_color_override("font_color", col)

func _process(dt: float) -> void:
	if banner_t > 0.0:
		banner_t -= dt
		banner.modulate.a = clampf(banner_t * 3.0, 0.0, 1.0)
		if banner_t <= 0.0: banner.text = ""
	pad.visible = pad_active and touch_seen
	pad.queue_redraw()
	if meter.visible: meter.queue_redraw()

func clear_just() -> void:
	for k in btn_just: btn_just[k] = false

func _btn_centres() -> Dictionary:
	var s := root.size
	return {"A": Vector2(s.x - 250, s.y - 90), "B": Vector2(s.x - 110, s.y - 120), "C": Vector2(s.x - 130, s.y - 270)}

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventScreenDrag: touch_seen = true
	if not pad_active or menu_open: return
	var s := root.size
	var scale_v := s / Vector2(get_viewport().get_visible_rect().size)
	if e is InputEventScreenTouch:
		var pos: Vector2 = e.position * scale_v
		if e.pressed:
			if pos.y < 70: return
			var hit := ""
			var cs := _btn_centres()
			for k in cs:
				if pos.distance_to(cs[k]) < 74: hit = k
			if hit != "":
				btn_held[hit] = true; btn_just[hit] = true; _btn_ids[e.index] = hit
			elif pos.x < s.x * 0.5 and _stick_id == -1:
				_stick_id = e.index; _stick_origin = pos; stick = Vector2.ZERO
		else:
			if e.index == _stick_id:
				_stick_id = -1; stick = Vector2.ZERO
			if _btn_ids.has(e.index):
				btn_held[_btn_ids[e.index]] = false; _btn_ids.erase(e.index)
	elif e is InputEventScreenDrag and e.index == _stick_id:
		var v: Vector2 = (e.position * scale_v - _stick_origin) / 70.0
		stick = v.limit_length(1.0)

func reset_touch() -> void:
	_stick_id = -1; stick = Vector2.ZERO; _btn_ids.clear()
	for k in btn_held: btn_held[k] = false

class Pad extends Control:
	var hud
	var labels := {"A": "Pass", "B": "Shoot", "C": "Sprint"}
	func _draw() -> void:
		var cs: Dictionary = hud._btn_centres()
		var f := ThemeDB.fallback_font
		for k in cs:
			var on: bool = hud.btn_held[k]
			draw_circle(cs[k], 62, Color(1, 1, 1, 0.34 if on else 0.16))
			draw_arc(cs[k], 62, 0, TAU, 32, Color(1, 1, 1, 0.6), 3.0)
			var t: String = labels[k]
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string_outline(f, cs[k] + Vector2(-w / 2, 8), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, Color(0.08, 0.05, 0.14, 0.85))
			draw_string(f, cs[k] + Vector2(-w / 2, 8), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.95))
		var o: Vector2 = hud._stick_origin if hud._stick_id != -1 else Vector2(150, size.y - 150)
		draw_circle(o, 80, Color(1, 1, 1, 0.1)); draw_arc(o, 80, 0, TAU, 32, Color(1, 1, 1, 0.45), 3.0)
		draw_circle(o + hud.stick * 60, 34, Color(1, 1, 1, 0.4))

class Meter extends Control:
	var hud
	func _draw() -> void:
		var w := size.x; var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color(0.1, 0.08, 0.16, 0.9))
		draw_rect(Rect2(0, 0, w * clampf(hud.meter_val, 0.0, 1.0), h), Color(1.0, 0.78, 0.62))
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.8), false, 3.0)
