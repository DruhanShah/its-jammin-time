shader_type spatial;
render_mode unshaded, cull_back;
// Electricity as a glowing liquid inside a pipe's glass section (valve game). The mesh is a
// CylinderMesh (along its local Y); `fill` cuts it off along its length, `flow` sets speed + glow.

uniform float fill : hint_range(0.0, 1.0) = 1.0; // How far along the pipe the electricity has got.
uniform float flow : hint_range(0.0, 1.0) = 0.0; // Speed and brightness.
uniform float half_length = 0.2; // CylinderMesh height / 2.
uniform float from_top = 1.0; // 1: fills (and flows) from the +Y end, 0: from the -Y end.
uniform vec4 color : source_color = vec4(0.6, 0.9, 1.0, 1.0);

varying float along;

void vertex() {
	float a = VERTEX.y / (2.0 * half_length) + 0.5;
	along = mix(a, 1.0 - a, from_top);
}

void fragment() {
	if (along > fill) {
		discard;
	}
	float bands = 0.5 + 0.5 * sin((along * 9.0 - TIME * (0.4 + 3.0 * flow)) * 6.2832);
	float boil = 0.5 + 0.5 * sin(UV.x * 37.7 + TIME * 7.0 + along * 30.0);
	float front = smoothstep(0.0, 0.04, fill - along); // A bright, frothy leading edge.
	ALBEDO = color.rgb * (0.45 + 1.1 * flow) * (0.7 + 0.4 * bands + 0.15 * boil) + vec3(0.6) * (1.0 - front) * step(fill, 0.995);
}
