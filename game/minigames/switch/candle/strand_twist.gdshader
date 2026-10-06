shader_type spatial;
// One strand of the candle game's thread (a thin CylinderMesh of height `height`, centred on its
// origin). Each vertex is pushed sideways around the thread's axis by `spread`, at an angle that
// grows with height: three strands with phases 0/120/240° wind round each other into a wick as
// `twist` grows. Flat cotton colour.

uniform float twist = 0.0;
uniform float phase = 0.0;
uniform float spread = 0.004;
uniform float height = 0.12;
uniform vec4 color : source_color = vec4(0.93, 0.9, 0.8, 1.0);

void vertex() {
	float t = VERTEX.y / height + 0.5;
	float a = phase + twist * t;
	VERTEX.xz += vec2(cos(a), sin(a)) * spread;
}

void fragment() {
	ALBEDO = color.rgb;
	ROUGHNESS = 0.95;
}
