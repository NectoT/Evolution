shader_type canvas_item;

uniform vec4 shining_color : hint_color;
uniform int shining_width = 10;
uniform float shining_frequency = 0.3;

uniform int fps = 30;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	vec2 texture_size = pow(TEXTURE_PIXEL_SIZE, vec2(-1.0));
	vec2 texture_center = texture_size / 2.0;
	vec2 radius_vector = vec2(UV.x * texture_size[0] - texture_center[0], UV.y * texture_size[1] - texture_center[1]);
	
	// code for shining borders
	int shining_frames = int(float(fps) / shining_frequency);
	int shining_timer = int(TIME * float(fps)) % shining_frames;
	
	bool pixel_in_width_border = abs(radius_vector[0]) > texture_size[0] / 2.0 - float(shining_width);
	bool pixel_in_height_border = abs(radius_vector[1]) > texture_size[1] / 2.0 - float(shining_width);
	if (pixel_in_width_border || pixel_in_height_border) {
		//COLOR = vec4(vec3(float(shining_timer) / float(shining_frames)), 1.0);
		if (shining_timer < shining_frames / 2) {
			COLOR = shining_color + vec4(vec3(float(shining_timer) / float(shining_frames)), 0.0) / 4.0;
		}
		else {
			COLOR = shining_color + vec4(vec3(float(shining_frames - shining_timer) / float(shining_frames)), 0.0) / 4.0;
		}
		
		float alpha_decrease_width = 0.0;
		float alpha_decrease_height = 0.0;
		if (pixel_in_width_border) {
			alpha_decrease_width = 1.0 * (abs(radius_vector[0]) - (texture_size[0] / 2.0 - float(shining_width))) / float(shining_width);
		}
		if (pixel_in_height_border) {
			alpha_decrease_height = 1.0 * (abs(radius_vector[1]) - (texture_size[1] / 2.0 - float(shining_width))) / float(shining_width);
		}
		COLOR.a -= max(alpha_decrease_width, alpha_decrease_height);
	}
}