shader_type sky;

// -- Sky Settings --
uniform vec4 sky_color : source_color = vec4(0.05, 0.08, 0.15, 1.0);

// -- Moon Settings --
uniform sampler2D moon_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float moon_rotation_x_deg : hint_range(-90.0, 90.0, 0.1) = 30.0;
uniform float moon_rotation_y_deg : hint_range(-180.0, 180.0, 0.1) = -45.0;
// ** CHANGE: Phase range is now 0 to 31 for a full lunar cycle. **
uniform int moon_phase_int : hint_range(0, 31, 1) = 0; // 0:New, 8:FirstQ, 16:Full, 24:LastQ
uniform float moon_size : hint_range(0.0, 0.2, 0.001) = 0.05;
uniform vec2 moon_tex_rotation = vec2(0.0, 0.0); // X and Y rotation in radians
uniform float moon_glow_strength : hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float moon_glow_falloff : hint_range(1.0, 8.0, 0.1) = 3.5;
uniform vec4 moon_glow_color : source_color = vec4(0.8, 0.85, 1.0, 1.0);

// -- Star Settings --
uniform float star_density : hint_range(0.0, 0.2, 0.001) = 0.002; // Higher is more stars
uniform float star_glow_falloff : hint_range(1.0, 5.0, 0.1) = 2.0;
uniform float twinkle_speed : hint_range(0.0, 10.0, 0.1) = 1.5;
uniform float twinkle_intensity : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform vec4 star_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);


//================================//
//      UTILITY FUNCTIONS         //
//================================//

mat2 rotate(float angle) {
	return mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

//================================//
//        MAIN SKY FUNCTION       //
//================================//

void sky() {
	vec3 dir = EYEDIR;

	// --- STAR CALCULATION (PROCEDURAL) ---
	vec2 star_uv = vec2(atan(dir.x, dir.z) / (PI * 2.0) + 0.5, acos(dir.y) / PI);
	vec2 star_grid_uv = star_uv * vec2(2000.0, 1000.0);
	vec2 cell_id = floor(star_grid_uv);
	vec2 cell_uv = fract(star_grid_uv) - 0.5;
	float star_seed = hash(cell_id);
	vec3 final_stars = vec3(0.0);
	if (star_seed < star_density) {
		vec2 star_pos_offset = vec2(hash(cell_id.yx) - 0.5, hash(cell_id.xy) - 0.5) * 0.8;
		float dist_to_star = length(cell_uv - star_pos_offset);
		float star_core = smoothstep(0.03, 0.0, dist_to_star);
		float star_glow = smoothstep(0.3, 0.0, dist_to_star);
		star_glow = pow(star_glow, star_glow_falloff);
		float twinkle1 = sin(TIME * twinkle_speed * (star_seed * 5.0) + star_seed * 6.28);
		float twinkle2 = sin(TIME * twinkle_speed * 0.3 * (hash(cell_id * 1.2) * 5.0) + hash(cell_id.yx) * 6.28);
		float twinkle = mix(1.0 - twinkle_intensity, 1.0, (twinkle1 * twinkle2 * 0.5 + 0.5));
		float brightness = hash(cell_id.yx) * 0.5 + 0.5;
		final_stars = (star_core + star_glow * 0.5) * star_color.rgb * twinkle * brightness;
	}
	
	// --- MOON CALCULATION ---
	float rot_x_rad = radians(moon_rotation_x_deg);
	float rot_y_rad = radians(moon_rotation_y_deg);
	vec3 norm_moon_dir;
	norm_moon_dir.y = sin(rot_x_rad);
	float h_len = cos(rot_x_rad);
	norm_moon_dir.x = h_len * sin(rot_y_rad);
	norm_moon_dir.z = h_len * -cos(rot_y_rad);
	
	float moon_dot = dot(dir, norm_moon_dir);
	float moon_disk = smoothstep(1.0 - moon_size, 1.0 - moon_size + 0.001, moon_dot);

	vec3 final_moon_color = vec3(0.0);
	vec3 final_moon_glow = vec3(0.0);
	float final_moon_mask = 0.0;

	if (moon_disk > 0.0) {
		vec3 moon_up_ref = abs(norm_moon_dir.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		vec3 moon_right = normalize(cross(norm_moon_dir, moon_up_ref));
		vec3 moon_up = normalize(cross(moon_right, norm_moon_dir));
		vec3 p = normalize(dir - norm_moon_dir * moon_dot);
		vec2 moon_uv = vec2(dot(p, moon_right), dot(p, moon_up)) / (moon_size * 2.0) + 0.5;
		
		moon_uv -= 0.5;
		moon_uv = rotate(moon_tex_rotation.y) * moon_uv;
		moon_uv = rotate(moon_tex_rotation.x) * moon_uv;
		moon_uv += 0.5;

		vec3 moon_albedo = vec3(0.0);
		if (moon_uv.x > 0.0 && moon_uv.x < 1.0 && moon_uv.y > 0.0 && moon_uv.y < 1.0){
			moon_albedo = texture(moon_texture, moon_uv).rgb;
		}

		vec3 point_on_sphere = dir * moon_dot - norm_moon_dir;
		vec3 moon_normal = normalize(norm_moon_dir + point_on_sphere / moon_size);
		
		float phase;
		
		// ** CHANGE: Updated special cases and angle math for the 0-31 range. **
		if (moon_phase_int == 0) {
			phase = 0.0; // New Moon is completely dark/invisible.
		} else if (moon_phase_int == 16) {
			phase = 1.0; // Full Moon is completely lit.
		} else {
			// This angle maps the 32 phases to a full 360-degree circle.
			float phase_angle = (float(moon_phase_int) / 16.0) * PI; 
			vec3 phase_light_dir = -norm_moon_dir * cos(phase_angle) + moon_right * sin(phase_angle);
			float phase_lighting = dot(moon_normal, phase_light_dir);
			phase = smoothstep(-0.02, 0.02, phase_lighting);
		}

		final_moon_color = moon_albedo;
		final_moon_mask = moon_disk * phase;
		
		float glow_disk = smoothstep(1.0 - (moon_size * (1.0 + moon_glow_strength * 0.2)), 1.0 - moon_size, moon_dot);
		final_moon_glow = pow(glow_disk, moon_glow_falloff) * moon_glow_color.rgb * moon_glow_strength;
		final_moon_glow *= phase;
	}

	// --- FINAL COMPOSITION ---
	vec3 color = sky_color.rgb + final_stars;
	color = mix(color, final_moon_color, final_moon_mask);
	color += final_moon_glow;
	
	COLOR = color;
}