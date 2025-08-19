require 'rails_helper'

RSpec.describe "Health", type: :request do
  it "GET /up は 200 を返す" do
    get "/up"
    expect(response).to have_http_status(:ok)
  end
end
