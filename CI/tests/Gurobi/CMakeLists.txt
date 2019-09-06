add_executable(test_c "test_c.c")
target_link_libraries(test_c Gurobi::Gurobi)

add_executable(test_cxx "test_cxx.cc")
target_link_libraries(test_cxx Gurobi::GurobiCXX)
