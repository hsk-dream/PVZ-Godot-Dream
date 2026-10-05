extends Node2D
class_name BulletEffect000Base
## 子弹命中特效基类：脱离子弹后独立播放，统一处理僵王命中的显示层级。

## 僵王命中特效的绝对层级，位于当前 4000 层的 ZombieBossRoot 机甲之前。
const BOSS_HIT_EFFECT_Z_INDEX: int = 4001

## 是否有子弹特效
@export var is_bullet_effect := true

## 保留世界位置，将特效挂到子弹原父节点，避免随子弹销毁；具体播放和释放由子类负责。[br]
## [param is_boss_hit] 扣血前记录的僵王命中结果；true 使用绝对 4001 层，false 沿用子弹相对层级。
func activate_bullet_effect(is_boss_hit: bool = false) -> void:
	# 特效脱离后仍挂在当前关卡的子弹容器下，不跟随机甲动画或后续移动。
	var bullet_parent: Node = owner.get_parent()
	# 在脱离之前保存原子弹层级，普通目标和撞地继续使用原有按行显示规则。
	var bullet_z_index: int = owner.z_index
	reparent(bullet_parent, true)
	# 僵王命中使用绝对层级，避免容器的 z_index 再次叠加；普通命中保持相对层级。
	z_as_relative = not is_boss_hit
	z_index = BOSS_HIT_EFFECT_Z_INDEX if is_boss_hit else bullet_z_index
