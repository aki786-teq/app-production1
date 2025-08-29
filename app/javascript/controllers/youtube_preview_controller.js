import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlInput", "preview", "title", "thumbnail", "viewCount", "uploadDate"]
  static values = { apiKey: String }

  connect() {
    this.debouncedFetchVideoInfo = this.debounce(this.fetchVideoInfo.bind(this), 500)

    // 既存のYouTube動画がある場合は初期化
    if (this.urlInputTarget.value.trim() && this.isValidYouTubeUrl(this.urlInputTarget.value.trim())) {
      const videoId = this.extractVideoId(this.urlInputTarget.value.trim())
      if (videoId) {
        // 既存の動画情報を取得してプレビューを表示
        this.debouncedFetchVideoInfo(videoId)
      }
    }
  }

  // URL入力時の処理
  urlChanged() {
    const url = this.urlInputTarget.value.trim()

    if (this.isValidYouTubeUrl(url)) {
      const videoId = this.extractVideoId(url)
      if (videoId) {
        this.debouncedFetchVideoInfo(videoId)
      }
    } else {
      this.hidePreview()
    }
  }

  // YouTube URLの妥当性チェック
  isValidYouTubeUrl(url) {
    const youtubePattern = /^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/
    return youtubePattern.test(url)
  }

  // YouTube動画IDを抽出
  extractVideoId(url) {
    const youtubePattern = /(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/
    const match = url.match(youtubePattern)
    return match ? match[1] : null
  }

  // 動画情報を取得
  async fetchVideoInfo(videoId) {
    if (!videoId) return

    try {
      this.showLoading()

      const response = await fetch(`/boards/youtube_info?video_id=${videoId}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'Cache-Control': 'no-cache'
        }
      })

      if (response.ok) {
        const data = await response.json()
        
        // データが正しく取得されているかチェック
        if (data && data.title && data.thumbnail_url) {
          this.displayPreview(data)
        } else {
          this.showError('動画情報の形式が正しくありません')
        }
      } else {
        const errorData = await response.json().catch(() => ({}))
        this.showError(`動画情報の取得に失敗しました (${response.status})`)
      }
    } catch (error) {
      this.showError('動画情報の取得に失敗しました')
    }
  }

  // プレビューを表示
  displayPreview(data) {
    this.previewTarget.classList.remove('hidden')

    // ローディング要素を削除
    if (this.loadingElement) {
      this.loadingElement.remove()
      this.loadingElement = null
    }

    // 既存のコンテンツを再表示
    const existingContent = this.previewTarget.querySelector('.bg-gray-50')
    if (existingContent) {
      existingContent.style.display = 'block'
    }

    if (this.hasTitleTarget) {
      this.titleTarget.textContent = data.title
    }

    if (this.hasThumbnailTarget) {
      this.thumbnailTarget.src = data.thumbnail_url
      this.thumbnailTarget.alt = data.title
    }

    if (this.hasViewCountTarget) {
      this.viewCountTarget.textContent = `${data.view_count} 回視聴`
    }

    if (this.hasUploadDateTarget) {
      this.uploadDateTarget.textContent = `${data.upload_date} 公開`
    }
  }

  // ローディング表示
  showLoading() {
    this.previewTarget.classList.remove('hidden')
    
    // ローディング要素を作成
    const loadingElement = document.createElement('div')
    loadingElement.className = 'flex items-center justify-center p-4'
    loadingElement.innerHTML = `
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500"></div>
      <span class="ml-2 text-gray-600">動画情報を取得中...</span>
    `
    
    // 既存のコンテンツを一時的に非表示にして、ローディングを表示
    const existingContent = this.previewTarget.querySelector('.bg-gray-50')
    if (existingContent) {
      existingContent.style.display = 'none'
    }
    
    // ローディング要素を追加
    this.previewTarget.appendChild(loadingElement)
    
    // ローディング要素を後で削除できるように保存
    this.loadingElement = loadingElement
  }

  // エラー表示
  showError(message) {
    this.previewTarget.classList.remove('hidden')
    
    // ローディング要素を削除
    if (this.loadingElement) {
      this.loadingElement.remove()
      this.loadingElement = null
    }

    // 既存のコンテンツを再表示
    const existingContent = this.previewTarget.querySelector('.bg-gray-50')
    if (existingContent) {
      existingContent.style.display = 'block'
    }
    
    // エラーメッセージを表示
    const errorElement = document.createElement('div')
    errorElement.className = 'bg-red-50 border border-red-200 rounded-md p-4 mt-2'
    errorElement.innerHTML = `<p class="text-red-600 text-sm">${message}</p>`
    
    this.previewTarget.appendChild(errorElement)
  }

  // プレビューを非表示
  hidePreview() {
    this.previewTarget.classList.add('hidden')
  }

  // デバウンス関数
  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
}
