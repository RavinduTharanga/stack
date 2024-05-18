set(NSS_WRAPPER_LIBRARY /opt/bitnami/common/lib/libnss_wrapper.so)

# Load information for each installed configuration.
file(GLOB _cmake_config_files "${CMAKE_CURRENT_LIST_DIR}/nss_wrapper-config-*.cmake")
foreach(_cmake_config_file IN LISTS _cmake_config_files)
    include("${_cmake_config_file}")
endforeach()
unset(_cmake_config_files)
unset(_cmake_config_file)

include(FindPackageMessage)
find_package_message(nss_wrapper
                     "Found nss_wrapper: ${NSS_WRAPPER_LIBRARY} (version \"${PACKAGE_VERSION}\")"
                     "[${NSS_WRAPPER_LIBRARY}][${PACKAGE_VERSION}]")
