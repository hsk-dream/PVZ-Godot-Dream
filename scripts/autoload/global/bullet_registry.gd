extends Node
class_name BulletRegistry


@export var BulletTypeMap :Dictionary[EnumsBullet.BulletType, PackedScene]= {
	EnumsBullet.BulletType.Bullet001Pea : preload("res://scenes/bullet/bullet_001_pea.tscn"),
	EnumsBullet.BulletType.Bullet002PeaSnow : preload("res://scenes/bullet/bullet_002_pea_snow.tscn"),
	EnumsBullet.BulletType.Bullet003Puff : preload("res://scenes/bullet/bullet_003_puff.tscn"),
	EnumsBullet.BulletType.Bullet004Fume : preload("res://scenes/bullet/bullet_004_fume.tscn"),
	EnumsBullet.BulletType.Bullet005PuffLongTime : preload("res://scenes/bullet/bullet_005_puff_long_time.tscn"),
	EnumsBullet.BulletType.Bullet006PeaFire : preload("res://scenes/bullet/bullet_006_pea_fire.tscn"),
	EnumsBullet.BulletType.Bullet007Cactus : preload("res://scenes/bullet/bullet_007_cactus.tscn"),
	EnumsBullet.BulletType.Bullet008Star : preload("res://scenes/bullet/bullet_008_star.tscn"),

	EnumsBullet.BulletType.Bullet009Cabbage :preload("res://scenes/bullet/bullet_009_cabbage.tscn"),
	EnumsBullet.BulletType.Bullet010Corn :preload("res://scenes/bullet/bullet_010_corn.tscn"),
	EnumsBullet.BulletType.Bullet011Butter :preload("res://scenes/bullet/bullet_011_butter.tscn"),
	EnumsBullet.BulletType.Bullet012Melon :preload("res://scenes/bullet/bullet_012_melon.tscn"),

	EnumsBullet.BulletType.Bullet013Basketball :preload("res://scenes/bullet/bullet_013_basketball.tscn"),

	EnumsBullet.BulletType.Bullet014CattailBullet :preload("res://scenes/bullet/bullet_014_cattail_bullet.tscn"),
	EnumsBullet.BulletType.Bullet015WinterMelon :preload("res://scenes/bullet/bullet_015_winter_melon.tscn"),

	EnumsBullet.BulletType.Bullet016CobCannon :preload("res://scenes/bullet/bullet_016_cob_cannon.tscn"),
}

## 获取子弹场景方法
func get_bullet_scenes(bullet_type:EnumsBullet.BulletType) -> PackedScene:
	return BulletTypeMap.get(bullet_type)
