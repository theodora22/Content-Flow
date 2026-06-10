import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()

    this._timer = null
    this._observer = new MutationObserver(() => {
      clearTimeout(this._timer)
      this._timer = setTimeout(() => this.scrollToBottom(), 100)
    })

    this._observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this._observer?.disconnect()
    clearTimeout(this._timer)
  }

  scrollToBottom() {
    window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" })
  }
}
