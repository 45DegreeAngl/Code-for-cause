shader_type canvas_item;
//render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
//uniform float amplitude = 1;
//uniform float frequency = 1;
//uniform float height_mult = 1;
uniform float waveX = 1;
uniform float waveY = 1;
uniform float uvScaleX = 1;
uniform float uvScaleY = 1;
uniform float drunkScale = 1;

void fragment() {
	//float x = sin((TIME*2.0*PI + SCREEN_UV.y * height_mult)*frequency) * amplitude;
	//float y = sin((TIME*2.0*PI + SCREEN_UV.x * height_mult)*frequency) * amplitude;
	//vec2 new_pos = clamp(SCREEN_UV + vec2(x,y), vec2(0,0), vec2(1,1));
	//COLOR = textureLod(screen_texture, new_pos, 0.0);

	//create reduced shader distortion at edges to reduce stretching effect
	float sinWave = sin(SCREEN_UV.y * waveY + TIME) + sin(SCREEN_UV.x * waveX + TIME);
	vec2 screenResolution = vec2(1,1)/SCREEN_PIXEL_SIZE;
	vec2 edgeDistance = vec2(min(SCREEN_UV.x, 1.0 - SCREEN_UV.x), min(SCREEN_UV.y, 1.0 - SCREEN_UV.y));
	vec2 waveUV = vec2(SCREEN_UV.x + sinWave * uvScaleX * edgeDistance.x, SCREEN_UV.y + sinWave * uvScaleY * edgeDistance.y);

	COLOR = textureLod(screen_texture, waveUV, 0.0);
}
void vertex() {
	// Called for every vertex the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
