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
    vec3 exitPoint;
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

    vec3 p = pc + b*(position1.x - abs(rx/2)) * R - v_normal * (position1.y - abs(ry/2)) * R ;
    return p;
     
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

    return true;

}

bool isIntersectPlane(vec3 P0, vec3 V, int oIndex, out Hit hit){
    vec3 N = objects[oIndex].xyz; //normal
    vec3 Q0 = vec3(0,0,-objects[oIndex].w/objects[oIndex].z); //point on Plane
    float t = dot(N,(Q0-P0)/dot(N,V));

    if(dot(V,N) == 0.0) return false;

    hit.hitPoint = P0 + t*V;
    hit.exitPoint = hit.hitPoint;
    hit.hitIndex = oIndex;
    return true;
}

bool intersection(vec3 P0,vec3 V,out Hit hit_ret,int currObjIndex)
{
    float minDistance = -1.;
    for(int i=0; i < sizes.x; i++)
    {
        Hit hit;
        if ( i!=currObjIndex && (((objects[i].w >= 0) && isIntersectSphere(P0, V, i,hit)) ||
            ((objects[i].w < 0) && isIntersectPlane(P0, V, i,hit)))){
                float dist = distance(hit.hitPoint,P0);
                if(minDistance == -1 || dist < minDistance){
                    minDistance = dist;
                    hit_ret = hit;
                }      
            }  
    }
    return minDistance != -1;
    
}

vec3 calcSpotlight(Hit hit,int lightIndex){
    //Slide 39 - Is K_c , K_l and K_q missing ?
    //Check here if you are hit other object (that is not yourself!), if yes color is black
    return vec3(0,0,0);
}

vec3 calcDirectonalLight(Hit hit,int lightIndex,vec3 V){
    //Slide 38
    return lightsIntensity[lightIndex]*dot(lightsDirection[lightIndex].xyz,V);
}

vec3 colorCalc(vec3 srcPoint)
{
    Hit hit;
    vec3 V = calcDirVec(srcPoint);
    if(!intersection(srcPoint,V,hit,-1))
        return vec3(0.5,0,0.5); //Flat background color
    int countLights = 1;
    //Iterate all over Lights
    vec3 color = vec3(0,0,0);
    for(int i=0;i<sizes.y;i++){
        if(lightsDirection[i].w >= 0.5){ //Spotlight
            color+= calcSpotlight(hit,i)*objColors[hit.hitIndex].xyz;
        }
        else{ //Directonal
            color+= calcDirectonalLight(hit,i,V)*objColors[hit.hitIndex].xyz;
        }
    }
    return color/countLights;
}

void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}