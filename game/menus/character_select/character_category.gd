class_name CharacterCategory
extends Resource
## One step of the character select screen: a list of options the player cycles through.
## Add a category by saving a new .tres and appending it to CharacterSelect.categories, then
## listing its id in the EventManager's `steps`.

## Step id, used by the EventManager's `steps`, ConfirmLine.requires and CharacterSelect.random_preset.
@export var id: StringName
## Heading shown while choosing, e.g. "SELECT HAIRSTYLE".
@export var title := ""
## Draw order in the preview (higher is on top), independent of the step order.
@export var layer := 0
@export var options: Array[CharacterOption] = []
## Where the placeholder block is drawn in the preview (0-1 of its size) while an option has no texture.
@export var placeholder_region := Rect2(0, 0, 1, 1)
