import { Controller } from "@hotwired/stimulus"

// 드롭다운 메뉴 컨트롤러 (필터링, 정렬 등)
export default class extends Controller {
  static targets = ["menu", "button", "option"]
  static values = { 
    open: { type: Boolean, default: false },
    closeOnClickOutside: { type: Boolean, default: true }
  }

  connect() {
    // 초기 상태 설정
    this.updateDisplay()
    
    // 외부 클릭 감지 설정
    if (this.closeOnClickOutsideValue) {
      document.addEventListener('click', this.handleClickOutside.bind(this))
    }

    // 키보드 접근성
    document.addEventListener('keydown', this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.handleClickOutside.bind(this))
    document.removeEventListener('keydown', this.handleKeydown.bind(this))
  }

  // 드롭다운 토글
  toggle() {
    this.openValue = !this.openValue
    this.updateDisplay()
  }

  // 드롭다운 열기
  open() {
    this.openValue = true
    this.updateDisplay()
  }

  // 드롭다운 닫기
  close() {
    this.openValue = false
    this.updateDisplay()
  }

  // 옵션 선택
  select(event) {
    const option = event.currentTarget
    const value = option.dataset.value
    const text = option.textContent.trim()

    // 선택된 값 업데이트
    this.updateSelectedOption(value, text)
    
    // 드롭다운 닫기
    this.close()

    // 커스텀 이벤트 발생 (다른 컨트롤러에서 감지 가능)
    this.dispatch('select', { 
      detail: { 
        value: value, 
        text: text,
        element: option 
      } 
    })

    // 폼 자동 제출 (data-auto-submit="true"인 경우)
    if (this.element.dataset.autoSubmit === 'true') {
      this.submitForm(value)
    }
  }

  // 선택된 옵션 UI 업데이트
  updateSelectedOption(value, text) {
    // 버튼 텍스트 업데이트
    if (this.hasButtonTarget) {
      const buttonText = this.buttonTarget.querySelector('[data-dropdown-text]')
      if (buttonText) {
        buttonText.textContent = text
      }
    }

    // 모든 옵션의 선택 상태 업데이트
    this.optionTargets.forEach(option => {
      const isSelected = option.dataset.value === value
      option.classList.toggle('bg-indigo-50', isSelected)
      option.classList.toggle('text-indigo-600', isSelected)
      option.setAttribute('aria-selected', isSelected.toString())

      // 체크 아이콘 표시/숨김
      const checkIcon = option.querySelector('[data-check-icon]')
      if (checkIcon) {
        checkIcon.classList.toggle('hidden', !isSelected)
      }
    })
  }

  // 폼 제출 (필터링, 정렬 등)
  submitForm(value) {
    const form = this.element.closest('form')
    if (!form) return

    // hidden input 생성 또는 업데이트
    const paramName = this.element.dataset.paramName || 'filter'
    let hiddenInput = form.querySelector(`input[name="${paramName}"]`)
    
    if (!hiddenInput) {
      hiddenInput = document.createElement('input')
      hiddenInput.type = 'hidden'
      hiddenInput.name = paramName
      form.appendChild(hiddenInput)
    }
    
    hiddenInput.value = value

    // 폼 제출 (Turbo 사용)
    if (window.Turbo) {
      Turbo.navigator.submitForm(form)
    } else {
      form.submit()
    }
  }

  // 표시 상태 업데이트
  updateDisplay() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle('hidden', !this.openValue)
      
      // 애니메이션 클래스 추가
      if (this.openValue) {
        this.menuTarget.classList.add('animate-fade-in')
      } else {
        this.menuTarget.classList.remove('animate-fade-in')
      }
    }

    if (this.hasButtonTarget) {
      // 버튼 상태 업데이트
      this.buttonTarget.setAttribute('aria-expanded', this.openValue.toString())
      
      // 화살표 아이콘 회전
      const arrow = this.buttonTarget.querySelector('[data-dropdown-arrow]')
      if (arrow) {
        arrow.classList.toggle('rotate-180', this.openValue)
      }
    }
  }

  // 외부 클릭 처리
  handleClickOutside(event) {
    if (!this.element.contains(event.target) && this.openValue) {
      this.close()
    }
  }

  // 키보드 접근성
  handleKeydown(event) {
    if (!this.openValue) return

    switch (event.key) {
      case 'Escape':
        this.close()
        this.buttonTarget?.focus()
        break
      case 'ArrowDown':
        event.preventDefault()
        this.focusNextOption()
        break
      case 'ArrowUp':
        event.preventDefault()
        this.focusPreviousOption()
        break
      case 'Enter':
      case ' ':
        if (document.activeElement && this.optionTargets.includes(document.activeElement)) {
          event.preventDefault()
          document.activeElement.click()
        }
        break
    }
  }

  // 다음 옵션에 포커스
  focusNextOption() {
    const currentIndex = this.optionTargets.indexOf(document.activeElement)
    const nextIndex = currentIndex === -1 ? 0 : (currentIndex + 1) % this.optionTargets.length
    this.optionTargets[nextIndex]?.focus()
  }

  // 이전 옵션에 포커스
  focusPreviousOption() {
    const currentIndex = this.optionTargets.indexOf(document.activeElement)
    const prevIndex = currentIndex === -1 ? 
      this.optionTargets.length - 1 : 
      (currentIndex - 1 + this.optionTargets.length) % this.optionTargets.length
    this.optionTargets[prevIndex]?.focus()
  }

  // 필터 리셋
  reset() {
    // 첫 번째 옵션 선택 (보통 "전체" 옵션)
    const firstOption = this.optionTargets[0]
    if (firstOption) {
      const value = firstOption.dataset.value
      const text = firstOption.textContent.trim()
      this.updateSelectedOption(value, text)
      
      if (this.element.dataset.autoSubmit === 'true') {
        this.submitForm(value)
      }
    }
  }

  // 현재 선택된 값 가져오기
  getSelectedValue() {
    const selectedOption = this.optionTargets.find(option => 
      option.classList.contains('bg-indigo-50')
    )
    return selectedOption?.dataset.value || null
  }

  // 특정 값으로 설정
  setValue(value) {
    const option = this.optionTargets.find(opt => opt.dataset.value === value)
    if (option) {
      const text = option.textContent.trim()
      this.updateSelectedOption(value, text)
    }
  }

  // 비전공자 친화적 라벨 매핑
  getFriendlyLabel(value) {
    const labels = {
      // 카테고리
      'it': '💻 IT 기초',
      'startup': '🚀 창업',
      'ui': '🎨 UI/UX', 
      'business': '💼 비즈니스',
      
      // 레벨
      '1': '⭐ 초급 (쉬워요)',
      '2': '⭐⭐ 중급 (보통이에요)',
      '3': '⭐⭐⭐ 고급 (어려워요)',
      
      // 정렬
      'popular': '🔥 인기순',
      'newest': '🆕 최신순',
      'helpful': '👍 도움순',
      'beginner': '🌱 초보자용',
      'verified': '✅ 검증된 개념'
    }
    
    return labels[value] || value
  }
}