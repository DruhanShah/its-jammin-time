shader_type canvas_item;
render_mode blend_mul;
// Emergency lighting for 2D close-ups: put it on a full-screen ColorRect above the scene. It
// multiplies everything under it by `tint` (white = normal light) and darkens the edges with a
// halftone vignette (Ben-Day dots that grow toward the corners). Pure maths, no screen reads.

uniform vec4 tint : source_color = vec4(1.0, 0.5, 0.45, 1.0);
// 0 = no vignette, 1 = full-strength dots.
uniform float vignette : hint_range(0.0, 1.0) = 0.7;
uniform vec4 dot_color : source_color = vec4(0.2, 0.04, 0.04, 1.0);
// Distance between dot centres, in pixels of the node.
uniform float cell_size = 14.0;

varying vec2 local_px;

void vertex() {
	local_px = VERTEX;
}

void fragment() {
	float a = radians(45.0);
	mat2 rot = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
	vec2 cell = fract(rot * local_px / cell_size) - 0.5;
	float t = clamp((length(UV - 0.5) * 1.6 - 0.4) / 0.6, 0.0, 1.0);
	float radius_px = t * 0.75 * cell_size;
	float ink = 1.0 - smoothstep(radius_px - 0.8, radius_px + 0.8, length(cell) * cell_size);
	COLOR = vec4(tint.rgb * mix(vec3(1.0), dot_color.rgb, ink * vignette), 1.0);
}
