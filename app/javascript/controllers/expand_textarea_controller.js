import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "icon"]

  connect() {
    this.collapse()
    // Use ResizeObserver with a small timeout to ensure layout is fully resolved before checking overflow
    this.resizeObserver = new ResizeObserver(() => {
      setTimeout(() => this.checkOverflow(), 20)
    })
    this.resizeObserver.observe(this.inputTarget)
    setTimeout(() => this.checkOverflow(), 50)
  }

  disconnect() {
    if (this.resizeObserver) this.resizeObserver.disconnect()
  }

  checkOverflow() {
    if (!this.hasInputTarget || !this.hasButtonTarget) return
    const el = this.inputTarget
    
    if (el.dataset.expanded === "true") return;

    // Safari has a bug where textareas with overflow: hidden and fixed height
    // report scrollHeight equal to clientHeight, hiding the overflow.
    // Temporarily set height to auto to measure true content height.
    const originalHeight = el.style.height
    const originalMinHeight = el.style.minHeight
    
    el.style.height = "auto"
    el.style.minHeight = "0px"
    
    const trueHeight = el.scrollHeight
    
    el.style.height = originalHeight
    el.style.minHeight = originalMinHeight

    // Check if content overflows the visible area. 
    if (trueHeight > el.clientHeight + 2) {
      this.buttonTarget.classList.remove("hidden")
    } else {
      this.buttonTarget.classList.add("hidden")
    }
  }

  adjustHeight() {
    const el = this.inputTarget
    if (el.dataset.expanded === "true" && !CSS.supports("field-sizing", "content")) {
      el.style.height = "auto"
      el.style.height = el.scrollHeight + "px"
    } else {
      this.checkOverflow()
    }
  }

  collapse() {
    const el = this.inputTarget
    el.dataset.expanded = "false"
    el.style.fieldSizing = "fixed"
    el.style.height = "64px"
    el.style.minHeight = "64px"
    el.style.overflow = "hidden"
    if (this.hasIconTarget) {
      this.iconTarget.style.transform = "rotate(0deg)"
    } else if (this.hasButtonTarget) {
      this.buttonTarget.innerText = "... read more"
    }
  }

  expand() {
    if (this.inputTarget.hasAttribute("readonly")) return
    const el = this.inputTarget
    el.dataset.expanded = "true"
    el.style.fieldSizing = "content"
    el.style.height = "auto"
    el.style.minHeight = "64px"
    el.style.overflow = "hidden"
    if (!CSS.supports("field-sizing", "content")) {
      el.style.height = el.scrollHeight + "px"
    }
    if (this.hasIconTarget) {
      this.iconTarget.style.transform = "rotate(90deg)"
    } else if (this.hasButtonTarget) {
      this.buttonTarget.innerText = "see less"
    }
  }

  toggle() {
    if (this.inputTarget.dataset.expanded === "true") {
      this.collapse()
      this.inputTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
    } else {
      this.expand()
    }
  }
}
