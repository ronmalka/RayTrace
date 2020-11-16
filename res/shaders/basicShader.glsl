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
    float enter;
    float exit;
};

// vector dir - calc eye and pixel vector

vec3 calcDirVec() 
{
    int width = sizes.z;
    int high = sizes.w;

    vec3 pc = vec3(high/2,width/2,0);
    vec3 p0 = vec3(eye.xyz);
    vec3 v= vec3(0,1,0);
 
    vec3 t = normalize(position1 - p0);

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

bool isIntersectSphere(vec3 sourcePoint,vec3 v, vec4 sphereInfo, out Hit hit)
{
    float r =sphereInfo.w;
    float t = dot(sourcePoint - sphereInfo.xyz , v);
    vec3 p = sourcePoint + t * v;
    float y = length(sourcePoint - p);
    float x = r*r - y*y;
    
    if(x<0)
        return false;

    x= sqrt(x);
    float t1 = x + t;
    float t2 = x - t;

    hit.enter = t1;
    hit.exit = t2;

    return true;
    
}

bool isIntersectPlane(vec3 sourcePoint,vec3 v, vec4 sphereInfo, out Hit hit){
    return true;
}
//loop for every object and check hit with the ray

//init color

//loop for every depth and ray 


bool intersection(vec3 sourcePoint,vec3 v,out Hit hit_ret,out vec3 pointHit)
{
    float minDistance = -1.;
    vec3 enter = vec3(0,0,0);
    for(int i=0; i < sizes.x; i++)
    {
        Hit hit;
        if (objects[i].w >= 0){
            if(isIntersectSphere(sourcePoint, v, objects[i],hit)){ 
                if(minDistance == -1 || hit.enter < minDistance){
                    pointHit = sourcePoint.xyz + v*hit.enter; 
                    minDistance = hit.enter;
                    hit_ret = hit;
                }  
           }
        }     
        else{
            if(isIntersectPlane(sourcePoint, v, objects[i],hit)){
                if(minDistance == -1 || hit.enter < minDistance){
                    pointHit = sourcePoint.xyz + v*hit.enter;
                    minDistance = hit.enter;
                    hit_ret = hit;
                }  
            }
        }
         
    }
    return minDistance != -1;
    
}

vec3 colorCalc(vec3 srcPoint)
{
    vec3 color = vec3(0.5,0,0.5);
    
    return color;
}

void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}