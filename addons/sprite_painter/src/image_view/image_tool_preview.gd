@tool
extends Sprite2D

@export var draw_handler : NodePath
@export var draw_method := "draw_preview"

var mouse_pos : Vector2


func _draw():
	get_node(draw_handler).call(draw_method, self, mouse_pos)


func _on_tool_switcher_tool_changed(tool_node):
	texture = null
