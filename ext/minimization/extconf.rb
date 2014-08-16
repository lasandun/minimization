require 'mkmf'

# Stops the installation process if one of these commands is not found in
# $PATH.
find_executable('make')

# Create a dummy extension file. Without this RubyGems would abort the
# installation process. On Linux this would result in the file "wat.so"
# being created in the current working directory.
#
# Normally the generated Makefile would take care of this but since we
# don't generate one we'll have to do this manually.
#
File.touch(File.join(Dir.pwd, 'dummy.' + RbConfig::CONFIG['DLEXT']))

# This is normally set by calling create_makefile() but we don't need that
# method since we'll provide a dummy Makefile. Without setting this value
# RubyGems will abort the installation.
$makefile_created = true
	true
