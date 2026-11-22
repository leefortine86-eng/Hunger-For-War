extends Node
## Runtime session state shared by scenes through the GameSession autoload.
## This manager keeps progress in memory while the application remains open.

var credits: int = 2500
var player_health: float = 100.0
var player_armor: float = 0.0
var weapon_id: String = ""
var magazine_ammo: int = 30
var reserve_ammo: int = 120

func spend_credits(amount: int) -> bool:
    if amount <= 0 or credits < amount:
        return false
    credits -= amount
    return true

func award_credits(amount: int) -> void:
    if amount > 0:
        credits += amount

func store_player_state(player: Node) -> void:
    if not is_instance_valid(player):
        return

    player_health = float(player.get("health"))
    player_armor = float(player.get("armor"))

    var weapon := player.get_node_or_null("Camera3D/Weapon")
    if weapon == null:
        return

    weapon_id = str(weapon.get("current_weapon_id"))
    magazine_ammo = int(weapon.get("ammo_in_magazine"))
    reserve_ammo = int(weapon.get("reserve_ammo"))

func restore_player_state(player: Node) -> void:
    if not is_instance_valid(player):
        return

    player.set("health", player_health)
    player.set("armor", player_armor)

    var weapon := player.get_node_or_null("Camera3D/Weapon")
    if weapon == null:
        return

    if not weapon_id.is_empty():
        weapon.call("equip_weapon_by_id", weapon_id)

    weapon.set("ammo_in_magazine", magazine_ammo)
    weapon.set("reserve_ammo", reserve_ammo)
