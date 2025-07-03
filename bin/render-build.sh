#!/usr/bin/env bash
set -o errexit

bundle install
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:reset
bundle exec rails assets:precompile
bundle exec rails assets:clean
