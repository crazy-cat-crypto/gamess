extends StaticBody2D

@onready var body_polygon: Polygon2D = $BodyPolygon

var breakable: bool = true
var block_type: int = 0

func _ready() -> void:
	set_block_type(block_type)

func set_block_type(value: int) -> void:
	block_type = value
	if not is_node_ready():
		return

	match block_type:
		0:
			breakable = true
			body_polygon.color = Color(0.55, 0.39, 0.23)
		1:
			breakable = true
			body_polygon.color = Color(0.42, 0.42, 0.46)
		2:
			breakable = false
			body_polygon.color = Color(0.18, 0.18, 0.2)
		_:
			breakable = true
			body_polygon.color = Color(0.55, 0.39, 0.23)
