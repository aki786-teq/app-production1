import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput", "results", "selectedItem",
    "itemCode", "itemName", "itemPrice", "itemUrl", "itemImageUrl"
  ]

  connect() {
    if (this.selectedItemTarget.innerHTML.trim() === '') {
      this.renderSelectedItemFromHiddenFields()
    } else {
      this.selectedItemTarget.classList.remove('hidden')
    }
  }

  // 検索処理
  async search() {
    const query = this.searchInputTarget.value.trim()

    if (!query) {
      alert('検索キーワードを入力してください')
      return
    }

    try {
      this.showLoading() // ローディング表示

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
    }
  }

  async fetchProducts(query) {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 10000)

    try {
      return await fetch(`/boards/search_items?keyword=${encodeURIComponent(query)}`, {
        signal: controller.signal
      })
    } finally {
      clearTimeout(timeoutId)
    }
  }

  // 検索結果の表示
  displayResults(data) {
    if (!data.items || data.items.length === 0) {
      this.resultsTarget.textContent = '商品が見つかりませんでした'
      this.resultsTarget.classList.remove('hidden')
      return
    }

    const container = document.createElement('div')
    container.className = 'grid gap-4 mb-4'

    data.items.forEach(item => {
      const card = document.createElement('div')
      card.className = 'border p-4 rounded'

      const img = document.createElement('img')
      img.src = item.medium_image_urls[0]
      img.alt = item.item_name
      img.className = 'w-20 h-20 object-cover mb-2'

      const name = document.createElement('h3')
      name.className = 'font-bold'
      name.textContent = item.item_name

      const price = document.createElement('p')
      price.className = 'text-red-600 font-bold'
      price.textContent = `¥${item.item_price.toLocaleString()}`

      const button = document.createElement('button')
      button.type = 'button'
      button.dataset.action = 'click->rakuten-search#selectItem'
      button.dataset.itemCode = item.item_code
      button.dataset.itemName = item.item_name
      button.dataset.itemPrice = item.item_price
      button.dataset.itemUrl = item.item_url
      button.dataset.itemImage = item.medium_image_urls[0]
      button.className = 'mt-2 px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600'
      button.textContent = 'この商品を選択'

      card.append(img, name, price, button)
      container.appendChild(card)
    })

    this.resultsTarget.innerHTML = ''
    this.resultsTarget.appendChild(container)
    this.resultsTarget.classList.remove('hidden')
  }

  // 商品選択
  selectItem(event) {
    const button = event.currentTarget
    const itemData = {
      code: button.dataset.itemCode,
      name: button.dataset.itemName,
      price: button.dataset.itemPrice,
      url: button.dataset.itemUrl,
      image: button.dataset.itemImage
    }

    // 隠しフィールドに値を保存
    this.itemCodeTarget.value = itemData.code
    this.itemNameTarget.value = itemData.name
    this.itemPriceTarget.value = itemData.price
    this.itemUrlTarget.value = itemData.url
    this.itemImageUrlTarget.value = itemData.image

    // 既存の表示をクリア
    this.selectedItemTarget.innerHTML = ''

    // 外枠
    const wrapper = document.createElement('div')
    wrapper.className = 'border p-4 rounded bg-green-50 relative'

    // 見出し
    const title = document.createElement('h4')
    title.className = 'font-bold text-green-800'
    title.textContent = '選択された商品'

    // ×ボタン
    const clearButton = document.createElement('button')
    clearButton.type = 'button'
    clearButton.dataset.action = 'click->rakuten-search#clearSelectedItem'
    clearButton.className = 'absolute text-2xl top-2 right-2 text-red-600 hover:text-red-800'
    clearButton.setAttribute('aria-label', '選択解除')
    clearButton.textContent = '×'

    // 商品情報コンテナ
    const infoContainer = document.createElement('div')
    infoContainer.className = 'flex items-center mt-2'

    // 商品画像
    const img = document.createElement('img')
    img.src = itemData.image
    img.alt = itemData.name
    img.className = 'w-16 h-16 object-cover mr-3'

    // 商品名と価格
    const textContainer = document.createElement('div')

    const name = document.createElement('p')
    name.className = 'font-semibold'
    name.textContent = itemData.name

    const price = document.createElement('p')
    price.className = 'text-red-600 font-bold'
    const formattedPrice = Number.parseInt(itemData.price, 10).toLocaleString()
    price.textContent = `¥${formattedPrice}`

    textContainer.append(name, price)
    infoContainer.append(img, textContainer)
    wrapper.append(title, clearButton, infoContainer)

    // 完成したDOMを追加
    this.selectedItemTarget.appendChild(wrapper)

    // 表示切り替え
    this.selectedItemTarget.classList.remove('hidden')
    this.resultsTarget.classList.add('hidden')
  }

  // メッセージの表示
  showLoading() {
    this.resultsTarget.textContent = '検索中...'
    this.resultsTarget.classList.remove('hidden')
  }

  showError(message) {
    const p = document.createElement('p');
    p.className = 'text-red-600';
    p.textContent = message;
    this.resultsTarget.replaceChildren(p);
    this.resultsTarget.classList.remove('hidden');
  }

  // ページを再読み込みした時の再表示
  renderSelectedItemFromHiddenFields() {
    const code = this.itemCodeTarget.value
    const name = this.itemNameTarget.value
    const price = this.itemPriceTarget.value
    const url = this.itemUrlTarget.value
    const image = this.itemImageUrlTarget.value

    if (code && name && price && url && image) {
      // 既存の内容をクリア
      this.selectedItemTarget.innerHTML = ''

      // 外枠
      const wrapper = document.createElement('div')
      wrapper.className = 'border p-4 rounded bg-green-50 relative'

      // 見出し
      const title = document.createElement('h4')
      title.className = 'font-bold text-green-800'
      title.textContent = '選択された商品'

      // ×ボタン
      const clearButton = document.createElement('button')
      clearButton.type = 'button'
      clearButton.dataset.action = 'click->rakuten-search#clearSelectedItem'
      clearButton.className = 'absolute top-2 right-2 text-red-600 hover:text-red-800'
      clearButton.setAttribute('aria-label', '選択解除')
      clearButton.textContent = '×'

      // 商品情報コンテナ
      const infoContainer = document.createElement('div')
      infoContainer.className = 'flex items-center mt-2'

      // 画像
      const img = document.createElement('img')
      img.src = image
      img.alt = name
      img.className = 'w-16 h-16 object-cover mr-3'

      // 商品名と価格
      const textContainer = document.createElement('div')

      const nameEl = document.createElement('p')
      nameEl.className = 'font-semibold'
      nameEl.textContent = name

      const priceEl = document.createElement('p')
      priceEl.className = 'text-red-600 font-bold'
      priceEl.textContent = `¥${Number.parseInt(price, 10).toLocaleString()}`

      textContainer.append(nameEl, priceEl)
      infoContainer.append(img, textContainer)
      wrapper.append(title, clearButton, infoContainer)

      // 完成したDOMを追加
      this.selectedItemTarget.appendChild(wrapper)
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
