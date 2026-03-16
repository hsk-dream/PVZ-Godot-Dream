@tool
extends Control

signal preview_changed(current_delta, expand_direction)
signal value_changed(delta, expand_direction)

@export var delta_color := Color(1.0, 0.25, 0.0, 0.75)
@export var sensitivity := 1.0

var dragging := false
var size_delta := Vector2()
var rect_scale := Vector2.ONE
var resize_direction := Vector2()


func _ready():
	$"X-".gui_input.connect(_on_child_gui_input.bind(Vector2.LEFT))
	$"X+".gui_input.connect(_on_child_gui_input.bind(Vector2.RIGHT))
	$"Y-".gui_input.connect(_on_child_gui_input.bind(Vector2.UP))
	$"Y+".gui_input.connect(_on_child_gui_input.bind(Vector2.DOWN))


func _draw():
	var anchor = (resize_direction + Vector2.ONE) * 0.5
	
	draw_rect(Rect2(size * anchor.floor(), (
		Vector2(resize_direction.x * round(size_delta.x) * rect_scale.x, size.y)
		if size_delta.x != 0.0 else
		Vector2(size.x, resize_direction.y * round(size_delta.y) * rect_scale.y)
	)), delta_color)


func _on_child_gui_input(event, direction):
	if event is InputEventMouseMotion:
		if !dragging: return
		size_delta += event.relative * direction * sensitivity / rect_scale
		preview_changed.emit(size_delta, Vector2i(direction))

	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		resize_direction = direction
		if !event.pressed:
			value_changed.emit(size_delta, Vector2i(direction))
			preview_changed.emit(Vector2.ZERO, Vector2i.ZERO)
			size_delta = Vector2.ZERO
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	queue_redraw()
