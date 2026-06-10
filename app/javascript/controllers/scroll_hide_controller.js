import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.style.transition = "transform 0.35s cubic-bezier(0.25, 0, 0.6, 1)"
    this._onScroll = this._handleScroll.bind(this)
    window.addEventListener("scroll", this._onScroll, { passive: true })
    this._handleScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this._onScroll)
  }

  _handleScroll() {
    const atBottom = window.scrollY + window.innerHeight >= document.body.scrollHeight - 40
    this.element.style.transform = atBottom ? "translateX(0)" : "translateX(100vw)"
  }
}
