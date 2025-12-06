import { Controller } from "@hotwired/stimulus"

// 비전공자 친화적 투표 시스템 (도움됨/어려움)
export default class extends Controller {
  static targets = ["helpfulBtn", "difficultBtn", "helpfulCount", "difficultCount", "feedback"]
  static values = { 
    explanationId: Number,
    currentVote: String, // 'helpful', 'difficult', or null
    userId: Number
  }

  connect() {
    this.updateButtonStates()
    this.setupTooltips()
  }

  // 도움됨 투표
  helpful(event) {
    event.preventDefault()
    this.vote('helpful')
  }

  // 어려움 투표  
  difficult(event) {
    event.preventDefault()
    this.vote('difficult')
  }

  // 투표 실행
  async vote(voteType) {
    // 투표 중 중복 클릭 방지
    this.disableButtons()

    try {
      const formData = new FormData()
      formData.append('vote_type', voteType)
      formData.append('authenticity_token', this.getAuthToken())

      const response = await fetch(this.getVoteUrl(), {
        method: 'PATCH',
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/vnd.turbo-stream.html'
        },
        body: formData
      })

      if (!response.ok) {
        throw new Error('투표 중 문제가 발생했어요')
      }

      // Turbo Stream 응답 처리
      const responseText = await response.text()
      if (responseText) {
        // Turbo가 자동으로 DOM 업데이트를 처리
        Turbo.renderStreamMessage(responseText)
      }

      // 사용자 피드백 표시
      this.showFeedback(voteType)
      
      // 로컬 상태 업데이트 (UI 즉시 반영용)
      this.updateLocalState(voteType)

    } catch (error) {
      console.error('Vote error:', error)
      this.showError('투표 중 문제가 발생했어요. 다시 시도해주세요.')
    } finally {
      this.enableButtons()
    }
  }

  // 투표 URL 생성
  getVoteUrl() {
    const conceptId = this.element.dataset.conceptId
    return `/concepts/${conceptId}/explanations/${this.explanationIdValue}/vote`
  }

  // CSRF 토큰 가져오기
  getAuthToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.content : ''
  }

  // 로컬 상태 업데이트
  updateLocalState(newVoteType) {
    const wasVoted = this.currentVoteValue === newVoteType
    
    if (wasVoted) {
      // 투표 취소
      this.currentVoteValue = null
    } else {
      // 새 투표 또는 투표 변경
      this.currentVoteValue = newVoteType
    }

    this.updateButtonStates()
    this.updateCounts(newVoteType, wasVoted)
  }

  // 버튼 상태 업데이트
  updateButtonStates() {
    // 도움됨 버튼
    if (this.hasHelpfulBtnTarget) {
      this.helpfulBtnTarget.classList.toggle(
        'bg-green-100 text-green-800 border-green-200', 
        this.currentVoteValue === 'helpful'
      )
      this.helpfulBtnTarget.classList.toggle(
        'bg-white text-gray-600 border-gray-300 hover:bg-gray-50',
        this.currentVoteValue !== 'helpful'
      )
    }

    // 어려움 버튼
    if (this.hasDifficultBtnTarget) {
      this.difficultBtnTarget.classList.toggle(
        'bg-red-100 text-red-800 border-red-200',
        this.currentVoteValue === 'difficult'
      )
      this.difficultBtnTarget.classList.toggle(
        'bg-white text-gray-600 border-gray-300 hover:bg-gray-50',
        this.currentVoteValue !== 'difficult'
      )
    }
  }

  // 투표 수 업데이트 (즉시 반영용)
  updateCounts(voteType, wasVoted) {
    const change = wasVoted ? -1 : 1
    
    if (voteType === 'helpful' && this.hasHelpfulCountTarget) {
      const current = parseInt(this.helpfulCountTarget.textContent) || 0
      this.helpfulCountTarget.textContent = Math.max(0, current + change)
    } else if (voteType === 'difficult' && this.hasDifficultCountTarget) {
      const current = parseInt(this.difficultCountTarget.textContent) || 0  
      this.difficultCountTarget.textContent = Math.max(0, current + change)
    }
  }

  // 사용자 피드백 표시
  showFeedback(voteType) {
    if (!this.hasFeedbackTarget) return

    const wasVoted = this.currentVoteValue === voteType
    let message, emoji

    if (wasVoted) {
      // 투표 취소
      message = voteType === 'helpful' ? '도움됨 투표를 취소했어요' : '어려움 투표를 취소했어요'
      emoji = '↩️'
    } else {
      // 새 투표
      if (voteType === 'helpful') {
        message = '도움됐다고 투표해주셔서 감사해요!'
        emoji = '👍'
      } else {
        message = '피드백 감사해요. 더 쉬운 설명이 추가되길 기대해봐요!'
        emoji = '💭'
      }
    }

    this.displayFeedback(message, emoji, 'success')
  }

  // 에러 표시
  showError(message) {
    this.displayFeedback(message, '😅', 'error')
  }

  // 피드백 메시지 표시
  displayFeedback(message, emoji, type) {
    if (!this.hasFeedbackTarget) return

    const bgColor = type === 'error' ? 'bg-red-50 border-red-200' : 'bg-green-50 border-green-200'
    const textColor = type === 'error' ? 'text-red-800' : 'text-green-800'

    this.feedbackTarget.innerHTML = `
      <div class="flex items-center p-2 rounded-md border ${bgColor} ${textColor}">
        <span class="text-lg mr-2">${emoji}</span>
        <span class="text-sm font-medium">${message}</span>
      </div>
    `

    this.feedbackTarget.classList.remove('hidden')

    // 3초 후 자동 숨김
    setTimeout(() => {
      this.feedbackTarget.classList.add('hidden')
    }, 3000)
  }

  // 버튼 비활성화
  disableButtons() {
    [this.helpfulBtnTarget, this.difficultBtnTarget].forEach(btn => {
      if (btn) {
        btn.disabled = true
        btn.classList.add('opacity-50', 'cursor-not-allowed')
      }
    })
  }

  // 버튼 활성화
  enableButtons() {
    [this.helpfulBtnTarget, this.difficultBtnTarget].forEach(btn => {
      if (btn) {
        btn.disabled = false
        btn.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    })
  }

  // 툴팁 설정 (비전공자 친화적 설명)
  setupTooltips() {
    if (this.hasHelpfulBtnTarget) {
      this.helpfulBtnTarget.title = '이 설명이 이해하기 쉬워서 도움이 되었어요!'
    }
    
    if (this.hasDifficultBtnTarget) {
      this.difficultBtnTarget.title = '조금 더 쉽게 설명해주시면 좋겠어요'
    }
  }

  // 비로그인 사용자 안내
  showLoginPrompt() {
    if (this.hasFeedbackTarget) {
      this.displayFeedback(
        '로그인하시면 투표할 수 있어요! 하지만 지금도 IP 기반으로 투표 가능해요 😊',
        'ℹ️',
        'info'
      )
    }
  }

  // 투표 이유 수집 (선택적)
  collectVoteReason(voteType) {
    const reasons = {
      helpful: [
        '일상 비유가 이해하기 쉬워요',
        '구체적인 예시가 도움됐어요', 
        '어려운 용어를 쉽게 설명해줘서 좋아요',
        '실무에 어떻게 쓰이는지 알 수 있어요'
      ],
      difficult: [
        '전문용어가 많아서 어려워요',
        '더 쉬운 비유가 필요해요',
        '구체적인 예시가 더 필요해요',
        '설명이 너무 복잡해요'
      ]
    }

    // 간단한 이유 선택 UI를 표시할 수 있음 (추후 확장)
    return reasons[voteType]?.[0] || null
  }
}