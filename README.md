# FS25_dlcBoatExtension

![Header](./docs/images/header.webp)

Extension mod for **Highlands Fishing Expansion DLC** Boat specialization.

- Allows players to buy DLC boats using in-game shop
- Enables lifting boats out of the water (lift vertically up)
- Disable boat water spray effects when it's out of the water (if applicable)
- Disable boat samples playing when it's out of the water (if applicable)
- Adds custom variation in store for both DLC boats using custom XML, improving handling
- Improves ShallowWaterSimulation render size for performance class High, Very High and Ultra
- Fixes issues with using boats on other maps than the DLC map
- Fixes multiplayer client issues

Using a mod enabling super strength is recommended.
Third party mods using the DLC Boat specialization are also supported.

And **YES**, you do need to own the DLC in order to use this extension mod.

NOTE: Due to game engine physics limitations, the movement of the boat when in water takes precedence.

## Placeables

This mod also enables several placeables to be placed by the player

- PlanET 500KW BGA
- Buying station manure
- Buying station liquid manure
- Buying station pig food

Allows following placeables to be used on other maps

- Offshore Aquaculture fish farm production

## How to download and install

Download the latest [```FS25_0_dlcBoatExtension.zip```](https://github.com/scfmod/FS25_dlcBoatExtension/releases/latest/download/FS25_0_dlcBoatExtension.zip) and copy/move it into your FS25 mods folder.

## Specializations

### AttachableBoatExtension

By adding this specialization when using the DLC Boat specialization it will allow the boat to safely attach and detach to a trailer (or similar applicable vehicles) while in water, if set up with base game Attachable specialization. No extra configuration needed.

NOTE: Important that the specialization is added after Boat specialization.

```xml
<vehicleTypes>
    <type ...>
        ...
        <specialization name="pdlc_highlandsFishingPack.boat" />
        <specialization name="FS25_0_dlcBoatExtension.attachableBoatExtension" />
        ...
    </type>
</vehicleTypes>
```

### BoatFillUnitExtension

Specialization to make sure that vehicles (Boat especially) with fillUnits set to updateMass="true" updates component mass correctly. When loading from savegame it will not always set mass correctly on component node, adding this specialization will make sure it updates correctly. No extra configuration needed.

```xml
<vehicleTypes>
    <type ...>
        ...
        <specialization name="pdlc_highlandsFishingPack.boat" />
        <specialization name="FS25_0_dlcBoatExtension.boatFillUnitExtension" />
        ...
    </type>
</vehicleTypes>
```

### BoatControlExtension

Enables toggling between multiple control modes for boats using custom input actions. E.g changing propeller force nodes, accelerationForce curve, steering parameters, acceleration parameters etc.

See [FS25_customExtensionBoats](https://github.com/scfmod/FS25_customExtensionBoats) mod for examples.

NOTE: Important that the specialization is added after Boat specialization.

```xml
<vehicleTypes>
    <type ...>
        ...
        <specialization name="pdlc_highlandsFishingPack.boat" />
        <specialization name="FS25_0_dlcBoatExtension.boatControlExtension" />
        ...
    </type>
</vehicleTypes>
```

## Info

### Reset spawn places for boats

In order to have a specific reset spawn place for boats on a map, there must be at least 1 placeable with following criterias:

- Implement vehicleBuyingStation specialization
- The XML filename must contain the name "boat"
- The placeable must have spawnPlaces

It will use the first valid placeable spawn place found, if not it will use the regular vehicle spawn place(s)

### Console commands

Toggle boat vehicle debug rendering useful for modding/inspecting various parameters

```gsBoatDebug```

## Screenshots

![Shop](./docs/images/boat_shop.webp)
![Multiplayer](./docs/images/boat_multiplayer.webp)
![Cargo Vessel](./docs/images/cargo_vessel.webp)