#include "logger.hpp"
#include <gl/gl.hpp>
#include <glm/glm.hpp>

struct BasicVertex {
  glm::vec2 position;
};

std::array<BasicVertex, 3> fullscreenTriangle = {
    BasicVertex{.position = {-1.0f, -1.0f}},
    BasicVertex{.position = {3.0f, -1.0f}},
    BasicVertex{.position = {-1.0f, 3.0f}},
};

constexpr int WINDOW_WIDTH = 1904;
constexpr int WINDOW_HEIGHT = 1190;

int main() {
  Logger::info("Starting application");
  auto& wm = gl::WindowManager::get();

  gl::Window window(WINDOW_WIDTH, WINDOW_HEIGHT, "Radiance Cascades FLOAT",
                    true);
  int version = wm.getGlVersion();

  if (version == 0) {
    Logger::error("Failed to initialize OpenGL context");
    return -1;
  }

  Logger::info("Loaded OpenGL {}.{}\n", GLVersion.major, GLVersion.minor);

  GLint maxSamples;
  glGetIntegerv(GL_MAX_SAMPLES, &maxSamples);
  Logger::info("Max MSAA samples supported: {}\n", maxSamples);

  gl::gui::Context gui(window);

  glm::vec4 clearColor(0.0f, 0.0f, 0.0f, 0.0f);
  glClearColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w);

  auto raytraceOpt =
      gl::Program::fromFiles({{"raytrace_vert.glsl", gl::Shader::VERTEX},
                              {"raytrace_frag.glsl", gl::Shader::FRAGMENT}});
  if (!raytraceOpt.has_value()) {
    Logger::error("Failed to load raymarch shader: {}", raytraceOpt.error());
    return -1;
  }
  auto& raytraceProgram = raytraceOpt.value();
  raytraceProgram.bind();

  gl::BasicBuffer fullscreenVbo(static_cast<GLuint>(fullscreenTriangle.size()) *
                                    sizeof(BasicVertex),
                                fullscreenTriangle.data());
  gl::Vao fullscreenVao;
  fullscreenVao.bindVertexBuffer(0, fullscreenVbo.id(), 0, sizeof(BasicVertex));
  fullscreenVao.attribFormat(0, 2, GL_FLOAT, false, 0, 0);

  fullscreenVao.bind();

  auto oldWindowSize = window.size();
  glm::vec2 fsize = {static_cast<float>(oldWindowSize.width),
                     static_cast<float>(oldWindowSize.height)};

  gl::Texture2DMultiSample outputTexture{};
  outputTexture.storage(
      maxSamples, GL_RGBA32F,
      gl::Texture::Size{oldWindowSize.width, oldWindowSize.height});

  gl::Framebuffer framebuffer;
  framebuffer.attachTexture(GL_COLOR_ATTACHMENT0, outputTexture);

  struct Params {
    glm::vec2 fsize;
    float vFov = glm::radians(90.0f);
    float focalLength = 1.0f;
  };

  Params params;
  params.fsize = fsize;

  gl::StorageBuffer resUbo(sizeof(Params), &params);
  resUbo.bindBase(gl::StorageBuffer::Target::UNIFORM, 0);

  framebuffer.bind();

  glDrawArrays(GL_TRIANGLES, 0, 3);

  gl::Framebuffer::unbind();

  while (!window.shouldClose()) {
    gl::Window::pollEvents();
    if (glfwGetWindowAttrib(window, GLFW_ICONIFIED) != 0) {
      gui.sleep(10);
      continue;
    }

    framebuffer.blit(0, 0, 0, oldWindowSize.width, oldWindowSize.height, 0, 0,
                     oldWindowSize.width, oldWindowSize.height,
                     GL_COLOR_BUFFER_BIT, GL_NEAREST);

    window.swapBuffers();
  }

  return 0;
}