shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

void fragment() {
    // Get the current screen color from the frame buffer
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    // Invert the RGB channels while keeping the alpha channel unchanged
    COLOR = vec4(vec3(1.0) - screen_color.rgb, screen_color.a);
}
