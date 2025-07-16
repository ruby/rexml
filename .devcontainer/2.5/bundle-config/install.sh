#!/bin/sh
RUBYGEMS_VERSION=3.3.27
gem install rubygems-update -v ${RUBYGEMS_VERSION} > /dev/null 2>&1 &&
update_rubygems > /dev/null 2>&1
# Depends on making a copy of the Gemfile, so we don't conflict with the Gemfile.lock
#   that is probably relegated to newer Ruby.
# We need to set the ENV variable here, but must wait to copy the Gemfile until the postCreateCommand hook.
# Ensure we use the right Gemfile
echo 'export BUNDLE_GEMFILE=Gemfile-ruby2_5.gemfile' >> ~/.bashrc
