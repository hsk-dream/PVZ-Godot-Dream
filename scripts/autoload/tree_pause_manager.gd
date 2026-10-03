## 汇总游戏暂停因素，并通知需要区分暂停原因的场景节点。
extends Node

## 每次暂停因素更新后发送，即使场景树的聚合暂停状态没有变化。
signal pause_factors_changed

## 游戏暂停因素
enum E_PauseFactor {
	Menu,			## 菜单
	GameOver,		## 游戏结束
	ReChooseCard,	## 重新选卡
}

## 各暂停因素是否生效；任一值为 true 时暂停场景树。
var curr_pause_factor: Dictionary = {}

## 更新场景树暂停状态，并通知轮次退场等需要区分暂停原因的逻辑。
func _update_pause_state() -> void:
	get_tree().paused = curr_pause_factor.values().any(func(v): return v)
	if get_tree().paused:
		print("暂停游戏")
	else:
		print("继续游戏")
	# 重新选卡暂停中打开菜单时，树仍暂停，但退雾必须收到新的菜单因素。
	pause_factors_changed.emit()

## 启用 [param pause_factor]，更新场景树并通知暂停因素变化。
func start_tree_pause(pause_factor: E_PauseFactor) -> void:
	curr_pause_factor[pause_factor] = true
	_update_pause_state()

## 解除 [param pause_factor]；其他因素仍生效时场景树保持暂停。
func end_tree_pause(pause_factor: E_PauseFactor) -> void:
	curr_pause_factor[pause_factor] = false
	_update_pause_state()

## 清除所有暂停因素
func end_tree_pause_clear_all_pause_factors() -> void:
	curr_pause_factor.clear()
	_update_pause_state()
