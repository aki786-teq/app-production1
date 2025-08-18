require 'rails_helper'

RSpec.describe "Boards session prefill", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'session[:stretch_measurement_data] があると new に本文自動入力し、消費後に削除される' do
    session_data = { 'flexibility_level' => 'good', 'comment' => 'コメント', 'created_at' => Time.current.strftime('%Y年%m月%d日 %H:%M') }
    # セッション付与のために result→create_post_with_result を通す
    sd = create(:stretch_distance, user: user)
    post create_post_with_result_stretch_distance_path(sd)
    follow_redirect!

    # boards#newへ到達
    expect(response).to have_http_status(:ok)
    # セッションは消される
    expect(session[:stretch_measurement_data]).to be_nil
  end
end


