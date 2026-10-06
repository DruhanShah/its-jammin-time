shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
// The candle flame (the model's own flame mesh, re-based so its origin sits at the flame's foot):
// a bright core at the bottom fading to the tip colour, over-bright so the scene's glow blooms it.

uniform vec4 base_color : source_color = vec4(1.0, 0.95, 0.6, 1.0);
uniform vec4 tip_color : source_color = vec4(1.0, 0.45, 0.05, 1.0);
uniform float height = 1.0;
uniform float energy = 2.2;

varying float v_h;

void vertex() {
	v_h = clamp(VERTEX.y / height, 0.0, 1.0);
}

void fragment() {
	ALBEDO = mix(base_color.rgb, tip_color.rgb, smoothstep(0.1, 0.9, v_h)) * energy;
}
