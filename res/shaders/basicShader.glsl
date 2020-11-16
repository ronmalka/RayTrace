 #version 130 

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

    vec2 pc = vec2(high / 2 , width / 2 ); 

    vec3 p0 = vec3 (eye.xyz );

    vec3 v= vec3(0,1,0) ;
 
    vec3 t = normalize(position1 - eye);

    vec3 b = normalize(cross(v,t));

    vec3 v_normal = cross(t,b);
    
    vec3 c = eye.xyz + t;

    float rx = width /2 ;
    float ry = high / 2;
    float R = 1 ;

    vec3 p = pc + b*(position1.x - abs(rx/2)) * R - v_normal * (position1.y - abs(ry/2)) * R ;

     
}

//calc shape intersect - sphere, plane

bool intersectionSphere(vec3 sourcePoint,vec3 v, vec4 sphereInfo, out Hit hit)
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


//loop for every object and check hit with the ray

//init color

//loop for every depth and ray 


float intersection(vec3 sourcePoint,vec3 v)
{
    float color;
    Hit hit;
    int i = 0 ; 

    int minHitIndex = -1;
    float minDistance = 999999.;
    vec3 enter = vec3(0,0,0);
    for( i=0; i < sizes.x; i++)
    {
        if (objects[i].w >= 0){
            if(intersectionSphere(sourcePoint, v, objects[i],hit)){ 
                if(hit.enter < minDistance){
                    enter = sourcePoint.xyz + v*hit.enter; 
                    minHitIndex = i;
                    minDistance = hit.enter;
                }  
                color = calcColor(); 
           }
        }     
        else{
            if(intersectionPlane(sourcePoint, v, objects[i],hit)){
                if(hit.enter < minDistance){
                    enter = sourcePoint.xyz + v*hit.enter;
                    minHitIndex = i;
                    minDistance = distance;
                }  
                color = calcColor();   
            }
        }
         
    }
    if(minHitIndex != -1){
        color += calcLight(objects[minHitIndex]);
    }
    else{
        color = backgroundColor;
    }
    return color;
    
}

vec3 colorCalc( vec3 intersectionPoint)
{
    vec3 color = vec3(1,0,1);
    
    return color;
}

void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}