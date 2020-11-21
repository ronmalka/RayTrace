#pragma once   //maybe should be static class
#include "display.h"
#include "renderer.h"
#include "raytrace.h"
#include <iostream>

bool pressed = false;
bool spherePressed = false;
int index = -1;

void mouse_callback(GLFWwindow* window, int button, int action, int mods)
{
}

void scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
{
	Renderer* rndr = (Renderer*)glfwGetWindowUserPointer(window);
	raytrace* scn = (raytrace*)rndr->GetScene();
	scn->doZoom(yoffset);
	std::cout << "Width: " << scn->getZoom() / 840 << std::endl;
}

void cursor_position_callback(GLFWwindow* window, double xpos, double ypos)
{

	Renderer* rndr = (Renderer*)glfwGetWindowUserPointer(window);
	raytrace* scn = (raytrace*)rndr->GetScene();

	if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT) == GLFW_PRESS)
	{
		if (!spherePressed) {
			spherePressed = !spherePressed;
			int viewport[4];
			glGetIntegerv(GL_VIEWPORT, viewport);
			float normal_x;
			float normal_y;

			normal_x = xpos - (viewport[2] / 2);
			normal_x = normal_x / (viewport[2] / 2);

			normal_y = ypos - (viewport[3] / 2);
			normal_y = -(normal_y / (viewport[3] / 2));

			scn->setNormalX(normal_x);
			scn->setNormalY(normal_y);

			glm::vec3 eye(scn->getSceneData()->eye);
			glm::vec3 dir(glm::vec3(normal_x, normal_y, 0)*scn->getZoom() - eye);
			index = scn->findMinIntersection(glm::normalize(dir));

			//if(index!=-1) scn->updateSpherePosition(index, xpos, ypos,0);
		}
		else {
			if (index != -1) {
				scn->updateSpherePosition(index,xpos,ypos,0.02);
			}
		}
		rndr->MouseProccessing(GLFW_MOUSE_BUTTON_RIGHT);
	}
	else if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS)
	{
		if (!pressed) {
			pressed = !pressed;
			scn->updatePressedPos(xpos, ypos);
		}
		else {
			scn->setNewOffset(xpos, ypos);
		}
		rndr->MouseProccessing(GLFW_MOUSE_BUTTON_LEFT);
	}
	else if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_RELEASE)
	{
		if (pressed) {
			pressed = !pressed;
			rndr->MouseProccessing(GLFW_MOUSE_BUTTON_LEFT);
		}

		if (spherePressed) {
			spherePressed = !spherePressed;
			index = -1;
			rndr->MouseProccessing(GLFW_MOUSE_BUTTON_RIGHT);
		}
	}

}

void window_size_callback(GLFWwindow* window, int width, int height)
{
	Renderer* rndr = (Renderer*)glfwGetWindowUserPointer(window);

	rndr->Resize(width, height);

}

void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
	Renderer* rndr = (Renderer*)glfwGetWindowUserPointer(window);
	raytrace* scn = (raytrace*)rndr->GetScene();

	if (action == GLFW_PRESS || action == GLFW_REPEAT)
	{
		switch (key)
		{
		case GLFW_KEY_ESCAPE:
			glfwSetWindowShouldClose(window, GLFW_TRUE);
			break;

		case GLFW_KEY_SPACE:
			if (scn->IsActive())
				scn->Deactivate();
			else
				scn->Activate();
			break;

		case GLFW_KEY_UP:

			break;

		case GLFW_KEY_DOWN:

			break;

		case GLFW_KEY_RIGHT:

			break;

		case GLFW_KEY_LEFT:
		
			break;

		default:
			break;
		}
	}
}

void Init(Display& display)
{
	display.AddKeyCallBack(key_callback);
	display.AddMouseCallBacks(mouse_callback, scroll_callback, cursor_position_callback);
	display.AddResizeCallBack(window_size_callback);
}
