shader_type canvas_item;
render_mode blend_disabled;
uniform sampler2D screen_tex:hint_screen_texture,filter_nearest;
uniform float source_weight=1.0;
uniform float destination_weight=1.0;
uniform bool subtractive=false;
void fragment(){
 vec4 src=texture(TEXTURE,UV);
 vec3 dst=texture(screen_tex,SCREEN_UV).rgb;
 vec3 value=subtractive?dst-src.rgb*source_weight:src.rgb*source_weight+dst*destination_weight;
 COLOR=vec4(mix(dst,clamp(value,vec3(0.0),vec3(1.0)),src.a),1.0);
}
