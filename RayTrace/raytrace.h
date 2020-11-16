#pragma once
#include "scene.h"

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
	inline void ResetCounter() { tmp = counter; counter = 0; }
	inline void SetCounter() { counter = tmp; }

	void UpdatePosition( float xpos, float ypos);
private:
	unsigned int counter;
	unsigned int tmp;
	float x, y;
	unsigned int power;
};

