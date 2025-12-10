import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.overlayTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  close() {
    this.overlayTarget.classList.add('hidden')
    document.body.style.overflow = 'auto'
    this.element.remove()
  }

  closeWithKeyboard(e) {
    if (e.key === "Escape") {
      this.close()
    }
  }

  closeBackground(e) {
    if (e.target === this.overlayTarget) {
      this.close()
    }
  }
}