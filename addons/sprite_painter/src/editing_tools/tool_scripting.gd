@tool
extends EditingTool

@export var workspace : NodePath

var live_update := true

var timer : Timer
var param_grid : Control
var script_instance : ImageScript
var original_image : Image
var result_image_tex : ImageTexture


func _ready():
	add_name()
	var button = add_property("Script",
		"",
		load_script,
		TOOL_PROP_FOLDER_SCAN,
		"res://addons/sprite_painter/image_scripts"
	)
	button.text = "Choose script...                   "
	button.fit_to_longest_item = false
	param_grid = start_property_grid()
	add_separator()
	add_property("Live Update",
		live_update,
		func(x):
			live_update = x
			if x: update_script(true),
		TOOL_PROP_BOOL
	)

	var buttons = add_button_panel(["Apply", "Reset"]).get_children()
	buttons[0].pressed.connect(func():
		var ws = get_node(workspace)
		var old_image = ws.edited_image
		ws.replace_image(old_image, result_image_tex.get_image())
		ws.image_replaced.emit(old_image, ws.edited_image)
	)
	buttons[1].pressed.connect(func(): load_script(script_instance.get_script()))

	# Updates are expensive if images are changed on the CPU.
	# Update only sometimes to reduce lag
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)


func load_script(script : Script):
	script_instance = script.new()
	param_grid.free()
	param_grid = start_property_grid()
	param_grid.get_parent().move_child(param_grid, 3)
	param_grid.get_parent().get_child(2).hide()

	for x in script_instance._get_param_list():
		add_property(
			x[0],  # Name
			x[2],  # Value
			func(y):
				script_instance._params[x[0]] = y
				update_script()
				if y is Resource && !y.changed.is_connected(update_script):
					y.changed.connect(update_script),
			x[1],  # Type
			x[3] if x.size() > 3 else null  # Hint (if any)
		)
		script_instance._params[x[0]] = x[2]
		if x[2] is Resource && !x[2].changed.is_connected(update_script):
			x[2].changed.connect(update_script)

	script_instance._ready(original_image)
	update_script()


func update_script(automatic : bool = false):
	if !live_update: return
	if timer.time_left != 0.0: return

	var new_image = Image.create_from_data(
		original_image.get_width(),
		original_image.get_height(),
		false,
		original_image.get_format(),
		original_image.get_data()
	)
	result_image_tex = ImageTexture.create_from_image(
		script_instance._get_image(new_image, selection)
	)
	if !automatic:
		timer.start()


func mouse_pressed(
	event : InputEventMouseButton,
	image : Image,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	original_image = image


func get_affected_rect() -> Rect2i:
	return Rect2i()


func mouse_moved(event : InputEventMouseMotion):
	original_image = get_node(workspace).edited_image


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	pass


func draw_shader_preview(image_view : CanvasItem, mouse_position : Vector2i):
	image_view.texture = result_image_tex


func _on_visibility_changed():
	super._on_visibility_changed()
	if is_visible_in_tree() && script_instance != null:
		script_instance._ready(original_image)
		update_script(true)


func _on_timer_timeout():
	update_script(true)


func _on_workspace_image_replaced(old_image, new_image):
	original_image = new_image
	if is_visible_in_tree() && script_instance != null:
		script_instance._ready(original_image)
		update_script(true)
