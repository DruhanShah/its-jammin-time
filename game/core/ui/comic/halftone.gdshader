shader_type canvas_item;
// Ben-Day dots (comic halftone) for backgrounds: a rotated grid of round dots on a paper colour whose
// size follows a linear or radial gradient. Pure maths on the node's own pixel coordinates, no
// textures or screen reads, so it is cheap and works in the Compatibility renderer.
// Use it on a ColorRect (or any Control/Sprite2D) through a ShaderMaterial.

uniform vec4 paper_color : source_color = vec4(0.53, 0.8, 0.98, 1.0);
uniform vec4 dot_color : source_color = vec4(0.33, 0.62, 0.93, 1.0);
// Distance between dot centres, in pixels of the node.
uniform float cell_size = 16.0;
uniform float angle_degrees = 45.0;
// Dot diameter as a fraction of the cell at the small and the big end of the gradient (>1 merges dots).
uniform float min_size : hint_range(0.0, 1.5) = 0.12;
uniform float max_size : hint_range(0.0, 1.5) = 0.9;
// Linear gradient direction in UV space (dots grow toward it).
uniform vec2 gradient_direction = vec2(0.3, 1.0);
// 0 = linear gradient, 1 = radial (dots grow away from the centre).
uniform float radial : hint_range(0.0, 1.0) = 0.0;
// Edge softness in pixels (anti-aliasing).
uniform float softness = 0.8;

varying vec2 local_px;

void vertex() {
	local_px = VERTEX;
}

void fragment() {
	float a = radians(angle_degrees);
	mat2 rot = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
	vec2 cell = fract(rot * local_px / cell_size) - 0.5;
	float dist_px = length(cell) * cell_size;
	vec2 centred = UV - 0.5;
	float t_linear = clamp(dot(centred, normalize(gradient_direction)) + 0.5, 0.0, 1.0);
	float t_radial = clamp(length(centred) * 1.6, 0.0, 1.0);
	float t = mix(t_linear, t_radial, radial);
	float radius_px = mix(min_size, max_size, t) * 0.5 * cell_size;
	float ink = 1.0 - smoothstep(radius_px - softness, radius_px + softness, dist_px);
	COLOR = vec4(mix(paper_color.rgb, dot_color.rgb, ink * dot_color.a), paper_color.a);
}
