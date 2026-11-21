extends RefCounted

static func get_weapons() -> Array:
    return [
        # WARDOGS-inspired arsenal: original game-ready tuning, not copied balance data.
        {"id":"a91","name":"A-91","class":"Assault Rifle","caliber":"5.56x45mm","damage":27,"rpm":700,"mag":30,"reserve":120,"reload":2.2,"range":350,"mode":"AUTO","profile":"rifle","sources":"WARDOGS"},
        {"id":"ak74","name":"AK-74","class":"Assault Rifle","caliber":"5.45x39mm","damage":28,"rpm":650,"mag":30,"reserve":120,"reload":2.4,"range":350,"mode":"AUTO","profile":"rifle","sources":"WARDOGS / ARMA"},
        {"id":"m17s","name":"Bushmaster M17S","class":"Assault Rifle","caliber":"5.56x45mm","damage":27,"rpm":700,"mag":30,"reserve":120,"reload":2.3,"range":330,"mode":"AUTO","profile":"bullpup","sources":"WARDOGS"},
        {"id":"fal","name":"FAL","class":"Battle Rifle","caliber":"7.62x51mm","damage":40,"rpm":600,"mag":20,"reserve":80,"reload":2.7,"range":450,"mode":"SEMI / AUTO","profile":"rifle","sources":"WARDOGS"},
        {"id":"galil","name":"Galil","class":"Assault Rifle","caliber":"5.56x45mm","damage":28,"rpm":650,"mag":35,"reserve":140,"reload":2.4,"range":350,"mode":"AUTO","profile":"rifle","sources":"WARDOGS"},
        {"id":"kh2002","name":"KH-2002","class":"Assault Rifle","caliber":"5.56x45mm","damage":27,"rpm":700,"mag":30,"reserve":120,"reload":2.2,"range":350,"mode":"AUTO","profile":"bullpup","sources":"WARDOGS"},
        {"id":"m4","name":"M4","class":"Assault Rifle","caliber":"5.56x45mm","damage":27,"rpm":800,"mag":30,"reserve":120,"reload":2.0,"range":400,"mode":"AUTO","profile":"rifle","sources":"WARDOGS"},
        {"id":"t21","name":"T-21","class":"Assault Rifle","caliber":"5.56x45mm","damage":28,"rpm":650,"mag":30,"reserve":120,"reload":2.2,"range":380,"mode":"AUTO","profile":"bullpup","sources":"WARDOGS"},
        {"id":"m14","name":"M14","class":"Marksman Rifle","caliber":".308 Win","damage":45,"rpm":350,"mag":20,"reserve":100,"reload":2.6,"range":550,"mode":"SEMI","profile":"dmr","sources":"WARDOGS"},
        {"id":"amp9","name":"AMP-9","class":"SMG","caliber":"9x19mm","damage":21,"rpm":900,"mag":30,"reserve":150,"reload":1.8,"range":100,"mode":"AUTO","profile":"smg","sources":"WARDOGS"},
        {"id":"mp5","name":"MP5","class":"SMG","caliber":"9x19mm","damage":22,"rpm":800,"mag":30,"reserve":150,"reload":1.9,"range":140,"mode":"AUTO","profile":"smg","sources":"WARDOGS"},
        {"id":"pp19bizon","name":"PP-19 Bizon","class":"SMG","caliber":"9x19mm","damage":22,"rpm":710,"mag":64,"reserve":192,"reload":3.0,"range":130,"mode":"AUTO","profile":"smg","sources":"WARDOGS"},
        {"id":"pp19","name":"PP-19 Vityaz","class":"SMG","caliber":"9x19mm","damage":21,"rpm":770,"mag":30,"reserve":150,"reload":2.0,"range":130,"mode":"AUTO","profile":"smg","sources":"WARDOGS"},
        {"id":"super45","name":"Super-45","class":"SMG","caliber":".45 ACP","damage":31,"rpm":1100,"mag":25,"reserve":100,"reload":2.0,"range":90,"mode":"AUTO","profile":"smg","sources":"WARDOGS"},
        {"id":"evo3","name":"Evo-3 Ultra","class":"Light Machine Gun","caliber":".308 Win","damage":33,"rpm":770,"mag":50,"reserve":200,"reload":4.0,"range":500,"mode":"AUTO","profile":"lmg","sources":"WARDOGS"},
        {"id":"bmr308","name":"BMR-308","class":"Marksman Rifle","caliber":".308 Win","damage":54,"rpm":300,"mag":20,"reserve":80,"reload":2.7,"range":600,"mode":"SEMI","profile":"dmr","sources":"WARDOGS"},
        {"id":"sks","name":"SKS","class":"Marksman Rifle","caliber":"7.62x39mm","damage":43,"rpm":300,"mag":10,"reserve":80,"reload":2.6,"range":400,"mode":"SEMI","profile":"dmr","sources":"WARDOGS"},
        {"id":"svd","name":"SVD","class":"Marksman Rifle","caliber":"7.62x54mmR","damage":55,"rpm":250,"mag":10,"reserve":60,"reload":2.8,"range":650,"mode":"SEMI","profile":"dmr","sources":"WARDOGS / ARMA"},
        {"id":"tcxspr","name":"TCX-SPR","class":"Assault Rifle","caliber":"7.62x39mm","damage":29,"rpm":785,"mag":30,"reserve":120,"reload":2.4,"range":350,"mode":"AUTO","profile":"rifle","sources":"WARDOGS"},
        {"id":"amr50","name":"AMR 50","class":"Sniper Rifle","caliber":".50 BMG","damage":95,"rpm":45,"mag":5,"reserve":25,"reload":3.8,"range":1000,"mode":"BOLT","profile":"sniper","sources":"WARDOGS"},
        {"id":"mk22","name":"MK22","class":"Sniper Rifle","caliber":".338 Lapua","damage":88,"rpm":50,"mag":5,"reserve":25,"reload":3.4,"range":900,"mode":"BOLT","profile":"sniper","sources":"WARDOGS"},
        {"id":"mosin","name":"Mosin Nagant","class":"Sniper Rifle","caliber":"7.62x54mmR","damage":78,"rpm":38,"mag":5,"reserve":30,"reload":3.5,"range":700,"mode":"BOLT","profile":"sniper","sources":"WARDOGS"},
        {"id":"scouttd","name":"Scout Rifle TD","class":"Sniper Rifle","caliber":".308 Win","damage":75,"rpm":55,"mag":5,"reserve":30,"reload":3.1,"range":750,"mode":"BOLT","profile":"sniper","sources":"WARDOGS"},
        {"id":"sv98","name":"SV-98","class":"Sniper Rifle","caliber":"7.62x54mmR","damage":80,"rpm":48,"mag":10,"reserve":40,"reload":3.3,"range":800,"mode":"BOLT","profile":"sniper","sources":"WARDOGS"},
        {"id":"m249","name":"M249 SAW","class":"Light Machine Gun","caliber":"5.56x45mm","damage":27,"rpm":750,"mag":100,"reserve":300,"reload":4.0,"range":500,"mode":"AUTO","profile":"lmg","sources":"WARDOGS / ARMA"},
        {"id":"pkm","name":"PKM","class":"Machine Gun","caliber":"7.62x54mmR","damage":42,"rpm":650,"mag":100,"reserve":300,"reload":4.2,"range":700,"mode":"AUTO","profile":"lmg","sources":"WARDOGS / ARMA"},
        {"id":"m60","name":"M60","class":"Machine Gun","caliber":"7.62x51mm","damage":42,"rpm":550,"mag":100,"reserve":200,"reload":4.4,"range":650,"mode":"AUTO","profile":"lmg","sources":"ARMA"},
        {"id":"uk59","name":"UK-59L","class":"Machine Gun","caliber":"7.62x54mmR","damage":40,"rpm":600,"mag":100,"reserve":300,"reload":4.3,"range":650,"mode":"AUTO","profile":"lmg","sources":"ARMA"},
        {"id":"deagle","name":"Deagle","class":"Pistol","caliber":".50 AE","damage":55,"rpm":180,"mag":7,"reserve":42,"reload":2.0,"range":100,"mode":"SEMI","profile":"pistol","sources":"WARDOGS"},
        {"id":"ggx17","name":"GGX 17","class":"Pistol","caliber":"9x19mm","damage":24,"rpm":300,"mag":17,"reserve":85,"reload":1.5,"range":65,"mode":"SEMI","profile":"pistol","sources":"WARDOGS"},
        {"id":"ggx18","name":"GGX 18","class":"Machine Pistol","caliber":"9x19mm","damage":21,"rpm":900,"mag":33,"reserve":132,"reload":1.8,"range":55,"mode":"AUTO","profile":"pistol","sources":"WARDOGS"},
        {"id":"judge","name":"Judge","class":"Revolver","caliber":".45 Colt","damage":45,"rpm":160,"mag":5,"reserve":30,"reload":2.4,"range":45,"mode":"SEMI","profile":"pistol","sources":"WARDOGS"},
        {"id":"m1911","name":"M1911","class":"Pistol","caliber":".45 ACP","damage":32,"rpm":240,"mag":8,"reserve":48,"reload":1.7,"range":60,"mode":"SEMI","profile":"pistol","sources":"WARDOGS"},
        {"id":"mp43","name":"MP43","class":"Shotgun","caliber":"12 Gauge","damage":80,"rpm":90,"mag":2,"reserve":24,"reload":2.8,"range":45,"mode":"PUMP / BREAK","profile":"shotgun","sources":"WARDOGS"},
        {"id":"m500","name":"M500","class":"Shotgun","caliber":"12 Gauge","damage":78,"rpm":75,"mag":6,"reserve":36,"reload":3.0,"range":55,"mode":"PUMP","profile":"shotgun","sources":"WARDOGS"},
        {"id":"mgl40","name":"MGL-40","class":"Grenade Launcher","caliber":"40mm","damage":100,"rpm":60,"mag":6,"reserve":18,"reload":3.8,"range":300,"mode":"REVOLVER","profile":"launcher","sources":"WARDOGS"},
        {"id":"rpg7","name":"RPG-7 / RPG-7V1","class":"Rocket Launcher","caliber":"PG-7 rocket","damage":180,"rpm":20,"mag":1,"reserve":4,"reload":3.5,"range":350,"mode":"SINGLE","profile":"launcher","sources":"WARDOGS / ARMA"},
        {"id":"maaws","name":"MAAWS","class":"Rocket Launcher","caliber":"84mm","damage":190,"rpm":18,"mag":1,"reserve":3,"reload":3.8,"range":500,"mode":"SINGLE","profile":"launcher","sources":"WARDOGS"},
        {"id":"verba","name":"9K333 Verba","class":"Anti-Air Launcher","caliber":"Missile","damage":200,"rpm":10,"mag":1,"reserve":2,"reload":4.0,"range":900,"mode":"LOCK-ON","profile":"launcher","sources":"WARDOGS"},
        {"id":"bow","name":"Compound Bow","class":"Bow","caliber":"Arrow","damage":70,"rpm":70,"mag":1,"reserve":12,"reload":1.2,"range":60,"mode":"SINGLE","profile":"bow","sources":"WARDOGS"},
        {"id":"m9","name":"M9","class":"Pistol","caliber":"9x19mm","damage":24,"rpm":300,"mag":15,"reserve":75,"reload":1.6,"range":60,"mode":"SEMI","profile":"pistol","sources":"ARMA"},
        {"id":"pm","name":"PM Makarov","class":"Pistol","caliber":"9x18mm","damage":25,"rpm":280,"mag":8,"reserve":48,"reload":1.8,"range":45,"mode":"SEMI","profile":"pistol","sources":"ARMA"},
        {"id":"m16carbine","name":"M16 Carbine","class":"Carbine","caliber":"5.56x45mm","damage":27,"rpm":750,"mag":30,"reserve":120,"reload":2.1,"range":300,"mode":"AUTO","profile":"rifle","sources":"ARMA"},
        {"id":"aks74u","name":"AKS-74U","class":"Carbine","caliber":"5.45x39mm","damage":27,"rpm":700,"mag":30,"reserve":120,"reload":2.2,"range":220,"mode":"AUTO","profile":"rifle","sources":"ARMA"},
        {"id":"m16a2","name":"M16A2","class":"Assault Rifle","caliber":"5.56x45mm","damage":28,"rpm":700,"mag":30,"reserve":120,"reload":2.2,"range":450,"mode":"BURST / SEMI","profile":"rifle","sources":"ARMA"},
        {"id":"sa58p","name":"Sa-58P","class":"Assault Rifle","caliber":"7.62x39mm","damage":37,"rpm":600,"mag":30,"reserve":120,"reload":2.5,"range":350,"mode":"AUTO","profile":"rifle","sources":"ARMA"},
        {"id":"m21","name":"M21 SWS","class":"Marksman Rifle","caliber":"7.62x51mm","damage":55,"rpm":250,"mag":20,"reserve":80,"reload":2.7,"range":650,"mode":"SEMI","profile":"dmr","sources":"ARMA"},
        {"id":"rpk74","name":"RPK-74","class":"Squad Automatic Weapon","caliber":"5.45x39mm","damage":28,"rpm":650,"mag":45,"reserve":180,"reload":3.3,"range":550,"mode":"AUTO","profile":"lmg","sources":"ARMA"},
        {"id":"m72law","name":"M72A3 LAW","class":"Anti-Armor Launcher","caliber":"66mm rocket","damage":170,"rpm":10,"mag":1,"reserve":1,"reload":4.0,"range":250,"mode":"SINGLE","profile":"launcher","sources":"ARMA"},
        {"id":"m203","name":"M203","class":"Underbarrel Grenade Launcher","caliber":"40mm","damage":100,"rpm":20,"mag":1,"reserve":4,"reload":2.8,"range":250,"mode":"SINGLE","profile":"launcher","sources":"ARMA"},
        {"id":"gp25","name":"GP-25","class":"Underbarrel Grenade Launcher","caliber":"40mm","damage":100,"rpm":20,"mag":1,"reserve":4,"reload":2.8,"range":200,"mode":"SINGLE","profile":"launcher","sources":"ARMA"},
        {"id":"rpg22","name":"RPG-22","class":"Anti-Armor Launcher","caliber":"72.5mm rocket","damage":160,"rpm":10,"mag":1,"reserve":1,"reload":4.0,"range":200,"mode":"SINGLE","profile":"launcher","sources":"ARMA"},
        {"id":"rpg75","name":"RPG-75","class":"Anti-Armor Launcher","caliber":"68mm rocket","damage":155,"rpm":10,"mag":1,"reserve":1,"reload":4.0,"range":180,"mode":"SINGLE","profile":"launcher","sources":"ARMA"}
    ]

static func find_weapon(weapon_id: String) -> Dictionary:
    for item in get_weapons():
        if item.get("id", "") == weapon_id:
            return item
    return get_weapons()[0]
