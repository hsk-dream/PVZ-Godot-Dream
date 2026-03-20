extends Node
class_name JacksonManager


@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 当前管理器持有僵尸
var curr_master_id := -1
## 初始动画
var current_animation = "armraise"
## 动画的次数，前4次举手，后两次walk，6次一循环
var time_anim :int = 0
## 当前朝向
var curr_scale = Vector2(1, 1)
## 当前管理器的僵尸-1为舞王
var zombie_dancers: Dictionary = {
	-1:null,
	0:null,
	1:null,
	2:null,
	3:null
}
## 是否为正常norm状态（walk、raise）,决定僵尸能否移动
var zombie_dancers_is_norm: Dictionary = {-1:true, 0:true, 1:true, 2:true, 3:true}
## 速度系数
var zombie_dancers_speed_factor_product: Dictionary[int, float]
## 原始动画播放速度
var animation_origin_speed :float
## 初始化随机速度
var init_random_speed :float
## 当前动画播放速度
var animation_curr_speed :float

## 需要召唤舞王的次数，第二次可以召唤,不然召唤太频繁
var time_need_call_zombie := 0
## 是否被魅惑，若被魅惑，舞王召唤魅惑伴舞
var is_hypnotized := false

func _ready() -> void:
	animation_player.set_blend_time('armraise', 'walk', 0.2)

## 开始动画
func start_anim() -> void:
	animation_player.play(current_animation)

## 动画播放速度,舞王初始化
func init_anim_speed(curr_animation_origin_speed, curr_init_random_speed:float):
	# 获取动画初始速度
	self.animation_origin_speed = curr_animation_origin_speed
	self.init_random_speed = curr_init_random_speed
	animation_player.speed_scale = animation_origin_speed * init_random_speed
	animation_curr_speed = animation_origin_speed * init_random_speed
	for i in range(-1, 4):
		zombie_dancers_speed_factor_product[i] = init_random_speed

## 更新舞王和伴舞是否为正常状态（移动） (-1为舞王)
func change_move(dancer_id:=-1, is_norm:=true):
	zombie_dancers_is_norm[dancer_id] = is_norm
	update_all_walk()

func update_all_walk():
	## 是否全为true,即是否全为移动
	if zombie_dancers_is_norm.values().all(func(v): return v == true):
		for i in zombie_dancers:
			if zombie_dancers[i] is Zombie009Jackson:
				zombie_dancers[i].update_move(true)
	else:
		for i in zombie_dancers:
			if zombie_dancers[i] is Zombie009Jackson:
				zombie_dancers[i].update_move(false)

## 更新舞王和伴舞动画速度是否正常 (-1为舞王),僵尸调用
func change_speed_factor_product(dancer_id:=-1, speed_factor_product:float=1):
	zombie_dancers_speed_factor_product[dancer_id] = speed_factor_product
	update_all_zombie_speed_factor_product()

## 更新所有播放速度为最小的播放速度
func update_all_zombie_speed_factor_product():
	var curr_min_speed_factor_product = zombie_dancers_speed_factor_product.values().min()
	animation_curr_speed = animation_origin_speed * curr_min_speed_factor_product
	animation_player.speed_scale = animation_origin_speed * curr_min_speed_factor_product

	for i in zombie_dancers:
		## 伴舞继承舞王僵尸， 有可能伴舞还未召唤，此时将伴舞置为false
		if zombie_dancers[i] is Zombie009Jackson:
			zombie_dancers[i].manager_update_anim_speed(curr_min_speed_factor_product)

## 动画结束回调函数
func _on_animation_player_animation_finished(anim_name:StringName):
	# 切换到另一个动画
	# 如果举手的次数小于4次，继续举手
	if time_anim < 4:
		## 首次抬手动作判断是否召唤僵尸
		if time_anim == 0:
			#如果需要召唤伴舞僵尸,并且舞王还存在
			if judge_need_call_dance() and zombie_dancers[-1]:
				time_need_call_zombie += 1
				if time_need_call_zombie >= 2:
					time_need_call_zombie = 0
					zombie_dancers[-1].anim_play("point", curr_scale, 0, 1)

		time_anim += 1
		current_animation = "armraise"
		curr_scale = curr_scale * Vector2(-1, 1)
		if time_anim == 4:
			animation_player.play("armraise_end")
		else:
			animation_player.play(current_animation)

	elif time_anim < 6:

		time_anim += 1
		current_animation = "walk"
		animation_player.play(current_animation)

	else:
		time_anim = 0
		_on_animation_player_animation_finished(anim_name)
		return
	for i in zombie_dancers:
		if is_instance_valid(zombie_dancers[i]) and zombie_dancers[i] is Zombie009Jackson:
			zombie_dancers[i].anim_play(current_animation, curr_scale, 0, 1)

## 是否需要召唤伴舞
func judge_need_call_dance():
	for i in zombie_dancers:
		if not zombie_dancers[i]:
			return true
	return false

# 获取当前播放动画的完整信息（名称、时间、速度等）
func get_current_animation_info():
	if animation_player.is_playing():
		# 1. 获取当前动画名称
		var anim_name = animation_player.current_animation
		# 2. 获取当前已播放时间（秒）
		var current_time = animation_player.get_current_animation_position()
		# 3. 获取当前动画总时长（秒）
		var total_time = animation_player.get_current_animation_length()
		# 4. 获取当前播放速度（1.0 为正常速度）
		var speed = animation_player.speed_scale

		# 返回整合后的信息字典
		return {
			"name": anim_name,
			"curr_scale": curr_scale,
			"current_time": current_time,
			"total_time": total_time,
			"speed": speed,
			"progress": current_time / total_time if total_time > 0 else 0.0
		}
	else:
		print("无动画播放")
		return {
			"name": 'armraise',
			"curr_scale": curr_scale,
			"current_time": 0,
			"total_time": 1,
			"speed": animation_origin_speed,
			"progress": 0
		}

## 召唤伴舞僵尸
func call_zombie_dancer():
	for i in zombie_dancers:
		if not zombie_dancers[i]:
			if i == -1:
				print("舞王不存在？有问题")

			var new_zombie_dancer_lane_and_pos = get_new_zombie_dancer_lane_and_glo_pos(i, zombie_dancers[-1].lane, zombie_dancers[-1].global_position)
			## 如果当前位置可以生成伴舞
			if new_zombie_dancer_lane_and_pos:
				var zombie_init_para:Dictionary = {
					Zombie000Base.E_ZInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsNorm,
					Zombie000Base.E_ZInitAttr.Lane:new_zombie_dancer_lane_and_pos["lane"],
				}
				var _new_zombie_dancer:Zombie010Dancer = Global.main_game.zombie_manager.create_norm_zombie(
					EnumsCharacter.ZombieType.Z010Dancer,
					Global.main_game.zombie_manager.all_zombie_rows[new_zombie_dancer_lane_and_pos["lane"]],
					zombie_init_para,
					new_zombie_dancer_lane_and_pos["pos"],
					call_dancer_init.bind(i)
				)

			## 不能生成伴舞，用true填充
			else:
				zombie_dancers[i] = true

	## 召唤伴舞完成后更新移动
	update_all_walk()

func call_dancer_init(z:Zombie010Dancer, dancer_i:int):
	z.init_dancer_be_call(
		dancer_i, animation_origin_speed, animation_curr_speed,
		init_random_speed, self, is_hypnotized
	)
	zombie_dancers[dancer_i] = z

func get_new_zombie_dancer_lane_and_glo_pos(i:int, lane_Jackson:int, global_postion_jackson:Vector2):
	## 上下左右顺序
	if i == 0:
		## 舞王在第一行，或者召唤行为泳池行
		if lane_Jackson == 0 or Global.main_game.zombie_manager.all_zombie_rows[lane_Jackson - 1].zombie_row_type == EnumsCharacter.ZombieRowType.Pool:
			return false
		var global_pos = Vector2(global_postion_jackson.x, Global.main_game.zombie_manager.all_zombie_rows[lane_Jackson - 1].zombie_create_position.global_position.y)

		return {
			"lane":lane_Jackson - 1,
			"pos": global_pos
		}
	elif i == 1:
		if lane_Jackson == Global.main_game.zombie_manager.all_zombie_rows.size() - 1 or Global.main_game.zombie_manager.all_zombie_rows[lane_Jackson + 1].zombie_row_type == EnumsCharacter.ZombieRowType.Pool:
			return false
		var global_pos = Vector2(global_postion_jackson.x, Global.main_game.zombie_manager.all_zombie_rows[lane_Jackson + 1].zombie_create_position.global_position.y)

		return {
			"lane":lane_Jackson + 1,
			"pos": global_pos
		}
	elif i == 2:
		var global_pos = Vector2(global_postion_jackson.x - 100, global_postion_jackson.y)
		return {
			"lane":lane_Jackson,
			"pos":global_pos
		}
	elif i == 3:
		var global_pos = Vector2(global_postion_jackson.x + 100, global_postion_jackson.y)
		return {
			"lane":lane_Jackson,
			"pos":global_pos
		}

## 或当前持有舞王管理器的伴舞死后，转移父节点
func change_manager_parent():
	for i in zombie_dancers:
		## 死亡的僵尸已经置为null
		if zombie_dancers[i] is Zombie009Jackson:
			curr_master_id = i
			get_parent().remove_child(self)
			zombie_dancers[i].add_child(self)
