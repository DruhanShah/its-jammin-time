shader_type canvas_item;
// The scope view: the wall painting's wedges, full screen through a round eyepiece. Samples the
// painting's source texture directly (no screen read), so it's exact, cheap and WebGL2-safe.
#include "res://minigames/switch/kaleidoscope/kaleido.gdshaderinc"

uniform sampler2D source : filter_linear, repeat_disable;
uniform float err = 0.0;
uniform float glow = 0.0;
// Node width / height, so the eyepiece stays round.
uniform float aspect = 1.7778;
// Eyepiece radius as a fraction of the node's height.
uniform float radius = 0.46;
uniform vec4 seam_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
// Light on the picture (the office is on emergency lighting).
uniform vec4 tint : source_color = vec4(1.0, 0.9, 0.84, 1.0);

void fragment() {
	vec2 q = (UV - 0.5) * vec2(aspect, 1.0) / radius;
	float r = length(q);
	// Same framing as the wall: the source's inscribed disk reaches its corners there.
	vec3 col = kaleido_color(source, q * 0.7071, err, seam_color, glow) * tint.rgb;
	col *= 1.0 - 0.5 * smoothstep(0.65, 1.0, r); // Lens vignette toward the rim.
	float inside = 1.0 - smoothstep(0.99, 1.0, r);
	COLOR = vec4(col * inside, 1.0);
}
