import { Controller } from "@hotwired/stimulus"

// 비전공자 친화적 검색 기능
export default class extends Controller {
  static targets = ["input", "results", "suggestions", "loading"]
  static values = { 
    url: String,
    minLength: { type: Number, default: 2 },
    delay: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
    this.controller = new AbortController()
    
    // 검색창에 포커스되면 도움말 표시
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("focus", this.showSearchTips.bind(this))
      this.inputTarget.addEventListener("blur", this.hideSearchTips.bind(this))
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    this.controller.abort()
  }

  // 실시간 검색 (타이핑할 때마다)
  search() {
    const query = this.inputTarget.value.trim()
    
    // 최소 길이 체크
    if (query.length < this.minLengthValue) {
      this.clearResults()
      return
    }

    // 이전 요청 취소
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // 로딩 표시
    this.showLoading()

    // 디바운스 적용
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, this.delayValue)
  }

  // 검색 실행
  async performSearch(query) {
    try {
      const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      
      const response = await fetch(url, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        },
        signal: this.controller.signal
      })

      if (!response.ok) {
        throw new Error('검색 중 오류가 발생했어요')
      }

      const data = await response.json()
      this.displayResults(data, query)
      
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Search error:', error)
        this.showError('검색 중 문제가 발생했어요. 다시 시도해주세요.')
      }
    } finally {
      this.hideLoading()
    }
  }

  // 검색 결과 표시
  displayResults(results, query) {
    if (!this.hasResultsTarget) return

    if (results.length === 0) {
      this.showNoResults(query)
      return
    }

    // 결과를 카드 형태로 표시
    const html = results.map(concept => this.createResultCard(concept, query)).join('')
    this.resultsTarget.innerHTML = html
    this.showResults()
  }

  // 개별 검색 결과 카드 생성
  createResultCard(concept, query) {
    const highlightedTitle = this.highlightSearchTerms(concept.title, query)
    const highlightedDefinition = this.highlightSearchTerms(concept.simple_definition, query)
    
    const categoryEmoji = {
      'it': '💻',
      'startup': '🚀', 
      'ui': '🎨',
      'business': '💼'
    }[concept.category] || '📚'

    const levelStars = '⭐'.repeat(concept.level)

    return `
      <div class="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
        <a href="${concept.url}" class="block group">
          <div class="flex items-start justify-between mb-2">
            <h3 class="text-lg font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors">
              ${highlightedTitle}
            </h3>
            <div class="flex items-center space-x-2 ml-4">
              <span class="text-xs bg-gray-100 text-gray-700 px-2 py-1 rounded-full">
                ${categoryEmoji} ${this.getCategoryName(concept.category)}
              </span>
              <span class="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded-full">
                ${levelStars}
              </span>
            </div>
          </div>
          <p class="text-sm text-gray-600 leading-relaxed">
            ${highlightedDefinition}
          </p>
        </a>
      </div>
    `
  }

  // 검색어 하이라이트
  highlightSearchTerms(text, query) {
    if (!text || !query) return text || ''
    
    const regex = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi')
    return text.replace(regex, '<mark class="bg-yellow-200 font-medium">$1</mark>')
  }

  // 카테고리 이름 변환
  getCategoryName(category) {
    const names = {
      'it': 'IT 기초',
      'startup': '창업', 
      'ui': 'UI/UX',
      'business': '비즈니스'
    }
    return names[category] || '일반'
  }

  // 검색 결과 없음
  showNoResults(query) {
    this.resultsTarget.innerHTML = `
      <div class="text-center py-12">
        <div class="text-6xl mb-4">🔍</div>
        <h3 class="text-lg font-medium text-gray-900 mb-2">'${query}'에 대한 개념을 찾을 수 없어요</h3>
        <p class="text-gray-600 mb-6">다른 검색어로 시도해보시거나, 새로운 개념을 추가해보세요!</p>
        <div class="space-y-2 text-sm text-gray-500">
          <p>💡 검색 팁:</p>
          <ul class="list-disc list-inside space-y-1 max-w-md mx-auto">
            <li>더 간단한 용어로 검색해보세요</li>
            <li>영어 대신 한국어로 검색해보세요</li>
            <li>비슷한 의미의 다른 단어를 사용해보세요</li>
          </ul>
        </div>
      </div>
    `
    this.showResults()
  }

  // 에러 표시
  showError(message) {
    if (!this.hasResultsTarget) return
    
    this.resultsTarget.innerHTML = `
      <div class="text-center py-8">
        <div class="text-4xl mb-4">😅</div>
        <p class="text-gray-600">${message}</p>
      </div>
    `
    this.showResults()
  }

  // 결과 지우기
  clearResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = ''
      this.hideResults()
    }
  }

  // 결과 영역 표시
  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove('hidden')
    }
  }

  // 결과 영역 숨기기  
  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add('hidden')
    }
  }

  // 로딩 표시
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
  }

  // 로딩 숨기기
  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
  }

  // 검색 팁 표시 (비전공자 친화적)
  showSearchTips() {
    // 검색창 아래에 도움말 툴팁 표시
    if (this.hasSuggestionsTarget && this.inputTarget.value.length === 0) {
      this.suggestionsTarget.innerHTML = `
        <div class="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg p-4 z-50">
          <h4 class="text-sm font-medium text-gray-900 mb-2">💡 검색 도움말</h4>
          <ul class="text-xs text-gray-600 space-y-1">
            <li>• "API"나 "Git" 같은 IT 용어를 검색해보세요</li>
            <li>• "프론트엔드"나 "백엔드" 등 개발 용어도 찾을 수 있어요</li>
            <li>• "창업"이나 "스타트업" 관련 용어도 검색 가능해요</li>
          </ul>
        </div>
      `
      this.suggestionsTarget.classList.remove('hidden')
    }
  }

  // 검색 팁 숨기기
  hideSearchTips() {
    if (this.hasSuggestionsTarget) {
      setTimeout(() => {
        this.suggestionsTarget.classList.add('hidden')
        this.suggestionsTarget.innerHTML = ''
      }, 200)
    }
  }

  // Enter 키로 첫 번째 결과로 이동
  handleKeydown(event) {
    if (event.key === 'Enter') {
      const firstResult = this.resultsTarget.querySelector('a')
      if (firstResult) {
        firstResult.click()
      }
    }
    
    if (event.key === 'Escape') {
      this.clearResults()
      this.inputTarget.blur()
    }
  }
}