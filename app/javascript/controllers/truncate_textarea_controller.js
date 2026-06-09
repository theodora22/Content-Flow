import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.truncate()
    
    // We must ensure the full text is restored before the form submits
    // so we don't accidentally save the truncated version with "..."
    this.formSubmitHandler = () => {
      if (!this.inputTarget.hasAttribute("readonly")) {
        this.restore()
      }
    }
    const form = this.element.closest("form")
    if (form) {
      form.addEventListener("submit", this.formSubmitHandler)
    }
  }

  disconnect() {
    const form = this.element.closest("form")
    if (form) {
      form.removeEventListener("submit", this.formSubmitHandler)
    }
  }

  focus() {
    if (!this.inputTarget.hasAttribute("readonly")) {
      this.restore()
    }
  }

  blur() {
    // DO NOT truncate when blurred in edit mode!
    // The user might just be clicking another field or the update button!
  }

  truncate() {
    const el = this.inputTarget
    const fullText = el.dataset.fullText || ""
    if (this.inputTarget.hasAttribute("readonly")) {
      if (fullText.length > 30) {
        el.value = fullText.substring(0, 30) + "..."
      } else {
        el.value = fullText
      }
      el.style.height = "60px"
    }
  }

  restore() {
    const el = this.inputTarget
    const fullText = el.dataset.fullText || ""
    el.value = fullText
    // Auto-expand height
    el.style.height = "auto"
    el.style.height = el.scrollHeight + "px"
    el.style.maxHeight = "none"
  }
  
  update(e) {
    // When user types, update the fullText so we don't lose edits
    this.inputTarget.dataset.fullText = this.inputTarget.value
    if (!CSS.supports("field-sizing", "content")) {
      this.inputTarget.style.height = "auto"
      this.inputTarget.style.height = this.inputTarget.scrollHeight + "px"
    }
  }
}
