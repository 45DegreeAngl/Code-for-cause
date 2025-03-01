shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float amplitude = 1;
uniform float frequency = 1;
uniform float height_mult = 1;

void fragment() {
	float x = sin((TIME*2.0*PI + SCREEN_UV.y * height_mult)*frequency) * amplitude;
	float y = sin((TIME*2.0*PI + SCREEN_UV.x * height_mult)*frequency) * amplitude;
	vec2 new_pos = clamp(SCREEN_UV + vec2(x,y), vec2(0,0), vec2(1,1));
	COLOR = textureLod(screen_texture, new_pos, 0.0);
}
void vertex() {
	// Called for every vertex the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
