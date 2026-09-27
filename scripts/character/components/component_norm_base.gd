@abstract
extends Node2D
class_name  ComponentNormBase
## 普通组件基类
"""
组件可以启用或禁用
"""

## 是否正在启用
var is_enabling := true
## 默认是否启用组件
@export var is_enable_default := true

## 影响节点是否启用的因素
enum E_IsEnableFactor{
	Default,	## 默认是否启用组件,只有角色不使用该组件时在检测器中禁用该组件
	InitType,	## 初始化状态类型（正常、展示、花园）
	Character,	## 角色本身特殊需要禁用组件(确保该条件不会冲突)
	MainGameProgress,	## 主游戏当前运行阶段
	Global,		## 全局禁用组件,追踪子弹全局检测组件使用
	Death,		## 死亡禁用组件
	Prepare,	## 准备（土豆雷）
	Sleep,		## 睡眠
	Scaredy,	## 害怕
	Jump,		## 跳跃
	Hypno,		## 魅惑重启节点
	Attack,		## 攻击(影响眨眼)
	Lose,		## 失去该组件(小丑爆炸匣子)
	Balloon,	## 气球在空中禁用攻击组件
	DownGround,	## 矿工在地下禁用攻击组件
	Garlic,		## 大蒜禁用攻击组件
	GameMode,	## 游戏模式，我是僵尸禁用生产组件
}

## 按原因记录的启用开关；所有已记录因素都为 true 时组件才可启用。
var is_enable_factors:Dictionary[E_IsEnableFactor, bool] = {}

func _ready() -> void:
	if not is_enable_default:
		disable_component(E_IsEnableFactor.Default)


## 改变组件是否启用状态
## [param value] 当前原因是否允许组件启用，true 启用、false 禁用。
## [param is_enable_factor] 本次启用或禁用操作对应的原因，避免覆盖其他原因的禁用状态。
func change_is_enabling(value:bool, is_enable_factor:E_IsEnableFactor):
	if value:
		enable_component(is_enable_factor)
	else:
		disable_component(is_enable_factor)

## 启用组件
## [param is_enable_factor] 本次启用或禁用操作对应的原因，避免覆盖其他原因的禁用状态。
func enable_component(is_enable_factor:E_IsEnableFactor):
	is_enable_factors[is_enable_factor] = true
	# v 是单个原因的允许开关，所有原因都允许时组件才启用。
	is_enabling = is_enable_factors.values().all(func(v): return v == true)

## 禁用组件
## [param is_enable_factor] 本次启用或禁用操作对应的原因，避免覆盖其他原因的禁用状态。
func disable_component(is_enable_factor:E_IsEnableFactor):
	is_enable_factors[is_enable_factor] = false
	is_enabling = false

## 修改速度
## [param _speed_product] 角色速度因素乘积；此基类不实现具体速度变化，交由子类处理。
func owner_update_speed(_speed_product:float):
	pass
