import { Controller } from "@hotwired/stimulus"

// Filas anidadas de un formulario (accepts_nested_attributes_for), p. ej. las lecturas
// de un kanji.
//
// - add: clona el <template> reemplazando NEW_RECORD por un índice único, para que Rails
//   reciba cada fila nueva con su propia clave en readings_attributes.
// - remove: una fila nueva se borra del DOM; una ya guardada se oculta y se marca con
//   _destroy=1 para que Rails la elimine al guardar.
export default class extends Controller {
  static targets = ["template", "list"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now().toString())
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.listTarget.lastElementChild?.querySelector("input[type=text]")?.focus()
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-row]")

    if (row.dataset.newRecord === "true") {
      row.remove()
    } else {
      row.querySelector("input[name*='[_destroy]']").value = "1"
      row.hidden = true
    }
  }
}
