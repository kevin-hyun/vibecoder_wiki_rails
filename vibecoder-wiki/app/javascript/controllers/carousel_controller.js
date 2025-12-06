import { Controller } from "@hotwired/stimulus"

// 베스트 설명 캐러셀 컨트롤러 (Swiper.js 기반)
export default class extends Controller {
  static targets = ["container", "slide", "prevBtn", "nextBtn", "indicator"]
  static values = {
    currentSlide: { type: Number, default: 0 },
    autoPlay: { type: Boolean, default: true },
    autoPlayDelay: { type: Number, default: 5000 },
    showIndicators: { type: Boolean, default: true },
    showArrows: { type: Boolean, default: true }
  }

  connect() {
    this.slideCount = this.slideTargets.length
    
    if (this.slideCount <= 1) {
      this.hidePagination()
      return
    }

    this.setupCarousel()
    this.updateIndicators()
    
    if (this.autoPlayValue) {
      this.startAutoPlay()
    }

    // 터치/스와이프 지원
    this.setupTouchEvents()
    
    // 키보드 지원
    this.setupKeyboardEvents()
  }

  disconnect() {
    this.stopAutoPlay()
    this.removeTouchEvents()
    this.removeKeyboardEvents()
  }

  // 캐러셀 초기 설정
  setupCarousel() {
    // 슬라이드 컨테이너 설정
    if (this.hasContainerTarget) {
      this.containerTarget.style.transform = `translateX(-${this.currentSlideValue * 100}%)`
      this.containerTarget.style.transition = 'transform 0.3s ease-in-out'
    }

    // 버튼 상태 업데이트
    this.updateButtonStates()
    
    // 접근성 설정
    this.setupAccessibility()
  }

  // 다음 슬라이드
  next() {
    if (this.currentSlideValue < this.slideCount - 1) {
      this.currentSlideValue += 1
    } else {
      this.currentSlideValue = 0 // 처음으로 돌아감
    }
    
    this.updateSlide()
  }

  // 이전 슬라이드
  prev() {
    if (this.currentSlideValue > 0) {
      this.currentSlideValue -= 1
    } else {
      this.currentSlideValue = this.slideCount - 1 // 마지막으로 이동
    }
    
    this.updateSlide()
  }

  // 특정 슬라이드로 이동
  goToSlide(event) {
    const slideIndex = parseInt(event.currentTarget.dataset.slideIndex)
    if (slideIndex >= 0 && slideIndex < this.slideCount) {
      this.currentSlideValue = slideIndex
      this.updateSlide()
    }
  }

  // 슬라이드 업데이트
  updateSlide() {
    // 슬라이드 이동 애니메이션
    if (this.hasContainerTarget) {
      this.containerTarget.style.transform = `translateX(-${this.currentSlideValue * 100}%)`
    }

    // 인디케이터 업데이트
    this.updateIndicators()
    
    // 버튼 상태 업데이트
    this.updateButtonStates()
    
    // 접근성 업데이트
    this.updateAccessibility()
    
    // 자동재생 중이면 재시작
    if (this.autoPlayValue) {
      this.restartAutoPlay()
    }

    // 커스텀 이벤트 발생
    this.dispatch('slideChanged', { 
      detail: { 
        currentSlide: this.currentSlideValue,
        totalSlides: this.slideCount 
      } 
    })
  }

  // 인디케이터 업데이트
  updateIndicators() {
    if (!this.showIndicatorsValue) return

    this.indicatorTargets.forEach((indicator, index) => {
      const isActive = index === this.currentSlideValue
      
      indicator.classList.toggle('bg-indigo-600', isActive)
      indicator.classList.toggle('bg-gray-300', !isActive)
      indicator.setAttribute('aria-selected', isActive.toString())
      
      if (isActive) {
        indicator.setAttribute('aria-label', `현재 슬라이드 ${index + 1}`)
      } else {
        indicator.setAttribute('aria-label', `슬라이드 ${index + 1}로 이동`)
      }
    })
  }

  // 버튼 상태 업데이트
  updateButtonStates() {
    if (!this.showArrowsValue) return

    // 이전 버튼
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.classList.toggle('opacity-50', this.currentSlideValue === 0)
      this.prevBtnTarget.classList.toggle('cursor-not-allowed', this.currentSlideValue === 0)
    }

    // 다음 버튼
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.classList.toggle('opacity-50', this.currentSlideValue === this.slideCount - 1)
      this.nextBtnTarget.classList.toggle('cursor-not-allowed', this.currentSlideValue === this.slideCount - 1)
    }
  }

  // 자동재생 시작
  startAutoPlay() {
    this.stopAutoPlay() // 기존 타이머 정리
    
    this.autoPlayTimer = setInterval(() => {
      this.next()
    }, this.autoPlayDelayValue)
  }

  // 자동재생 중지
  stopAutoPlay() {
    if (this.autoPlayTimer) {
      clearInterval(this.autoPlayTimer)
      this.autoPlayTimer = null
    }
  }

  // 자동재생 재시작
  restartAutoPlay() {
    if (this.autoPlayValue) {
      this.startAutoPlay()
    }
  }

  // 마우스 호버시 자동재생 일시정지
  pauseAutoPlay() {
    this.stopAutoPlay()
  }

  // 마우스가 벗어나면 자동재생 재개
  resumeAutoPlay() {
    if (this.autoPlayValue) {
      this.startAutoPlay()
    }
  }

  // 터치/스와이프 이벤트 설정
  setupTouchEvents() {
    this.touchStartX = 0
    this.touchEndX = 0
    
    this.handleTouchStart = this.handleTouchStart.bind(this)
    this.handleTouchMove = this.handleTouchMove.bind(this)
    this.handleTouchEnd = this.handleTouchEnd.bind(this)

    this.element.addEventListener('touchstart', this.handleTouchStart, { passive: true })
    this.element.addEventListener('touchmove', this.handleTouchMove, { passive: true })
    this.element.addEventListener('touchend', this.handleTouchEnd, { passive: true })
  }

  // 터치 시작
  handleTouchStart(event) {
    this.touchStartX = event.changedTouches[0].screenX
    this.pauseAutoPlay()
  }

  // 터치 이동
  handleTouchMove(event) {
    this.touchEndX = event.changedTouches[0].screenX
  }

  // 터치 종료
  handleTouchEnd() {
    const swipeThreshold = 50
    const swipeDistance = this.touchStartX - this.touchEndX

    if (Math.abs(swipeDistance) > swipeThreshold) {
      if (swipeDistance > 0) {
        this.next() // 왼쪽으로 스와이프 = 다음
      } else {
        this.prev() // 오른쪽으로 스와이프 = 이전
      }
    }

    this.resumeAutoPlay()
  }

  // 터치 이벤트 제거
  removeTouchEvents() {
    this.element.removeEventListener('touchstart', this.handleTouchStart)
    this.element.removeEventListener('touchmove', this.handleTouchMove)
    this.element.removeEventListener('touchend', this.handleTouchEnd)
  }

  // 키보드 이벤트 설정
  setupKeyboardEvents() {
    this.handleKeydown = this.handleKeydown.bind(this)
    this.element.addEventListener('keydown', this.handleKeydown)
  }

  // 키보드 처리
  handleKeydown(event) {
    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault()
        this.prev()
        break
      case 'ArrowRight':
        event.preventDefault()
        this.next()
        break
      case 'Home':
        event.preventDefault()
        this.currentSlideValue = 0
        this.updateSlide()
        break
      case 'End':
        event.preventDefault()
        this.currentSlideValue = this.slideCount - 1
        this.updateSlide()
        break
    }
  }

  // 키보드 이벤트 제거
  removeKeyboardEvents() {
    this.element.removeEventListener('keydown', this.handleKeydown)
  }

  // 접근성 설정
  setupAccessibility() {
    // 캐러셀 컨테이너에 role 설정
    this.element.setAttribute('role', 'region')
    this.element.setAttribute('aria-label', '베스트 설명 캐러셀')
    
    // 슬라이드들에 접근성 속성 설정
    this.slideTargets.forEach((slide, index) => {
      slide.setAttribute('role', 'group')
      slide.setAttribute('aria-roledescription', 'slide')
      slide.setAttribute('aria-label', `${index + 1} / ${this.slideCount}`)
    })
  }

  // 접근성 업데이트
  updateAccessibility() {
    this.slideTargets.forEach((slide, index) => {
      const isVisible = index === this.currentSlideValue
      slide.setAttribute('aria-hidden', (!isVisible).toString())
      
      if (isVisible) {
        // 현재 슬라이드의 포커스 가능한 요소들 활성화
        const focusableElements = slide.querySelectorAll('a, button, [tabindex]')
        focusableElements.forEach(el => el.setAttribute('tabindex', '0'))
      } else {
        // 숨겨진 슬라이드의 포커스 가능한 요소들 비활성화
        const focusableElements = slide.querySelectorAll('a, button, [tabindex]')
        focusableElements.forEach(el => el.setAttribute('tabindex', '-1'))
      }
    })
  }

  // 페이지네이션 숨기기 (슬라이드가 1개인 경우)
  hidePagination() {
    if (this.hasPrevBtnTarget) this.prevBtnTarget.style.display = 'none'
    if (this.hasNextBtnTarget) this.nextBtnTarget.style.display = 'none'
    this.indicatorTargets.forEach(indicator => indicator.style.display = 'none')
  }
}