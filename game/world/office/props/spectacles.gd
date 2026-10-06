extends Node3D
## The ending's spectacles (iPoly3D's "Glasses", CC0). The model's frame is black, which vanishes on the
## black desk, so the frame and lenses get their own colours here. StoryStage places it in the ENDING
## step and listens to its Interactable.

@export var frame_color := Color("#e8453c")
@export var lens_color := Color(0.75, 0.9, 1.0, 0.45)


func _ready() -> void:
	var frame := StandardMaterial3D.new()
	frame.albedo_color = frame_color
	frame.roughness = 0.35
	var lens := StandardMaterial3D.new()
	lens.albedo_color = lens_color
	lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lens.roughness = 0.1
	lens.metallic_specular = 0.9
	for mesh: MeshInstance3D in $Model.find_children("*", "MeshInstance3D", true, false):
		mesh.set_surface_override_material(0, frame)
		if mesh.mesh.get_surface_count() > 1:
			mesh.set_surface_override_material(1, lens)
