#!/bin/sh
RUBYGEMS_VERSION=3.3.27
gem install rubygems-update -v ${RUBYGEMS_VERSION} > /dev/null 2>&1 &&
update_rubygems > /dev/null 2>&1
# Ensure we use the right Gemfile
echo 'export BUNDLE_GEMFILE=Gemfile-ruby2_5.gemfile' >> ~/.bashrc
