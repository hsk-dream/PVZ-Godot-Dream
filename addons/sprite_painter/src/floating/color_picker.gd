@tool
extends MarginContainer

signal color_changed(new_color, is_primary)

@export var workspace : NodePath
@export var picker_shortcut : Shortcut

@onready var color1_button = $Container/Box/Box/Box/Control/Color1
@onready var color2_button = $Container/Box/Box/Box/Control/Color2
@onready var palette = $Container/Box/Box/Palette
@onready var which_color_picked = $Container/Box/Box/WhichColor
@onready var color_picker_container = $Control/Picker
@onready var color_picker = $Control/Picker/Margins/Box/ColorPicker
@onready var color_picker_tool_button = $Container/Box/Box/Box/Control/Control.get_child(0)

var color1 := Color.WHITE
var color2 := Color.TRANSPARENT

var color_picker_primary := true
var color_picker_picking := false
var color_picker_picking_disable_with_click := false
var color_picker_pick_from_image := false
var screen_image : Image


func _ready():
	if get_viewport() is SubViewport: return

	hide()
	size = Vector2.ZERO
	show()
	position = Vector2(0, get_parent().size.y - get_minimum_size().y)

	set_picked_primary(true, false)
	set_color(true, color1)
	set_color(false, color2)
	_on_visibility_changed()
	_yoink_color_picker_tool_button()
	hide()
	show()
	color_picker_container.hide()
	color_picker_container.size = Vector2.ZERO
	await get_tree().process_frame
	color_picker_container.global_position = (
		global_position
		+ get_minimum_size()
		+ Vector2(16, -color_picker_container.size.y)
	)


func set_color(is_primary, color):
	if is_primary:
		color1 = color
		color1_button.self_modulate = color

	else:
		color2 = color
		color2_button.self_modulate = color

	if color_picker_primary == is_primary:
		color_picker.color = color

	color_changed.emit(color, is_primary)


func set_picked_primary(is_primary, toggle_picker_shown = true):
	if toggle_picker_shown:
		color_picker_container.visible = !color_picker_container.visible

	color_picker_primary = is_primary
	color_picker.color = color1 if is_primary else color2
	if !color_picker_container.visible:
		which_color_picked.text = "Color"
	
	elif is_primary:
		which_color_picked.text = "Primary"

	else:
		which_color_picked.text = "Secondary"


func set_color_screen_picking(picking, hold):
	color_picker_picking_disable_with_click = !hold
	color_picker_picking = picking
	get_node(workspace).input_disabled = picking
	if picking:
		screen_image = get_viewport().get_texture().get_image()


func _input(event):
	if picker_shortcut.matches_event(event) && !event.is_echo():
		# Only pick primary color (for consistent feel if picker not open)
		set_color_screen_picking(event.is_pressed(), true)
		return

	if event is InputEventMouseButton && color_picker_picking:
		if !event.pressed: return
		if color_picker_picking_disable_with_click:
			set_color_screen_picking(false, false)

		if color_picker_pick_from_image:
			var img_view = get_node(workspace).image_view
			var imagespace_event = img_view.event_vp_to_image(event)
			var color = get_node(workspace).edited_image.get_pixelv(imagespace_event.position)
			set_color(event.button_index == MOUSE_BUTTON_LEFT, color)

		else:
			set_color(event.button_index == MOUSE_BUTTON_LEFT, screen_image.get_pixelv(event.position))


func _yoink_color_picker_tool_button():
	var child = color_picker.get_child(1, true);
	if child == null:
		return

	for x in child.get_children(true):
		if !x is Button:
			continue

		x.free()
		break


func _on_color_picker_color_changed(color):
	set_color(color_picker_primary, color)


func _on_color_1_pressed():
	set_picked_primary(true, !color_picker_container.visible || color_picker_primary)


func _on_color_2_pressed():
	set_picked_primary(false, !color_picker_container.visible || !color_picker_primary)


func _on_swap_pressed():
	var swap = color1
	set_color(true, color2)
	set_color(false, swap)
	set_picked_primary(color_picker_primary, false)


func _on_open_picker_toggled(button_pressed):
	color_picker_container.visible = button_pressed
	set_picked_primary(color_picker_primary)


func _on_palette_toggled(button_pressed):
	palette.visible = button_pressed


func _on_visibility_changed():
	set_process_input(is_visible_in_tree())


func _on_picker_header_gui_input(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			color_picker_container.position += event.relative


func _on_color_pick_pressed():
	set_color_screen_picking(!color_picker_picking, false)


func _on_pick_from_image_toggled(button_pressed):
	color_picker_pick_from_image = button_pressed
