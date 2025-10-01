require 'rails_helper'

RSpec.describe 'ユーザー登録から投稿まで', type: :system do
  it '新規登録 → 目標作成 → 投稿作成 → 投稿表示 ができる' do
    # 新規登録
    visit new_user_registration_path
    within('form#new_user') do
      fill_in 'user_name', with: 'SystemTester'
      fill_in 'user_email', with: 'system@example.com'
      fill_in 'user_password', with: 'password123'
      fill_in 'user_password_confirmation', with: 'password123'
      find('input[name="commit"]').click
    end

    # 目標作成にリダイレクトされる
    expect(page).to have_current_path(new_goal_path)
    fill_in '目標（必須）', with: '床に指がつく'
    fill_in '内容（必須）', with: '毎日3分ストレッチ'
    find('input[type="submit"].my-orange-btn').click

    # 投稿作成ページに遷移（成功フラッシュ）
    expect(page).to have_current_path(new_board_path)

    # 投稿作成
    # did_stretch を「やった！」にする（ラベルクリックで対応）
    find('label[for="did_stretch_yes"]').click
    fill_in '今日の記録', with: 'きょうもがんばった'
    find('input[type="submit"].my-orange-btn, button.my-orange-btn', match: :first).click

    # 一覧ページに遷移し、200 で表示される
    expect(page).to have_current_path(boards_path)
    expect(page).to have_content('みんなの投稿')
  end
end
