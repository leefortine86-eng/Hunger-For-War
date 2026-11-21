shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_texture : hint_default_black, filter_linear_mipmap_anisotropic;
uniform sampler2D ao_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float roughness_strength : hint_range(0.0, 1.0) = 1.0;
uniform float metallic_strength : hint_range(0.0, 1.0) = 1.0;
uniform float ao_strength : hint_range(0.0, 1.0) = 1.0;
uniform vec4 albedo_tint : source_color = vec4(1.0);

void fragment() {
    vec4 base = texture(albedo_texture, UV) * albedo_tint;
    ALBEDO = base.rgb;
    NORMAL_MAP = texture(normal_texture, UV).rgb;
    NORMAL_MAP_DEPTH = normal_strength;
    ROUGHNESS = texture(roughness_texture, UV).r * roughness_strength;
    METALLIC = texture(metallic_texture, UV).r * metallic_strength;
    AO = mix(1.0, texture(ao_texture, UV).r, ao_strength);
}
