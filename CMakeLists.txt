cmake_minimum_required(VERSION 3.20)
project(MyDesktopVideo LANGUAGES OBJCXX)

# Create a macOS application bundle
set(CMAKE_OSX_DEPLOYMENT_TARGET "13.0")

# Set the source files
set(SOURCES main.mm)

# Create the executable bundle
add_executable(MyDesktopVideo MACOSX_BUNDLE ${SOURCES})

# Configure Automatic Reference Counting (ARC) and Optimization
target_compile_options(MyDesktopVideo PRIVATE -fobjc-arc -O3)

# Use C++20 for code modern code support
set_target_properties(MyDesktopVideo PROPERTIES 
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
)

# Link required macOS Frameworks
target_link_libraries(MyDesktopVideo PRIVATE
    "-framework Cocoa"
    "-framework AVFoundation"
    "-framework AVKit"
    "-framework ServiceManagement"
    "-framework QuartzCore"
    "-framework UniformTypeIdentifiers"
)

# Output directory adjustment for the bundle
set_target_properties(MyDesktopVideo PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.johndiniz.MyDesktopVideo"
    MACOSX_BUNDLE_BUNDLE_NAME "MyDesktopVideo"
)
