#version 300 es
/*********
* made by Matthias Hurrle (@atzedent)
*/
precision highp float;
out vec4 O;
uniform float time;
uniform vec2 resolution;
#define FC gl_FragCoord.xy
#define R resolution
// start animation with a delay to give the compiler a head start
#define T max(1.,time-1.)
#define MN min(R.x,R.y)
#define N normalize
#define S smoothstep
// smooth edge
#define SE(v,s,k) S(s+k,s-k,v)
// fast (unprecise) 2D rotation
#define rot(a) mat2(cos((a)-vec4(0,11,33,0)))
// restrict the ray marcher to 10 units of depth
#define MAXD 10.
// calculate the luminance (bw) of a color
#define lum(a) dot(a,vec3(.27,.71,.07))
// simple color palette - param a can be float or vec3
#define hue(a) (.24+.6*cos(6.3*(a)+vec3(0,83,21)))
// convert color a to sepia
#define sepia(a) vec3(dot(a,vec3(.4,.8,.28)),dot(a,vec3(.3,.7,.24)),dot(a,vec3(.2,.6,.18)))
// Returns a pseudo random number for a given point (white noise)
float rnd(vec2 p) {
	p=fract(p*vec2(12.9898,78.233));
	p+=dot(p,p+34.56);
	return fract(p.x*p.y);
}
// Returns a pseudo random number for a given point (value noise)
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p), u=f*f*(3.-2.*f), k=vec2(1,0);
	float
	a=rnd(i),
	b=rnd(i+k),
	c=rnd(i+k.yx),
	d=rnd(i+1.);
	return mix(mix(a,b,u.x),mix(c,d,u.x),u.y);
}
// Returns a pseudo random number for a given point (fractal noise)
float fbm(vec2 p) {
	float t=.0, a=1., h=.0; mat2 m=mat2(1,.2,1,1);
	for (float i=.0; i<5.; i++) {
		t+=a*noise(p);
		p*=2.;
		a/=2.;
		h+=a;
	}
	return t/h;
}
// returns the distance to a 3D box at point p with the dimension s and radius r
float box(vec3 p, vec3 s, float r) {
	p=abs(p)-s+r;
	return length(max(p,.0))+min(.0,max(max(p.x,p.y),p.z))-r;
}
// returns the distance to a 2D box at point p with the dimension s
float box(vec2 p, vec2 s) {
	p=abs(p)-s;
	return length(max(p,.0))+min(.0,max(p.x,p.y));
}
// initialize material and glow
float mat=.0, glow=.0;
// Returns the distance to the 3D scene
float map(vec3 p) {
	// the distance between the cubes
	const float n=2.;
	// sphere mapping vector for the distortion effect
	vec2 sm=vec2(.5+atan(p.x,p.z),atan(length(p.xz),p.y))*5./6.28318;
	// the ground of the scene with some random wavy pattern
	float fl=p.y+3.*(1.-.1*noise(p.xz+vec2(1,2))-.00125*noise(p.xz*120.)), ball=length(p)-1.;
	// initialize the 3D grid for the cubes (three as a result)
	p.y-=clamp(round(p.y/n),-1.,1.)*n;
	// generate some distortion for the effect on the cubes (using the sphere mapping vector) 
	float a=noise(sm*8.+noise(sm*15.+fbm(sm*20.))),
	// generate the cubes with the distortion
	b=box(p,vec3(S(4.5,.0,a)),.05);
	// determine if the pixel is on the spere or on the cube for texture application
	mat=ball<b?1.:.0;
	// add glow to the sphere
	glow+=.05/(.05+ball*ball*80.);
	// return the minimum of floor, ball and cubes (reduce step size for better results)
	return min(fl,min(ball,b))*.5;
}
// Raymarcher
float march(inout vec3 p, vec3 rd) {
	float dd=.0;
	for (float i=.0; i<800.; i++) {
		float d=map(p);
		if (abs(d)<1e-3 || dd>MAXD) break;
		p+=rd*d;
		dd+=d;
	}
	return dd;
}
// Returns the normal of the surface at the given point
vec3 norm(vec3 p) {
	float h=1e-3; vec2 k=vec2(-1,1);
	return N(
		k.xyy*map(p+k.xyy*h)+
		k.yxy*map(p+k.yxy*h)+
		k.yyx*map(p+k.yyx*h)+
		k.xxx*map(p+k.xxx*h)
	);
}
// Renders the scene
vec3 render(inout vec3 p, vec3 rd) {
	// keep time at a constant for 3.14 seconds (used to delay the animations)
	float t=max(T,3.14);
	// initialize the color vector
	vec3 col=vec3(0);
	// get the distance to the scene at point p and ray direction rd
	float d=march(p,rd);
	// treat scene and background diffenently
	if (d<MAXD) {
		// ray has hit the scene, so calculate the normal and place the light
		vec3 n=norm(p), lp=vec3(3,3,-3), l=N(lp-p);
		// calculate diffuse and specualar, fesnel and brightness
		float dif=clamp(dot(l,n),.0,1.), spe=pow(clamp(dot(reflect(rd,n),l),.0,1.),7.),
		fres=pow(clamp(1.+dot(rd,n),.0,1.),5.), bri=clamp(dot(N(lp-rd),n),.0,1.);
		// add ambient and diffuse lights
		col+=.2+dif;
		// add a bit of specular light
		col+=.6*spe;
		// f is radius, k is blur factor
		const float f=.05; float k=50./MN;
		// s is the dimension of the box for the grid pattern
		vec2 s=vec2(f*8.);
		// generate the grid pattern, initialize a temporary color vector, calculate the hightlights
		vec3 q=fract(p*5.)-.5, c=vec3(0), cc=hue(length(p.xz+noise(p.zy+fbm(vec2(-p.x,p.z)+t*.1))));
		// apply the grid pattern like a texture as a cube map to the temporary color vector
		c+=SE(box(q.xy,s)-f,.0,k)*abs(n.z);
		c+=SE(box(q.xz,s)-f,.0,k)*abs(n.y);
		c+=SE(box(q.yz,s)-f,.0,k)*abs(n.x);
		// apply the grid pattern to everything except the glowing sphere in the center
		col=mat<1.?min(col,c):col;
		// apply sunlight color to the sphere
		col*=mat<1.?cc:vec3(1,.95,.8)*3.;
		// apply a fair bit of specular light to the scene
		col=max(col,.7*spe);
		// apply a fair bit of bright light to the scene
		col=max(col,.7*bri*bri);
		// darken the edges of the scene
		col=mix(col,vec3(0),fres);
	} else {
		// ray as reached the maximum distance without hitting a surface (thats background then)
		// calculate the unit vector for the sky
		vec2 uv=FC/(R.x>R.y?R:R.yy);
		// apply a gradient to the sky
		col=mix(col,vec3(uv,4),.9);
		// darken the shadows
		col/=1.+exp(-col*col*col);
		// colorize the sky
		col=hue(lum(col));
		// calculate the cloud pattern (with animation)
		float n=noise((uv-vec2(t*.004,t*.003))*mat2(1,.5,.5,1.5)*120.);
		// apply the cloud pattern to the backround
		col=mix(col,mix(vec3(1),col,.95),n);
	}
	return col;
}
// animates the camera
void cam(inout vec3 p) {
	p.yz*=rot(-.42+.2*S(.0,10.,.5+.5*sin(min(3.14,T))));
	p.xz*=rot(-.57);
}
void main() {
	// calculate the unit vector
	vec2 uv=(FC-.5*R)/MN;
	// factor for initial pixelation effect
	float n=max(500.*exp(cos(min(T+3.1415,6.28318))),1.);
	// apply initial pixelation effect
	uv=n>1.?floor(uv*n)/n:uv;
	// initialize the color vector
	vec3 col=vec3(0),
	// place the camera seven units behind the scene
	p=vec3(0,0,-7),
	// zoom out a tad bit
	rd=N(vec3(uv,.9));
	// animate the camera
	cam(p); cam(rd);
	// initial time to reveal the scene
	float t=min(time*.3,1.);
	// render the scene (animate the revealing)
	col=mix(col,render(p,rd*mix(.85,1.,rnd(uv))),t);
	// increase the contrast
	col=S(.2,1.,col);
	// darken the shadows
	col=tanh(col);
	// a bit of a foggy foreground (come in a tad bit after the initial animation)
	col=mix(col,mix(col,mix(tanh(col*col),vec3(.25),fbm(uv+noise(uv.yy+vec2(5.+T*.01,-10.-T*.005)))),S(.55,-.25,.5+uv.y)),t);
	// convert the colors to sepia
	col=sepia(col);
	// the glowing sphere at the center of the rock
	col+=mix(vec3(0),glow*mix(.05,.25,noise(uv+T))*vec3(.8,.4,.28),min(S(.0,.5,time*.2-.5),1.));
	// vignette (dimensions of the window, normalized)
	vec2 vp=FC/R*2.-1.;
	// widen the frame
	vp*=1.1;
	// increase the curvature in the corners
	vp*=vp*vp*vp*vp;
	// calculate the distance to the vignette and soften the transition
	float v=pow(dot(vp,vp),.8);
	// just a precaution not to get negative results
	v=max(.0,v);
	// darken the corners (yes absolute black leads to the desired result)
	col=mix(col,vec3(0),v);	
	// fade in the darkest parts from black to dark gray
	col=max(col,mix(.0,.08,t));
	// output the pixel's color
	O=vec4(col,1);
}