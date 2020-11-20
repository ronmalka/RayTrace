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

bool solveQuadricEquasion(float a,float b,float c,out vec2 result){
    float root = b*b - 4*a*c;
    if(root < 0) return false;
    root = sqrt(root);
    result.x = (-b - root)/(2*a);
    result.y = (-b + root)/(2*a);
    return true;
}

bool isIntersectSphere(vec3 P0, vec3 V, int oIndex, out Hit hit){
    float a = 1.0;
    vec3 tmp = P0-objects[oIndex].xyz;
    float b = dot(2*V,tmp);
    float c = dot(abs(tmp),abs(tmp)) - objects[oIndex].w*objects[oIndex].w;

    vec2 result;
    if(!solveQuadricEquasion(a,b,c,result)) return false;

    float t = min(result.x,result.y);
    if(t < 0){
        t = max(result.x,result.y);
    }
    if(t <= 0.0) return false;

    hit.hitPoint = P0+t*V;
    hit.hitIndex = oIndex;
    hit.normal = normalize(hit.hitPoint - objects[oIndex].xyz);
    hit.t = t;

    return true;

}

bool isIntersectPlane(vec3 P0, vec3 V, int oIndex, out Hit hit){
    vec3 N = normalize(objects[oIndex].xyz); //normal maybe - ????
    vec3 Q0 = vec3(0,0,-objects[oIndex].w/objects[oIndex].z); //point on Plane
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
    float minDistance = -1;
    bool found = false;
    for(int i=0; i < sizes.x; i++)
    {
        bool flag = false;
        Hit hit;
        if(i!=currObjIndex){
            if(objects[i].w > 0.0){
                flag = isIntersectSphere(P0, V, i, hit);
            }
            else{
                flag = isIntersectPlane(P0, V, i, hit);
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
    Hit next_hit;
    vec3 V;
    if(lightsDirection[lightIndex].w > 0.5)//Spotlight
    {
        vec3 L = normalize(hit.hitPoint - lightPosition[lightIndex].xyz);
        vec3 D = normalize(lightsDirection[lightIndex].xyz);
        if(dot(D,L) < lightPosition[lightIndex].w) return true;
        V = -L;
    }
    else//Directonal
    {
        V = -normalize(lightsDirection[lightIndex].xyz);
    }
    if(intersection(hit.hitPoint,V, next_hit, hit.hitIndex))
    {
        if(lightsDirection[lightIndex].w > 0.5){

            if(length(lightPosition[lightIndex].xyz - hit.hitPoint) > length(next_hit.hitPoint - hit.hitPoint))
                return true;
        }
        else{
            return true;
        }
    }
    return false;
}

vec3 colorCalc(vec3 srcPoint)
{
    Hit hit;
    vec3 Ks = vec3(0.7,0.7,0.7);
    vec3 V = normalize(position1 - srcPoint);
    if(!intersection(srcPoint,V,hit,-1))
        return vec3(0.5,0,0.2); //Flat background color
    
    //Iterate all over Lights
    vec3 color = vec3(0,0,0);
    for(int i=0;i<4;++i){
            vec3 Ia = ambient.xyz; // amibent
    vec3 Ka = objColors[hit.hitIndex].xyz;
    vec3 Kd = objColors[hit.hitIndex].xyz;

    color += Ia * Ka;
    
    for(int i=0;i<sizes.y;i++){
        if(!isOccluded(hit,i)){
            vec3 Li;
            vec3 D = lightsDirection[i].xyz;
            vec3 N = hit.normal;
            if(lightsDirection[i].w > 0.5){
                Li = normalize(lightPosition[i].xyz - hit.hitPoint);
            }
            else{
                Li = -normalize(lightsDirection[i].xyz);
            }

            V = normalize(srcPoint - hit.hitPoint);
            vec3 R = reflect(-Li,N);
            float diffDot = dot(N,Li);
            float specDot = dot(V,R);
            vec3 diffuse = vec3(0,0,0);
            vec3 specular = vec3(0,0,0);
            if(diffDot > 0){
                diffuse =  Kd * diffDot;
            }
            if(specDot > 0){
                specular = Ks * pow(specDot, objColors[hit.hitIndex].w);
            }
            color+= (diffuse+specular)*lightsIntensity[i].xyz*dot(D,N);
        }
    }

    }
    return color;
}

void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}