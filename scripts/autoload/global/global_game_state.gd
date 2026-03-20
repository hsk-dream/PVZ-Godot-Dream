extends Node
class_name GlobalGameState

const DEFAULT_COIN_VALUE: int = 0
const DEFAULT_CURR_NUM_NEW_GARDEN_PLANT: int = 3
const DEFAULT_GARDEN_DATA: Dictionary = {
	"num_bg_page_0": 1,
	"num_bg_page_1": 1,
	"num_bg_page_2": 1,
}
const DEFAULT_CURR_ALL_LEVEL_STATE_DATA: Dictionary = {}
"""
## 一个关卡的游戏状态的例子
var curr_one_level_state_data:Dictionary = {
	"IsSuccess":false,
	"IsHaveMultiRoundSaveGameData":false,
	"CurrGameRound":1
}
"""
signal coin_value_changed(new_value: int)

var coin_value: int = DEFAULT_COIN_VALUE:
	set(value):
		coin_value = value
		coin_value_changed.emit(coin_value)

var curr_num_new_garden_plant: int = DEFAULT_CURR_NUM_NEW_GARDEN_PLANT
var garden_data: Dictionary = DEFAULT_GARDEN_DATA.duplicate(true)
var curr_all_level_state_data: Dictionary = DEFAULT_CURR_ALL_LEVEL_STATE_DATA.duplicate(true)
var selected_cards: Array = []

var curr_plant :Array[EnumsCharacter.PlantType]= [
	EnumsCharacter.PlantType.P001PeaShooterSingle,
	EnumsCharacter.PlantType.P002SunFlower,
	EnumsCharacter.PlantType.P003CherryBomb,
	EnumsCharacter.PlantType.P004WallNut,
	EnumsCharacter.PlantType.P005PotatoMine,
	EnumsCharacter.PlantType.P006SnowPea,
	EnumsCharacter.PlantType.P007Chomper,
	EnumsCharacter.PlantType.P008PeaShooterDouble,
	EnumsCharacter.PlantType.P009PuffShroom,
	EnumsCharacter.PlantType.P010SunShroom,
	EnumsCharacter.PlantType.P011FumeShroom,
	EnumsCharacter.PlantType.P012GraveBuster,
	EnumsCharacter.PlantType.P013HypnoShroom,
	EnumsCharacter.PlantType.P014ScaredyShroom,
	EnumsCharacter.PlantType.P015IceShroom,
	EnumsCharacter.PlantType.P016DoomShroom,
	EnumsCharacter.PlantType.P017LilyPad,
	EnumsCharacter.PlantType.P018Squash,
	EnumsCharacter.PlantType.P019ThreePeater,
	EnumsCharacter.PlantType.P020TangleKelp,
	EnumsCharacter.PlantType.P021Jalapeno,
	EnumsCharacter.PlantType.P022Caltrop,
	EnumsCharacter.PlantType.P023TorchWood,
	EnumsCharacter.PlantType.P024TallNut,
	EnumsCharacter.PlantType.P025SeaShroom,
	EnumsCharacter.PlantType.P026Plantern,
	EnumsCharacter.PlantType.P027Cactus,
	EnumsCharacter.PlantType.P028Blover,
	EnumsCharacter.PlantType.P029SplitPea,
	EnumsCharacter.PlantType.P030StarFruit,
	EnumsCharacter.PlantType.P031Pumpkin,
	EnumsCharacter.PlantType.P032MagnetShroom,
	EnumsCharacter.PlantType.P033CabbagePult,
	EnumsCharacter.PlantType.P034FlowerPot,
	EnumsCharacter.PlantType.P035CornPult,
	EnumsCharacter.PlantType.P036CoffeeBean,
	EnumsCharacter.PlantType.P037Garlic,
	EnumsCharacter.PlantType.P038UmbrellaLeaf,
	EnumsCharacter.PlantType.P039MariGold,
	EnumsCharacter.PlantType.P040MelonPult,
	EnumsCharacter.PlantType.P041GatlingPea,
	EnumsCharacter.PlantType.P042TwinSunFlower,
	EnumsCharacter.PlantType.P043GloomShroom,
	EnumsCharacter.PlantType.P044Cattail,
	EnumsCharacter.PlantType.P045WinterMelon,
	EnumsCharacter.PlantType.P046GoldMagnet,
	EnumsCharacter.PlantType.P047SpikeRock,
	EnumsCharacter.PlantType.P048CobCannon,
]

var curr_zombie :Array[EnumsCharacter.ZombieType]= [
	EnumsCharacter.ZombieType.Z001Norm,
	EnumsCharacter.ZombieType.Z002Flag,
	EnumsCharacter.ZombieType.Z003Cone,
	EnumsCharacter.ZombieType.Z004PoleVaulter,
	EnumsCharacter.ZombieType.Z005Bucket,
	EnumsCharacter.ZombieType.Z006Paper,
	EnumsCharacter.ZombieType.Z007ScreenDoor,
	EnumsCharacter.ZombieType.Z008Football,
	EnumsCharacter.ZombieType.Z009Jackson,
	EnumsCharacter.ZombieType.Z010Dancer,
	EnumsCharacter.ZombieType.Z011Duckytube,
	EnumsCharacter.ZombieType.Z012Snorkle,
	EnumsCharacter.ZombieType.Z013Zamboni,
	EnumsCharacter.ZombieType.Z014Bobsled,
	EnumsCharacter.ZombieType.Z015Dolphinrider,
	EnumsCharacter.ZombieType.Z016Jackbox,
	EnumsCharacter.ZombieType.Z017Balloon,
	EnumsCharacter.ZombieType.Z018Digger,
	EnumsCharacter.ZombieType.Z019Pogo,
	EnumsCharacter.ZombieType.Z020Yeti,
	EnumsCharacter.ZombieType.Z021Bungi,
	EnumsCharacter.ZombieType.Z022Ladder,
	EnumsCharacter.ZombieType.Z023Catapult,
	EnumsCharacter.ZombieType.Z024Gargantuar,
	EnumsCharacter.ZombieType.Z025Imp,
	EnumsCharacter.ZombieType.Z1001BobsledSingle,
]
