require 'rails_helper'

RSpec.describe "Home", type: :request do
  it "GET / は 200 を返す" do
    get root_path
    expect(response).to have_http_status(:ok)
  end
end
