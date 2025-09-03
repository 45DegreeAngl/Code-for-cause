shader_type sky;

uniform sampler2D sky_tex:source_color,filter_linear,hint_default_black;
uniform sampler2D planet_tex:source_color,filter_linear;
uniform float planet_radius = 150.0;
uniform float planet_z = 150.0;

// Replaced old light uniforms with new, clearer ones for the moon glow
uniform vec3 glow_color:source_color = vec3(0.4, 0.45, 0.6); // A nice moonlight color
uniform float glow_size = 70.0; // Controls the falloff/sharpness of the glow
uniform float glow_intensity = 1.5; // Overall brightness of the glow


struct RayHit{
	bool is_hit;
	vec3 normal;//normal of the vector at point of intersection
	vec3 hit_point;
};

RayHit hit_sphere(vec3 ray_origin, vec3 ray_dir, vec3 sphere_center,float sphere_radius){
	RayHit ray_hit;
	ray_hit.is_hit = false;
	vec3 oc = ray_origin - sphere_center;
	float a = dot(ray_dir,ray_dir);
	float b = 2.0 * dot(oc,ray_dir);
	float c = dot(oc,oc) - sphere_radius * sphere_radius;
	float delta = b * b - 4.0 * a * c;

	if (delta < 0.0){
		return ray_hit;
	}
	
	float root = sqrt(delta);
	float t1 = (-b - root) / (2.0 * a);
	float t2 = (-b + root) / (2.0 * a);
	
	float t = t1;
	if (t < 0.0) {
		t = t2;
		if (t < 0.0) {
			return ray_hit;
		}
	}
	
	ray_hit.hit_point = fma(ray_dir,vec3(t),ray_origin);
	ray_hit.normal = normalize(ray_hit.hit_point - sphere_center);
	ray_hit.is_hit = true;
	return ray_hit;
}

vec2 get_spherical_uv(vec3 point_on_sphere,float rotation){
	vec3 n = normalize(point_on_sphere);
	float theta = atan(n.z,n.x);
	float phi = acos(n.y);
	theta += rotation;
	float u = (theta + PI)/TAU;
	float v = (phi)/PI;
	return vec2(u,v);
}

// This function is no longer needed since the planet is the light source
// vec3 compute_lighting(vec3 normal, vec3 light_dir){ ... }


void sky() {
	if(AT_CUBEMAP_PASS){
		COLOR = vec3(0.2,0.6,1.0);
	} else{
		
		vec3 planet_center = vec3(0.0,100.0 * 5.0,planet_radius * 4.0 + planet_z);
		RayHit planet_hit = hit_sphere(POSITION,EYEDIR,planet_center,planet_radius);
		
		if (planet_hit.is_hit){
			// The planet is now emissive (it's the light source)
			// So we just sample its texture and don't apply any external lighting.
			vec2 uv = get_spherical_uv(planet_hit.hit_point - planet_center, TIME * 0.02);
			COLOR = texture(planet_tex, uv).rgb;
			
		}else{
			// The sky is now lit by the planet's glow
			COLOR = texture(sky_tex,SKY_COORDS).rgb;
			
			// 1. Get the direction from the current sky pixel to the center of the planet
			vec3 light_dir = normalize(planet_center - POSITION);
			
			// 2. Calculate the glow based on the angle between the view direction and light direction
			float glow_factor = max(dot(light_dir, EYEDIR), 0.0);
			
			// 3. Apply the glow effect using our new uniforms
			vec3 glow = glow_color * pow(glow_factor, glow_size) * glow_intensity;
			
			COLOR += glow;
		}
	}
}