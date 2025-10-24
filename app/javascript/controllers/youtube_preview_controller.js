import { Controller } from "@hotwired/stimulus"

// YouTube URL入力時に動画情報をRails経由で取得し、プレビューを表示するコントローラ
export default class extends Controller {
  static targets = ["urlInput", "preview", "title", "thumbnail", "viewCount", "uploadDate"]

  // StimulusコントローラがDOMに接続されたタイミングで自動的に呼ばれる
  connect() {
    // fetchVideoInfoをデバウンス化（入力から0.5秒後に実行）
    this.debouncedFetchVideoInfo = this.debounce(this.fetchVideoInfo.bind(this), 500)
    this.processUrl() // すでに値が入っている場合に対応
  }

  // 入力欄が変更されたときに呼ばれる
  urlChanged() {
    this.processUrl()
  }

  // URLを検証・解析して、動画情報を取得する
  processUrl() {
    const url = this.urlInputTarget.value.trim()
    const videoId = this.extractVideoId(url)

    if (videoId) {
      this.debouncedFetchVideoInfo(videoId)
    } else {
      this.hidePreview()
    }
  }

  // YouTube動画IDをURLから抽出
  extractVideoId(url) {
    const match = url.match(
      /^(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/
    )
    return match ? match[1] : null
  }

  // Railsサーバ経由で動画情報を取得
  async fetchVideoInfo(videoId) {
    if (!videoId) {
      this.hidePreview()
      return
    }

    this.showLoading()

    try {
      const response = await fetch(`/boards/youtube_info?video_id=${videoId}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest",
          "Cache-Control": "no-cache",
        },
      })

      const data = await response.json()

      if (response.ok && data && data.title && data.thumbnail_url) {
        this.displayPreview(data)
      } else {
        this.showError("動画情報の形式が正しくありません")
      }
    } catch (error) {
      console.error("Fetch error:", error)
      this.showError("動画情報の取得に失敗しました")
    }
  }

  // 取得した動画情報をプレビュー表示
  displayPreview(data) {
    this.previewTarget.classList.remove("hidden")
    this.removeLoading()

    // 既存のエラーや内容をクリア
    this.clearErrors()

    // 各項目をセット
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = data.title
    }

    if (this.hasThumbnailTarget) {
      this.thumbnailTarget.src = data.thumbnail_url
      this.thumbnailTarget.alt = data.title
    }

    if (this.hasViewCountTarget && data.view_count) {
      this.viewCountTarget.textContent = `${Number(data.view_count).toLocaleString()} 回視聴`
    }

    if (this.hasUploadDateTarget && data.upload_date) {
      this.uploadDateTarget.textContent = `${data.upload_date} 公開`
    }

    // コンテンツを表示
    const existingContent = this.previewTarget.querySelector(".bg-stone-50")
    if (existingContent) existingContent.style.display = "block"
  }

  // ローディングスピナー表示
  showLoading() {
    this.previewTarget.classList.remove("hidden")

    const existingContent = this.previewTarget.querySelector(".bg-stone-50")
    if (existingContent) existingContent.style.display = "none"

    this.removeLoading() // 二重生成防止

    const loadingElement = document.createElement("div")
    loadingElement.className = "flex items-center justify-center p-4"
    loadingElement.innerHTML = `
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500"></div>
      <span class="ml-2 text-stone-600">動画情報を取得中...</span>
    `
    this.previewTarget.appendChild(loadingElement)
    this.loadingElement = loadingElement
  }

  // ローディング削除
  removeLoading() {
    if (this.loadingElement) {
      this.loadingElement.remove()
      this.loadingElement = null
    }
  }

  // エラー表示
  showError(message) {
    this.previewTarget.classList.remove("hidden")
    this.removeLoading()
    this.clearErrors()

    const errorElement = document.createElement("div")
    errorElement.className = "bg-red-50 border border-red-200 rounded-md p-4 mt-2"
    errorElement.innerHTML = `<p class="text-red-600 text-sm">${message}</p>`

    this.previewTarget.appendChild(errorElement)
  }

  // 既存のエラー要素を削除
  clearErrors() {
    this.previewTarget.querySelectorAll(".bg-red-50").forEach((el) => el.remove())
  }

  // プレビュー非表示
  hidePreview() {
    this.previewTarget.classList.add("hidden")
  }

  // デバウンス関数（入力の連打防止）
  debounce(func, wait) {
    let timeout
    return (...args) => {
      clearTimeout(timeout)
      timeout = setTimeout(() => func(...args), wait)
    }
  }
}
