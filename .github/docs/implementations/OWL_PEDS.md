# Using New-Models in OwlGaming

Unfinished guide. Feel free to contribute.

## Custom Peds

Example scripts that you need to adapt:

- Clientside peds in character selection screen [account/c_characters.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/account/c_characters.lua)
- Serverside character spawning [account/s_characters.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/account/s_characters.lua)
- Serverside player skin saving [saveplayer-system/s_saveplayer_system.lua](https://github.com/OwlGamingCommunity/MTA/blob/main/mods/deathmatch/resources/saveplayer-system/s_saveplayer_system.lua)

For new skin images used in the inventory, place them in [account/img](https://github.com/OwlGamingCommunity/MTA/tree/main/mods/deathmatch/resources/account/img) as ID.png with a minimum of 3 digits.

You will find a lot more scripts that need to be changed if you want to use new IDs to the maximum potential, for example:

- Shops/NPCs having custom skin IDs
- Supporting custom skins in the [clothes](https://github.com/OwlGamingCommunity/MTA/tree/main/mods/deathmatch/resources/clothes) system
- ...
