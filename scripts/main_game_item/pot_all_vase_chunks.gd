extends Node2D
class_name PotAllVaseChunks

@onready var vase_chunks: PotVaseChunkDrop = $VaseChunks

## 根据罐子类型更新罐子外表
func update_pot_vase_chunks_appearance(curr_pot_type:EnumsItem.E_PotType):
	vase_chunks.frame_coords.y = int(curr_pot_type)
	vase_chunks.frame_coords.y = int(curr_pot_type)

func activate_it():
	reparent(owner.plant_cell)
	visible = true
	# 让它从当前按钮位置开始掉落
	random_init_vase(vase_chunks)
	for i in range(randi_range(8,12)):
		copy_and_random_init()
	await get_tree().create_timer(5.0).timeout
	queue_free()

func copy_and_random_init():
	var new_vase_chunks = vase_chunks.duplicate()
	add_child(new_vase_chunks)
	random_init_vase(new_vase_chunks)

func random_init_vase(curr_vase_chunks:PotVaseChunkDrop):
	# 让它从当前按钮位置开始掉落
	curr_vase_chunks.x_velocity = randf_range(-30, 30)    # 随机水平速度
	curr_vase_chunks.rotation_speed = randf_range(-5, 5)   # 随机旋转
	curr_vase_chunks.activate_drop()
	curr_vase_chunks.position += Vector2(randf_range(-15, 15), randf_range(-10,10))
	curr_vase_chunks.rotation_degrees += randf_range(0, 360)
	curr_vase_chunks.frame_coords.x = randi_range(0, 8)

