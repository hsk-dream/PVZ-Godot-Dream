@tool
extends "res://addons/sprite_painter/src/editing_tools/tool_brush.gd"

var fill_mode := 0
var tolerance := 0.0

var allowed_pixels = BitMap.new()
var image_size := Vector2i()


func _ready():
	super._ready()
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
	image_size = image.get_size()
	if event.pressed:
		allowed_pixels.create(image.get_size())
		ImageFillTools.fill_on_image(
			image, allowed_pixels, event.position,
			tolerance, fill_mode == 0, selection
		)

	super.mouse_pressed(event, image, color1, color2)


func get_new_pixel(on_image : Image, color : Color, stroke_start : Vector2, stroke_end : Vector2, cur_pos : Vector2, radius : float, solid_radius : float):
	if !allowed_pixels.get_bitv(cur_pos):
		return on_image.get_pixelv(cur_pos)

	return super.get_new_pixel(on_image, color, stroke_start, stroke_end, cur_pos, radius, solid_radius)
