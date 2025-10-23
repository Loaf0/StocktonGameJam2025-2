shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float radius : hint_range(0.0, 2.0) = 0.0;
uniform vec4 color : source_color = vec4(0.4, 0.8, 1.0, 0.4);
uniform float edge_width : hint_range(0.0, 0.2) = 0.06;

void fragment() {
    vec2 u = UV;
    float d = distance(u, center);
    
    float fade_in = smoothstep(radius - edge_width, radius, d); 

    float fade_out = 1.0 - smoothstep(radius, radius + edge_width, d);
    
    float final_alpha = min(fade_in, fade_out);
    
    COLOR = vec4(color.rgb, color.a * final_alpha);
}