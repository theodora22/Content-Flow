import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "button"]

  connect() {
    this.checkOverflow = this.checkOverflow.bind(this)
    window.addEventListener('resize', this.checkOverflow)
    
    this.resizeObserver = new ResizeObserver(() => {
      this.checkOverflow()
    })
    
    if (this.hasTextTarget) {
      this.resizeObserver.observe(this.textTarget)
    }

    // Initial checks
    setTimeout(this.checkOverflow, 50)
    setTimeout(this.checkOverflow, 200)
    setTimeout(this.checkOverflow, 500)
  }

  disconnect() {
    window.removeEventListener('resize', this.checkOverflow)
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }

  checkOverflow() {
    if (!this.hasTextTarget || !this.hasButtonTarget) return

    const el = this.textTarget
    
    // If element is not rendered yet, do nothing
    if (el.clientHeight === 0) return

    // If it's currently expanded, do not hide the button.
    if (!el.classList.contains("cf-line-clamp-3")) return

    // With -webkit-line-clamp, scrollHeight is the full height, 
    // and clientHeight is the visible (clamped) height.
    if (el.scrollHeight > el.clientHeight) {
      this.buttonTarget.classList.remove("hidden")
    } else {
      this.buttonTarget.classList.add("hidden")
    }
  }

  toggle() {
    if (!this.hasTextTarget) return

    const isClamped = this.textTarget.classList.contains("cf-line-clamp-3")
    const textSpan = this.buttonTarget.querySelector("span")
    const arrowImg = this.buttonTarget.querySelector("img")

    if (isClamped) {
      // Expand
      this.textTarget.classList.remove("cf-line-clamp-3")
      if (textSpan) textSpan.textContent = "see less"
      if (arrowImg) {
        arrowImg.style.transform = "rotate(-90deg)"
      }

      // Remove the fixed height and overflow-hidden on parents to allow page scrolling
      const pageContainer = this.element.closest('[style*="height: calc(100vh - 64px)"]') || this.element.closest('[data-controller$="-edit"]')
      if (pageContainer) {
        pageContainer.style.height = "auto"
        pageContainer.style.minHeight = "calc(100vh - 64px)"
      }
      
      let current = this.element
      while (current && current !== document.body) {
        if (current.classList.contains('overflow-hidden')) {
          current.classList.remove('overflow-hidden')
          current.dataset.wasOverflowHidden = "true"
        }
        current = current.parentElement
      }
    } else {
      // Collapse
      this.textTarget.classList.add("cf-line-clamp-3")
      if (textSpan) textSpan.textContent = "see full script"
      if (arrowImg) {
        arrowImg.style.transform = "rotate(90deg)"
      }

      // Restore height and overflow
      const pageContainer = this.element.closest('[style*="height: auto"]') || this.element.closest('[data-controller$="-edit"]')
      if (pageContainer) {
        pageContainer.style.height = "calc(100vh - 64px)"
        pageContainer.style.minHeight = ""
      }
      
      let current = this.element
      while (current && current !== document.body) {
        if (current.dataset.wasOverflowHidden === "true") {
          current.classList.add('overflow-hidden')
          delete current.dataset.wasOverflowHidden
        }
        current = current.parentElement
      }
      
      this.element.scrollIntoView({ behavior: "smooth", block: "nearest" })
    }
  }
}
