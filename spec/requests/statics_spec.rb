require 'rails_helper'

RSpec.describe "Statics", type: :request do
  it 'GET /static/terms_of_service は200' do
    get "/static/terms_of_service"
    expect(response).to have_http_status(:ok)
  end

  it 'GET /static/privacy_policy は200' do
    get "/static/privacy_policy"
    expect(response).to have_http_status(:ok)
  end
end


