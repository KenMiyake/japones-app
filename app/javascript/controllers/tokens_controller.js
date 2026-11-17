import { Controller } from "@hotwired/stimulus"

// Campo de "chips": se escribe un valor, Enter (o coma) lo agrega como chip con un input
// oculto; ✕ lo quita. Los chips nuevos se clonan de un <template> y el texto se asigna con
// textContent/value (nunca innerHTML), así lo escrito no puede inyectar HTML.
export default class extends Controller {
  static targets = ["input", "list", "template"]

  keydown(event) {
    if (event.key === "Enter" || event.key === ",") {
      event.preventDefault()
      this.add()
    } else if (event.key === "Backspace" && this.inputTarget.value === "") {
      this.listTarget.querySelector("[data-token]:last-of-type")?.remove()
    }
  }

  add() {
    const value = this.inputTarget.value.replace(/,/g, "").trim()
    this.inputTarget.value = ""
    if (value === "" || this.#values().includes(value)) return

    const chip = this.templateTarget.content.firstElementChild.cloneNode(true)
    chip.dataset.token = value
    chip.querySelector("input").value = value
    chip.querySelector("[data-token-label]").textContent = value
    this.listTarget.appendChild(chip)
    this.inputTarget.focus()
  }

  remove(event) {
    event.preventDefault()
    event.target.closest("[data-token]").remove()
    this.inputTarget.focus()
  }

  #values() {
    return [...this.listTarget.querySelectorAll("[data-token]")].map((chip) => chip.dataset.token)
  }
}
