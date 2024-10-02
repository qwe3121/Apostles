shader_type canvas_item;
render_mode unshaded;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform vec4 new_color : source_color;

uniform vec4 flash_color: source_color = vec4(1.0);
uniform float flash_modifier: hint_range(0.0, 1.0) = 0;

vec4 texturePointSmooth(sampler2D smp, vec2 uv, vec2 pixel_size)
{
	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);
	vec2 lxy = sqrt(ddx * ddx + ddy * ddy);

	vec2 uv_pixels = uv / pixel_size;

	vec2 uv_pixels_floor = round(uv_pixels) - vec2(0.5f);
	vec2 uv_dxy_pixels = uv_pixels - uv_pixels_floor;

	uv_dxy_pixels = clamp((uv_dxy_pixels - vec2(0.5f)) * pixel_size / lxy + vec2(0.5f), 0.0f, 1.0f);

	uv = uv_pixels_floor * pixel_size;

	return textureGrad(smp, uv + uv_dxy_pixels * pixel_size, ddx, ddy);
}

void fragment() {
	vec4 pixel_color = texture(TEXTURE, UV);
	if (flash_modifier > 0.0){
		if (COLOR.a > 0.0) {
			COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_modifier);
		}
	}
	else {
		if (pixel_color == color1 || pixel_color == color2){
			COLOR = new_color;
	}
	}
}