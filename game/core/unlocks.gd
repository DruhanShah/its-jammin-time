class_name Unlocks
## Every unlock id in the game, in one place. Internal only; the player never sees these.
## Use them in code, e.g. `GameState.unlock(Unlocks.GENIE_LAMP)`; `Interactable.unlock_id` offers them in a dropdown.
## Ids are snake_case names of the thing. Add new ones here and to ALL.

const GENIE_LAMP := &"genie_lamp"
const SWITCHBOARD := &"switchboard"
const BINOCULARS := &"binoculars"
const GLASSES := &"glasses"

## Comma-separated, for the Inspector dropdown and the typo check.
const ALL := GENIE_LAMP + "," + SWITCHBOARD + "," + BINOCULARS + "," + GLASSES


static func has(id: StringName) -> bool:
	return id in ALL.split(",")
