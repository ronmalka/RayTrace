# RayTrace

This assignment has been made as a part of the Computer Graphics course that I took in my bachelor's degree in computer science at Ben-Gurion University.

The concept of ray tracing: a technique for generating an image by tracing the path of light through pixels in an image plane and simulating the effects of its encounters with virtual objects.
The technique can produce a very high degree of visual realism, usually higher than that of typical scan line rendering methods, but at a greater computational cost.
The objective of this exercise is to implement a ray casting/tracing engine. A ray tracer shoots rays from the observer’s eye through a screen and into a scene of objects. It calculates the ray’s
intersection with objects finds the nearest intersection and calculates the color of the surface according to its material and lighting conditions.

The feature set that was implemented in this assignment is as follows:
● Background
         o Plain color background
● Display geometric primitives in space:
         o Spheres
         o Planes
● Basic lighting
         o Directional lights
         o Spotlights 
         o Ambient light
         o Simple materials (ambient, diffuse, specular...)
● Basic hard shadows
● Reflection, up to 5 recursive steps (mirror) after 5 steps take the material properties of
the last mirror the ray hits.
● Ray picking

![raytrace2](https://user-images.githubusercontent.com/43497130/110621268-ae118180-81a2-11eb-9db5-6db157d9fdcc.png)
![raytrace3](https://user-images.githubusercontent.com/43497130/110621273-aeaa1800-81a2-11eb-89ba-2f3643c5045a.png)
![raytrace4](https://user-images.githubusercontent.com/43497130/110621276-af42ae80-81a2-11eb-8454-f6b1d339f804.png)
![raytrace5](https://user-images.githubusercontent.com/43497130/110621278-afdb4500-81a2-11eb-9879-8b1a86cc22f5.png)
![raytrace1](https://user-images.githubusercontent.com/43497130/110621280-afdb4500-81a2-11eb-8b92-4d511f6ae799.png)
