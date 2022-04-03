--[[
	Author: Fernando

	_config.lua

	All global config variables are in this file:
]]

START_STOP_MESSAGES = true -- enable resouce start/stop automatic chat messages

SEE_ALLOCATED_TABLE = true -- automatically executes /allocatedids on startup

ENABLE_DEBUG_MESSAGES = true -- toggle all debug console messages

CHAT_DEBUG_MESSAGES = true -- make debug console messages to go chatbox (better readability imo)


----------- OPTIONAL CONFIGURATION -----------

-- NandoCrypt | https://github.com/Fernando-A-Rocha/mta-nandocrypt
	-- The decrypt function needs to be named ncDecrypt inside a decrypter script (named nando_decrypter by default)

	ENABLE_NANDOCRYPT = true

	NANDOCRYPT_EXT = ".nandocrypt"