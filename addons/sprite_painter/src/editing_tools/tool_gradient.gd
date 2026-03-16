@tool
extends EditingTool

enum {
	GRADIENT_LINEAR,
	GRADIENT_LINEAR_MIRRORED,
	GRADIENT_RADIAL,
	GRADIENT_CONIC,
	GRADIENT_BOUNDING_BOX,
}

@export var line_color = Color.GRAY
@export var line_aligned_color = Color.GREEN
@export var point_grab_area = Vector2(5, 5)
@export var point_grab_color = Color.GRAY
@export var shader_preview : NodePath
@export var shader_viewport_texture : Texture2D

var gradient_type := 0
var fill_mode := 0
var tolerance := 1.0

var drawing := false
var default_gradient := Gradient.new()
var custom_gradient : Gradient = null
var default_color2 := Color.TRANSPARENT

var affected_pixels := BitMap.new()
var affected_pixels_tex : ImageTexture
var points := [Vector2(-INF, -INF), Vector2(-INF, -INF)]
var point_grabbed := -1
var last_affected_rect := Rect2i()


func _ready():
	default_gradient.add_point(1.0, Color.WHITE)

	add_name()
	start_property_grid()
	add_property("Type", gradient_type,
		func (x): gradient_type = x,
		TOOL_PROP_ICON_ENUM,
		{
			"Line": "Linear",
			"Hsize": "Linear Mirrored",
			"Node": "Radial",
			"ToolRotate": "Conic",
			"Groups": "Bounding Box",
		},
		true
	)
	add_property("Gradient", custom_gradient,
		func (x): custom_gradient = x,
		TOOL_PROP_RESOURCE,
		["Gradient"]
	)
	add_property("Fill Mode", fill_mode,
		func (x): fill_mode = x,
		TOOL_PROP_ENUM,
		[&"Contiguous", &"Global"]
	)
	add_property("Tolerance", tolerance * 100,
		func (x): tolerance = x * 0.01,
		TOOL_PROP_INT,
		[0, 100]
	)


func mouse_pressed(
	event : InputEventMouseButton,
	image : Image,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	drawing = event.pressed
	default_gradient.set_color(0, color1)
	default_gradient.set_color(1, color2)
	var cur_color := image.get_pixelv(event.position)
	if drawing:
		if try_grab_point(event):
			return

		if is_out_of_bounds(event.position, image.get_size()):
			affected_pixels.create(affected_pixels.get_size())
			return

		points[0] = event.position.floor()
		points[1] = event.position.floor()
		affected_pixels.create(image.get_size())
		fill(event.position, image)
		var mask = affected_pixels.convert_to_image()
		mask.clear_mipmaps()
		affected_pixels_tex = ImageTexture.create_from_image(mask)
		update_preview_shader()
		point_grabbed = 1

	else:
		point_grabbed = -1
		if points[0] == points[1]:
			points[0] = Vector2(-INF, -INF)
			points[1] = Vector2(-INF, -INF)
			return

		var result_image = shader_viewport_texture.get_image()
		for i in result_image.get_width():
			for j in result_image.get_height():
				if affected_pixels.get_bit(i, j):
					set_image_pixel(image, i, j, result_image.get_pixel(i, j))


func try_grab_point(event : InputEventMouse) -> bool:
	for i in points.size():
		if Rect2(points[i] - point_grab_area * 0.5, point_grab_area).has_point(event.position):
			point_grabbed = i
			return true

	return false


func get_affected_rect():
	return last_affected_rect.grow_individual(0, 0, 1, 1)


func mouse_moved(event : InputEventMouseMotion):
	if point_grabbed == -1: return

	if Input.is_key_pressed(KEY_SHIFT):
		var origin = points[1 - point_grabbed]
		var angle_rounded = snappedf(origin.angle_to_point(event.position), PI * 0.25)
		var distance = (event.position - origin).length()
		points[point_grabbed] = (origin + Vector2(
			distance * cos(angle_rounded),
			distance * sin(angle_rounded)
		)).floor()

	else:
		points[point_grabbed] = event.position.floor()

	update_preview_shader()


func update_preview_shader():
	var preview_node = get_node(shader_preview)
	var g_tex = preview_node.material.get_shader_parameter("gradient")
	g_tex.gradient = default_gradient if custom_gradient == null else custom_gradient
	preview_node.texture = affected_pixels_tex
	preview_shader.set_shader_parameter("gradient", g_tex)
	preview_shader.set_shader_parameter("type", gradient_type)
	preview_shader.set_shader_parameter("from", points[0] / Vector2(affected_pixels.get_size()))
	preview_shader.set_shader_parameter("delta", (points[1] - points[0]) / Vector2(affected_pixels.get_size()))


func fill(start_pos : Vector2, image : Image):
	last_affected_rect = ImageFillTools.fill_on_image(
		image,
		affected_pixels,
		start_pos,
		tolerance,
		(fill_mode == 0) != Input.is_key_pressed(KEY_SHIFT),
		selection
	)


func draw_shader_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if points[0] == Vector2(-INF, -INF):
		image_view.hide()
		return

	image_view.texture = affected_pixels_tex


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if points[0] == Vector2(-INF, -INF):
		return

	for i in points.size():
		image_view.draw_line(points[0], points[1], line_color, 1.1)
		image_view.draw_rect(
			Rect2(points[i] - point_grab_area * 0.5, point_grab_area),
			point_grab_color, false, 2
		)


func _on_visibility_changed():
	points = [Vector2(-INF, -INF), Vector2(-INF, -INF)]
	super._on_visibility_changed()
