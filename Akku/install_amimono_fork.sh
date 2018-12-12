# Akku runs a custom fork of cocoapods-amimono.
# The real plugin assumes you want all targets to have it's frameworks embedded, we don't want this for the main app, only the helper (which needs to be fully standalone)

cd cocoapods-amimono
gem build cocoapods-amimono.gemspec
gem install cocoapods-amimono-0.0.10.gem
cd ..
