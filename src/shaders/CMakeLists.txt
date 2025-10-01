include(shaders)

compile_shader(shaders GLSL ${PROJECT_NAME} SOURCES
  basic
  raytrace
  INCLUDES
  material
  objects
  rand
  ray
  util
  uv
)
