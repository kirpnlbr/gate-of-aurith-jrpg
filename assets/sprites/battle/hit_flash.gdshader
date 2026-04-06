shader_type canvas_item;

uniform bool flash_active = false;
uniform float flash_intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Magenta discard (residual from AI sprite generation)
	if (c.r > 0.85 && c.g < 0.2 && c.b > 0.85 && c.a > 0.1) {
		discard;
	}
	if (c.a > 0.0 && c.a < 0.15) {
		discard;
	}
	// White flash on hit
	if (flash_active && c.a > 0.1) {
		c.rgb = mix(c.rgb, vec3(1.0), flash_intensity);
	}
	COLOR = c;
}
