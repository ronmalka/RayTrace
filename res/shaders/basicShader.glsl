#version 330 core

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;
uniform vec4[10] lightsDirection;
uniform vec4[10] lightsIntensity;
uniform vec4[10] lightPosition;
uniform ivec4 sizes; //{number of objects , number of lights , width, hight}  
// vec4 eye = vec4(0.0, 0.0, 4.0, 1.0);
// vec4 ambient = vec4(0.1, 0.2 ,0.3, 1.0);
// vec4[3] objects = vec4[3](vec4(0.0, -0.5, -1.0, -3.5),vec4(-0.7, -0.7 ,-2.0, 0.5),vec4(0.6, -0.5, -1.0, 0.5));
// vec4[3] objColors = vec4[3](vec4(0.0, 1.0,1.0,10.0),vec4(1.0, 0.0 ,0.0, 10.0),vec4(0.6, 0.0, 0.8, 10.0));
// vec4[2] lightsDirection= vec4[2](vec4(0.5, 0.0, -1.0, 1.0),vec4(0.0, -0.5 ,-1.0, 0.0));
// vec4[2] lightsIntensity = vec4[2](vec4(0.2, 0.5, 0.7, 1.0),vec4(0.7, 0.5 ,0.0, 1.0));
// vec4[1] lightPosition= vec4[1](vec4(2.0, 1.5, 3.0, 0.6));
// ivec4 sizes = ivec4(3, 2 ,500, 500); //{number of objects , number of lights , width, hight}  
in vec3 position1;

struct Hit 
{
    vec3 hitPoint;
    vec3 exitPoint;
    vec3 normal;
    int hitIndex;
};

// vector dir - calc eye and pixel vector

vec3 calcDirVec(vec3 src) 
{
    int width = sizes.z;
    int high = sizes.w;

    vec3 pc = vec3(high/2,width/2,0);
    vec3 v= vec3(0,1,0);
    vec3 t = normalize(position1 - src);
    vec3 b = normalize(cross(v,t));

    vec3 v_normal = cross(t,b);
    
    vec3 c = eye.xyz + t;

    float rx = width/2 ;
    float ry = high/2;
    float R = 1;

    vec3 p = b*(position1.x - abs(rx/2)) * R - v_normal * (position1.y - abs(ry/2)) * R ;
   // return p;

   return normalize(position1 - src);
     
}

//calc shape intersect - sphere, plane

bool solveQuadricEquasion(float a,float b,float c,out vec2 result){
    float root = b*b - 4*a*c;
    if(root < 0) return false;
    root = sqrt(root);
    result.x = (-b + root)/(2*a);
    result.y = (-b - root)/(2*a);
    return true;
}

bool isIntersectSphere(vec3 P0, vec3 V, int oIndex, out Hit hit){  
    float a = 1.0;
    vec3 tmp = P0-objects[oIndex].xyz;
    float b = dot(2*V,tmp);
    float c = dot(abs(tmp),abs(tmp)) - objects[oIndex].w*objects[oIndex].w;

    vec2 result;
    if(!solveQuadricEquasion(a,b,c,result)) return false;

    hit.hitPoint = P0+result.x*V;
    hit.exitPoint = P0+result.y*V;
    hit.hitIndex = oIndex;
    hit.normal = normalize(hit.hitPoint - objects[oIndex].xyz);

    return true;

}

bool isIntersectPlane(vec3 P0, vec3 V, int oIndex, out Hit hit){
    vec3 N = normalize(objects[oIndex].xyz); //normal
    vec3 Q0 = vec3(0,0,-objects[oIndex].w/objects[oIndex].z); //point on Plane
    float t = dot(N,(Q0-P0)/dot(N,V));

    if(dot(V,N) == 0.0) return false;

    hit.hitPoint = P0 + t*V;
    hit.exitPoint = hit.hitPoint;
    hit.hitIndex = oIndex;
    hit.normal = N;
    return true;
}

bool intersection(vec3 P0,vec3 V,out Hit hit_ret,int currObjIndex)
{
    float minDistance = -1.0;
    bool flag = false;
    for(int i=0; i < sizes.x; i++)
    {
        Hit hit;
        if(i!=currObjIndex){
            if(objects[i].w >= 0.0){
                flag = isIntersectSphere(P0, V, i,hit);
            }
            else{
                flag = isIntersectPlane(P0, V, i,hit);
            }
        }
        if(flag){
            float dist = distance(hit.hitPoint,P0);
            if(minDistance == -1.0 || dist < minDistance){
                minDistance = dist;
                hit_ret = hit;
            } 
        }  
    }
    return minDistance != -1.0;
    
}

vec3 calcLight(Hit hit,int lightIndex)
{
    //Check here if you are hit other object (that is not yourself!), if yes color is black
    Hit next_hit;
    vec3 dir = normalize(lightsDirection[lightIndex].xyz);
    vec3 V;
    if(lightsDirection[lightIndex].w >= 0.5)//Spotlight
    {
        V = normalize(lightPosition[lightIndex].xyz - hit.hitPoint);
    }
    else//Directonal
    {
        V = -1*dir;
    }
    if(intersection(hit.hitPoint,V, next_hit, hit.hitIndex))
    {
        return vec3(0,0,0);
    }
    return dot(dir, -hit.normal);
}

vec3 colorCalc(vec3 srcPoint)
{
    Hit hit;
    vec3 Ks = vec3(0.7,0.7,0.7);
    vec3 V = normalize(position1 - srcPoint);;
    if(!intersection(srcPoint,V,hit,-1))
        return vec3(0.5,0,0.5); //Flat background color
    //Iterate all over Lights
    vec3 color = vec3(0,0,0);
    for(int i=0;i<sizes.y;i++){
        vec3 light= calcLight(hit,i)*objColors[hit.hitIndex].xyz;
        vec3 dir = normalize(lightsDirection[i].xyz);
        color += (light + Ks * pow(dot(V,dir), objColors[hit.hitIndex].w)) * lightsIntensity[i].xyz;
    }

    vec3 Ia = ambient.xyz; // amibent
    color += Ia * objColors[hit.hitIndex].xyz;
    return normalize(color);
}

void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}