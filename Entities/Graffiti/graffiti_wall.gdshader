shader_type spatial;

// Texture of the graffiti/decal
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;

// The single parameter to control the reveal (0.0 = hidden, 1.0 = fully revealed)
uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;

// Number of vertical sweeps (up and down strokes)
uniform float sweeps = 10.0;

// Softness of the spray paint edge
uniform float brush_softness : hint_range(0.0, 0.5) = 0.05;

// Noise texture for organic spray scatter
uniform sampler2D noise_texture : repeat_enable;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    // 1. Calculate which sweep column the current pixel belongs to
    float sweep_index = floor(UV.x * sweeps);
    
    // 2. Determine if the stroke is going down (even) or up (odd)
    float is_odd = mod(sweep_index, 2.0);
    
    // 3. Calculate the Y-progress based on the stroke direction.
    float y_prog = mix(UV.y, 1.0 - UV.y, is_odd);
    
    // 4. Calculate the base threshold for this pixel
    float threshold = (sweep_index + y_prog) / sweeps;
    
    // 5. Add noise for organic spray edge
    float noise_val = texture(noise_texture, UV * 2.0).r;
    threshold += (noise_val - 0.5) * noise_strength;
    
    // 6. Compare the pixel's threshold to the global reveal progress
float alpha = smoothstep(threshold - brush_softness, threshold + brush_softness, reveal_progress);
    
    // 7. Apply to 3D material
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb;
    
    // Multiply the texture's alpha by our calculated shader mask
    ALPHA = tex_color.a * alpha;
    
    // Ensure the material is set to "Transparent" or "Alpha Scissor" in the Inspector
    ALPHA_SCISSOR_THRESHOLD = 0.01; 
}
