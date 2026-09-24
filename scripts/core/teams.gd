class_name Teams
## Takım tanımları ve takım renklerine göre paylaşılan malzemeler.

enum Team { BLUE, ORANGE }

const COLORS := {
	Team.BLUE: Color(0.12, 0.5, 1.0),
	Team.ORANGE: Color(1.0, 0.45, 0.05),
}

const NAMES := {
	Team.BLUE: "Mavi",
	Team.ORANGE: "Turuncu",
}

static var _body_materials := {}
static var _paintball_materials := {}


static func color(team: Team) -> Color:
	return COLORS[team]


static func body_material(team: Team) -> StandardMaterial3D:
	if not _body_materials.has(team):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color(team)
		mat.roughness = 0.6
		_body_materials[team] = mat
	return _body_materials[team]


static func paintball_material(team: Team) -> StandardMaterial3D:
	if not _paintball_materials.has(team):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color(team)
		mat.emission_enabled = true
		mat.emission = color(team)
		mat.emission_energy_multiplier = 0.6
		_paintball_materials[team] = mat
	return _paintball_materials[team]
