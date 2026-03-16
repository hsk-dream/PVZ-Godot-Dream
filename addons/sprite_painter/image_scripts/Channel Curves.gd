extends ImageScript


func _get_param_list():
	var default_curve = Curve.new()
	default_curve.add_point(Vector2.ZERO, 1, 1)
	default_curve.add_point(Vector2.ONE, 1, 1)
	return [
		[
			"Red",
			SCRIPT_PARAM_RESOURCE,
			default_curve.duplicate(),
			"Curve",
		],
		[
			"Green",
			SCRIPT_PARAM_RESOURCE,
			default_curve.duplicate(),
			"Curve",
		],
		[
			"Blue",
			SCRIPT_PARAM_RESOURCE,
			default_curve.duplicate(),
			"Curve",
		],
		[
			"Alpha",
			SCRIPT_PARAM_RESOURCE,
			default_curve.duplicate(),
			"Curve",
		],
	]


func _get_image(new_image, selection):
	var r_curve = get_param("Red")
	var g_curve = get_param("Green")
	var b_curve = get_param("Blue")
	var a_curve = get_param("Alpha")
	var pix : Color
	for i in new_image.get_width():
		for j in new_image.get_width():
			if !selection.get_bit(i, j): continue
			pix = new_image.get_pixel(i, j)
			pix.r = r_curve.sample(pix.r)
			pix.g = g_curve.sample(pix.g)
			pix.b = b_curve.sample(pix.b)
			pix.a = a_curve.sample(pix.a)
			new_image.set_pixel(i, j, pix)

	return new_image
