shader_type spatial;

// --- Parameters you can edit in the Inspector ---

// This will hold our NoiseTexture2D resource.
uniform sampler2D noise_texture : source_color, hint_default_black;

// Controls the overall height of the hills.
uniform float height_scale : hint_range(0.0, 1.0, 0.01) = 0.2;
// Controls the "zoom" of the noise. Higher values = more, smaller hills.
uniform float noise_scale : hint_range(1.0, 20.0) = 5.0;

// Sets the color for the lowest points (valleys).
uniform vec4 low_color : source_color = vec4(0.2, 0.5, 0.1, 1.0); // Dark Green
// Sets the color for the highest points (peaks).
uniform vec4 high_color : source_color = vec4(0.4, 0.6, 0.2, 1.0); // Light Green

// A variable to pass the calculated height from the vertex to the fragment function.
varying float v_height_factor;


void vertex() {
	vec2 noise_uv = UV * noise_scale;

	// Get noise from the texture. The value is in the red (.r) channel and ranges from 0.0 to 1.0.
	float height_01 = texture(noise_texture, noise_uv).r;

	// Convert the 0-1 range to a -1 to 1 range for more natural displacement up and down.
	float height_signed = (height_01 * 2.0) - 1.0;

	// Pass the 0-1 height value to the fragment shader for coloring.
	v_height_factor = height_01;

	// Apply the height to the vertex's Y position, scaled by our height_scale.
	VERTEX.y += height_signed * height_scale;
}

void fragment() {
	// The v_height_factor is already in the 0.0 to 1.0 range, perfect for mix().
	vec3 final_color = mix(low_color.rgb, high_color.rgb, v_height_factor);

	// Apply the final color to the mesh.
	ALBEDO = final_color;
}