@tool
extends Node2D

@export var grid_color := Color.WHITE
@export var grid_line_width := 1.0
@export var region_color := Color.WHITE
@export var region_line_width := 1.0
@export var region_outer_color := Color.BLACK

var image_size := Vector2i()
var grid_size := Vector2i()
var grid_offset := Vector2i()
var is_region := false


func _draw():
	if grid_size == Vector2i.ZERO: return
	if is_region:
		draw_rect(Rect2(
			Vector2.ZERO, 
			Vector2(image_size.x, grid_offset.y)
		), region_outer_color)
		draw_rect(Rect2(
			Vector2(0, grid_offset.y), 
			Vector2(grid_offset.x, grid_size.y)
		), region_outer_color)
		draw_rect(Rect2(
			Vector2(grid_offset.x + grid_size.x, grid_offset.y), 
			Vector2(image_size.x - grid_offset.x - grid_size.x, grid_size.y)
		), region_outer_color)
		draw_rect(Rect2(
			Vector2(0, grid_offset.y + grid_size.y),
			Vector2(image_size.x, image_size.y - grid_offset.y - grid_size.y)
		), region_outer_color)

		draw_rect(Rect2(
			grid_offset + Vector2i(-region_line_width, -region_line_width),
			Vector2(grid_size.x + region_line_width * 2, region_line_width)
		), region_color)
		draw_rect(Rect2(
			grid_offset + Vector2i(-region_line_width, 0),
			Vector2(region_line_width, grid_size.y)
		), region_color)
		draw_rect(Rect2(
			grid_offset + Vector2i(grid_size.x, 0),
			Vector2(region_line_width, grid_size.y)
		), region_color)
		draw_rect(Rect2(
			grid_offset + Vector2i(-region_line_width, grid_size.y),
			Vector2(grid_size.x + region_line_width * 2, region_line_width)
		), region_color)

		return

	var lines = []
	var line_count = Vector2i(
		float(image_size.x - grid_offset.x % grid_size.x) / grid_size.x,
		float(image_size.y - grid_offset.y % grid_size.y) / grid_size.y
	)
	lines.resize(line_count.x * 2)
	for i in line_count.x:
		lines[i * 2] = Vector2((i + 1) * grid_size.x + grid_offset.x, 0)
		lines[i * 2 + 1] = lines[i * 2] + Vector2(0, image_size.y)

	draw_multiline(lines, grid_color, grid_line_width)
	
	lines.resize(line_count.y * 2)
	for i in line_count.y:
		lines[i * 2] = Vector2(0, (i + 1) * grid_size.y + grid_offset.y)
		lines[i * 2 + 1] = lines[i * 2] + Vector2(image_size.x, 0)

	draw_multiline(lines, grid_color, grid_line_width)
