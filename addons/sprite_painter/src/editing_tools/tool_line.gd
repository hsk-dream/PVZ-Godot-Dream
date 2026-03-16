@tool
extends "./tool_shape.gd"


func _ready():
	add_name()
	start_property_grid()
	add_property("Width", line_width,
		func (x): line_width = x,
		TOOL_PROP_INT,
		[0, 250]
	)
	add_property("Flags", [erase_mode, aa],
		func (x):
			print(x)
			erase_mode = x[0]
			aa = x[1],
		TOOL_PROP_ICON_FLAGS,
		{"Eraser" : "Erase Mode", "CurveTexture" : "Anti-Aliasing"}
	)


func mouse_moved(event : InputEventMouseMotion):
	if !drawing: return
	if Input.is_key_pressed(KEY_SHIFT):
		var angle_rounded = snappedf((Vector2(start_pos)).angle_to_point(event.position), PI * 0.25)
		var distance = (event.position - Vector2(start_pos)).length()
		end_pos = (Vector2(start_pos) + Vector2(
			distance * cos(angle_rounded),
			distance * sin(angle_rounded)
		)).round()

	else:
		end_pos = event.position.floor()


func get_affected_rect():
	return super.get_affected_rect().grow(line_width)


func update_preview_cheddar():
	var rect = super.get_affected_rect()
	preview_shader.set_shader_parameter("color", color_line if !erase_mode else Color.BLACK.blend(color_line));
	preview_shader.set_shader_parameter("origin", Vector2(start_pos) + Vector2(0.5, 0.5));
	preview_shader.set_shader_parameter("width", line_width);
	preview_shader.set_shader_parameter("enable_aa", aa);

	if end_pos == start_pos: return  # The SDF for this case evaluates to being inside; abort
	preview_shader.set_shader_parameter("delta", end_pos - start_pos);
