require 'mkmf'

# Stops the installation process if one of these commands is not found in
# $PATH.
find_executable('make')
find_executable('gcc')

# Go to 'minimization/lib/opencl' directory and runs the makefile.
# The shared library 'cl.so' will be created at 'minimization/lib/opencl'
exec 'cd ../../lib/opencl/ ; make'

# This is normally set by calling create_makefile() but we don't need that
# method since we'll provide a dummy Makefile. Without setting this value
# RubyGems will abort the installation.
$makefile_created = true
