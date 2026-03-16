@tool
extends Node2D

@export var selection_color := Color(0.5, 0.5, 0.5, 0.5)

var selection : BitMap


func _ready():
	get_node("../../..").image_changed.connect(_on_image_changed)
	_on_visibility_changed()


func _process(delta):
	if Engine.get_process_frames() % 10 != 0: return
	self_modulate.a = abs(1.0 - fmod(Time.get_ticks_msec() * 0.0005, 2.0))


func _draw():
	if selection == null: return
	var sel_size = selection.get_size()
	if selection.get_true_bit_count() == sel_size.x * sel_size.y:
		return

	ImageFillTools.draw_bitmap(self, selection, selection_color)


func _on_visibility_changed():
	if !get_viewport() is Window:
		set_process(false)
		self_modulate.a = 0.75
		return

	set_process(is_visible_in_tree())


func _on_image_changed(image, rect_changed):
	if selection != null:
		queue_redraw()
