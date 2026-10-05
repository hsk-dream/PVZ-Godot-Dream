extends ComponentNormBase
## 被攻击组件
class_name HurtBoxComponent

## 实际承受攻击的区域；攻击方使用其位置与重叠结果确定命中。
@onready var hurt_box_real: Area2D = %HurtBoxReal

 #在碰撞区域内修改属性似乎没有作用
## 启用组件
## [param is_enable_factor] 本次启用或禁用操作对应的原因，避免覆盖其他原因的禁用状态。
func enable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)
	if is_enabling:
		# 当前受击子区域；延迟更新其可被检测状态，避开物理回调期间直接修改。
		for area:Area2D in get_children():
			#area.set_deferred("monitorable", true)
			call_deferred("update_area_monitorable", area, true)

## 禁用组件
## [param is_enable_factor] 本次启用或禁用操作对应的原因，避免覆盖其他原因的禁用状态。
func disable_component(is_enable_factor:E_IsEnableFactor):
	#print_debug("受击组件")
	super(is_enable_factor)
	if not is_enabling:
		# 当前受击子区域；延迟更新其可被检测状态，避开物理回调期间直接修改。
		for area:Area2D in get_children():
			call_deferred("update_area_monitorable", area, false)
			#area.set_deferred("monitorable", false)

## 更新区域是否可以被检查
## [param area] 要更新检测状态的受击区域。
## [param v] 区域是否允许被其他区域检测，true 表示允许。
func update_area_monitorable(area:Area2D, v:bool):
	area.monitorable = v

	## INFO: 更新 monitoring 才会更新 monitorable
	area.monitoring = not area.monitoring
	area.monitoring = not area.monitoring
