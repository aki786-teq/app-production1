import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput", "results", "selectedItem",
    "itemCode", "itemName", "itemPrice", "itemUrl", "itemImageUrl"
  ]

  // 検索ボタンがクリックされた時、またはEnterキーが押された時
  async search() {
    const query = this.searchInputTarget.value.trim()

    if (!query) {
      alert('検索キーワードを入力してください')
      return
    }

    try {
      // ローディング表示
      this.showLoading()

      // 楽天APIを呼び出し
      const response = await this.fetchProducts(query)

      if (response.ok) {
        const data = await response.json()
        this.displayResults(data)
      } else {
        throw new Error('検索に失敗しました')
      }

    } catch (error) {
      console.error('検索エラー:', error)
      this.showError('検索中にエラーが発生しました')
    } finally {
      this.hideLoading()
    }
  }

  // 楽天API呼び出し
  async fetchProducts(query) {
    // タイムアウト設定
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 10000)

    try {
      const response = await fetch(`/boards/search_items?keyword=${encodeURIComponent(query)}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: controller.signal
      })

      clearTimeout(timeoutId)
      return response

    } catch (error) {
      clearTimeout(timeoutId)
      throw error
    }
  }

  // 検索結果を表示
  displayResults(data) {
    if (!data.items || data.items.length === 0) {
      this.resultsTarget.innerHTML = '<p>商品が見つかりませんでした</p>'
      this.resultsTarget.classList.remove('hidden')
      return
    }

    let html = '<div class="grid gap-4 mb-4">'

    data.items.forEach(item => {
      html += `
        <div class="border p-4 rounded">
      <img src="${item.medium_image_urls[0]}" alt="${item.item_name}" class="w-20 h-20 object-cover mb-2">
      <h3 class="font-bold">${item.item_name}</h3>
      <p class="text-red-600 font-bold">¥${item.item_price.toLocaleString()}</p>
      <button
        type="button"
        data-action="click->rakuten-search#selectItem"
        data-item-code="${item.item_code}"
        data-item-name="${item.item_name}"
        data-item-price="${item.item_price}"
        data-item-url="${item.item_url}"
        data-item-image="${item.medium_image_urls[0]}"
        class="mt-2 px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600"
      >
        この商品を選択
      </button>
    </div>
  `
})

    html += '</div>'
    this.resultsTarget.innerHTML = html
    this.resultsTarget.classList.remove('hidden')
  }

  // 商品を選択
selectItem(event) {
  const button = event.currentTarget
  const itemData = {
    code: button.dataset.itemCode,
    name: button.dataset.itemName,
    price: button.dataset.itemPrice,
    url: button.dataset.itemUrl,
    image: button.dataset.itemImage
  }

  // 隠しフィールドに値を設定
  this.itemCodeTarget.value = itemData.code
  this.itemNameTarget.value = itemData.name
  this.itemPriceTarget.value = itemData.price
  this.itemUrlTarget.value = itemData.url
  this.itemImageUrlTarget.value = itemData.image

  // 選択された商品を表示（×ボタン付き）
  this.selectedItemTarget.innerHTML = `
    <div class="border p-4 rounded bg-green-50 relative">
      <h4 class="font-bold text-green-800">選択された商品</h4>
      <button
        type="button"
        data-action="click->rakuten-search#clearSelectedItem"
        class="absolute text-2xl top-2 right-2 text-red-600 hover:text-red-800"
        aria-label="選択解除"
      >
        &times;
      </button>
      <div class="flex items-center mt-2">
        <img src="${itemData.image}" alt="${itemData.name}" class="w-16 h-16 object-cover mr-3">
        <div>
          <p class="font-semibold">${itemData.name}</p>
          <p class="text-red-600 font-bold">¥${parseInt(itemData.price).toLocaleString()}</p>
        </div>
      </div>
    </div>
  `
  this.selectedItemTarget.classList.remove('hidden')

  // 検索結果を非表示
  this.resultsTarget.classList.add('hidden')
}
  // ローディング表示
  showLoading() {
    this.resultsTarget.innerHTML = '<p>検索中...</p>'
    this.resultsTarget.classList.remove('hidden')
  }

  // ローディング非表示
  hideLoading() {
    // displayResultsまたはshowErrorで上書きされる
  }

  // エラー表示
  showError(message) {
    this.resultsTarget.innerHTML = `<p class="text-red-600">${message}</p>`
    this.resultsTarget.classList.remove('hidden')
  }

connect() {
  if (this.selectedItemTarget.innerHTML.trim() === '') {
    this.renderSelectedItemFromHiddenFields()
  } else {
    this.selectedItemTarget.classList.remove('hidden')
  }
}

renderSelectedItemFromHiddenFields() {
  const code = this.itemCodeTarget.value
  const name = this.itemNameTarget.value
  const price = this.itemPriceTarget.value
  const url = this.itemUrlTarget.value
  const image = this.itemImageUrlTarget.value

  if (code && name && price && url && image) {
    this.selectedItemTarget.innerHTML = `
      <div class="border p-4 rounded bg-green-50 relative">
        <h4 class="font-bold text-green-800">選択された商品</h4>
        <button
          type="button"
          data-action="click->rakuten-search#clearSelectedItem"
          class="absolute top-2 right-2 text-red-600 hover:text-red-800"
          aria-label="選択解除"
        >
          &times;
        </button>
        <div class="flex items-center mt-2">
          <img src="${image}" alt="${name}" class="w-16 h-16 object-cover mr-3">
          <div>
            <p class="font-semibold">${name}</p>
            <p class="text-red-600 font-bold">¥${parseInt(price).toLocaleString()}</p>
          </div>
        </div>
      </div>
    `
    this.selectedItemTarget.classList.remove('hidden')
  }
}
clearSelectedItem() {
  this.itemCodeTarget.value = ''
  this.itemNameTarget.value = ''
  this.itemPriceTarget.value = ''
  this.itemUrlTarget.value = ''
  this.itemImageUrlTarget.value = ''

  this.selectedItemTarget.innerHTML = ''
  this.selectedItemTarget.classList.add('hidden')
}

}
