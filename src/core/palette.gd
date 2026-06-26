class_name Palette
extends RefCounted
## The DriftLands art direction in one place: a deliberate "ruined keep"
## palette — warm stone, bone, moss, rust, ember, and a single restrained gold
## accent. No neon, no purple. Every colour the game uses is named here so the
## whole look stays cohesive and can be retuned from a single file.

const INK := Color("16140f")        # deepest background / void
const STONE_DARK := Color("221f18")
const STONE := Color("3a3527")
const STONE_LIT := Color("574f3b")
const BONE := Color("d8c9a3")       # parchment / UI text
const BONE_LIT := Color("efe4c8")

const MOSS_DARK := Color("2c3f25")
const MOSS := Color("5d7d3a")
const LEAF := Color("9bb24c")

const RUST_DARK := Color("5e2a1b")
const RUST := Color("9c4527")
const EMBER := Color("d6743a")      # torchlight / fire
const GOLD := Color("e7b24c")       # the one accent — coins, legendary, focus

const BLOOD := Color("aa3a30")      # damage / enemy tint
const TEAL := Color("2f6f6a")       # cool accent (mana, water), used sparingly
const FROST := Color("8fb3ad")

const SHADOW := Color(0, 0, 0, 0.5)

## Loot rarity colours — earthy and legible, deliberately avoiding the
## neon-purple "epic" cliché (epic is burnt ember here, legendary is gold).
const RARITY := {
	"common": Color("b9ad8f"),
	"uncommon": Color("7fa64a"),
	"rare": Color("4f93a8"),
	"epic": Color("c8762f"),
	"legendary": Color("e7b24c"),
}


static func rarity_color(rarity: String) -> Color:
	return RARITY.get(rarity, RARITY["common"])
