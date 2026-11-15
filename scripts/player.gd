extends Node3D
# One soccer player, built from simple shapes and animated in code. The model faces +X. 1 unit is 1 yard.

var body: Node3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var ring: MeshInstance3D
var phase := 0.0

static var _mats := {}

static func mat(c: Color) -> StandardMaterial3D:
	var k := c.to_html()
	if not _mats.has(k):
		var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = 0.95
		_mats[k] = m
	return _mats[k]

func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var b := BoxMesh.new(); b.size = size
	mi.mesh = b; mi.position = pos; mi.material_override = mat(c); parent.add_child(mi)
	return mi

func build(kit: Dictionary, skin: Color, hair: Color, num: int) -> void:
	var shirt := Color(str(kit.shirt)); var trim := Color(str(kit.trim)); var shorts := Color(str(kit.shorts)); var socks := Color(str(kit.socks))
	body = Node3D.new(); add_child(body)
	_box(body, Vector3(0.38, 0.62, 0.64), Vector3(0, 1.40, 0), shirt)
	_box(body, Vector3(0.40, 0.10, 0.66), Vector3(0, 1.30, 0), trim)
	_box(body, Vector3(0.40, 0.30, 0.62), Vector3(0, 0.96, 0), shorts)
	# head and hair
	var head := MeshInstance3D.new(); var hm := SphereMesh.new(); hm.radius = 0.29; hm.height = 0.58; hm.radial_segments = 10; hm.rings = 6
	head.mesh = hm; head.position = Vector3(0.02, 2.0, 0); head.material_override = mat(skin); body.add_child(head)
	var hr := MeshInstance3D.new(); var hh := SphereMesh.new(); hh.radius = 0.31; hh.height = 0.31; hh.is_hemisphere = true; hh.radial_segments = 10; hh.rings = 4
	hr.mesh = hh; hr.position = Vector3(-0.03, 2.03, 0); hr.material_override = mat(hair); body.add_child(hr)
	for s in [-1.0, 1.0]:
		var leg := Node3D.new(); leg.position = Vector3(0, 0.84, s * 0.17); body.add_child(leg)
		_box(leg, Vector3(0.2, 0.3, 0.2), Vector3(0, -0.14, 0), skin)
		_box(leg, Vector3(0.22, 0.42, 0.22), Vector3(0, -0.5, 0), socks)
		_box(leg, Vector3(0.36, 0.13, 0.24), Vector3(0.06, -0.77, 0), Color(0.12, 0.11, 0.15))
		var arm := Node3D.new(); arm.position = Vector3(0, 1.66, s * 0.41); body.add_child(arm)
		_box(arm, Vector3(0.2, 0.26, 0.18), Vector3(0, -0.12, 0), shirt)
		_box(arm, Vector3(0.15, 0.36, 0.14), Vector3(0, -0.42, 0), skin)
		if s < 0: leg_l = leg; arm_l = arm
		else: leg_r = leg; arm_r = arm
	var n := Label3D.new(); n.text = str(num); n.font_size = 96; n.pixel_size = 0.0042; n.outline_size = 0; n.modulate = trim
	n.position = Vector3(-0.2, 1.46, 0); n.rotation.y = -PI / 2; body.add_child(n)
	# ring under the player you control
	ring = MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.62; tm.outer_radius = 0.8; tm.rings = 20; tm.ring_segments = 6
	ring.mesh = tm; ring.scale = Vector3(1, 0.25, 1); ring.position = Vector3(0, 0.07, 0)
	var rm := StandardMaterial3D.new(); rm.albedo_color = Color(1.0, 0.86, 0.55); rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rm; ring.visible = false; ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(ring)

func anim(dt: float, speed: float, diving: float, down: bool) -> void:
	var amt := clampf(speed / 6.0, 0.0, 1.0)
	phase += dt * (4.0 + speed * 1.5)
	var sw := sin(phase) * amt * 0.95
	leg_l.rotation.z = sw; leg_r.rotation.z = -sw
	arm_l.rotation.z = -sw * 0.7; arm_r.rotation.z = sw * 0.7
	var tx := 0.0; var tz := -amt * 0.12
	if diving != 0.0: tx = 1.25 * signf(diving)
	if down: tz = -0.7
	body.rotation.x = lerpf(body.rotation.x, tx, minf(1.0, dt * 14.0))
	body.rotation.z = lerpf(body.rotation.z, tz, minf(1.0, dt * 12.0))
