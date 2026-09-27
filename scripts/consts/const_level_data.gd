extends RefCounted
class_name ConstLevelData

#region 游戏背景
## 游戏场景
enum GameBg {
	FrontDay,
	FrontNight,
	Pool,
	Fog,
	Roof,
}

## 背景图
const GameBgTextureMap: Dictionary = {
	GameBg.FrontDay: preload("res://assets/image/background/background1.jpg"),
	GameBg.FrontNight: preload("res://assets/image/background/background2.jpg"),
	GameBg.Pool: preload("res://assets/image/background/background3.jpg"),
	GameBg.Fog: preload("res://assets/image/background/background4.jpg"),
	GameBg.Roof: preload("res://assets/image/background/background5.jpg"),
}
#endregion

#region 音乐
enum GameBGM {
	FrontDay,
	FrontNight,
	Pool,
	Fog,
	Roof,
	MiniGame,
	Boss,
	Puzzle,
}

## BGM 资源路径
const GameBGMMap: Dictionary[GameBGM, String] = {
	GameBGM.FrontDay: "res://assets/audio/BGM/front_day.mp3",
	GameBGM.FrontNight: "res://assets/audio/BGM/front_night.mp3",
	GameBGM.Pool: "res://assets/audio/BGM/pool.mp3",
	GameBGM.Fog: "res://assets/audio/BGM/fog.mp3",
	GameBGM.Roof: "res://assets/audio/BGM/roof.mp3",
	GameBGM.MiniGame: "res://assets/audio/BGM/mini_game.mp3",
	GameBGM.Boss: "res://assets/audio/BGM/boss.mp3",
	GameBGM.Puzzle: "res://assets/audio/BGM/puzzle.mp3",
}
#endregion

#region 出怪
## 出怪模式。新增模式追加在末尾，保留关卡资源中已保存的枚举编号。
enum E_MonsterMode {
	Null, ## 不出怪，测试使用
	Norm, ## 正常出怪模式
	HammerZombie, ## 锤僵尸出怪模式
	Boss, ## 僵王出怪模式：不启动普通波次，由死亡动画方法轨道请求奖杯
}
#endregion

#region 卡槽
## 卡槽模式
enum E_CardMode {
	Null,
	Norm,
	ConveyorBelt,
	Coin, ## 金币卡槽(雪人du狗小游戏)
}
#endregion

#region 罐子
## 罐子的生成模式
enum E_PotMode {
	Null, ## 无
	Weight, ## 根据权重随机生成罐子
	Fixd, ## 固定生成，随机位置
}
#endregion
