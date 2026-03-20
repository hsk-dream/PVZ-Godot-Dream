extends RefCounted
class_name EnumsMainScene


## 加载场景
enum MainScenes{
	MainGameFront,
	MainGameBack,
	MainGameRoof,

	StartMenu = 100,
	ChooseLevelAdventure,
	ChooseLevelMiniGame,
	ChooseLevelPuzzle,
	ChooseLevelSurvival,
	ChooseLevelCustom,

	Garden = 200,
	Almanac,
	Store,

	Null = 999,
}
