shader_type spatial;
// The TWIST ME painting's canvas: the source picture (password + shards) cut into kaleidoscope wedges
// at the scope's starting twist, so on the wall it's an unreadable mandala.
#include "res://minigames/switch/kaleidoscope/kaleido.gdshaderinc"

uniform sampler2D source : source_color, filter_linear, repeat_disable;
// Twist error in radians (the wall shows the scope's start: -target).
uniform float err = 2.4;
// Where the canvas sits in the mesh's UVs (x, y, width, height): Painting.fbx's canvas is a sub-rect.
uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 seam_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);

void fragment() {
	vec2 uv = (UV - uv_rect.xy) / uv_rect.zw;
	// The disk's rim reaches the canvas corners, so the whole canvas is mandala.
	vec2 p = (uv * 2.0 - 1.0) * 0.7071;
	ALBEDO = kaleido_color(source, p, err, seam_color, 0.0);
	ROUGHNESS = 0.8;
}
