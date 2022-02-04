# pAttach
Optimized bone attach thanks to the new MTA functions/events.

This resource doesn't match with well known bone_attach, you can not use the same parameters!


# Performance Comparison
\- There is not so much similiar resources but I will run some performance tests on them.
CPU usages (Ryzen 5 2600), streamed-in/out attached objects to a ped, on default MTA server with play gamemode.

| Objects count | pAttach (in_stream) | pAttach (out_of_stream) | attachToBones (in_stream) | attachToBones (out_of_stream) | bone_attach (in_stream) | bone_attach (out_of_stream) |
| :------------ | :-----------------: | :---------------------: | :-----------------------: | :---------------------------: | :---------------------: | :-------------------------: |
| 10 objects    |        0.63%        |            -            |           0.84%           |             0.15%             |          1.64%          |            0.17%            |
| 100 objects   |        4.56%        |            -            |           6.44%           |             0.38%             |         12.82%          |            0.43%            |
| 500 objects   |       28.87%        |            -            |          36.91%           |             1.36%             |         69.40%          |            1.62%            |
| 1000 objects  |       46.34%        |            -            |          61.62%           |             2.60%             |         113.12%         |            3.11%            |


# Exported Functions (shared)

## **attach**
\- This function attaches an element to the bone of the ped or player.

```
bool attach(element Element, element Ped, int/string Bone [, float xPosOffset = 0, float yPosOffset = 0, float zPosOffset = 0, float xRotOffset = 0, float yRotOffset = 0, float zRotOffset = 0])
```

| Required arguments | Description                                                                                                   |
| :----------------- | :------------------------------------------------------------------------------------------------------------ |
| **Element**        | The element which you want to attach. (Except: player)                                                        |
| **Ped**            | The ped or player which you want to attach element to.                                                        |
| **Bone**           | The number (or name what you can find below) of the ped or player's bone which you want to attach element to. |

| Optional arguments | Description            |
| :----------------- | :--------------------- |
| **xPosOffset**     | The X position offset. |
| **yPosOffset**     | The Y position offset. |
| **zPosOffset**     | The Z position offset. |
| **xRotOffset**     | The X rotation offset. |
| **yRotOffset**     | The Y rotation offset. |
| **zRotOffset**     | The Z rotation offset. |

**Returns:** Returns true if element was successfully attached, false otherwise. (only on client side)

## **detach**
\- This function detaches an element from the bone of the ped or player.

```
bool detach(element Element)
```

| Required arguments | Description                             |
| :----------------- | :-------------------------------------- |
| **Element**        | The element which you want to detached. |

**Returns:** Returns true if element was successfully detached, false otherwise. (only on client side)


## **detachAll**
\- This function detaches every elements from the bone of the ped or player.

```
bool detachAll(element Ped)
```

| Required arguments | Description                                                       |
| :----------------- | :---------------------------------------------------------------- |
| **Ped**            | The ped or player from where you want to detaches every elements. |

**Returns:** Returns true if elements was successfully detached, false otherwise. (only on client side)


## **setPositionOffset**
\- This function changes position offset of attached element.

```
bool setPositionOffset(element Element [, float xPosOffset = 0, float yPosOffset = 0, float zPosOffset = 0 ])
```

| Required arguments | Description                                 |
| :----------------- | :------------------------------------------ |
| **Element**        | Element which you want to change offset of. |

| Optional arguments | Description   |
| :----------------- | :------------ |
| **xPosOffset**     | New X offset. |
| **yPosOffset**     | New Y offset. |
| **zPosOffset**     | New Z offset. |

**Returns:** Returns true if offset was successfully changed, false otherwise. (only on client side)


## **setRotationOffset**
\- This function changes rotation offset of attached element.

```
bool setRotationOffset(element Element [, float xRotOffset = 0, float yRotOffset = 0, float zRotOffset = 0 ])
```

| Required arguments | Description                                 |
| :----------------- | :------------------------------------------ |
| **Element**        | Element which you want to change offset of. |

| Optional arguments | Description   |
| :----------------- | :------------ |
| **xRotOffset**     | New X offset. |
| **yRotOffset**     | New Y offset. |
| **zRotOffset**     | New Z offset. |

**Returns:** Returns true if offset was successfully changed, false otherwise. (only on client side)


## **invisibleAll**
\- This function make visible or invisible every attached elements on ped or player.

```
bool invisibleAll(element Element, bool State)
```

| Required arguments | Description                                             |
| :----------------- | :------------------------------------------------------ |
| **Element**        | Element which you want to make visible or invisible.    |
| **State**          | Visibility status. (true = invisible / false = visible) |

**Returns:** Returns true if visibility was successfully changed, false otherwise.


## **isAttached**
\- This function check is element already attached or not.

```
bool isAttached(element Element)
```

| Required arguments | Description                      |
| :----------------- | :------------------------------- |
| **Element**        | Element which you want to check. |

**Returns:** Returns true if element is already attached, false otherwise.


## **getDetails**
\- This function gets details of attached element.

```
table getDetails(element Element)
```

| Required arguments | Description                      |
| :----------------- | :------------------------------- |
| **Element**        | Element which you want to check. |

**Returns:** Returns table with details (value order same as attach function's parameters, starts from Ped) if element exists and attached, false otherwise.


## **getAttacheds**
\- This function get attached elements which is attached to ped or player.

```
table getAttacheds(element Ped)
```

| Required arguments | Description                                           |
| :----------------- | :---------------------------------------------------- |
| **Ped**            | The ped or player to which the elements are attached. |

**Returns:** Returns a table of all the elements attached to the specified ped or player, false otherwise.

 
# How to use
\- Server sided example to attach backpack (parachute) to player's back.

```lua
addCommandHandler("testbackpack", function(player)
    local object = createObject(371, 0, 0, 0)
    exports.pAttach:attach(object, player, "backpack", 0, -0.15, 0, 90, 0, 0)
end)
```
 

# Known issues
\- There are desynchronization problems when attaching a player to ped or player.


# Bone IDs and Names
\- You can use the default bone IDs, or the bone-names which makes it easier to use.

| Bone ID | Bone Name                    | Description                                                                                     |
| :-----: | :--------------------------- | :---------------------------------------------------------------------------------------------- |
|  **1**  | **pelvis**                   | Pelvis                                                                                          |
|  **2**  | **pelvis2**                  | Pelvis 2                                                                                        |
|  **3**  | **spine (OR: backpack)**     | Spine                                                                                           |
|  **4**  | **neck**                     | Neck (upper torso)                                                                              |
|  **5**  | **neck2**                    | Neck 2                                                                                          |
|  **6**  | **head2**                    | Head 2                                                                                          |
|  **7**  | **head3**                    | Head 3                                                                                          |
|  **8**  | **head**                     | Head                                                                                            |
| **21**  | **right-upper-torso**        | Right upper torso                                                                               |
| **22**  | **right-shoulder**           | Right shoulder                                                                                  |
| **23**  | **right-elbow**              | Right elbow                                                                                     |
| **24**  | **right-wrist (OR: weapon)** | Right wrist                                                                                     |
| **25**  | **right-hand**               | Right hand (Note: use **right-wrist** instead if you want to attach something to player's hand) |
| **26**  | **right-thumb**              | Right thumb                                                                                     |
| **31**  | **left-upper-torso**         | Left upper torso                                                                                |
| **32**  | **left-shoulder**            | Left shoulder                                                                                   |
| **33**  | **left-elbow**               | Left elbow                                                                                      |
| **34**  | **left-wrist**               | Left wrist                                                                                      |
| **35**  | **left-hand**                | Left hand (Note: use **left-wrist** instead if you want to attach something to player's hand)   |
| **36**  | **left-thumb**               | Left thumb                                                                                      |
| **41**  | **left-hip**                 | Left hip                                                                                        |
| **42**  | **left-knee**                | Left knee                                                                                       |
| **43**  | **left-tankle**              | Left tangle                                                                                     |
| **44**  | **left-foot**                | Left foot                                                                                       |
| **51**  | **right-hip**                | Right hip                                                                                       |
| **52**  | **right-knee**               | Right knee                                                                                      |
| **53**  | **right-tankle**             | Right tankle                                                                                    |
| **54**  | **right-foot**               | Right foot                                                                                      |