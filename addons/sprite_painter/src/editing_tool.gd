@tool
class_name EditingTool
extends VBoxContainer

enum {
  TOOL_PROP_BOOL,
  TOOL_PROP_INT,
  TOOL_PROP_FLOAT,
  TOOL_PROP_ENUM,
  TOOL_PROP_ICON_ENUM,
  TOOL_PROP_ICON_FLAGS,
  TOOL_PROP_RESOURCE,
  TOOL_PROP_FOLDER_SCAN,
  TOOL_PROP_COLOR,
}

enum {
  OPERATION_REPLACE,
  OPERATION_ADD,
  OPERATION_SUBTRACT,
  OPERATION_INTERSECTION,
  OPERATION_XOR,
}

@export var tool_name := "Box Selection"
@export_multiline var tool_desc := ""
@export var preview_shader : ShaderMaterial
@export_enum("None", "When Drawing", "When Active") var image_hide_mode := 0

var selection : BitMap

var _last_grid : GridContainer
var _hotkey_adjustment_hook : Callable


func _enter_tree():
	if !visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)

	set_process_shortcut_input(false)


func add_name():
	var label = Label.new()
	label.text = tool_name
	label.size_flags_vertical = SIZE_SHRINK_CENTER | SIZE_FILL
	add_child(label)
	add_separator()
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.self_modulate.a = 0.75
	label.text = tool_desc
	label.size_flags_vertical = SIZE_SHRINK_CENTER | SIZE_FILL
	if tool_desc == "": label.hide()
	add_child(label)

	_last_grid = null


func add_separator():
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = get_theme_color("accent_color", "Editor")
	sep.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(sep)
	
	_last_grid = null


func start_property_grid():
	var grid = GridContainer.new()
	grid.columns = 2
	_last_grid = grid
	add_child(grid)
	return grid


func add_property(
	property_name,
	default_value,
	setter : Callable,
	type : int,
	hint : Variant = null,
	hotkey_adjustment = false,
):
	var parent = _last_grid
	if _last_grid == null:
		parent = HBoxContainer.new()
		add_child(parent)

	var label = Label.new()
	label.size_flags_vertical = SIZE_SHRINK_CENTER | SIZE_FILL
	label.text = property_name
	parent.add_child(label)

	var editor
	match type:
		TOOL_PROP_BOOL:
			editor = CheckBox.new()
			editor.button_pressed = default_value
			editor.text = "On"
			editor.toggled.connect(setter)
			if hotkey_adjustment:
				_hotkey_adjustment_hook = func(x):
					editor.button_pressed = !editor.button_pressed
					setter.call(editor.button_pressed)

		TOOL_PROP_INT, TOOL_PROP_FLOAT:
			editor = EditorSpinSlider.new()
			if hint == null:
				editor.max_value = INF
				editor.min_value = -INF

			else:
				editor.min_value = hint[0]
				editor.max_value = hint[1]
				editor.hide_slider = false
			
			editor.value = default_value
			editor.step = 0.01 if type == TOOL_PROP_FLOAT else 1.0
			editor.custom_minimum_size.x = 64.0
			editor.value_changed.connect(setter)
			if hotkey_adjustment:
				_hotkey_adjustment_hook = func(x):
					editor.value += editor.step * x
					setter.call(editor.value)

		TOOL_PROP_ENUM:
			if hint.size() != 2:
				editor = OptionButton.new()
				for x in hint:
					editor.add_item(x)

				editor.item_selected.connect(setter)
				editor.select(default_value)
				if hotkey_adjustment:
					_hotkey_adjustment_hook = func(x):
						editor.select(posmod((editor.get_selected_id() + x), hint.size()))
						setter.call(editor.get_selected_id())

			else:
				editor = Button.new()
				editor.text = hint[default_value]
				editor.pressed.connect(func():
					var x = 1 if editor.text == hint[0] else 0
					editor.text = hint[x]
					setter.call(x)
				)
				if hotkey_adjustment:
					_hotkey_adjustment_hook = func(x):
						var new_value = 1 if editor.text == hint[0] else 0
						editor.text = hint[new_value]
						setter.call(new_value)


		TOOL_PROP_ICON_ENUM, TOOL_PROP_ICON_FLAGS:
			editor = HBoxContainer.new()
			var icons = hint if hint is Array else hint.keys()
			var tooltips = {} if hint is Array else hint
			var button

			var bgroup = ButtonGroup.new()

			for x in icons:
				button = load("res://addons/sprite_painter/editor_icon_button.gd").new()
				button.tooltip_text = tooltips.get(x)
				button.toggle_mode = true
				button.add_theme_stylebox_override("pressed", button.get_theme_stylebox("focus", "Button"))
				button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

				if x is Texture:
					button.set_deferred("icon", x)

				else:
					button._set_icon_name(x)

				editor.add_child(button)
				if type == TOOL_PROP_ICON_ENUM:
					button.button_group = bgroup
					button.toggled.connect(func(toggled):
						if !toggled: return
						setter.call(button.get_index())
					)
					button.button_pressed = default_value == button.get_index()

				else:
					button.toggled.connect(func(toggled):
						default_value[button.get_index()] = toggled
						setter.call(default_value)
					)
					button.button_pressed = default_value[button.get_index()]

			if hotkey_adjustment:
				_hotkey_adjustment_hook = func(x):
					var new_value : int
					for i in editor.get_child_count():
						if editor.get_child(i).button_pressed:
							new_value = posmod(i + x, hint.size())
							editor.get_child(new_value).button_pressed = true
							editor.get_child(i).button_pressed = false
							break

#					setter.call(new_value)

		TOOL_PROP_RESOURCE:
			editor = EditorResourcePicker.new()
			editor.resource_changed.connect(func(x):
				setter.call(x)
			)
			editor.edited_resource = default_value
			if !hint is Array || hint.size() > 0:
				editor.base_type = hint if hint is String else hint[0]

			var plugin_root = get_parent()
			while !plugin_root is Window:
				plugin_root = plugin_root.get_parent()
				if plugin_root is SpritePainterRoot:
					editor.resource_selected.connect(func(x, inspected):
						plugin_root.editor_interface.edit_resource(x)
					)
					break

		TOOL_PROP_FOLDER_SCAN:
			editor = OptionButton.new()
			var folder = (hint if hint is String else hint[0]).trim_suffix("/") + "/"
			var filenames = DirAccess.get_files_at(folder)
			
			for x in filenames:
				editor.add_item(x.get_basename())

			editor.item_selected.connect(func(x):
				setter.call(load(folder + filenames[x]))
			)
			if default_value is int:
				editor.select(default_value)

			elif default_value is String:
				default_value = default_value.get_file()

				var found_index = filenames.find(default_value)
				editor.select(found_index)

			if hotkey_adjustment:
				_hotkey_adjustment_hook = func(x):
					editor.select(posmod((editor.get_selected_id() + x), hint.size()))
					setter.call(load(folder + filenames[editor.get_selected_id()]))

		TOOL_PROP_COLOR:
			editor = ColorPickerButton.new()
			editor.color = default_value
			editor.color_changed.connect(setter)
			

	editor.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(editor)
	return editor


func add_text_display():
	var textbox = LineEdit.new()
	textbox.editable = false
	textbox.size_flags_vertical = SIZE_FILL
	textbox.expand_to_text_length = true
	add_child(textbox)

	_last_grid = null
	return textbox


func add_button_panel(labels : Array[String]):
	var container = HFlowContainer.new()
	for x in labels:
		var new_button = Button.new()
		new_button.text = x
		new_button.size_flags_horizontal = SIZE_EXPAND_FILL
		container.add_child(new_button)

	add_child(container)

	_last_grid = null
	return container


func is_out_of_bounds(pos : Vector2i, rect_size : Vector2i):
	return (
		pos.x < 0 || pos.y < 0
		|| pos.x >= rect_size.x || pos.y >= rect_size.y
	)


func get_rect_from_drag(start_pos, end_pos, squarify : bool = false):
	var rect = Rect2i(start_pos, end_pos - start_pos)
	if !squarify:
		return rect.abs().grow_individual(0, 0, 1, 1)

	var max_side = maxi(abs(rect.size.x), abs(rect.size.y))
	var square = Rect2i(rect.position, Vector2i(max_side, max_side))
	if rect.size.x < 0:
		square.position.x -= square.size.x

	if rect.size.y < 0:
		square.position.y -= square.size.y

	return square



func is_selection_empty():
	return selection.get_true_bit_count() == selection.get_size().x * selection.get_size().y


func set_image_pixel(image : Image, x : int, y : int, color : Color):
	if !is_out_of_bounds(Vector2i(x, y), image.get_size()):
		if selection.get_bit(x, y):
			image.set_pixel(x, y, color)


func set_image_pixelv(image : Image, pos : Vector2i, color : Color):
	if !is_out_of_bounds(pos, image.get_size()):
		if selection.get_bitv(pos):
			image.set_pixelv(pos, color)


func mouse_pressed(
	event : InputEventMouseButton,
	image : Image,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	printerr("Not implemented: mouse_pressed! (" + get_script().resource_path.get_file() + ")")


func get_affected_rect() -> Rect2i:
	printerr("Not implemented: get_affected_rect! (" + get_script().resource_path.get_file() + ")")
	return Rect2i()


func mouse_moved(event : InputEventMouseMotion):
	printerr("Not implemented: mouse_moved! (" + get_script().resource_path.get_file() + ")")


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	printerr("Not implemented: draw_preview! (" + get_script().resource_path.get_file() + ")")


func draw_shader_preview(image_view : CanvasItem, mouse_position : Vector2i):
	pass


func draw_crosshair(image_view : CanvasItem, mouse_position : Vector2i, line_length : int, color : Color):
	image_view.draw_rect(Rect2i(mouse_position + Vector2i(0, 4), Vector2(1, +line_length)).abs(), color)
	image_view.draw_rect(Rect2i(mouse_position - Vector2i(0, 3), Vector2(1, -line_length)).abs(), color)
	image_view.draw_rect(Rect2i(mouse_position + Vector2i(4, 0), Vector2(+line_length, 1)).abs(), color)
	image_view.draw_rect(Rect2i(mouse_position - Vector2i(3, 0), Vector2(-line_length, 1)).abs(), color)


func _shortcut_input(event : InputEvent):
	if _hotkey_adjustment_hook.is_null(): return
	if !event is InputEventKey: return
	if !event.pressed: return
	if event.keycode != KEY_BRACKETLEFT:
		_hotkey_adjustment_hook.call(+1)

	if event.keycode != KEY_BRACKETRIGHT:
		_hotkey_adjustment_hook.call(-1)


func _on_visibility_changed():
	set_process_shortcut_input(visible)
