import { Controller } from "@hotwired/stimulus"

// Menú desplegable. El estado vive en data-open del elemento y Tailwind anima según él
// (variantes group-data-open/menu:*). Se cierra con Esc o con un clic fuera del menú.
export default class extends Controller {
  static targets = ["button", "menu"]

  toggle() {
    this.element.hasAttribute("data-open") ? this.close() : this.open()
  }

  open() {
    this.element.setAttribute("data-open", "")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    if (!this.element.hasAttribute("data-open")) return

    this.element.removeAttribute("data-open")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  closeOnEscape() {
    if (this.element.hasAttribute("data-open")) {
      this.close()
      this.buttonTarget.focus()
    }
  }
}
