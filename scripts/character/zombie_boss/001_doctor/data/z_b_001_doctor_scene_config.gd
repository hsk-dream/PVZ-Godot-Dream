## 博士在一种场地中的静态技能配置；各实例只读共享资源，运行时目标和成长数据由技能保存。
extends Resource
class_name ZB001DoctorSceneConfig

@export_group("放置僵尸")
## 从 1 开始的行号到动画及 OuterArm 位置；不存在于当前地图的行不参与选行。
@export var spawn_row_actions: Dictionary[int, ZB001DoctorRowAction] = {}
## 放置动作开始定位、1.25 秒关键帧开始复位所用的时长与曲线；各场地可独立调整。
@export var spawn_part_motion: ZB001DoctorPartMotionConfig = ZB001DoctorPartMotionConfig.new()

@export_group("冰火球")
## 从 1 开始的行号到攻击动画及 Head 位置；只在吐球攻击中平移头部，根节点受击框保持原位。
@export var ice_fire_ball_row_actions: Dictionary[int, ZB001DoctorRowAction] = {}
## 吐球攻击开始定位、2.5 秒关键帧开始复位所用的时长与曲线，不在低头进入阶段移动。
@export var ice_fire_ball_part_motion: ZB001DoctorPartMotionConfig = ZB001DoctorPartMotionConfig.new()

@export_group("脚踩")
## 每项绑定动画、腿部位置和完整攻击区域；动画 1、2 定位 InnerLeg，3、4 定位 OuterLeg，默认攻击 2 行 3 列。
@export var stomp_actions: Array[ZB001DoctorAreaAction] = []
## 脚踩动作开始定位、1.5 秒落地关键帧开始复位所用的时长与曲线。
@export var stomp_part_motion: ZB001DoctorPartMotionConfig = ZB001DoctorPartMotionConfig.new()

@export_group("蹦极偷植物")
## 连续列组从第 1 列开始时 InnerArm 的局部位置；Y 不随目标植物所在行变化。
@export var bungee_first_column_position: Vector2 = Vector2.ZERO
## 起始列的包含式下限和上限；默认抽取 123、234、345 三组，地图边缘的不完整组排除。
@export var bungee_start_column_range: Vector2i = Vector2i(1, 3)
## 连续覆盖列数，默认 3；上限对应博士已有的左、中、右三个手指定位点，空列不补名额。
@export_range(1, 3, 1) var bungee_column_count: int = 3

@export_group("砸车")
## 攻击左上角为第 1 行第 1 列时 InnerArm 的局部位置，与技能结束后的待机位置分别保存。
@export var throw_rv_cell_one_position: Vector2 = Vector2.ZERO
## 可随机攻击左上角的最小行列，从 1 开始，包含边界。
@export var throw_rv_top_left_min: Vector2i = Vector2i(1, 1)
## 可随机攻击左上角的最大行列；不能容纳完整攻击区域的位置不参与抽取。
@export var throw_rv_top_left_max: Vector2i = Vector2i(4, 3)
## 攻击覆盖的行数、列数，默认为 2 行 3 列，均必须为正数。
@export var throw_rv_size: Vector2i = Vector2i(2, 3)


## 校验 [param actions] 的行号、动画与部件位置；[param context] 指示出错的技能或资源。
## 空字符串表示有效；错误在发现处报告，允许不同行复用同一动画。
func get_row_actions_error(actions: Dictionary[int, ZB001DoctorRowAction], context: String) -> String:
	if actions.is_empty():
		push_error("%s：必须配置至少一个行动作。" % context)
		return "行动作配置为空。"
	# 字典键决定显示行号，数组下标转换只发生在技能访问僵尸管理器时。
	for row: int in actions:
		# 每项只读共享资源，不能在校验或动作准备期间修改。
		var action: ZB001DoctorRowAction = actions[row]
		if row < 1 or action == null or action.animation_name.is_empty() or not action.part_position.is_finite():
			push_error("%s：行动作必须具有正数行号、有效动画名称和有限部件位置。" % context)
			return "行动作配置无效。"
	return ""
