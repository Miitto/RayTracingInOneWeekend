include(shaders)

compile_shader(shaders GLSL ${PROJECT_NAME} SOURCES
  basic
  raytrace
  INCLUDES
  uv
  raymarching
)
