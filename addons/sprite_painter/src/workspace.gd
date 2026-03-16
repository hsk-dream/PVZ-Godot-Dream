@tool
extends Control

signal pre_image_changed(image, rect_changed)
signal image_changed(image, rect_changed)
signal image_replaced(old_image, new_image)

@onready var image_view = $"%EditedImageView"
@onready var selection_view = $"%SelectionView"
@onready var grid_view = $"%GridView"
@onready var tool_manager = $"%ToolSwitcher"
@onready var context_settings = $"%ContextSettings"

var cur_scale := 1.0
var mouse_button := -1
var input_disabled := false
var dragging := false
var rollback_to_image : Image
var edited_image : Image
var edited_image_path : String
var edited_image_selection := BitMap.new()


func _ready():
	if !get_viewport() is Window: return

	# Recolor all floating panels to make buttons more visible
	var style = get_theme_stylebox("panel", "Panel").duplicate()
	style.bg_color = get_theme_color("base_color", "Editor")
	theme = Theme.new()
	theme.set_stylebox("panel", "Panel", style)


func handle_input(event) -> bool:
	if input_disabled: return true
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT || event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				mouse_button = event.button_index
				return pass_event_to_tool(event)

			elif mouse_button == event.button_index:
				dragging = false
				mouse_button = -1
				var rect = tool_manager.get_affected_rect()
				make_image_edit(func(): pass_event_to_tool(event), rect)
				return true

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			image_view.zoom(Vector2.ONE * 1.05)
			return true

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			image_view.zoom(Vector2.ONE / 1.05)
			return true

		if event.button_index == MOUSE_BUTTON_MIDDLE:
			return true

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) || Input.is_key_pressed(KEY_SPACE):
			image_view.translate(event.relative)

		grab_focus()
		return pass_event_to_tool(event)

	if event is InputEventKey:
		var ctrl = (event.get_keycode_with_modifiers() & (KEY_MASK_CMD_OR_CTRL)) != 0
		match event.keycode:
			KEY_A, KEY_D:
				if ctrl:
					clear_selection()

				return ctrl

		return false

	return false


func make_image_edit(edit : Callable, affected_rect : Rect2i):
	pre_image_changed.emit(edited_image, affected_rect)
	edit.call()
	image_changed.emit(edited_image, affected_rect)
	if edited_image_selection.get_true_bit_count() == 0:
		clear_selection()

	image_view.texture.update(edited_image)


func pass_event_to_tool(event) -> bool:
	event.position = event.global_position
	var image_space_event = image_view.event_vp_to_image(event)
	if context_settings.handle_image_input(image_space_event):
		return true

	return tool_manager.handle_image_input(
		image_space_event,
		edited_image,
		edited_image_selection
	)


func edit_texture(tex_path : String):
	var new_image = Image.load_from_file(tex_path)
	if new_image.get_format() == Image.FORMAT_RGB8:
		# If no alpha, add alpha.
		var image_bytes := new_image.get_data()
		var new_image_bytes := PackedByteArray()
		new_image_bytes.resize(image_bytes.size() / 3 * 4)
		for i in image_bytes.size() / 3:
			new_image_bytes[i * 4 + 0] = image_bytes[i * 3 + 0]
			new_image_bytes[i * 4 + 1] = image_bytes[i * 3 + 1]
			new_image_bytes[i * 4 + 2] = image_bytes[i * 3 + 2]
			new_image_bytes[i * 4 + 3] = 255

		new_image.set_data(new_image.get_width(), new_image.get_height(), new_image.has_mipmaps(), Image.FORMAT_RGBA8, new_image_bytes)

	rollback_to_image = Image.create_from_data(new_image.get_width(), new_image.get_height(), new_image.has_mipmaps(), new_image.get_format(), new_image.get_data())
	image_view.texture = ImageTexture.create_from_image(new_image)
	image_view.reset_position()
	replace_image(edited_image, new_image)

	image_view.call_deferred("update_position")
	edited_image_path = tex_path


func rollback_changes():
	image_view.texture = ImageTexture.create_from_image(rollback_to_image)
	replace_image(edited_image, rollback_to_image)


func set_view_grid(grid_size, grid_offset, is_region):
	grid_view.image_size = edited_image.get_size()
	grid_view.grid_size = grid_size
	grid_view.grid_offset = grid_offset
	grid_view.is_region = is_region
	grid_view.queue_redraw()


func update_texture(new_image):
	if new_image.get_size() != edited_image.get_size():
		image_view.texture = ImageTexture.create_from_image(new_image)
		image_view.update_position()
		image_view.queue_redraw()
		replace_image(edited_image, new_image)

	image_view.texture.update(new_image)
	edited_image = new_image

	grid_view.image_size = new_image.get_size()
	grid_view.queue_redraw()


func get_resized(old_image, new_size, expand_direction, stretch_format = -1) -> Image:
	var old_size = old_image.get_size()
	if stretch_format != -1:
		var new_image = Image.create(old_size.x, old_size.y, false, old_image.get_format())
		new_image.blit_rect(
			old_image,
			Rect2i(Vector2.ZERO, old_image.get_size()), Vector2i.ZERO
		)
		new_image.resize(new_size.x, new_size.y, stretch_format)
		return new_image

	else:
		var new_image = Image.create(new_size.x, new_size.y, false, old_image.get_format())
		var anchors = (Vector2i.ONE - expand_direction) * 0.5
		new_image.blit_rect(
			old_image,
			Rect2i(Vector2i.ZERO, old_image.get_size()),
			Vector2i(
				(new_size.x - old_size.x) * anchors.x,
				(new_size.y - old_size.y) * anchors.y,
			)
		)
		return new_image


func replace_image(old_image, new_image):
	var new_size = new_image.get_size()
	edited_image = new_image

	edited_image_selection.create(new_size)
	clear_selection()
	selection_view.selection = edited_image_selection


func clear_selection():
	edited_image_selection.set_bit_rect(Rect2i(Vector2i.ZERO, edited_image_selection.get_size()), true)


func _on_resize_value_changed(
	delta, expand_direction,
	stretch_format = Image.INTERPOLATE_NEAREST if Input.is_key_pressed(KEY_SHIFT) else -1
):
	var old_size = edited_image.get_size()
	var new_size = old_size + Vector2i(delta.round())

	var new_image = get_resized(edited_image, new_size, expand_direction, stretch_format)
	image_replaced.emit(edited_image, new_image)
	update_texture(new_image)
