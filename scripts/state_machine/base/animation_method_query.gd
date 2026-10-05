## 只读查询动画方法事件；调用者决定数量、时刻和报错规则，不修改动画资源。
extends RefCounted
class_name AnimationMethodQuery

## 返回所有符合条件且位于动画时长内的关键帧秒数。[br]
## [param animation] 待查询动画；[param target] 方法轨道目标路径；[param method] 调用方法名。[br]
## [param arguments] 必须完全匹配的方法参数；[param include_edges] 是否接受动画起点和终点。
static func get_times(animation: Animation, target: NodePath, method: StringName, arguments: Array, include_edges: bool = true) -> Array[float]:
	# 按轨道顺序收集，调用者检查数量或具体时间，不依赖排序。
	var times: Array[float] = []
	if animation == null:
		return times
	# 只查询启用且目标正确的方法轨道。
	for track: int in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_METHOD or not animation.track_is_enabled(track) \
			or animation.track_get_path(track) != target:
			continue
		# 当前方法关键帧索引。
		for key: int in animation.track_get_key_count(track):
			# 方法名和参数必须共同匹配，不仅靠事件名猜测。
			var event: Dictionary = animation.track_get_key_value(track, key)
			# 当前关键帧秒数；技能释放不允许位于起止边界，死亡事件允许。
			var time: float = animation.track_get_key_time(track, key)
			if event.get("method") != method or event.get("args", []) != arguments:
				continue
			if (include_edges and time >= 0.0 and time <= animation.length) \
				or (not include_edges and time > 0.0 and time < animation.length):
				times.append(time)
	return times
