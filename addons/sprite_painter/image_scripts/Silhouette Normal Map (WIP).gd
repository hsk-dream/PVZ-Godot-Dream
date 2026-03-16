extends ImageScript

const ROOT2DIV2 = 0.7071


func _get_param_list():
	var default_curve = Curve.new()
	default_curve.add_point(Vector2(0.0, 0.5), 1, 1, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	default_curve.add_point(Vector2(1.0, 0.5), 1, 1, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	return [
		[
			"Bevel",
			SCRIPT_PARAM_INT,
			1,
			[1, 150]
		],
		[
			"Bevel Distance",
			SCRIPT_PARAM_ENUM,
			0,
			["Circle", "Square", "Diamond"]
		],
	]


func _get_image(new_image, selection):
	var image_size : Vector2i = new_image.get_size()
	var closest_edge : Array[Vector2] = []
	var entropy := {}
	closest_edge.resize(image_size.x * image_size.y)

	var pix : Color
	var vec : Vector2
	for i in image_size.x:
		for j in image_size.y:
			pix = new_image.get_pixel(i, j)
			if pix.a == 0.0:
				closest_edge[i + j * image_size.x] = Vector2.ZERO

			else:
				vec = Vector2(0, 0)
				if i == 0: vec.x -= 1
				if j == 0: vec.y -= 1
				if i == image_size.x - 1: vec.x += 1
				if j == image_size.y - 1: vec.y += 1

				if vec == Vector2.ZERO:
					vec = Vector2(-INF, -INF)
					entropy[Vector2(i, j)] = 5

				closest_edge[i + j * image_size.x] = vec

	var neighbors = []
	var neighbor_pos = []
	var iters = 0
	var closest_edge_new : Array[Vector2]
	while entropy.size() > 0:
		iters += 1
		closest_edge_new = closest_edge.duplicate()
		for pos in entropy.keys():
			neighbor_pos = [
				pos + Vector2.RIGHT,
				pos + Vector2.DOWN,
				pos + Vector2.LEFT,
				pos + Vector2.UP,
			]
			var any_neighbor_defined = false
			for x in neighbor_pos:
				if closest_edge[x.x + x.y * image_size.x] != Vector2(-INF, -INF):
					any_neighbor_defined = true
					break

			if any_neighbor_defined:
				entropy.erase(pos)

			neighbors = [
				closest_edge[pos.x + 1 + pos.y * image_size.x]
					if !entropy.has(pos + Vector2.RIGHT) else Vector2(-INF, -INF),
				closest_edge[pos.x + (pos.y + 1) * image_size.x]
					if !entropy.has(pos + Vector2.DOWN) else Vector2(-INF, -INF),
				closest_edge[pos.x - 1 + pos.y * image_size.x]
					if !entropy.has(pos + Vector2.LEFT) else Vector2(-INF, -INF),
				closest_edge[pos.x + (pos.y - 1) * image_size.x]
					if !entropy.has(pos + Vector2.UP) else Vector2(-INF, -INF),
			]
			closest_edge_new[pos.x + pos.y * image_size.x] = get_closest_edge(neighbors)

		closest_edge = closest_edge_new

	var bevel = get_param("Bevel")
	var dist_func = [
		# Three different distance calculations have their own artifacts..
		func (x): return x.length_squared() > bevel * 2.0,  # Circle
		func (x): return max(abs(x.x), abs(x.y)) > bevel,  # Square
		func (x): return abs(x.x) + abs(x.y) > bevel * 2.0,  # Diamond
	][get_param("Bevel Distance")]

	var vec3 : Vector3
	var vec_len : float
	var vec_dir : Vector2
	for i in image_size.x:
		for j in image_size.y:
			vec = closest_edge[i + j * image_size.x]
			if vec == Vector2.ZERO || dist_func.call(vec):
				new_image.set_pixel(i, j, Color(0.5, 0.5, 1.0))
				continue

			vec_len = vec.length()
			vec_dir = vec / vec_len
			vec3 = Vector3.BACK.rotated(
				Vector3(-vec_dir.y, vec_dir.x, 0.0),
				PI * 0.25
			)
			vec3 = vec3 * Vector3(0.5, -0.5, 1.0) + Vector3(0.5, 0.5, 0.0)

			new_image.set_pixel(i, j, Color(vec3.x, vec3.y, vec3.z))

	return new_image


func get_closest_edge(neighbor_vecs):
	var lengths = [
		neighbor_vecs[0].length_squared(),
		neighbor_vecs[1].length_squared(),
		neighbor_vecs[2].length_squared(),
		neighbor_vecs[3].length_squared(),
	]
	var closest_length = INF
	for i in 4:
		if lengths[i] < closest_length:
			closest_length = lengths[i]

	var result = Vector2.ZERO
	var neighbor_dirs = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	var coeff = 1.0
	for i in 4:
		if lengths[i] == closest_length:
			result += neighbor_vecs[i] + neighbor_dirs[i]

	return result
