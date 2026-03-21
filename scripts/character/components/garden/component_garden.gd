extends ComponentNormBase
class_name GardenComponent

## 植物身体
@onready var body: BodyCharacter = %Body
## 植物需求计时器,每次启动更新下次时间
@onready var need_timer: Timer = $NeedTimer
## 完美植物生产金币计时器
@onready var create_coin_timer: Timer = $CreateCoinTimer
## 花园需求气泡
var garden_speech_bubble : GardenSpeehBubble
## 该植物下的花盆
var flower_pot:GardenFlowerPot
## 当前植物类型
var curr_plant_type : EnumsCharacter.PlantType
## 植物朝向x
var direction_x := 1.0
## 植物种植条件（默认为草地）
var curr_plant_condition:int = 2

#region 植物状态属性
## 当前植物成长状态
var curr_growth_stage := GardenManager.E_GrowthStage.Sprout
var curr_need_item := GardenManager.E_NeedItem.WateringCan
## 植物需求下次更新需要的时间（短和长时间）
var short_time_range_need_item_next = Vector2(10,15)
## 半小时左右
var long_time_range_need_item_next = Vector2(2500,3500)
## 当前浇水次数
var curr_water_time := 0
## 最大浇水次数，每次浇水满足当前次数时重置，范围为[3,5]
var max_water_time := 5
## 下次更新时间
var next_update_time: String = ""  # 存储为 ISO 8601 字符串

## 创建金币的位置，为本体位置向上60像素(全局位置)
var global_position_create_coin:Vector2
## 生产金币的间隔，上下波动5秒
var create_coin_time_cd:float = 30
#endregion
## 当前植物格子,发芽成长时
var plant_cell_garden:PlantCellGarden
## 发芽成长信号,组件与植物根节点连接信号
signal signal_sprout_grow

func _ready() -> void:
	## 需求气泡
	garden_speech_bubble = SceneRegistry.GARDEN_SPEECH_BUBBLE.instantiate()
	add_child(garden_speech_bubble)
	global_position_create_coin = global_position + Vector2(0, -60)
#region 睡眠禁用组件
## 启用组件(应该用不到,更换场景时重新创建新植物)
func enable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)

## 禁用组件
func disable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)
	need_timer.stop()
	create_coin_timer.stop()

	## 重置需求
	curr_need_item = GardenManager.E_NeedItem.Null
	garden_speech_bubble.change_plant_need_item(curr_need_item)


#endregion
## 初始化花园组件数据(ready之后)
func init_garden_component(garden_date_init:Dictionary):
	self.flower_pot = garden_date_init["flower_pot"]
	self.curr_plant_condition = garden_date_init["curr_plant_condition"]

	var garden_plant_data = garden_date_init["curr_garden_plant_data"]
	direction_x = garden_plant_data.get("direction_x",  direction_x)
	curr_plant_type = garden_plant_data.get("curr_plant_type", curr_plant_type)
	curr_growth_stage = garden_plant_data.get("curr_growth_stage", curr_growth_stage)
	curr_need_item = garden_plant_data.get("curr_need_item", curr_need_item)
	curr_water_time = garden_plant_data.get("curr_water_time", curr_water_time)
	max_water_time = garden_plant_data.get("max_water_time", max_water_time)
	next_update_time = garden_plant_data.get("next_update_time", next_update_time)
	update_growth_stage()
	_check_if_need_should_trigger()

## 触发需求
func _on_coin_timer_timeout():
	## 下次触发
	if curr_growth_stage == GardenManager.E_GrowthStage.Perfect:
		create_coin_timer.start(create_coin_time_cd + randf_range(-5, 5))
	else:
		create_coin_timer.stop()
	EventBus.push_event("create_coin", [[0.7, 0.25, 0.05], global_position_create_coin])

## 检测当前是否需要触发，读档时使用
func _check_if_need_should_trigger():
	## 如果下次更新为空
	if next_update_time == "":
		_on_need_timer_timeout()
	else:
		var now = Time.get_datetime_dict_from_system()  # 当前系统时间
		var now_unix = Time.get_unix_time_from_datetime_dict(now)
		var next_unix = Time.get_unix_time_from_datetime_string(next_update_time)

		if now_unix >= next_unix:
			_on_need_timer_timeout()  # 手动触发
		else:
			# 计算间隔，启动定时器
			var delta = next_unix - now_unix
			need_timer.wait_time = delta
			need_timer.start()

## 计算下次更新时间，启动计时器
func _calculate_next_need_time(time_range:Vector2):
	# 1. 随机生成需求等待时间
	var wait_seconds = randf_range(time_range.x, time_range.y)
	# 2. 启动定时器
	need_timer.wait_time = wait_seconds
	need_timer.start()
	# 3. 保存下次更新时间（当前时间 + 等待时间）
	var now = Time.get_datetime_dict_from_system()  # 当前系统时间
	var now_unix = Time.get_unix_time_from_datetime_dict(now)
	var next_unix = now_unix + wait_seconds
	# 转换为 ISO 8601 字符串（例如："2025-07-28T12:34:56"）
	next_update_time = Time.get_datetime_string_from_unix_time(next_unix, true)

## 更新状态
func update_growth_stage():
	match curr_growth_stage:
		GardenManager.E_GrowthStage.Sprout:
			#print("发芽状态")
			pass
		GardenManager.E_GrowthStage.Small:
			change_body_scale(Vector2(0.33 * direction_x, 0.33))
		GardenManager.E_GrowthStage.Medium:
			change_body_scale(Vector2(0.66 * direction_x, 0.66))
		GardenManager.E_GrowthStage.Large:
			change_body_scale(Vector2(1.0 * direction_x, 1.0))
			create_coin_timer.stop()
		GardenManager.E_GrowthStage.Perfect:
			create_coin_timer.start(create_coin_time_cd + randf_range(-5, 5))
	flower_pot.plant_change_profect(curr_growth_stage == GardenManager.E_GrowthStage.Perfect)

## 满足当前需求
func satisfy_need(item: GardenManager.E_NeedItem):
	## 如果植物当前没有需求，或者道具不匹配，直接返回
	if curr_need_item == GardenManager.E_NeedItem.Null or item != curr_need_item:
		return
	var is_update_growth_stage := false
	match curr_need_item:
		GardenManager.E_NeedItem.WateringCan:
			EventBus.push_event("create_coin", [[0.5, 0.5, 0.0], global_position_create_coin])
			curr_water_time += 1
			# 开启下一次需求计时
			_calculate_next_need_time(short_time_range_need_item_next)

		GardenManager.E_NeedItem.Fertilizer, GardenManager.E_NeedItem.BugSpray, GardenManager.E_NeedItem.Phonograph:
			if curr_growth_stage < GardenManager.E_GrowthStage.Perfect:
				up_growth_stage()
			else:
				print("不应该出现该语句，当前满足完美状态需求，")
			EventBus.push_event("create_coin", [[0.0, 0.95, 0.05], global_position_create_coin])
			EventBus.push_event("create_coin", [[0.0, 0.95, 0.05], global_position_create_coin])

			curr_water_time = 0
			max_water_time = randi_range(3, 5)  # 重置新的最大次数

			# 开启下一次需求计时
			_calculate_next_need_time(long_time_range_need_item_next)
			is_update_growth_stage = true
	curr_need_item = GardenManager.E_NeedItem.Null
	## 重置需求
	garden_speech_bubble.change_plant_need_item(curr_need_item)
	if is_update_growth_stage:
		if curr_growth_stage == GardenManager.E_GrowthStage.Small:
			signal_sprout_grow.emit()
			return
		update_growth_stage()

## 成长状态升级
func up_growth_stage():
	## 如果是发芽状态成长
	if curr_growth_stage == GardenManager.E_GrowthStage.Sprout:
		curr_plant_type = Global.global_game_state.curr_plant.pick_random()
		direction_x = [-1,1].pick_random()
	curr_growth_stage = (curr_growth_stage + 1) as GardenManager.E_GrowthStage

## 改变植物大小
func change_body_scale(new_scale:Vector2):
	## 如果是原始大小，即初始化时，非生长变大
	if body.scale == Vector2(1,1) or body.scale == Vector2(-1,1):
		## 修改大小，影子位置不变
		body.scale = new_scale

	else:
		SoundManager.play_other_SFX("wakeup")
		var tween :Tween = create_tween()
		tween.tween_property(body, "scale", new_scale, 1)

## 时间回调函数调用植物状态变化,触发该函数生成需求
func _on_need_timer_timeout():
	## 如果当前为完美状态，触发需求函数，将完美状态退化为大状态
	if curr_growth_stage == GardenManager.E_GrowthStage.Perfect:
		curr_growth_stage = GardenManager.E_GrowthStage.Large
		update_growth_stage()
	## 判断是否在水中
	if flower_pot.is_water:
		curr_water_time = max_water_time
	## 判断是否需要浇水
	if curr_water_time < max_water_time:
		## 需要浇水
		curr_need_item = GardenManager.E_NeedItem.WateringCan
	else:
		## 需要除浇水外的东西
		match curr_growth_stage:
			## 发芽，小，中
			GardenManager.E_GrowthStage.Sprout, GardenManager.E_GrowthStage.Small, GardenManager.E_GrowthStage.Medium:
				curr_need_item = GardenManager.E_NeedItem.Fertilizer
			## 大，完美
			GardenManager.E_GrowthStage.Large:
				curr_need_item = [GardenManager.E_NeedItem.BugSpray, GardenManager.E_NeedItem.Phonograph,].pick_random()
	## 更新植物需求气泡
	garden_speech_bubble.change_plant_need_item(curr_need_item)


func get_curr_plant_data() -> Dictionary:
	var data := {
		"curr_plant_type": curr_plant_type,
		"direction_x" : direction_x,
		"curr_growth_stage": curr_growth_stage,
		"curr_need_item": curr_need_item,
		"curr_water_time": curr_water_time,
		"max_water_time": max_water_time,
		"next_update_time": next_update_time,
		"curr_plant_condition": curr_plant_condition
	}
	return data

