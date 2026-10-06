// Kaleidoscope wedge maths, shared by the wall painting and the scope view, so the wall shows exactly
// the scope's starting frame. The picture is cut into twelve wedges around its centre; wedge i shows
// the source turned by err * KALEIDO_MULT[i] plus a swirl that grows toward the rim (odd wedges
// optionally mirrored, like a real kaleidoscope). At err = 0 every wedge shows the unturned source,
// so the pieces join into the readable picture; one step off, they nearly do.

const float KALEIDO_MULT[12] = float[](1.0, -2.0, 3.0, -1.0, 2.0, -3.0, 2.0, -1.0, 3.0, -2.0, 1.0, -3.0);
const float KALEIDO_PI = 3.14159265359;
const float KALEIDO_WEDGE = 6.28318530718 / 12.0;
// Extra turn per unit of radius, times sin(err) (so a full turn still lines up): bends straight
// strokes into curves while it's off.
const float KALEIDO_SWIRL = 1.5;

// p: centred, |p| <= 1 covers the source's inscribed disk. err: radians. Returns the source uv.
vec2 kaleido_uv(vec2 p, float err, float mirror) {
	float a = atan(p.y, p.x) + KALEIDO_PI;
	float r = length(p);
	int i = int(floor(a / KALEIDO_WEDGE)) % 12;
	float local = mod(a, KALEIDO_WEDGE);
	if (mirror > 0.5 && (i % 2) == 1) {
		local = KALEIDO_WEDGE - local;
	}
	float a2 = float(i) * KALEIDO_WEDGE - KALEIDO_PI + local + err * KALEIDO_MULT[i] + sin(err) * KALEIDO_SWIRL * r;
	return vec2(cos(a2), sin(a2)) * r * 0.5 + 0.5;
}

// Distance (in p units) to the nearest wedge border, for the seam lines.
float kaleido_seam(vec2 p) {
	float local = mod(atan(p.y, p.x) + KALEIDO_PI, KALEIDO_WEDGE);
	return length(p) * sin(min(local, KALEIDO_WEDGE - local));
}

// The full look: far from aligned = mirrored ghosting and seam lines; aligned (err = 0) = the clean
// source. `glow` (0..1) brightens the centre for the solve flash.
vec3 kaleido_color(sampler2D source, vec2 p, float err, vec4 seam_color, float glow) {
	float off = 2.0 * abs(sin(err * 0.5)); // ~|err| near 0, and 0 again after a full turn.
	float m = smoothstep(0.0, 0.35, off);
	vec3 clean = texture(source, kaleido_uv(p, err, 0.0)).rgb;
	vec3 flip = texture(source, kaleido_uv(p, err, 1.0)).rgb;
	vec3 col = mix(clean, flip, 0.5 * m);
	float s = 1.0 - smoothstep(0.003, 0.009, kaleido_seam(p));
	col = mix(col, seam_color.rgb, s * smoothstep(0.0, 0.06, off) * seam_color.a);
	col += glow * 0.6 * (1.0 - smoothstep(0.0, 0.8, length(p)));
	return col;
}
