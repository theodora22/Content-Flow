import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "platform"]

  move(event) {
    const index = this.platformTargets.indexOf(event.currentTarget)
    this.indicatorTargets.forEach((el, i) => {
      el.style.opacity = i === index ? "1" : "0"
    })
  }
}
