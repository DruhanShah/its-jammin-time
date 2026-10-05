shader_type spatial;
// Subtle highlight drawn over a targeted prop (set as its MeshInstance3Ds' material_overlay).
// Adds a faint warm tint plus a brighter rim at grazing angles, gently pulsing. Cheap: one extra unshaded pass.
render_mode unshaded, blend_add, depth_draw_never, cull_back, fog_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.9, 0.7);
uniform float tint = 0.07; // Flat brightness added everywhere.
uniform float rim = 0.4; // Extra brightness at the silhouette edges.
uniform float rim_power = 2.5;
uniform float pulse_speed = 3.0;

void fragment() {
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
	ALBEDO = color * (tint + rim * edge) * pulse;
}
