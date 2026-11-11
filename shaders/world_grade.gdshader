shader_type canvas_item;
render_mode unshaded;

uniform float saturation = 1.0;
uniform float contrast = 1.0;
uniform float brightness = 1.0;
uniform vec3 tint : source_color = vec3(1.0);

void fragment() {
	vec4 pixel = COLOR;
	float luma = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 graded = mix(vec3(luma), pixel.rgb, saturation);
	graded = (graded - vec3(0.5)) * contrast + vec3(0.5);
	COLOR = vec4(clamp(graded * tint * brightness, 0.0, 1.0), pixel.a);
}
