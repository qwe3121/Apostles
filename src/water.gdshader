shader_type canvas_item;

uniform float scale_y;
uniform float zoom_y;

void fragment() {
	float uv_height = SCREEN_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.y * 5.0;
	vec2 reflection_screen_uv = vec2(SCREEN_UV.x, SCREEN_UV.y + uv_height * UV.y * scale_y);
	vec4 reflection = textureLod(SCREEN_TEXTURE, reflection_screen_uv, 0.0);
	COLOR = reflection;
}
