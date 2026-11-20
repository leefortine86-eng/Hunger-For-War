
extends Node3D

@export var damage: float = 25.0
@export var fire_rate: float = 0.12
@export var magazine_size: int = 30
@export var reserve_ammo: int = 120

var ammo_in_magazine: int = 30
var can_fire: bool = true
var reloading: bool = false

func _ready():
    ammo_in_magazine = magazine_size

func fire(raycast: RayCast3D):
    if not can_fire or reloading:
        return

    if ammo_in_magazine <= 0:
        print("Magazine empty! Press R to reload.")
        return

    ammo_in_magazine -= 1
    can_fire = false

    raycast.force_raycast_update()

    if raycast.is_colliding():
        var target = raycast.get_collider()
        print("Hit: ", target.name)

        if target.has_method("take_damage"):
            target.take_damage(damage)
    else:
        print("Shot fired!")

    print("Ammo: ", ammo_in_magazine, "/", reserve_ammo)

    await get_tree().create_timer(fire_rate).timeout
    can_fire = true

func reload():
    if reloading or ammo_in_magazine == magazine_size:
        return

    if reserve_ammo <= 0:
        print("No reserve ammunition!")
        return

    reloading = true
    print("Reloading...")

    await get_tree().create_timer(2.0).timeout

    var needed = magazine_size - ammo_in_magazine
    var loaded = min(needed, reserve_ammo)

    ammo_in_magazine += loaded
    reserve_ammo -= loaded
    reloading = false

    print("Reload complete!")

