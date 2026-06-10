import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "input", "submit", "penIcon", "penLine", "editLabel"]

  connect() {
    if (!this.hasPenIconTarget) return
    const penIcon = this.penIconTarget
    const rollDistance = window.innerWidth - penIcon.getBoundingClientRect().left
    penIcon.style.transition = "none"
    penIcon.style.transform = `translateX(${rollDistance}px) rotate(720deg)`
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        penIcon.style.transition = "transform 0.8s cubic-bezier(0.25, 0, 0.6, 1)"
        penIcon.style.transform = "translateX(0) rotate(0deg)"
      })
    })
  }

  reveal() {
    // Same pen exit as idea_edit: label fades, underline collapses, pen rolls off-screen
    if (this.hasEditLabelTarget) this.editLabelTarget.style.opacity = "0"
    if (this.hasPenLineTarget) this.penLineTarget.style.width = "0"

    setTimeout(() => {
      if (!this.hasPenIconTarget) return
      const penIcon = this.penIconTarget
      const rollDistance = window.innerWidth - penIcon.getBoundingClientRect().left
      penIcon.style.transition = "transform 0.8s cubic-bezier(0.25, 0, 0.6, 1)"
      penIcon.style.transform = `translateX(${rollDistance}px) rotate(720deg)`
    }, 500)

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
        // The hidden avatar file input has no readonly mode, so it is rendered disabled instead
        input.removeAttribute("readonly")
        input.removeAttribute("disabled")
        input.classList.remove("cursor-default")
        input.classList.add("cursor-text")
      })

      document.getElementById("avatar-label")?.classList.add("cursor-pointer")

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

  updateAvatar(event) {
    const file = event.target.files[0]
    const circle = document.getElementById('preview-avatar')
    if (!file || !circle) return

    if (this.avatarPreviewUrl) URL.revokeObjectURL(this.avatarPreviewUrl)
    this.avatarPreviewUrl = URL.createObjectURL(file)

    const img = document.createElement('img')
    img.src = this.avatarPreviewUrl
    img.alt = 'avatar preview'
    img.className = 'w-full h-full object-cover'
    circle.replaceChildren(img)
  }
}
