shader_type canvas_item;

const float SIZE = 150.0;

uniform float radius;
uniform float power;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float amount = mix(1.0, 1.5, power);
	
	vec2 screen_pixel = SCREEN_UV * 1.0/SCREEN_PIXEL_SIZE;
	vec2 center = vec2(0.5, 0.5) * 1.0/SCREEN_PIXEL_SIZE;
	
	float dist = distance(center, screen_pixel);
	vec2 pow_pixel = screen_pixel;
	if (dist > radius) {
		float t = clamp((dist - radius) / SIZE, 0.0, 1.0);
		pow_pixel = center + ((screen_pixel - center) * (1.0 + t));
	}
	
	vec2 adjusted_pixel = mix(screen_pixel, pow_pixel, clamp(power, 0.0, 1.0));
	COLOR = texture(screen_tex, adjusted_pixel * SCREEN_PIXEL_SIZE);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
