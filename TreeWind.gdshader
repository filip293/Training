shader_type spatial;
render_mode cull_disabled;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;
uniform sampler2D noise_tex : hint_default_black;

uniform float wind_speed : hint_range(0.0, 10.0) = 1.5;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.2;
uniform float leaf_flutter_strength : hint_range(0.0, 0.5) = 0.08;
uniform float trunk_anchor_height : hint_range(0.0, 5.0) = 0.5; // Height where sway begins
uniform vec3 wind_direction = vec3(1.0, 0.0, 0.5);

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Smooth transition: 0.0 at ground level up to trunk_anchor_height, ramping to 1.0
    float height_mask = smoothstep(0.0, trunk_anchor_height, VERTEX.y);

    // Continuous wind noise
    vec2 noise_uv = world_pos.xz * 0.1 + (wind_direction.xz * TIME * wind_speed * 0.1);
    float noise = texture(noise_tex, noise_uv).r;

    // 1. Main sway (multiplied by height_mask so ground never moves)
    vec3 main_wind = normalize(wind_direction) * sin(TIME * wind_speed + world_pos.x * 0.5) * wind_strength * height_mask * noise;
    
    // 2. Leaf flutter (also masked so low trunk vertices don't flutter)
    float leaf_wave = sin(TIME * wind_speed * 4.0 + VERTEX.x * 12.0 + VERTEX.z * 12.0 + VERTEX.y * 6.0);
    vec3 flutter = NORMAL * leaf_wave * leaf_flutter_strength * height_mask;

    VERTEX += main_wind + flutter;
}

void fragment() {
    vec4 albedo_tex = texture(texture_albedo, UV);
    ALBEDO = albedo_tex.rgb;
    ALPHA = albedo_tex.a;
    ALPHA_SCISSOR_THRESHOLD = 0.5;

    if (!FRONT_FACING) {
        NORMAL = -NORMAL;
    }
}