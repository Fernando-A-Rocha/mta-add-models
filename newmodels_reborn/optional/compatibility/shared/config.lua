-- Backwards compatibility with newmodels 3.3.0
-- Configurable variables

OLD_DATA_NAMES = {
    ped = "skinID",
    vehicle = "vehicleID",
    object = "objectID",
}
OLD_DATA_NAMES.pickup = OLD_DATA_NAMES.object
OLD_DATA_NAMES.player = OLD_DATA_NAMES.ped

OLD_BASE_DATA_NAME = "baseID"

LINKED_RESOURCES = {
	-- { name = "sampobj_reloaded", start = true, stop = true },
	-- { name = "vehicle_manager", start = true, stop = true },
}

-- NandoCrypt | https://github.com/Fernando-A-Rocha/mta-nandocrypt
-- The decrypt function needs to be named ncDecrypt inside a decrypter script (named nando_decrypter by default)
ENABLE_NANDOCRYPT = true
NANDOCRYPT_EXT = ".nandocrypt"
