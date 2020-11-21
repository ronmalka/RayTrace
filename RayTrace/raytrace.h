#pragma once
#include "scene.h"
#include "sceneParser.h"
#include <glm/glm.hpp>

#define INFINITY 9999

class raytrace : public Scene
{
public:
	
	raytrace();
	void Init();
	void Update(const glm::mat4 &MVP,const glm::mat4 &Model,const int  shaderIndx);
	
	void WhenRotate();
	void WhenTranslate();
	void Motion();
	
	unsigned int TextureDesine(int width, int height);
	~raytrace(void);
	inline void setScnData(SceneData* data) { scnData = data; }

	void UpdatePosition( float xpos, float ypos);
	void updatePressedPos(double xpos, double ypos);
	void setNewOffset(double x, double y);
	void updateSpherePosition(int index, double x, double y,float move);
	int findMinIntersection(glm::vec3 dir);
	float isIntersectSphere(glm::vec3 dir, int oIndex);
	bool solveQuadricEquasion(float a, float b, float c,  glm::vec2 &result);
	inline void doZoom(double yoffset) { zoom = yoffset > 0 ? zoom * pow(0.5, yoffset) : zoom * pow(2, -yoffset); }
	inline float getZoom() { return zoom; }
	inline void setNormalX(float x) { normal_x = x; }
	inline void setNormalY(float y) { normal_y = y; }
	inline float getNormalX() { return normal_x; }
	inline float getNormalY() { return normal_y; }
	inline SceneData* getSceneData() { return scnData; }

private:
	float x, y;
	float zoom;
	float old_x;
	float old_y;
	float offset_x;
	float offset_y;
	float normal_x;
	float normal_y;
	SceneData* scnData;
};

