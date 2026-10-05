extends Node
class_name GlobalUtilsClass
## 全局工具脚本

#const RandomPicker = preload("random_picker.gd")
#region 工具方法
## plantcell对应的斜面位置与监测位置的差值更新
func update_plant_cell_slope_y(plant_cell:PlantCell, node_2d:Node2D):
	## 斜面与水平面的差值
	var diff_slope_flat:float = 0
	if is_instance_valid(plant_cell):
		diff_slope_flat = plant_cell.position.y

	if diff_slope_flat != 0:
		node_2d.position.y -= diff_slope_flat

func update_plant_cell_slope_y_array(plant_cell:PlantCell, node2d_detect_in_slope:Array):
	## 斜面与水平面的差值
	var diff_slope_flat:float = 0
	if is_instance_valid(plant_cell):
		diff_slope_flat = plant_cell.position.y

	if diff_slope_flat != 0:
		for n in node2d_detect_in_slope:
			n.position.y -= diff_slope_flat


## 数字转str,每三位加逗号
func format_number_with_commas(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result
	return result

## 递归让子节点使用父节点shader材质
func node_use_parent_material(node: Node2D) -> void:
	node.use_parent_material = true
	## 遍历所有子节点
	for child in node.get_children():
		if child.is_class("Node2D"):
			node_use_parent_material(child)

## 求字典value乘积
func get_dic_product(my_dict:Dictionary) -> float:
	var product = 1.0
	for value in my_dict.values():
		product *= value
	return product

## 列表求和
func sum_arr(arr: Array[float]) -> float:
	var total = 0.0
	for n in arr:
		total += n
	return total

## 补全列表
func pad_array(arr: Array, target_size: int, pad_value = 0) -> Array:
	while arr.size() < target_size:
		arr.append(pad_value)
	return arr

## 世界坐标转屏幕坐标
func world_to_screen(global_pos : Vector2) -> Vector2:
	# pos 是 world / canvas 坐标，也就是某个 Node2D 的 global_position
	var viewport := get_viewport()
	# 获取视口变换 （画布 -> 屏幕）
	var vt : Transform2D = viewport.get_screen_transform()
	# 用 vt * pos 得到屏幕上的像素位置
	return vt * global_pos

## 创建计时器(触发一次)(角色buff[减速]使用)
func create_new_timer_once(need_node:Node, callable:Callable, wait_time:float=0):
	var timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	if wait_time != 0:
		timer.wait_time = wait_time
	timer.timeout.connect(callable)
	need_node.add_child(timer)
	return timer

enum E_CurrTimeType{
	String,

}

## 获取当前时间
func get_curr_time(curr_time_type:E_CurrTimeType=E_CurrTimeType.String):
	match curr_time_type:
		E_CurrTimeType.String:
			var d := Time.get_datetime_dict_from_system()
			var text := "%04d-%02d-%02d %02d:%02d:%02d" % [
				d.year, d.month, d.day, d.hour, d.minute, d.second
			]
			return text




#endregion


#region 特殊僵尸生成函数

func get_special_zombie_callable(zombie_type:CharacterRegistry.ZombieType, plant_cell:PlantCell) -> Callable:
	match zombie_type:
		CharacterRegistry.ZombieType.Z021Bungi:
			return create_bungi.bind(plant_cell)
	return Callable()

## 普通出怪在入树前注入蹦极目标，保留靶子与下降前预警。[br]
## [param zombie_bungi] 尚未入树的蹦极实例；[param plant_cell] 本次偷取的目标格子。
func create_bungi(zombie_bungi:Zombie021Bungi, plant_cell:PlantCell):
	zombie_bungi.initialize_spawn(plant_cell)

#endregion
