extends AttackComponentBulletBase
class_name AttackComponentBulletThreePea
## 三线射手攻击组件


## 边路补偿(0：正常，1：上路补偿，-1：下路补偿)
var bullet_border_compensation := 0

## 攻击检测射线区域
var attack_ray_coll_shape:Array[CollisionShape2D]

## 初始化三线射手攻击组件
func _ready() -> void:
	super()
	for area:Area2D in detect_component.get_children():
		attack_ray_coll_shape.append(area.get_child(0))
	if is_instance_valid(Global.main_game):
		_init_attack_component_bullet_three_pea(owner.row_col)


func _init_attack_component_bullet_three_pea(row_col:Vector2i):
	_judge_position_bullet_position(row_col)


func _shoot_bullet():
	for i in range(3):
		## 边路补偿补偿
		if (bullet_border_compensation == 1 and i == 0) or (bullet_border_compensation == -1 and i == 2):
			_create_bullte(0.3, 1)

		else:
			_create_bullte(0, i, true)

	## 攻击音效
	SoundManager.play_character_SFX(&"Throw")

func _create_bullte(await_time:float, i:int=1, change_y_target:bool=false):
	if await_time:
		await get_tree().create_timer(await_time).timeout
	var bullet:Bullet000Base = Global.bullet_registry.get_bullet_scenes(attack_bullet_type).instantiate()

	## 有偏移的为正常发射的子弹
	if change_y_target:
		bullet.global_position = markers_2d_bullet[0].global_position
		var bullet_paras:Dictionary = {
			Bullet000Base.E_InitParasAttr.BulletLane : owner.row_col.x + i -1,
			Bullet000Base.E_InitParasAttr.Position :  bullets.to_local(markers_2d_bullet[0].global_position),
		}
		bullet.init_bullet(bullet_paras)
		bullets.add_child(bullet)
		bullet.change_y(markers_2d_bullet[0].global_position.y + (i-1) * 100)
	## 没有偏移的为边路补偿子弹
	else:
		bullet.global_position = markers_2d_bullet[0].global_position
		var bullet_paras :Dictionary= {
			Bullet000Base.E_InitParasAttr.BulletLane : owner.row_col.x,
			Bullet000Base.E_InitParasAttr.Position :  bullets.to_local(markers_2d_bullet[0].global_position),
		}
		bullet.init_bullet(bullet_paras)
		bullets.add_child(bullet)

	bullet.global_position = markers_2d_bullet[0].global_position


## 初始化时根据位置决定子弹偏移：边路补偿
func _judge_position_bullet_position(row_col:Vector2i):
	if row_col.x == 0:
		bullet_border_compensation = 1
	elif row_col.x == Global.main_game.plant_cell_manager.row_col.x - 1:
		bullet_border_compensation = -1
	else:
		bullet_border_compensation = 0
