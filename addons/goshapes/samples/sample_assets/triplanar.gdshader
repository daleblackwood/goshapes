shader_type spatial;

// Varyings
varying float flatness;
varying vec3 power_normal;
varying vec3 object_normal;
varying vec3 world_normal;
varying vec3 triplanar_pos;

uniform float wall_texture_scale = 1.0;
uniform sampler2D wall_texture;
uniform float top_texture_scale = 1.0;
uniform sampler2D top_texture;
uniform vec4 blend_values = vec4(3,-2,0,1);

vec2 hash(vec2 p) {
	return fract( sin( p * mat2( vec2( 127.1, 311.7 ), vec2( 269.5, 183.3 ) ) ) * 43758.5453 );
}

void vertex() {
	object_normal = NORMAL;
	world_normal = vec3(0.0,1.0,0.0);
	flatness = dot(object_normal,world_normal);
	power_normal = normalize(pow(abs(object_normal),vec3(10.0,10.0,10.0)));
	triplanar_pos = VERTEX*vec3(1.0,-1.0,1.0);
}

vec4 stochastic_sample(sampler2D tex, vec2 uv){
	vec2 skewV = mat2(vec2(1.0,1.0),vec2(-0.57735027 , 1.15470054))*uv * 3.464;	
	vec2 vxID = floor(skewV);
	vec2 fracV = fract(skewV);
	vec3 barry = vec3(fracV.x,fracV.y,1.0-fracV.x-fracV.y);	
	mat4 bw_vx = barry.z>0.0?
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
	vec4 wall_tex = triplanar_texture(wall_texture, power_normal, triplanar_pos,wall_texture_scale);
	vec3 wall = wall_tex.rgb;

	vec4 top_tex = triplanar_texture(top_texture, power_normal, triplanar_pos,top_texture_scale);
	vec3 top = top_tex.rgb;
	
	float blend = clamp((flatness*blend_values.x)+blend_values.y,blend_values.z,blend_values.w);
	ALBEDO = mix(wall,top,blend);
}




