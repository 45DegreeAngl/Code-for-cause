// NOTE: Shader automatically converted from Godot Engine 4.4.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// -- WIND PARAMETERS (New Uniforms) --
group_uniforms wind;
uniform float wind_strength : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float wind_speed : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float wind_rustle_scale : hint_range(0.1, 10.0, 0.1) = 4.0;
uniform float wind_phase_variation : hint_range(0.0, 5.0, 0.1) = 2.0;

// -- Original Uniforms --
group_uniforms material;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	// -- Original UV transform --
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	// -- WIND SWAY LOGIC (New Code) --
	// INSTANCE_CUSTOM.x will be a random value unique to each leaf.
	// This breaks up the synchronized movement.
	float instance_random = INSTANCE_CUSTOM.x;

	// Calculate time with variations for speed and per-instance offset.
	float time = (TIME * wind_speed) + (instance_random * wind_phase_variation);

	// Create two sine waves for a more complex, natural rustle.
	// We use the vertex's X and Z position to make the rustle vary across the leaf's surface.
	float rustle = sin(time + VERTEX.x * wind_rustle_scale) + cos(time * 0.5 + VERTEX.z * wind_rustle_scale);

	// Calculate the final wind effect strength.
	// We multiply by UV.y so that the base of the leaf (where UV.y is 0) stays attached
	// to the branch, and the tip (where UV.y is 1) moves the most.
	float strength = rustle * wind_strength * UV.y;

	// Apply the offset to the vertex position.
	// Here, we're pushing the vertex along the X-axis in Model Space.
	VERTEX.x += strength;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
}
