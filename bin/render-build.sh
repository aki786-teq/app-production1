#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate

# 一時的に追加（実行後削除推奨）
bundle exec rake user:confirm_all