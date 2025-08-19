require 'rails_helper'

RSpec.describe "StretchDistances", type: :request do
  let(:user) { create(:user) }

  describe 'アクセス制御（連続投稿未達）' do
    let!(:goal) { create(:goal, user: user, goal: '床に指', content: '毎日') }

    before { sign_in user }

    it 'GET /stretch_distances/measure は未達ならリダイレクト' do
      get measure_stretch_distances_path
      expect(response).to redirect_to(root_path)
    end

    it 'POST /stretch_distances/analyze は未達ならリダイレクト' do
      post analyze_stretch_distances_path, params: { stretch_distance: { flexibility_level: 'good' } }
      expect(response).to redirect_to(root_path)
    end

    it 'POST /stretch_distances/:id/create_post_with_result は未達ならリダイレクト' do
      sd = create(:stretch_distance, user: user)
      post create_post_with_result_stretch_distance_path(sd)
      expect(response).to redirect_to(root_path)
    end
  end

  describe '正常系（連続投稿達成）' do
    let!(:goal) { create(:goal, user: user, goal: '床に指', content: '毎日') }

    before do
      # 昨日から過去4日分の投稿を作成して連続投稿達成状態にする
      (1..4).each do |i|
        create(:board, user: user, goal: goal, created_at: i.days.ago)
      end
      sign_in user
    end

    it 'GET /stretch_distances/measure は 200' do
      get measure_stretch_distances_path
      expect(response).to have_http_status(:ok)
    end

    it 'POST /stretch_distances/analyze 成功時は JSON success: true を返す' do
      post analyze_stretch_distances_path, params: { stretch_distance: { flexibility_level: 'good', comment_template: '任意' } }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(true)
      expect(json['stretch_distance_id']).to be_present
      expect(json['result_url']).to be_present
    end

    it 'POST /stretch_distances/analyze 失敗時は 422' do
      post analyze_stretch_distances_path, params: { stretch_distance: { flexibility_level: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(false)
    end

    it 'GET /stretch_distances/:id/result は 200' do
      sd = create(:stretch_distance, user: user)
      get result_stretch_distance_path(sd)
      expect(response).to have_http_status(:ok)
    end

    it 'GET /stretch_distances/:id/result 他人のID/未所持IDはリダイレクト' do
      other = create(:user)
      other_goal = create(:goal, user: other)
      sd = create(:stretch_distance, user: other)
      get result_stretch_distance_path(sd)
      expect(response).to redirect_to(measure_stretch_distances_path)
    end

    it 'POST /stretch_distances/:id/create_post_with_result はセッション設定して boards/new へリダイレクト' do
      sd = create(:stretch_distance, user: user)
      post create_post_with_result_stretch_distance_path(sd)
      expect(response).to redirect_to(new_board_path(stretch_distance_id: sd.id))
      expect(session[:stretch_measurement_data]).to be_present
    end
  end
end

require 'rails_helper'

RSpec.describe "StretchDistances", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  it '連続投稿条件を満たさないと /stretch_distances/measure はリダイレクト' do
    sign_in user
    get measure_stretch_distances_path
    expect(response).to redirect_to(root_path)
  end

  it '4日分の投稿があると /stretch_distances/measure は 200' do
    sign_in user
    # 昨日から4日分の日時で投稿を作成
    (1..4).each do |i|
      create(:board, user: user, goal: goal, created_at: i.days.ago)
    end
    get measure_stretch_distances_path
    expect(response).to have_http_status(:ok)
  end
end
