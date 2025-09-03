// Starry Sky Shader for Godot 4.x
// This shader creates a procedural skybox with twinkling and slowly moving stars.
// The rotation is based on a real-world sidereal day.
shader_type sky;

// Uniforms allow you to adjust the sky's appearance from the Inspector in Godot.
uniform vec4 night_sky_color : source_color = vec4(0.05, 0.0, 0.15, 1.0); // Dark blue/purple for the sky
uniform vec4 star_color : source_color = vec4(1.0, 1.0, 0.95, 1.0);     // Slightly yellowish-white for stars
uniform sampler2D noise_texture : hint_default_white;                   // Noise texture for star placement (e.g., FastNoiseLite)
uniform int star_layers : hint_range(1, 8, 1) = 3;                       // Number of parallax star layers for depth
uniform float star_density : hint_range(0.0, 1.0) = 0.95;               // Controls the brightness threshold for stars to appear
uniform float star_sharpness : hint_range(10.0, 500.0) = 200.0;         // How sharp/point-like the noise-based stars are
uniform float twinkle_speed : hint_range(0.0, 3.0) = 1.0;               // How fast the stars twinkle (lower is a gentle shimmer)
uniform float twinkle_intensity : hint_range(0.0, 1.0) = 0.5;           // The brightness variation of the twinkle

// This uniform should be updated from a script with the real-world time.
// Default value is set to 58920.0, which is 4:22 PM (16*3600 + 22*60).
uniform float real_time_seconds : hint_range(0.0, 86400.0) = 58920.0;

// Function to create a single layer of stars using a noise texture.
float star_layer(vec3 p, float size) {
	// We map the 3D direction vector 'p' to a 2D texture coordinate.
	// Using .xz is a simple cylindrical projection. The 'size' parameter
	// scales the coordinates to sample different "zoom levels" of the noise for each layer.
	vec2 uv = p.xz * size;

	// Sample the red channel of the noise texture.
	float noise_val = texture(noise_texture, uv).r;

	// To turn the smooth noise into sharp points, we raise it to a high power.
	float star_brightness = pow(noise_val, star_sharpness);
	
	// We use density to filter out the dimmer points.
	if (star_brightness < (1.0 - star_density)) {
		return 0.0;
	}

	// For an individualized twinkle, we need a unique value per star.
	float twinkle_seed = texture(noise_texture, uv).g;
	
	// Apply twinkling effect based on time and the twinkle_seed.
	float twinkle = 0.5 + 0.5 * sin((TIME * twinkle_speed) + twinkle_seed * 100.0);
	twinkle = mix(1.0, twinkle, twinkle_intensity);

	// The final brightness is a combination of the sharpened noise value and the twinkle effect.
	return star_brightness * 50.0 * twinkle;
}


void sky() {
	// `SKY_COORDS` is a vec2. We must convert these 2D equirectangular UVs 
	// into a 3D direction vector for our calculations.
	
	// Convert UVs to spherical coordinates (theta: polar, phi: azimuthal)
	float theta = SKY_COORDS.y * PI;
	float phi = SKY_COORDS.x * 2.0 * PI;

	// Convert spherical coordinates to a 3D direction vector
	vec3 dir;
	dir.y = cos(theta);
	dir.x = sin(theta) * sin(phi);
	dir.z = sin(theta) * cos(phi);

	// Base color of the sky.
	vec4 final_color = night_sky_color;
	
	// --- Real-time Rotation Calculation ---
	// A sidereal day is the time it takes for stars to return to the same position.
	const float SIDEREAL_DAY_SECONDS = 86164.09; 
	// Calculate how far through the day we are (0.0 to 1.0).
	float rotation_progress = real_time_seconds / SIDEREAL_DAY_SECONDS;
	// Convert that progress into a rotation angle.
	float angle = rotation_progress * 2.0 * PI;
	mat2 rotation_matrix = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));

	// Loop to create multiple layers of stars with different sizes and speeds
	for (int i = 1; i <= star_layers; i++) {
		float i_float = float(i);

		vec3 rotated_dir = dir;
		// All stars rotate together in the real sky.
		rotated_dir.xz = rotation_matrix * rotated_dir.xz;

		// Star size and brightness decrease for layers further away, creating a depth effect.
		float size = 50.0 * i_float;
		float brightness = 1.0 / i_float;

		// Generate the star layer and add it to the final color.
		final_color.rgb += star_layer(rotated_dir, size) * star_color.rgb * brightness;
	}

	// Set the final color and alpha for the skybox.
	COLOR = final_color.rgb;
	ALPHA = final_color.a;
}

