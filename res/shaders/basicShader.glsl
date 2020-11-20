#version 330 core

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;
uniform vec4[10] lightsDirection;
uniform vec4[10] lightsIntensity;
uniform vec4[10] lightPosition;
uniform ivec4 sizes; //{number of objects , number of lights , width, hight}  
in vec3 position1;

struct Hit 
{
    vec3 hitPoint;
    vec3 normal;
    int hitIndex;
    float t;
};


//calc shape intersect - sphere, plane
vec4 getSpotlight(int index){
	int count = -1;
	for(int i = 0; i <= index; i++){
		if(lightsDirection[i].w > 0.5){
			count = count+1;
		}
	}
	return lightPosition[count];
}

bool solveQuadricEquasion(float a,float b,float c,out vec2 result){
    float root = b*b - 4*a*c;
    if(root < 0) return false;
    root = sqrt(root);
    result.x = (-b - root)/(2*a);
    result.y = (-b + root)/(2*a);
    return true;
}

bool isIntersectSphere(vec3 P0, vec3 V,int oIndex, vec4 sphere, out Hit hit){
    float a = 1.0;
    vec3 tmp = P0-objects[oIndex].xyz;
    float b = dot(2*V,tmp);
    float c = pow(length(tmp),2) - sphere.w*sphere.w;

    vec2 result;
    if(!solveQuadricEquasion(a,b,c,result)) return false;

    float t = min(result.x,result.y);
    if(t < 0){
        t = max(result.x,result.y);
    }
    if(t <= 0.0) return false;

    hit.hitPoint = P0+t*V;
    hit.hitIndex = oIndex;
    hit.normal = normalize(hit.hitPoint - sphere.xyz);
    hit.t = t;

    return true;

}

bool isIntersectPlane(vec3 P0, vec3 V,int oIndex, vec4 plane, out Hit hit){
    vec3 N = normalize(plane.xyz); 
    vec3 Q0 = vec3(0,0,-plane.w/plane.z); //point on Plane
    float t = dot(N,(Q0-P0)/dot(N,V));

    if(t<=0) return false;
    
    hit.hitPoint = P0 + t*V;
    hit.hitIndex = oIndex;
    hit.normal = N;
    hit.t = t;

    return true;
}

bool intersection(vec3 P0,vec3 V,out Hit hit_ret,int currObjIndex)
{
    float minDistance = 9999;
    bool found = false;
    for(int i=0; i < sizes.x; i++)
    {
        bool flag = false;
        Hit hit;
        if(i!=currObjIndex){
            if(objects[i].w > 0.0){
                flag = isIntersectSphere(P0, V, i, objects[i], hit);
            }
            else{
                flag = isIntersectPlane(P0, V, i, objects[i],hit);
            }
            if(flag){
                if(!found || hit.t < minDistance){
                    minDistance = hit.t;
                    hit_ret = hit;
                    found = true;
                } 
            }  
        }
        
    }
    return found;
    
}


bool isOccluded(Hit hit,int lightIndex)
{
    //Check here if you are hit other object (that is not yourself!), if yes color is black
    vec3 V;
    if(lightsDirection[lightIndex].w > 0.5)//Spotlight
    {
        vec4 spot = getSpotlight(lightIndex);
        vec3 L = normalize(hit.hitPoint - spot.xyz);
        vec3 D = normalize(lightsDirection[lightIndex].xyz);
        if(dot(D,L) < spot.w) return true;
        V = -L;
    }
    else//Directonal
    {
        V = -normalize(lightsDirection[lightIndex].xyz);
    }
    Hit next_hit;
    
    if(intersection(hit.hitPoint,V, next_hit, hit.hitIndex)){
        if(lightsDirection[lightIndex].w > 0.5){
            vec4 spot = getSpotlight(lightIndex);
            if(length(spot.xyz - hit.hitPoint) > length(next_hit.hitPoint - hit.hitPoint)){
                return true;
            }
        }
        else{
            return true;
        }
    }
    return false;
}

vec3 colorCalc(vec3 srcPoint,Hit hit)
{
    vec3 color;
	Hit currhit = hit;
	vec3 curr_sourcePoint = srcPoint;
	vec3 Ka = objColors[currhit.hitIndex].xyz;
    vec3 Kd = Ka;
	vec3 diffuse=vec3(0,0,0);
	vec3 specular=vec3(0,0,0);
	if(objects[currhit.hitIndex].w < 0)
	{
		vec3 p = currhit.hitPoint;
		if(p.x * p.y >=0){
			if((mod(int(1.5*p.x),2) == mod(int(1.5*p.y),2)))
			{
				Ka=0.5*Ka;
			}
		}
		else{
			if((mod(int(1.5*p.x),2) != mod(int(1.5*p.y),2)))
			{
				Ka=0.5*Ka;
			}
		}
	}

	vec3 KaIamb = Ka*(ambient.xyz);
	vec3 Ks = vec3(0.7,0.7,0.7);
	for(int i = 0; i < sizes[1]; i++){
		if(!isOccluded(currhit, i)){
			vec3 N = normalize(hit.normal);
			vec3 L;
			if(lightsDirection[i].w == 1.0){
				vec3 sl_pos = getSpotlight(i).xyz;
				L = normalize(sl_pos - currhit.hitIndex);
			}
			else{
				L = -normalize(lightsDirection[i].xyz);
			}
            vec3 D = lightsDirection[i].xyz;
			vec3 Ili = lightsIntensity[i].xyz;
			if((dot(N,L))>0){
				diffuse += Kd*(dot(N,L))*Ili;
			}
			vec3 V = normalize(srcPoint - hit.hitPoint);
			vec3 R = reflect(-L,N);
			if((dot(V,R))>0){
				specular += Ks*(pow(dot(V,R),objColors[hit.hitIndex].w))*Ili;
			}
		}
	}
	color = KaIamb + diffuse + specular;
    return color;
}

void main()
{
    Hit hit;
    vec3 V = normalize(position1 - eye.xyz);
    if(!intersection(eye.xyz,V,hit,-1))
        gl_FragColor = vec4(0.5,0,0.2,1); //Flat background color
    else
        gl_FragColor = vec4(colorCalc(eye.xyz,hit),1);      
}