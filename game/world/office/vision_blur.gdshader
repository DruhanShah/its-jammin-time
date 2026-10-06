shader_type canvas_item;
// Short-sighted vision for the ending (see vision_blur.gd): a disc blur of everything drawn below
// this CanvasLayer (the 3D office), plus an optional pair of spectacles sliding down over the eyes.
// Inside the lenses the view is sharp, outside it stays blurry; the frame is drawn as a comic outline.
// Compatibility/WebGL2-safe: one screen read per tap (no mipmaps, no loops over variable counts).

uniform sampler2D screen : hint_screen_texture, filter_linear, repeat_disable;
// 0 = sharp, 1 = fully blurred.
uniform float blur : hint_range(0.0, 1.0) = 0.0;
// Blur radius at blur = 1, as a fraction of the screen height (so it looks the same at any resolution).
uniform float radius = 0.014;
// Spectacles: 0 = above the screen (not drawn), 1 = in front of the eyes.
uniform float glasses : hint_range(0.0, 1.0) = 0.0;
uniform vec4 frame_color : source_color = vec4(0.07, 0.06, 0.08, 1.0);

const int TAPS = 24;
const float GOLDEN_ANGLE = 2.39996323;

// Signed distance to a rounded box centred at the origin.
float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec3 blurred(vec2 uv, float amount, vec2 px) {
	vec3 sum = texture(screen, uv).rgb;
	float total = 1.0;
	float r = radius * amount;
	vec2 scale = vec2(r * px.x / px.y, r);
	for (int i = 1; i < TAPS; i++) {
		float k = float(i);
		float d = sqrt(k / float(TAPS));
		float a = k * GOLDEN_ANGLE;
		sum += texture(screen, uv + vec2(cos(a), sin(a)) * d * scale).rgb;
		total += 1.0;
	}
	return sum / total;
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	float aspect = px.y / px.x;
	// Centred coordinates, y down, height = 1.
	vec2 p = (SCREEN_UV - 0.5) * vec2(aspect, 1.0);
	// The spectacles hang from above and settle on the eye line.
	float drop = (1.0 - glasses) * -1.15;
	vec2 g = p - vec2(0.0, drop + 0.03);
	vec2 lens_half = vec2(min(0.36, aspect * 0.23), 0.25);
	float lens_x = lens_half.x + 0.05;
	float d_left = rounded_box(g - vec2(-lens_x, 0.0), lens_half, 0.13);
	float d_right = rounded_box(g - vec2(lens_x, 0.0), lens_half, 0.13);
	float d_lens = min(d_left, d_right);
	float aa = px.y * 1.5;
	float in_lens = (1.0 - smoothstep(-aa, aa, d_lens)) * step(0.001, glasses);
	float thickness = 0.03;
	float on_rim = (1.0 - smoothstep(thickness * 0.5 - aa, thickness * 0.5 + aa, abs(d_lens)));
	float d_bridge = rounded_box(g - vec2(0.0, -0.08), vec2(0.07, 0.016), 0.012);
	float on_bridge = 1.0 - smoothstep(-aa, aa, d_bridge);
	float frame = max(on_rim, on_bridge) * step(0.001, glasses);

	float amount = mix(blur, 0.0, in_lens);
	vec3 col = amount > 0.01 ? blurred(SCREEN_UV, amount, px) : texture(screen, SCREEN_UV).rgb;
	// Outside the lenses (once they're on) the world is a little darker, so the eye goes to the lenses.
	col *= mix(1.0, 0.72, glasses * (1.0 - in_lens));
	// A comic glint across each lens.
	vec2 lp = g - vec2(sign(g.x) * lens_x, 0.0);
	float glint = smoothstep(0.012, 0.0, abs(lp.x + lp.y * 0.8 + 0.12)) * step(lp.y, -0.06) * in_lens;
	col = mix(col, vec3(1.0), glint * 0.35);
	col = mix(col, frame_color.rgb, frame);
	COLOR = vec4(col, 1.0);
}
