#include "raytrace.h"
#include <iostream>
#include "GL/glew.h"
#include <glm/glm.hpp>


static void printMat(const glm::mat4 mat)
{
	std::cout<<" matrix:"<<std::endl;
	for (int i = 0; i < 4; i++)
	{
		for (int j = 0; j < 4; j++)
			std::cout<< mat[j][i]<<" ";
		std::cout<<std::endl;
	}
}

raytrace::raytrace() : Scene()
{
	zoom = 1.;
	offset_x = 0.;
	offset_y = 0.;
	
}

//raytrace::raytrace(float angle ,float relationWH, float near, float far) : Scene(angle,relationWH,near,far)
//{ 	
//}

void raytrace::Init()
{		
	unsigned int texIDs[3] = { 0 , 1, 0};
	unsigned int slots[3] = { 0 , 1, 0 };
	
	AddShader("../res/shaders/pickingShader");	
	AddShader("../res/shaders/basicShader");
	AddTexture("../res/textures/pal.png",1);
	//TextureDesine(840, 840);

	AddMaterial(texIDs,slots, 1);
	
	AddShape(Plane, -1, TRIANGLES);
	SetShapeShader(0, 1);
}

void raytrace::Update(const glm::mat4 &MVP,const glm::mat4 &Model,const int  shaderIndx)
{	
	Shader *s = shaders[shaderIndx];
	int r = ((pickedShape+1) & 0x000000FF) >>  0;
	int g = ((pickedShape+1) & 0x0000FF00) >>  8;
	int b = ((pickedShape+1) & 0x00FF0000) >> 16;
	if (shapes[pickedShape]->GetMaterial() >= 0 && !materials.empty())
		BindMaterial(s, shapes[pickedShape]->GetMaterial());
	//textures[0]->Bind(0);
	s->Bind();
	if (shaderIndx != 1)
	{
		s->SetUniformMat4f("MVP", MVP);
		s->SetUniformMat4f("Normal", Model);
	}
	else
	{
		s->SetUniformMat4f("MVP", glm::mat4(1));
		s->SetUniformMat4f("Normal", glm::mat4(1));
	}
	//s->SetUniform1i("sampler1", materials[shapes[pickedShape]->GetMaterial()]->GetSlot(0));
	if(shaderIndx!=1)
		s->SetUniform1i("sampler2", materials[shapes[pickedShape]->GetMaterial()]->GetSlot(1));
	//s->SetUniform1ui("counter", counter);
	//s->SetUniform1f("x", x);
	//s->SetUniform1f("y", y);
	//s->SetUniform1ui("power", power);
	s->SetUniform4fv("objects",scnData->objects.data(),scnData->objects.size());
	s->SetUniform4fv("objColors", scnData->colors.data(), scnData->colors.size());
	s->SetUniform4fv("lightsDirection", scnData->directions.data(), scnData->directions.size());
	s->SetUniform4fv("lightsIntensity", scnData->intensities.data(), scnData->intensities.size());
	s->SetUniform4fv("lightPosition", scnData->lights.data(), scnData->lights.size());
	s->SetUniform4f("eye",scnData->eye[0], scnData->eye[1], scnData->eye[2], scnData->eye[3]);
	s->SetUniform4f("ambient",scnData->ambient[0], scnData->ambient[1], scnData->ambient[2], scnData->ambient[3]);
	s->SetUniform4i("sizes", scnData->sizes[0], scnData->sizes[1], scnData->sizes[2], scnData->sizes[3]);
	s->SetUniform1f("zoom", zoom);
	s->SetUniform1f("offset_x", offset_x);
	s->SetUniform1f("offset_y", offset_y);
	s->Unbind();
}


void raytrace::UpdatePosition(float xpos,  float ypos)
{
	int viewport[4];
	glGetIntegerv(GL_VIEWPORT, viewport);
	x = xpos / viewport[2];
	y = 1 - ypos / viewport[3];
}

void raytrace::setNewOffset(double xpos, double ypos) {
	int viewport[4];
	glGetIntegerv(GL_VIEWPORT, viewport);
	offset_x += (xpos - old_x) / viewport[2];
	offset_y += (old_y - ypos) / viewport[3];
	offset_x = offset_x * 0.7;
	offset_y = offset_y * 0.7;
	
	std::cout << " offset_x: " << offset_x << "\n" << std::endl;
	std::cout << " offset_y: " << offset_y << "\n" << std::endl;

}

void raytrace::updatePressedPos(double xpos, double ypos) {
	int viewport[4];
	glGetIntegerv(GL_VIEWPORT, viewport);
	old_x = xpos;
	old_y = ypos;
}
bool raytrace::solveQuadricEquasion(float a, float b, float c, glm::vec2& result) {
	float root = b * b - 4 * a * c;
	if (root < 0) return false;
	root = sqrt(root);
	result.x = (-b - root) / (2 * a);
	result.y = (-b + root) / (2 * a);
	return true;
}

void raytrace::updateSpherePosition(int index, double x, double y) {

}

float raytrace::isIntersectSphere(glm::vec3 dir, int oIndex) {
	glm::vec3 sphere (scnData->objects[oIndex]);
	glm::vec3 eye(scnData->eye);
	float r = scnData->objects[oIndex][3];
	float t = INFINITY;
	float a = 1.0;
	glm::vec3 tmp = eye - sphere;
	glm::vec3 dir2 = 2.0f * dir; 
	float b = glm::dot(dir2, tmp);
	float c = glm::dot(tmp, tmp) - r * r;

	glm::vec2 result;
	if (!solveQuadricEquasion(a, b, c, result)) return INFINITY;

	t = glm::min(result.x, result.y);
	if (t < 0) {
		t = glm::max(result.x, result.y);
	}
	if (t <= 0.0) {
		t = INFINITY;
	}
	return t;
}

int raytrace::findMinIntersection(glm::vec3 dir) {
	int index = -1;
	int minDistance = INFINITY;
	float t = 0;
	for (int i = 0; i < scnData->sizes[0]; i++) {
			if (scnData->objects[i].w > 0.0) {
				t = isIntersectSphere(dir, i);
				if (t < minDistance) {
					minDistance = t;
					index = i;
				}
			}	
	}
	std::cout << "index: " << index << std::endl;
	return index;
}

void raytrace::WhenRotate()
{
	//std::cout << "x "<<x<<", y "<<y<<std::endl;
	
}

void raytrace::WhenTranslate()
{
}



void raytrace::Motion()
{
	if(isActive)
	{
	}
}

unsigned int raytrace::TextureDesine(int width, int height)
{
	unsigned char* data = new unsigned char[width * height * 4];
	for (size_t i = 0; i < width; i++)
	{
		for (size_t j = 0; j < height; j++)
		{
			data[(i * height + j) * 4] = (i + j) % 256;
			data[(i * height + j) * 4 + 1] = (i + j * 2) % 256;
			data[(i * height + j) * 4 + 2] = (i * 2 + j) % 256;
			data[(i * height + j) * 4 + 3] = (i * 3 + j) % 256;
		}
	}
	textures.push_back(new Texture(width, height));
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data); //note GL_RED internal format, to save 
	glBindTexture(GL_TEXTURE_2D, 0);
	delete[] data;
	return(textures.size() - 1);
}

raytrace::~raytrace(void)
{

}
