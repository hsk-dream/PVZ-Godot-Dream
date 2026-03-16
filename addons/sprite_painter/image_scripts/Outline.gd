extends ImageScript

var sample_modes = [
	[Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1)],
	range(8).map(func(i):return Vector2(cos(i * PI * 0.25), sin(i * PI * 0.25))),
	range(16).map(func(i):return Vector2(cos(i * PI * 0.125), sin(i * PI * 0.125))),
	# The following modes sample two rings around the pixel,
	# resulting in a more precise thick outline around thin objects
	range(16).map(func(i):return ceil((i + 1) * 0.125) * 0.5 * Vector2(cos(i * PI * 0.25), sin(i * PI * 0.25))),
	range(32).map(func(i):return ceil((i + 1) * 0.0625) * 0.5 * Vector2(cos(i * PI * 0.125), sin(i * PI * 0.125))),
]


func _get_param_list():
	return [
		[
			"Width",
			SCRIPT_PARAM_INT,
			1,
			[1, 150]
		],
		[
			"Color",
			SCRIPT_PARAM_COLOR,
			Color.BLACK
		],
		[
			"Samples",
			SCRIPT_PARAM_ENUM,
			0,
			["4 (Naive)", "8", "16", "4+4 (Wide Line)", "8+8 (Wide Line Ultra)"]
		],
		[
			"Mode",
			SCRIPT_PARAM_ENUM,
			0,
			["Outline + Image", "Just Outline"]
		],
	]


func _get_image(new_image, selection):
	var line_color = get_param("Color")
	var width = get_param("Width")
	var line_only = get_param("Mode") == 1
	var samples = sample_modes[get_param("Samples")]
	var image_size = new_image.get_size()
	var new_new_image = Image.create_from_data(
		image_size.x,
		image_size.y,
		false,
		new_image.get_format(),
		new_image.get_data()
	)
	var pix : Color
	var pix_outline_alpha := 0.0
	for i in new_image.get_width():
		for j in new_image.get_height():
			if !selection.get_bit(i, j): continue
			pix = new_image.get_pixel(i, j)
			if pix.a == 1.0:
				if line_only:
					new_new_image.set_pixel(i, j, Color.TRANSPARENT)

				continue

			pix_outline_alpha = 0.0
			for x in samples:
				if pix_outline_alpha >= line_color.a: break
				if ImageFillTools.is_out_of_bounds(Vector2(i, j) + x * width, image_size):
					continue

				pix_outline_alpha = max(pix_outline_alpha, min(
					line_color.a,
					new_image.get_pixelv(Vector2(i, j) + x * width).a
				))

			if pix_outline_alpha > 0.0:
				if line_only:
					pix = Color(line_color, pix_outline_alpha)

				else:
					pix = Color(line_color, pix_outline_alpha).blend(pix)

			new_new_image.set_pixel(i, j, pix)

	return new_new_image
