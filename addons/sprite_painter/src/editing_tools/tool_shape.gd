@tool
extends EditingTool

enum {
	SHAPE_RECTANGLE,
	SHAPE_ELLIPSE,
	SHAPE_TRIANGLE,
	SHAPE_DIAMOND,
	SHAPE_HEXAGON,
}

const I_SIN120 = sin(PI * 0.66666)  # Used for making hexagons have equal qdges

@export var crosshair_color := Color(0.5, 0.5, 0.5, 0.75)
@export var crosshair_size := 3
@export var shader_viewport_texture : Texture2D

var shape := 0
var fill_mode := 0
var line_width := 1
var erase_mode := false
var aa := false

var drawing := false
var color_line : Color = Color.BLACK
var color_fill : Color = Color.WHITE
var image_size := Vector2()

var start_pos := Vector2i()
var end_pos := Vector2i()


func _ready():
	var icon_folder = "res://addons/sprite_painter/graphics/"
	add_name()
	start_property_grid()
	add_property("Shape", shape,
		func (x): shape = x,
		TOOL_PROP_ICON_ENUM,
		{
			load(icon_folder + "rect_shape_2d.svg") : "Rectangle",
			load(icon_folder + "circle_shape_2d.svg") : "Ellipse",
			load(icon_folder + "triangle_shape_2d.svg") : "Triangle",
			load(icon_folder + "diamond_shape_2d.svg") : "Diamond",
			load(icon_folder + "hex_shape_2d.svg") : "Hexagon",
		},
		true
	)
	add_property("Fill Color", fill_mode,
		func (x): fill_mode = x,
		TOOL_PROP_ENUM,
		["Primary", "Secondary", "None (outline only)"]
	)
	add_property("Border Width", line_width,
		func (x): line_width = x,
		TOOL_PROP_INT,
		[0, 20]
	)
	add_property("Flags", [erase_mode, aa],
		func (x):
			erase_mode = x[0]
			aa = x[1],
		TOOL_PROP_ICON_FLAGS,
		{"Eraser" : "Erase Mode", "CurveTexture" : "Anti-Aliasing"}
	)


func mouse_pressed(
	event : InputEventMouseButton,
	image : Image,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	drawing = event.pressed
	color_line = color1
	color_fill = [color1, color2, Color.TRANSPARENT][fill_mode]
	image_size = image.get_size()
	if drawing:
		start_pos = Vector2i(event.position)
		end_pos = Vector2i(event.position)

	else:
		var rect = get_affected_rect()
		var new_image = shader_viewport_texture.get_image()
		var cur_pos : Vector2i
		var cur_pixel : Color
		for i in rect.size.x:
			for j in rect.size.y:
				cur_pos = rect.position + Vector2i(i, j)
				if is_out_of_bounds(cur_pos, image_size):
					continue

				cur_pixel = image.get_pixelv(cur_pos)
				if !erase_mode:
					set_image_pixelv(image, cur_pos,
						cur_pixel.blend(new_image.get_pixelv(cur_pos))
					)
				
				else:
					set_image_pixelv(image, cur_pos, Color(
						cur_pixel,
						(cur_pixel.a - new_image.get_pixelv(cur_pos).a)
					))


func get_affected_rect():
	var squarify = Input.is_key_pressed(KEY_SHIFT)
	var rect = get_rect_from_drag(start_pos, end_pos, squarify)
	if shape == SHAPE_HEXAGON && squarify:
		if (start_pos.x < end_pos.x) == (start_pos.y < end_pos.y):
			rect.size.y *= I_SIN120

		else:
			rect.size.x *= I_SIN120

	return rect


func mouse_moved(event : InputEventMouseMotion):
	if !drawing: return
	end_pos = event.position


func update_preview_cheddar():
	var rect = get_affected_rect()
	preview_shader.set_shader_parameter("shape_index", shape);
	preview_shader.set_shader_parameter("color_border", color_line if !erase_mode else Color.BLACK.blend(color_line));
	preview_shader.set_shader_parameter("color_fill", color_fill);
	preview_shader.set_shader_parameter("origin", rect.position);
	preview_shader.set_shader_parameter("shape_size", rect.size);
	preview_shader.set_shader_parameter("border_width", line_width);
	preview_shader.set_shader_parameter("drag_delta", start_pos - end_pos);
	preview_shader.set_shader_parameter("enable_aa", aa);


func draw_shader_preview(image_view : CanvasItem, mouse_position : Vector2i):
	image_view.texture = null
	if !drawing:
		image_view.hide()

	else:
		if image_view.texture == null || image_view.texture.get_size() != image_size:
			image_view.texture = ImageTexture.create_from_image(Image.create(
				image_size.x,
				image_size.y,
				false,
				Image.FORMAT_L8  # Doesn't matter, won't read from it
			))

		update_preview_cheddar()


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if !drawing:
		draw_crosshair(image_view, mouse_position, crosshair_size, crosshair_color)
