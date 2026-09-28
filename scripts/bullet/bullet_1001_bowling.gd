extends BulletLinear000Base
class_name Bullet1001Bowling

## 坚果旋转的表现节点。
@onready var body_correct: Node2D = $Body/BodyCorrect
## 僵王没有普通僵尸的保龄球伤害特判，单独配置并默认沿用无防具目标的 1800 点伤害。
@export_range(0, 10000, 1, "or_greater") var boss_attack_value: int = 1800
## 旋转速度
var rotation_speed = 5.0
## 每行的y坐标
var y_every_lane:Array[float]
## 第一次攻击是否完成
var first_attack_end := false
## 是否在当前行,为 true 时可以攻击
var in_curr_lane := true
## 当前的碰撞敌人,到达当前行后对当前敌人攻击
var curr_enemy :Character000Base


func _ready() -> void:
	super._ready()
	for i_zombie_row_node:ZombieRow in Global.main_game.zombie_manager.all_zombie_rows:
		y_every_lane.append(i_zombie_row_node.zombie_create_position.global_position.y)
	SoundManager.play_bullet_attack_SFX(SoundManager.TypeBulletSFX.Bowling)


func _physics_process(delta: float) -> void:
	super(delta)
	body_correct.rotation += rotation_speed * delta
	## 如果第一次攻击已完成，碰到边缘时
	if first_attack_end:
		## 如果超过第0行
		if global_position.y < y_every_lane[0]:
			lane = 0
			_update_direction()
		## 如果超过第最后一行
		if global_position.y > y_every_lane[-1] + 5:
			lane = y_every_lane.size() - 1
			_update_direction()

	## 如果到达目标行
	if not in_curr_lane and (y_every_lane[lane] - 10 < global_position.y and global_position.y < y_every_lane[lane] + 10):
		# 到达目标行时重新检查目标；死亡或已关闭受击的引用不能阻塞后续碰撞。
		if is_instance_valid(curr_enemy) and _can_attack_character(curr_enemy) \
			and (curr_enemy is ZB000Base or lane == curr_enemy.lane):
			_hit_and_bounce(curr_enemy)
		else:
			curr_enemy = null
			in_curr_lane = true

	## 移动离开当前行后，更新当前
	if in_curr_lane and (y_every_lane[lane] - 10 > global_position.y or global_position.y > y_every_lane[lane] + 10):
		in_curr_lane = false	# 修改当前行
		update_z_index_and_lane(lane, int(lane + direction.y))


## 更新图层
@warning_ignore("unused_parameter")
func update_z_index_and_lane(curr_lane:int, target_lane:int):
	lane = target_lane
	z_index = 50 * lane + 45

## 更新保龄球移动方向
func _update_direction():
	if lane == 0:
		direction.y = 1
	elif lane == y_every_lane.size() - 1:
		direction.y = -1
	else:
		if direction.y == 0:
			direction.y = 1 if randf() > 0.5 else -1
		else:
			direction.y *= -1

	update_z_index_and_lane(lane, int(lane + direction.y))

## [param area] 与坚果重叠的区域；僵王按空间命中，普通僵尸继续等待坚果到达对应行。
func _on_area_2d_attack_area_entered(area: Area2D) -> void:
	# 过滤地形和其他非角色，不再把僵王强制当作普通僵尸。
	var enemy := area.owner as Character000Base
	if not _can_attack_character(enemy, false):
		return
	if enemy is ZB000Base:
		_hit_and_bounce(enemy)
	elif in_curr_lane:
		if lane == enemy.lane:
			_hit_and_bounce(enemy)
	else:
		curr_enemy = enemy


## [param enemy] 准备命中的目标；同一坚果对同一僵王只扣血和改变方向一次。
func _hit_and_bounce(enemy: Character000Base) -> void:
	if is_queued_for_deletion() or not _can_attack_character(enemy):
		return
	if enemy is ZB000Base and _hit_boss_ids.has(enemy.get_instance_id()):
		return
	in_curr_lane = false
	curr_enemy = null
	attack_once(enemy)
	_update_direction()
	first_attack_end = true
	bullet_mode = BulletRegistry.AttackMode.BowlingSide

## [param enemy] 基类确认的命中目标；僵王使用独立伤害，普通僵尸仍使用原有正面与侧面保龄球规则。
func _attack_enemy(enemy: Character000Base):
	if enemy is ZB000Base:
		enemy.be_attacked_bullet(boss_attack_value, BulletRegistry.AttackMode.Penetration, true, trigger_be_attack_sfx)
	else:
		super(enemy)


## 子弹离开当前敌人
func _on_area_2d_attack_area_exited(area: Area2D) -> void:
	if curr_enemy == area.owner:
		curr_enemy = null
