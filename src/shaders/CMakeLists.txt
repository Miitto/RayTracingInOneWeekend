include(shaders)

compile_shader(shaders GLSL ${PROJECT_NAME} SOURCES
  basic
  raytrace
  INCLUDES
  constants
  material
  objects
  rand
  ray
  util
  uv
)
