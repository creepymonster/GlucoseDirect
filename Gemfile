source "https://rubygems.org"

gem "fastlane", "2.235.0"

# Work around an upstream googleapis/fastlane bug where fastlane 2.235.0 loads
# google-apis-* which requires multi_json, but newer google-apis-core no longer
# pulls it in — so it must be declared explicitly (fixed upstream in fastlane
# 2.236.0). Without this, `bundle exec fastlane` fails at load time with
# "multi_json is not part of the bundle".
gem "multi_json"
