@tool
extends Sprite2D

@export var draw_handler : NodePath

@onready var border_rect = $"../ImageBorder"
@onready var resize_result = $"../ResizeResult"
@onready var preview = $"ToolView"
@onready var preview_shader = $"SubViewport/ShaderView"
@onready var resize_rect = border_rect.get_node("Resize")

var camera_pos := Vector2.ZERO
var mouse_pos := Vector2.ZERO


func zoom(by : Vector2):
	scale *= by
	camera_pos *= by
	update_position()


func translate(by : Vector2):
	camera_pos += by
	update_position()


func update_position():
	update_position_local()
	resize_rect.rect_scale = global_scale
	$"SubViewport".size = texture.get_size()


func reset_position():
	camera_pos = Vector2.ZERO
	scale = Vector2.ONE
	update_position()


func update_position_local():
	position = get_parent().size * 0.5 + camera_pos - texture.get_size() * 0.5
	centered = false
	update_texture_view_rect()


func update_position_overlay(edited_node):
	position = edited_node.global_position - edited_node.get_viewport().get_visible_rect().position
	centered = false
	scale = edited_node.global_scale if edited_node is Node2D else edited_node.scale
	# TODO: fetch source's actual on-screen position.
	update_texture_view_rect()


func update_texture_view_rect():
	border_rect.size = scale * (texture.get_size() if texture != null else Vector2.ZERO)
	border_rect.position = position
	if centered:
		border_rect.position -= border_rect.size * 0.5


func _on_resize_preview_changed(current_delta, expand_direction):
	resize_result.hide()
	
	var old_size = texture.get_size()
	var delta_one_axis = round(current_delta.x if expand_direction.x != 0 else current_delta.y)
	var old_size_one_axis = old_size.x if expand_direction.x != 0 else old_size.y
	resize_result.text = "%s%spx (%.1f%s)\n-> %s\n" % [
		"+" if delta_one_axis >= 0.5 else "",
		delta_one_axis,
		(1.0 + delta_one_axis / float(old_size_one_axis)) * 100,
		"%",
		(old_size + current_delta).round(),
		]

	resize_result.visible = expand_direction != Vector2i(0, 0)
	resize_result.global_position = get_global_mouse_position() - resize_result.size * 0.5


func event_vp_to_image(from_event : InputEventMouse, unsafe : bool = false) -> InputEventMouse:
	if !unsafe:
		from_event = from_event.duplicate()

	from_event.position = (from_event.position - global_position) / scale
	if from_event is InputEventMouseMotion:
		from_event.relative /= scale

	preview.mouse_pos = from_event.position
	preview.show()
	preview.queue_redraw()
	preview_shader.mouse_pos = from_event.position
	preview_shader.show()
	preview_shader.queue_redraw()
	return from_event
