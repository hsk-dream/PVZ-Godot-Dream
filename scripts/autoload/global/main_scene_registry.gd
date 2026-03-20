extends Node
class_name MainSceneRegistry


@export var MainScenesMap = {
	EnumsMainScene.MainScenes.MainGameFront: "res://scenes/main/MainGame01Front.tscn",
	EnumsMainScene.MainScenes.MainGameBack: "res://scenes/main/MainGame02Back.tscn",
	EnumsMainScene.MainScenes.MainGameRoof: "res://scenes/main/MainGame03Roof.tscn",

	EnumsMainScene.MainScenes.StartMenu: "res://scenes/main/01StartMenu.tscn",
	EnumsMainScene.MainScenes.ChooseLevelAdventure: "res://scenes/main/02AdventureChooesLevel.tscn",
	EnumsMainScene.MainScenes.ChooseLevelMiniGame: "res://scenes/main/03MiniGameChooesLevel.tscn",
	EnumsMainScene.MainScenes.ChooseLevelPuzzle: "res://scenes/main/04PuzzleChooesLevel.tscn",
	EnumsMainScene.MainScenes.ChooseLevelSurvival: "res://scenes/main/05SurvivalChooesLevel.tscn",
	EnumsMainScene.MainScenes.ChooseLevelCustom: "res://scenes/main/06CustomChooesLevel.tscn",

	EnumsMainScene.MainScenes.Garden: "res://scenes/main/10Garden.tscn",
	EnumsMainScene.MainScenes.Almanac: "res://scenes/main/11Almanac.tscn",
	EnumsMainScene.MainScenes.Store: "res://scenes/main/12Store.tscn",
}

## 场景僵尸的行类型
@export var ZombieRowTypewithMainScenesMap:Dictionary[EnumsMainScene.MainScenes, EnumsCharacter.ZombieRowType] = {
	EnumsMainScene.MainScenes.MainGameFront:EnumsCharacter.ZombieRowType.Land,
	EnumsMainScene.MainScenes.MainGameBack:EnumsCharacter.ZombieRowType.Both,
	EnumsMainScene.MainScenes.MainGameRoof:EnumsCharacter.ZombieRowType.Land,
}
