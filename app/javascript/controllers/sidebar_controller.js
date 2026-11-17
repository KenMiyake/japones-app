import { Controller } from "@hotwired/stimulus"

// Sidebar: colapsable en escritorio y cajón deslizable en móvil.
//
// El estado vive en atributos del <body> (data-collapsed, data-open) y Tailwind anima
// según ellos (variantes group-data-*). El colapso se guarda en una cookie para que el
// servidor renderice el estado correcto y no haya parpadeo al navegar con Turbo.
export default class extends Controller {
  static targets = ["toggle"]

  toggleCollapsed() {
    const collapsed = !this.element.hasAttribute("data-collapsed")
    this.element.toggleAttribute("data-collapsed", collapsed)
    document.cookie = `sidebar_collapsed=${collapsed ? 1 : 0}; path=/; max-age=31536000; SameSite=Lax`
    this.#syncAria(collapsed)
  }

  open() {
    this.element.setAttribute("data-open", "")
  }

  close() {
    this.element.removeAttribute("data-open")
  }

  #syncAria(collapsed) {
    this.toggleTargets.forEach((button) => button.setAttribute("aria-expanded", String(!collapsed)))
  }
}
