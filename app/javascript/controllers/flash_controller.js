import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => {
      this.close()
    }, 5000)
  }

  close() {
    clearTimeout(this.timeout)
    this.element.remove()
  }
  disconnect() {
    clearTimeout(this.timeout)
  }
}
