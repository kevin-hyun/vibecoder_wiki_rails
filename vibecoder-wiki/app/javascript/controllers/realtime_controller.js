import { Controller } from "@hotwired/stimulus"
import { createClient } from '@supabase/supabase-js'

// Supabase 실시간 기능을 활용한 실시간 업데이트
export default class extends Controller {
  static values = { 
    conceptId: Number,
    userId: Number,
    supabaseUrl: String,
    supabaseKey: String
  }

  connect() {
    // Supabase 클라이언트 초기화
    this.supabase = createClient(
      this.supabaseUrlValue, 
      this.supabaseKeyValue
    )
    
    this.setupRealtimeSubscriptions()
  }

  disconnect() {
    if (this.conceptSubscription) {
      this.supabase.removeSubscription(this.conceptSubscription)
    }
    if (this.explanationSubscription) {
      this.supabase.removeSubscription(this.explanationSubscription)
    }
  }

  // 실시간 구독 설정
  setupRealtimeSubscriptions() {
    // 1. 새로운 설명 실시간 추가
    this.explanationSubscription = this.supabase
      .from(`explanations:concept_id=eq.${this.conceptIdValue}`)
      .on('INSERT', (payload) => {
        this.handleNewExplanation(payload.new)
      })
      .on('UPDATE', (payload) => {
        this.handleExplanationUpdate(payload.new)
      })
      .subscribe()

    // 2. 투표 실시간 업데이트
    this.voteSubscription = this.supabase
      .from('votes')
      .on('INSERT', (payload) => {
        this.handleNewVote(payload.new)
      })
      .on('DELETE', (payload) => {
        this.handleVoteRemoved(payload.old)
      })
      .subscribe()

    // 3. 개념 조회수 실시간 업데이트
    this.conceptSubscription = this.supabase
      .from(`concepts:id=eq.${this.conceptIdValue}`)
      .on('UPDATE', (payload) => {
        this.handleConceptUpdate(payload.new)
      })
      .subscribe()
  }

  // 새 설명 실시간 추가
  handleNewExplanation(explanation) {
    // 내가 작성한 설명이면 무시 (이미 추가됨)
    if (explanation.author_id === this.userIdValue) return

    // 설명 목록에 실시간으로 추가
    const explanationsList = document.getElementById('explanations-list')
    if (explanationsList) {
      // 서버에서 렌더링된 HTML 가져와서 추가
      fetch(`/concepts/${this.conceptIdValue}/explanations/${explanation.id}/preview`)
        .then(response => response.text())
        .then(html => {
          const tempDiv = document.createElement('div')
          tempDiv.innerHTML = html
          explanationsList.prepend(tempDiv.firstElementChild)
          
          // 새 설명 하이라이트 효과
          this.highlightNewContent(tempDiv.firstElementChild)
        })
    }

    // 사용자에게 알림
    this.showNotification('💬 새로운 설명이 추가되었어요!', 'info')
  }

  // 설명 업데이트 (베스트 설명 선정 등)
  handleExplanationUpdate(explanation) {
    const explanationElement = document.getElementById(`explanation-${explanation.id}`)
    if (explanationElement && explanation.is_best_explanation) {
      // 베스트 설명으로 선정됨을 표시
      this.addBestExplanationBadge(explanationElement)
      this.showNotification('⭐ 베스트 설명이 업데이트되었어요!', 'success')
    }
  }

  // 새 투표 실시간 업데이트
  handleNewVote(vote) {
    const voteElement = document.getElementById(`explanation-votes-${vote.explanation_id}`)
    if (voteElement) {
      // 투표 수 업데이트
      this.updateVoteCount(voteElement, vote.vote_type, 1)
      
      // 시각적 피드백
      if (vote.vote_type === 'helpful') {
        this.showNotification('👍 누군가 도움됐다고 투표했어요!', 'success')
      }
    }
  }

  // 투표 취소 처리
  handleVoteRemoved(vote) {
    const voteElement = document.getElementById(`explanation-votes-${vote.explanation_id}`)
    if (voteElement) {
      this.updateVoteCount(voteElement, vote.vote_type, -1)
    }
  }

  // 개념 정보 업데이트 (조회수 등)
  handleConceptUpdate(concept) {
    const viewCountElement = document.querySelector('[data-view-count]')
    if (viewCountElement) {
      viewCountElement.textContent = `${concept.view_count.toLocaleString()} 번 읽음`
    }
  }

  // 투표 수 업데이트 헬퍼
  updateVoteCount(voteElement, voteType, change) {
    const countElement = voteElement.querySelector(`[data-${voteType}-count]`)
    if (countElement) {
      const current = parseInt(countElement.textContent) || 0
      const newCount = Math.max(0, current + change)
      countElement.textContent = newCount

      // 애니메이션 효과
      countElement.classList.add('animate-pulse')
      setTimeout(() => {
        countElement.classList.remove('animate-pulse')
      }, 1000)
    }
  }

  // 새 콘텐츠 하이라이트
  highlightNewContent(element) {
    element.classList.add('bg-green-50', 'border-green-200')
    
    setTimeout(() => {
      element.classList.remove('bg-green-50', 'border-green-200')
    }, 3000)
  }

  // 베스트 설명 배지 추가
  addBestExplanationBadge(element) {
    const badge = document.createElement('div')
    badge.className = 'absolute top-2 right-2'
    badge.innerHTML = `
      <span class="bg-yellow-500 text-white text-xs font-bold px-2 py-1 rounded-full shadow-sm animate-bounce">
        ⭐ 베스트
      </span>
    `
    element.style.position = 'relative'
    element.appendChild(badge)
  }

  // 알림 표시
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    const bgColor = type === 'success' ? 'bg-green-500' : 
                   type === 'error' ? 'bg-red-500' : 'bg-blue-500'
    
    notification.className = `fixed bottom-4 right-4 ${bgColor} text-white px-4 py-2 rounded-lg shadow-lg z-50 animate-slide-in-bottom`
    notification.textContent = message
    
    document.body.appendChild(notification)
    
    // 3초 후 자동 제거
    setTimeout(() => {
      notification.classList.add('animate-fade-out')
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 3000)
  }
}