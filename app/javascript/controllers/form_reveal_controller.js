import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "input", "submit"]

  reveal() {
    this.lineTargets.forEach((line, index) => {
      setTimeout(() => {
        line.classList.add("w-full")
      }, index * 350)
    })

    const totalLineTime = this.lineTargets.length * 350 + 700

    setTimeout(() => {
      this.lineTargets.forEach((line) => {
        line.style.backgroundColor = "var(--cf-accent)"
      })

      this.inputTargets.forEach((input) => {
        input.removeAttribute("readonly")
        input.classList.remove("cursor-default")
        input.classList.add("cursor-text")
      })

      this.inputTargets[0].focus()
    }, totalLineTime)

    setTimeout(() => {
      this.submitTarget.classList.remove("opacity-0", "pointer-events-none")
      this.submitTarget.classList.add("opacity-100")
    }, totalLineTime + 400)
  }

  submit() {
    const btn = this.submitTarget
    btn.style.backgroundColor = "var(--cf-accent)"
    btn.style.borderColor = "var(--cf-accent)"
    btn.style.color = "var(--cf-fg-inverse)"

    setTimeout(() => {
      document.getElementById("creator-form").requestSubmit()
    }, 400)
  }

  updatePreview(event) {
    const match = event.target.name.match(/creator\[(\w+)\]/)
    if (!match) return
    const field = match[1]
    const previewElement = document.getElementById(`preview-${field}`)
    if (previewElement) {
      if (field === 'audience') {
        previewElement.textContent = event.target.value ? `"${event.target.value}"` : '"Not specified yet"'
      } else {
        previewElement.textContent = event.target.value || (field === 'name' ? 'Anonymous Creator' : 'Not specified yet')
      }
    }

    // Dynamic initials update
    if (field === 'name') {
      const nameVal = event.target.value.trim()
      const initials = nameVal
        ? nameVal.split(/\s+/).map(word => word[0]).join('').toUpperCase().slice(0, 2)
        : 'CF'
      const initialsElement = document.getElementById('preview-initials')
      if (initialsElement) {
        initialsElement.textContent = initials
      }
    }
  }
}
