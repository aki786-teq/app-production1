require 'rails_helper'

RSpec.describe "Boards search_items success", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it '正常系: アイテム配列のJSON形状を返す' do
    fake_item = {
      'itemCode' => 'code123',
      'itemName' => 'name',
      'itemPrice' => 1000,
      'itemUrl' => 'https://example.com/item',
      'affiliateUrl' => nil,
      'smallImageUrls' => ['https://img/small.jpg'],
      'mediumImageUrls' => ['https://img/medium.jpg']
    }

    fake_enum = [fake_item]
    allow(RakutenWebService::Ichiba::Item).to receive(:search).and_return(fake_enum)

    get search_items_boards_path, params: { keyword: 'yoga' }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json['items'].first['item_code']).to eq('code123')
    expect(json['items'].first['item_url']).to eq('https://example.com/item')
  end
end


