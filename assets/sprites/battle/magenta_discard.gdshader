shader_type canvas_item;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Discard near-magenta pixels (residual from AI sprite generation cleanup)
	if (c.r > 0.85 && c.g < 0.2 && c.b > 0.85 && c.a > 0.1) {
		discard;
	}
	// Also discard near-white/light gray border artifacts
	if (c.a > 0.0 && c.a < 0.15) {
		discard;
	}
	COLOR = c;
}
