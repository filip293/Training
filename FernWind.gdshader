shader_type spatial;
render_mode cull_disabled;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;

uniform float wind_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.15;
uniform float frond_flutter : hint_range(0.0, 0.5) = 0.05;
uniform vec3 wind_direction = vec3(1.0, 0.0, 0.5);

void vertex() {
    // 1. Distance from central root (0.0 at center, grows toward tips)
    float dist = length(VERTEX.xz);
    
    // 2. Calculate frond angle around center (atan2 gives -PI to PI)
    // Every frond branch gets a completely different angle ID
    float frond_angle = atan(VERTEX.z, VERTEX.x);
    
    // 3. Normalized outward direction of THIS specific frond
    vec3 frond_dir = vec3(cos(frond_angle), 0.0, sin(frond_angle));
    
    // 4. Directional alignment with global wind direction
    // Fronds pointing into wind bend down/forward; side fronds sway sideways
    vec3 norm_wind = normalize(wind_direction);
    float wind_align = dot(frond_dir.xz, norm_wind.xz);

    // 5. Per-frond wave calculation (Offset time by frond_angle so fronds move independently)
    float wave = sin(TIME * wind_speed + frond_angle * 3.0);
    
    // 6. Primary Frond Motion: Push along global wind + dip frond tip downwards
    vec3 global_push = norm_wind * wave * wind_strength * dist;
    vec3 tip_dip = vec3(0.0, -1.0, 0.0) * abs(wave) * wind_strength * dist * 0.5;
    
    // 7. Secondary Leaf Flutter: High-frequency ripple on frond edges using NORMAL
    float leaf_ripple = sin(TIME * wind_speed * 4.0 + dist * 10.0 + frond_angle * 5.0);
    vec3 local_flutter = NORMAL * leaf_ripple * frond_flutter * dist;

    // Apply combined displacements (dist factor ensures root stays firmly planted)
    VERTEX += global_push + tip_dip + local_flutter;
}

void fragment() {
    vec4 albedo_tex = texture(texture_albedo, UV);
    ALBEDO = albedo_tex.rgb;
    ALPHA = albedo_tex.a;
    ALPHA_SCISSOR_THRESHOLD = 0.5;

    // Matte, glare-free finish
    ROUGHNESS = 0.9;
    SPECULAR = 0.02;

    if (!FRONT_FACING) {
        NORMAL = -NORMAL;
    }
}