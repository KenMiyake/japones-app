import { Controller } from "@hotwired/stimulus"

// Tutorial: recorrido guiado sobre la interfaz.
//
// Los pasos y los textos vienen del servidor (I18n, config/locales/tutorial.<idioma>.yml)
// en data-tour-config-value; aquí no hay textos propios. Cada paso puede resaltar un
// elemento con data-tour="<target>": un foco animado lo rodea y la tarjeta se ubica al lado.
// Si el elemento no está visible (p. ej. el sidebar en móvil), la tarjeta va centrada.
//
// Se abre solo la primera vez (si autostart) y luego con la acción tour#start.
// Teclado: → o Enter avanza, ← retrocede, Esc cierra.
const STORAGE_KEY = "tutorial:v1:done"
const AUTOSTART_DELAY = 3800 // deja terminar la animación de おかえり

export default class extends Controller {
  static values = { config: Object, autostart: Boolean }

  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    this.onResize = () => this.position()
    if (this.autostartValue && !localStorage.getItem(STORAGE_KEY)) {
      this.timeout = setTimeout(() => this.start(), AUTOSTART_DELAY)
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
    this.teardown()
  }

  start(event) {
    event?.preventDefault()
    clearTimeout(this.timeout)
    this.index = 0
    this.build()
    document.addEventListener("keydown", this.onKeydown)
    window.addEventListener("resize", this.onResize)
    this.render()
  }

  next() {
    if (this.index < this.steps.length - 1) {
      this.index += 1
      this.render()
    } else {
      this.finish()
    }
  }

  previous() {
    if (this.index > 0) {
      this.index -= 1
      this.render()
    }
  }

  finish() {
    localStorage.setItem(STORAGE_KEY, "1")
    this.teardown()
  }

  // --- privado ---

  get steps() {
    return this.configValue.steps || []
  }

  get labels() {
    return this.configValue.labels || {}
  }

  onKeydown(event) {
    if (event.key === "Escape") this.finish()
    else if (event.key === "ArrowRight" || event.key === "Enter") { event.preventDefault(); this.next() }
    else if (event.key === "ArrowLeft") this.previous()
  }

  build() {
    this.teardown()
    this.root = document.createElement("div")
    this.root.setAttribute("role", "dialog")
    this.root.setAttribute("aria-modal", "true")
    this.root.setAttribute("aria-labelledby", "tour-title")
    this.root.className = "tour fixed inset-0 z-[60] print:hidden"

    // Foco: un recuadro con una sombra enorme que oscurece todo lo demás.
    this.spotlight = document.createElement("div")
    this.spotlight.className =
      "pointer-events-none fixed rounded-lg ring-2 ring-shu/70 transition-all duration-300 ease-out " +
      "shadow-[0_0_0_9999px_rgb(36_34_31/0.45)] motion-reduce:transition-none"

    this.card = document.createElement("div")
    this.card.className =
      "fixed w-[min(22rem,calc(100vw-2rem))] rounded-md border border-sumi/10 bg-washi p-5 text-sumi " +
      "shadow-[0_20px_48px_-16px_rgb(36_34_31/0.45)] transition-all duration-300 ease-out motion-reduce:transition-none"

    this.title = document.createElement("h2")
    this.title.id = "tour-title"
    this.title.className = "font-kanji text-lg font-bold tracking-wide"
    this.body = document.createElement("p")
    this.body.className = "mt-2 text-sm leading-relaxed text-sumi/80"

    const footer = document.createElement("div")
    footer.className = "mt-5 flex items-center gap-2"
    this.progress = document.createElement("span")
    this.progress.className = "mr-auto text-xs text-nezumi"
    this.skipButton = this.button(this.labels.skip, "text-nezumi hover:text-sumi", () => this.finish())
    this.previousButton = this.button(this.labels.previous, "text-nezumi hover:text-sumi", () => this.previous())
    this.nextButton = this.button(this.labels.next, "bg-sumi text-washi hover:bg-sumi/85", () => this.next())
    footer.append(this.progress, this.skipButton, this.previousButton, this.nextButton)

    this.card.append(this.title, this.body, footer)
    this.root.append(this.spotlight, this.card)
    document.body.appendChild(this.root)
  }

  button(label, classes, onClick) {
    const button = document.createElement("button")
    button.type = "button"
    button.textContent = label || ""
    button.className = `rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${classes}`
    button.addEventListener("click", onClick)
    return button
  }

  render() {
    const step = this.steps[this.index]
    if (!step) return this.finish()

    this.title.textContent = step.title || ""
    this.body.textContent = step.body || ""
    this.progress.textContent = (this.labels.progress || "%{current} / %{total}")
      .replace("%{current}", this.index + 1)
      .replace("%{total}", this.steps.length)

    const last = this.index === this.steps.length - 1
    this.nextButton.textContent = last ? this.labels.finish : this.labels.next
    this.previousButton.hidden = this.index === 0
    this.skipButton.hidden = last

    this.position()
    this.nextButton.focus()
  }

  position() {
    if (!this.root) return
    const step = this.steps[this.index]
    const target = step?.target && document.querySelector(`[data-tour="${step.target}"]`)
    const rect = target?.getBoundingClientRect()
    const visible = rect && rect.width > 0 && rect.height > 0 && target.offsetParent !== null

    if (!visible) {
      // Sin elemento: foco de tamaño cero en el centro (todo oscuro) y tarjeta centrada.
      Object.assign(this.spotlight.style, { top: "50%", left: "50%", width: "0px", height: "0px" })
      this.spotlight.classList.remove("ring-2")
      const card = this.card.getBoundingClientRect()
      this.place((window.innerWidth - card.width) / 2, (window.innerHeight - card.height) / 2)
      return
    }

    const pad = 6
    this.spotlight.classList.add("ring-2")
    Object.assign(this.spotlight.style, {
      top: `${rect.top - pad}px`, left: `${rect.left - pad}px`,
      width: `${rect.width + pad * 2}px`, height: `${rect.height + pad * 2}px`
    })

    // Al lado derecho si el elemento está a la izquierda (sidebar); si no, debajo.
    const card = this.card.getBoundingClientRect()
    const gap = 16
    if (rect.right + gap + card.width < window.innerWidth && rect.left < window.innerWidth / 3) {
      this.place(rect.right + gap, rect.top + rect.height / 2 - card.height / 2)
    } else {
      this.place(rect.right - card.width, rect.bottom + gap)
    }
  }

  place(left, top) {
    const card = this.card.getBoundingClientRect()
    const margin = 16
    const x = Math.min(Math.max(left, margin), window.innerWidth - card.width - margin)
    const y = Math.min(Math.max(top, margin), window.innerHeight - card.height - margin)
    Object.assign(this.card.style, { left: `${x}px`, top: `${y}px` })
  }

  teardown() {
    document.removeEventListener("keydown", this.onKeydown)
    window.removeEventListener("resize", this.onResize)
    this.root?.remove()
    this.root = null
  }
}
