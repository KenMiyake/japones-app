import { Controller } from "@hotwired/stimulus"

// Búsqueda mientras se escribe: envía el formulario (GET) tras una pausa corta.
// El formulario apunta a un Turbo Frame, así que solo se reemplaza la lista.
export default class extends Controller {
  static values = { delay: { type: Number, default: 250 } }

  disconnect() {
    clearTimeout(this.timeout)
  }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }
}
