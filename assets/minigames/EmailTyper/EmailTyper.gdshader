shader_type canvas_item;

uniform vec4 Color_Tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    vec3 tinted_rgb = texture_color.rgb * Color_Tint.rgb;

    COLOR = vec4(tinted_rgb, texture_color.a);
}
