require 'rails_helper'

RSpec.describe "Boards", type: :request do
  it "GET /boards は 200 を返す" do
    get boards_path
    expect(response).to have_http_status(:ok)
  end
end
