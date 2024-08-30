// GoShapes terrain shader sample is derived from the following great work:
// - https://github.com/acegiak/Godot4TerrainShader
// - https://github.com/jotson/godot3-triplanar-terrain-demo
// which was inspired by:
// - https://www.reddit.com/r/Unity3D/comments/dhr5g2/i_made_a_stochastic_texture_sampling_shader/

shader_type spatial;

uniform sampler2D grass_diffuse : source_color;
uniform sampler2D grass_normal : source_color;
uniform sampler2D snow_diffuse : source_color;
uniform sampler2D snow_normal : source_color;
uniform sampler2D sand_diffuse : source_color;
uniform sampler2D sand_normal : source_color;
uniform sampler2D wall_diffuse : source_color;
uniform sampler2D wall_normal : source_color;
uniform sampler2D path_map : source_color;
uniform float fade_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float surface_scale : hint_range(0.001, 10.0) = 0.5;
uniform float wall_scale : hint_range(0.001, 10.0) = 0.5;
uniform float sand_height = 0.1;
uniform float snow_height = 10.0;
uniform float surface_depth = 2.0;
uniform float wall_depth = 2.0;

varying vec3 wpos;
varying vec3 norm;
varying vec3 pnorm;
varying vec3 wnorm;
varying vec3 tpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	norm = NORMAL;

	mat3 invcam = mat3(INV_PROJECTION_MATRIX);
	wnorm = NORMAL;
	pnorm = normalize(pow(abs(NORMAL), vec3(10.0,10.0,10.0)));
	tpos = VERTEX * vec3(1.0,-1.0,1.0);
}

vec2 worldToUV(vec3 w) {
    return vec2(w.x + w.z, w.y);
}

vec2 hash(vec2 p) {
	return fract( sin( p * mat2( vec2( 127.1, 311.7 ), vec2( 269.5, 183.3 ) ) ) * 43758.5453 );
}

vec4 stochastic_sample(sampler2D tex, vec2 uv){
	vec2 skewV = mat2(vec2(1.0,1.0), vec2(-0.57735027 , 1.15470054)) * uv * 3.464;
	vec2 vxID = floor(skewV);
	vec2 fracV = fract(skewV);
	vec3 barry = vec3(fracV.x,fracV.y,1.0-fracV.x-fracV.y);
	mat4 bw_vx = barry.z > 0.0 ?
		mat4(vec4(vxID,0.0,0.0),vec4((vxID+vec2(0.0,1.0)),0.0,0.0),vec4(vxID+vec2(1.0,0.0),0,0),vec4(barry.zyx,0)):
		mat4(vec4(vxID+vec2(1.0,1.0),0.0,0.0),vec4((vxID+vec2(1.0,0.0)),0.0,0.0),vec4(vxID+vec2(0.0,1.0),0,0),vec4(-barry.z,1.0-barry.y,1.0-barry.x,0));
	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);
	return (textureGrad(tex,uv+hash(bw_vx[0].xy),ddx,ddy)*bw_vx[3].x) +
		(textureGrad(tex,uv+hash(bw_vx[1].xy),ddx,ddy)*bw_vx[3].y) +
		(textureGrad(tex,uv+hash(bw_vx[2].xy),ddx,ddy)*bw_vx[3].z);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos, float uv_scale) {
	vec4 samp = vec4(0.0);
	samp += stochastic_sample(p_sampler, p_triplanar_pos.xy*vec2(uv_scale,uv_scale)) * p_weights.z;
	samp += stochastic_sample(p_sampler, p_triplanar_pos.xz*vec2(uv_scale,uv_scale)) * p_weights.y;
	samp += stochastic_sample(p_sampler, p_triplanar_pos.zy * vec2(-1.0,1.0)*vec2(uv_scale,uv_scale)) * p_weights.x;
	return samp;
}

void fragment() {
	float wall_blend = clamp((1.0 - (wnorm.y * wnorm.y * wnorm.y)) * 2.0, 0.0, 1.0);
	float sand_blend = clamp((wpos.y - sand_height) * 0.08f, 0.0, 1.0);
	float snow_blend = clamp((wpos.y - snow_height) * 0.02, 0.0, 1.0);
	float path_blend = texture(path_map, UV).r;

	float inv_wall_scale = 1.0 / wall_scale;
	vec3 wall_d = triplanar_texture(wall_diffuse, pnorm, tpos, inv_wall_scale).rgb;
	vec3 wall_n = triplanar_texture(wall_normal, pnorm, tpos, inv_wall_scale).rgb;

	float inv_surface_scale = 1.0 / surface_scale;
	vec3 grass_d = texture(grass_diffuse, wpos.xz * inv_surface_scale).rgb;
	vec3 grass_n = texture(grass_normal, wpos.xz * inv_surface_scale).rgb;
	vec3 snow_d = texture(snow_diffuse, wpos.xz * inv_surface_scale).rgb;
	vec3 snow_n = texture(snow_normal, wpos.xz * inv_surface_scale).rgb;
	vec3 sand_d = texture(sand_diffuse, wpos.xz * inv_surface_scale).rgb;
	vec3 sand_n = texture(sand_normal, wpos.xz * inv_surface_scale).rgb;

	// grass + sand
    vec3 out_color = grass_d;
	vec3 out_norm = grass_n;

	// mix in snow
	out_color = mix(out_color, snow_d, snow_blend);
	out_norm = mix(out_norm, snow_n, snow_blend);

	// mix in wall
	out_color = mix(out_color, wall_d, wall_blend);
	out_norm = mix(out_norm, wall_n, wall_blend);

	// mix in sand
	out_color = mix(out_color, sand_d, 1.0 - sand_blend);
	out_norm = mix(out_norm, sand_n, 1.0 - sand_blend);

	// mix in path
	out_color = mix(out_color, sand_d, path_blend);
	out_norm = mix(out_norm, sand_n, path_blend);
	float out_depth = mix(surface_depth, wall_depth, wall_blend);

	ALBEDO = out_color;
  	NORMAL_MAP = clamp(out_norm * out_depth, 0.0, 1.0);
	SPECULAR = clamp(wall_blend * 0.5, 0.0, 0.5);
}
