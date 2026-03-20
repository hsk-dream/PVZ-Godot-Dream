extends TextureRect
class_name GardenConditionFlag

@onready var water: TextureRect = $Water
@onready var sprout: TextureRect = $Sprout


func _ready() -> void:
	judge_garden_condition()

func judge_garden_condition():
	if Global.global_game_state.curr_num_new_garden_plant > 0:
		sprout.visible = true
		water.visible = false
		visible = true
	elif _judge_need_water():
		sprout.visible = false
		water.visible = true
		visible = true
	else:
		visible = false

func _judge_need_water() -> bool:
	for i in range(GardenManager.E_GardenBgType.size()):
		## 背景种类
		var curr_bg_data = Global.global_game_state.garden_data.get("第"+str(i)+"类背景", {})
		for j in range(Global.global_game_state.garden_data["num_bg_page_" + str(i)]):
			## 当前背景种类的页码数据
			var curr_bg_page_data = curr_bg_data.get("第"+str(j)+"页", {})
			for k in range(curr_bg_page_data.size()):
				var plant_data:Dictionary = curr_bg_page_data.get("第"+str(k)+"个植物格子", {})
				## 如果该植物格子有植物
				if plant_data:
					var next_update_time = plant_data.get("next_update_time")
					if next_update_time == null:
						return true
					else:
						var now = Time.get_datetime_dict_from_system()  # 当前系统时间
						var now_unix = Time.get_unix_time_from_datetime_dict(now)
						var next_unix = Time.get_unix_time_from_datetime_string(next_update_time)
						if now_unix >= next_unix:
							print("存在需要浇水的植物")

							return true

	return false

