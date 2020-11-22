#version 130 

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;
uniform vec4[10] lightsDirection;
uniform vec4[10] lightsIntensity;
uniform vec4[10] lightPosition;
uniform ivec4 sizes; //{number of objects , number of lights , mirrors}  
uniform float zoom;
uniform float offset_x;
uniform float offset_y;
in vec3 position1;

#define LEVELS 5
#define INFINITY 9999

struct Hit
{
    int hitIndex;
    float t;
    vec3 hitPoint;
    vec3 normal;
};


float isIntersectPlane(vec3 P0,vec3 V, int oIndex)
{
    vec4 plane = objects[oIndex];
	vec3 N = normalize(plane.xyz); 
    vec3 Q0 = plane.z!=0 ? (vec3(0,0,-plane.w/plane.z)) : ( plane.y!=0 ? vec3(0,-plane.w/plane.y,0) : vec3(-plane.w/plane.x,0,0));//point on Plane
    float t = dot(N,(Q0-P0)/dot(N,V));

    if(t<=0) return INFINITY;
    return t;
}

bool solveQuadricEquasion(float a,float b,float c,out vec2 result){
    float root = b*b - 4*a*c;
    if(root < 0) return false;
    root = sqrt(root);
    result.x = (-b - root)/(2*a);
    result.y = (-b + root)/(2*a);
    return true;
}

float isIntersectSphere(vec3 P0,vec3 V, int oIndex)
{
    vec4 sphere = objects[oIndex];
	float t = INFINITY;
    float a = 1.0;
    vec3 tmp = P0-sphere.xyz;
    float b = dot(2*V,tmp);
    float c = dot(tmp,tmp) - sphere.w*sphere.w;

    vec2 result;
    if(!solveQuadricEquasion(a,b,c,result)) return INFINITY;

	t=min(result.x,result.y);
	if (t<0){
		t=max(result.x,result.y);
	}
	if(t <=0.0){
		t = INFINITY;	
	}
    return t; 
}

vec4 getSpotlight(int index){
	int count = -1;
	for(int i = 0; i <= index; i++){
		if(lightsDirection[i].w > 0.5){
			count = count+1;
		}
	}
	return lightPosition[count];
}

Hit findIntersection(vec3 sourcePoint,vec3 V, int currObject)
{
	Hit hit;
	hit.t = INFINITY;
	float t = 0;
	for(int i = 0; i < sizes[0]; i++){
        if(i!=currObject){
            if(objects[i].w > 0.0){
                t = isIntersectSphere(sourcePoint,V, i);
            }
            else{
                t = isIntersectPlane(sourcePoint,V, i);
            }
            if(t < hit.t){
				hit.hitIndex = i;
                hit.t=t;
            }
        }
	}
	hit.hitPoint = sourcePoint + hit.t*V;
    if(objects[hit.hitIndex].w > 0.0){
        hit.normal = normalize(hit.hitPoint - objects[hit.hitIndex].xyz);
	}
    else{
		hit.normal = normalize(-objects[hit.hitIndex].xyz);
	}
    return hit;
    
}


bool isOccluded(vec3 P0, int lightIndex,int currObject){
	vec4 currLight = lightsDirection[lightIndex];
	vec3 V;
	if(currLight.w > 0.5){
		vec4 spot = getSpotlight(lightIndex);
        vec3 D = normalize(currLight.xyz);
        vec3 L = normalize(P0 - spot.xyz);
        if(dot(D,L) < spot.w){
            return true;
        }
		V = normalize(spot.xyz - P0);
	}
    else{
		V = -normalize(currLight.xyz);
	}
	Hit hit = findIntersection(P0, V, currObject);
    if(hit.t != INFINITY){
        if(currLight.w > 0.5){
            vec4 spot = getSpotlight(lightIndex);
            if(length(hit.hitPoint - P0) < length(spot.xyz - P0))
                return true;
        }
		else if (objects[hit.hitIndex].w > 0){
			return true;
		}
	}
	return false;
}

vec3 colorCalc(Hit hit, vec3 P0)
{
	int level = 0;
	while(LEVELS >= level){
		vec3 Ka = objColors[hit.hitIndex].xyz;
		vec3 Kd = Ka;
		vec3 Ks = vec3(0.7,0.7,0.7);
		vec3 color = vec3(0,0,0);
		vec3 diffuse = vec3(0,0,0);
		vec3 specular = vec3(0,0,0);
		if(objects[hit.hitIndex].w < 0)
		{
			vec3 p= hit.hitPoint;
			if(p.x * p.y >=0 && mod(int(1.5*p.x),2) == mod(int(1.5*p.y),2)){
				Ka = Kd*=0.5;
				Ks *=0.5;
			}
			else if(p.x * p.y < 0 && mod(int(1.5*p.x),2) != mod(int(1.5*p.y),2)){
				Ka = Kd*=0.5;
				Ks *=0.5;
			}
		}
		for(int i = 0; i < sizes.y; i++){
			if(!isOccluded(hit.hitPoint, i, hit.hitIndex)){
				vec3 L;
				vec3 N = hit.normal;
				if(lightsDirection[i].w > 0.5){
					L = normalize(getSpotlight(i).xyz - hit.hitPoint);
				}
				else{
					L = -normalize(lightsDirection[i].xyz);
				}
				vec3 IL = lightsIntensity[i].xyz*dot(N,L);
				vec3 V = normalize(P0 - hit.hitPoint);
				vec3 R = reflect(-L,N);
				
				float dotDiffuse = dot(N,L);
				float dotSpec = dot(V,R);
				if(dotSpec > 0){
					color += Ks*(pow(dotSpec,objColors[hit.hitIndex].w))*IL;
				}
				if(dotDiffuse > 0){
					color += Kd*(dotDiffuse)*IL;
				}	
				
			}
		}
		color += Ka*ambient.xyz;
		if (hit.hitIndex >= sizes.z || level == LEVELS) return color;
		else{ //Do Reflect
			vec3 dirToObject = normalize(hit.hitPoint - P0);
			P0 = hit.hitPoint;
			vec3 newV = normalize(reflect(dirToObject,hit.normal));
			Hit tmp_hit = findIntersection(P0,newV,hit.hitIndex);
			if(tmp_hit.t == INFINITY) return vec3(0,0,0);
			level++;
			hit = tmp_hit;
		}
		
	}
    return vec3(0,0,0);
}


void main()
{	
	vec3 tmpPosition = position1;
	tmpPosition.x += offset_x;
	tmpPosition.y += offset_y;
	tmpPosition = tmpPosition * zoom;
	vec3 v =normalize(tmpPosition - eye.xyz);
	Hit hit = findIntersection(eye.xyz, v,-1);
    if(hit.t == INFINITY) gl_FragColor = vec4(0,0,0,1);
    else gl_FragColor = vec4(colorCalc(hit, eye.xyz),1);
}
