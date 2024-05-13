file(GLOB analysis_HEADERS *.h lattices/*.h)
set(analysis_SOURCES
  callgraph.cpp
  cfg.cpp
  ${analysis_HEADERS}
)
target_sources(binaryen PRIVATE ${analysis_SOURCES})
