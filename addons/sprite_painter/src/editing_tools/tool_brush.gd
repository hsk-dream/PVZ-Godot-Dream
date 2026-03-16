@tool
extends EditingTool

enum {
  BRUSH_DRAW,
  BRUSH_ERASE,
  BRUSH_CLONE,
  BRUSH_SHADING,
  BRUSH_NORMALMAP,
}

@export_enum("Draw", "Erase", "Clone", "Shading", "Normal Map") var brush_type := 0
@export var chunk_size := Vector2i(256, 256)
@export var max_brush_size := 150
@export var max_brush_min_size := 150
@export var crosshair_color := Color(0.5, 0.5, 0.5, 0.75)

var brushsize := 5
var brushminsize := 5
var brush_offset := Vector2(0.5, 0.5)
var hardness := 1.0
var opacity := 1.0
var pen_flags := [true, false, false]

var drawing := false
var drawing_color1 := Color()
var drawing_color2 := Color()
var last_edits_chunks := {}
var last_edits_textures := {}
var last_affected_rect := Rect2i()


func _ready():
	add_name()
	start_property_grid()
	add_property("Size", brushsize,
		func (x):
			brushsize = x
			brush_offset = Vector2(0.5, 0.5) * float(int(x) % 2),
		TOOL_PROP_INT,
		[1, max_brush_size],
		true
	)
	add_property("Min Size", brushminsize,
		func (x):
		brushminsize = x,
		TOOL_PROP_INT,
		[1, max_brush_min_size],
		true
	)
	add_property("Hardness", hardness * 100,
		func (x): hardness = x * 0.01,
		TOOL_PROP_INT,
		[0, 100]
	)
	add_property("Strength", opacity * 100,
		func (x): opacity = x * 0.01,
		TOOL_PROP_INT,
		[0, 100]
	)

	var pressure_options := {
		"ToolScale" : "Size",
		"Gradient" : "Opacity",
	}
	if brush_type == BRUSH_DRAW:
		pressure_options["CanvasItemMaterial"] = "Tint"

	add_property("Pen Pressure", pen_flags,
		func (x): pen_flags = x,
		TOOL_PROP_ICON_FLAGS,
		pressure_options
	)


func mouse_pressed(
	event : InputEventMouseButton,
	image : Image,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	drawing = event.pressed
	drawing_color1 = color1
	drawing_color2 = color2
	if drawing:
		start_drawing(image, event.position)

	else:
		match brush_type:
			BRUSH_ERASE:
				apply_eraser(image)

			_:
				apply_brush(image)


func start_drawing(image, start_pos):
	last_edits_chunks.clear()
	# Break the image up into tiles - small images are faster to edit.
	for i in ceil(float(image.get_width()) / chunk_size.x):
		for j in ceil(float(image.get_height()) / chunk_size.y):
			last_edits_chunks[Vector2i(i, j) * chunk_size] = Image.create(
				chunk_size.x, chunk_size.y,
				false, image.get_format()
			)
	for k in last_edits_chunks:
		last_edits_textures[k] = ImageTexture.create_from_image(last_edits_chunks[k])
		# Copy the image to the tiles. Worse opacity handling,
		# but with more work can make eraser editing more performant and previewable.
		# last_edits_chunks[k].blit_rect(image, Rect2i(k, chunk_size), Vector2i.ZERO)

	last_affected_rect = Rect2i(start_pos, Vector2i.ZERO)


func apply_brush(image):
	for k in last_edits_chunks:
		image.blend_rect(
			last_edits_chunks[k],
			Rect2i(Vector2i.ZERO, chunk_size),
			k
		)


func apply_eraser(image):
	# Cutting off a smaller image does not increase performance.
	# Must find another way - erasing is very slow.
#	var new_image = Image.create(last_affected_rect.size.x + 1, last_affected_rect.size.y + 1, false, image.get_format())
#	new_image.blit_rect(new_image, last_affected_rect, Vector2i.ZERO)
	var pos : Vector2i
	for k in last_edits_chunks:
		var chunk = last_edits_chunks[k]
		var height = mini(image.get_height() - k.y, chunk.get_height())
		for i in mini(image.get_width() - k.x, chunk.get_width()):
			for j in height:
#				pos = k - last_affected_rect.position + Vector2i(i, j)
				pos = Vector2i(i + k.x, j + k.y)
				chunk.set_pixel(
					i, j,
					image.get_pixelv(pos) - chunk.get_pixel(i, j)
				)
		image.blit_rect(last_edits_chunks[k], Rect2i(Vector2i.ZERO, chunk_size), k)


func get_affected_rect():
	return last_affected_rect.grow_individual(0, 0, 1, 1)


func mouse_moved(event : InputEventMouseMotion):
	if !drawing: return
	if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0.0:
		stroke(event.position, event.position - event.relative, event.pressure)

	else:
		stroke(event.position, event.position - event.relative, 1.0)


func stroke(stroke_start : Vector2, stroke_end : Vector2, pressure : float):
	var rect = Rect2i(stroke_start, Vector2.ZERO)\
		.expand(stroke_end)\
		.grow(brushsize * 0.5 + 1)
	rect = Rect2i(rect.position / chunk_size, rect.end / chunk_size)
	var key : Vector2i
	var keyf : Vector2
	for i in rect.size.x + 1:
		for j in rect.size.y + 1:
			key = (rect.position + Vector2i(i, j)) * chunk_size
			keyf = Vector2(key)
			if !last_edits_chunks.has(key): continue

			paint(
				last_edits_chunks[key],
				stroke_end - keyf,
				stroke_start - keyf,
				key,
				pressure
			)


func paint(on_image : Image, stroke_start : Vector2, stroke_end : Vector2, chunk_position : Vector2i, pressure : float):
	var unsolid_radius := (brushsize * 0.5) * (1.0 - hardness)
	var radius := lerpf(brushminsize, brushsize, pressure if pen_flags[0] else 1.0) * 0.5
	var solid_radius := radius - unsolid_radius

	var color : Color
	if brush_type == BRUSH_ERASE:
		color = Color.BLACK

	elif pen_flags[2]:
		color = lerp(drawing_color2, drawing_color1, pressure)

	else:
		color = drawing_color1

	color.a *= opacity
	if pen_flags[1]:
		color.a *= pressure

	var new_rect := Rect2i(stroke_start, Vector2i.ZERO)\
		.expand(stroke_end)\
		.grow(radius + 2)\
		.intersection(Rect2i(Vector2i.ZERO, on_image.get_size()))

	if new_rect.size == Vector2i.ZERO:
		return

	last_affected_rect = last_affected_rect\
		.expand(Vector2i(new_rect.position) + chunk_position)\
		.expand(Vector2i(new_rect.end) + chunk_position)

	stroke_start = stroke_start.floor() + Vector2(0.5, 0.5)
	stroke_end = stroke_end.floor() + Vector2(0.5, 0.5)
	var cur_pos
	for i in new_rect.size.x:
		for j in new_rect.size.y:
			cur_pos = new_rect.position + Vector2i(i, j)
			if is_out_of_bounds(cur_pos + chunk_position, selection.get_size()):
				continue

			if !selection.get_bitv(cur_pos + chunk_position):
				continue

			on_image.set_pixelv(cur_pos, get_new_pixel(
				on_image, color,
				stroke_start, stroke_end, Vector2(cur_pos) + brush_offset,
				radius, solid_radius
			))


func get_new_pixel(on_image : Image, color : Color, stroke_start : Vector2, stroke_end : Vector2, cur_pos : Vector2, radius : float, solid_radius : float):
	var old_color = on_image.get_pixelv(cur_pos)
	var distance = Geometry2D.get_closest_point_to_segment(
		cur_pos, stroke_start, stroke_end
	).distance_to(cur_pos)

	if distance <= solid_radius:
		var blended = old_color.blend(color)
		blended.a = max(old_color.a, color.a)
		return blended

	elif distance <= radius:
		var blended := old_color.blend(color)
		distance = (distance - solid_radius) / (radius - solid_radius)
#		Possible better handling of variable pressure,
#		but creates artifacts when zig-zagging
		blended.a = max(old_color.a, color.a * (1.0 - distance * distance))
#		This one also creates artifacts, but this is during normal brush usage.
#		blended.a = lerp(old_color.a, color.a, (1.0 - distance * distance))
		return blended

	else:
		return old_color


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if drawing:
		for k in last_edits_chunks:
			last_edits_textures[k].update(last_edits_chunks[k])
			image_view.draw_texture(last_edits_textures[k], k)

	var circle_center = Vector2(mouse_position + Vector2i.ONE) - brush_offset
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 0.1, PI * 0.9, 32, crosshair_color, 1.0)
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 1.1, PI * 1.9, 32, crosshair_color, 1.0)
	# With region set to (0, 0, 0, 0), hides the image.
	# image_view.region_enabled = drawing
