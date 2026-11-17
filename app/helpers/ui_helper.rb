# Clases de Tailwind para los elementos de formulario y botones, en un solo lugar.
# (Con Bootstrap serían .form-control, .form-label y .btn-*; ver README, Aprendizajes.)
module UiHelper
  INPUT = "block w-full rounded-md border border-sumi/15 bg-white/80 px-3 py-2 text-sm text-sumi " \
          "placeholder:text-sumi/30 transition focus:border-shu/50 focus:outline-none focus:ring-2 focus:ring-shu/15 " \
          "aria-invalid:border-shu/60"
  LABEL = "mb-1.5 block text-xs font-medium tracking-wide text-nezumi"
  BUTTON_BASE = "inline-flex items-center justify-center gap-2 rounded-md px-4 py-2 text-sm font-medium " \
                "transition-colors duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-shu/30"
  BUTTONS = {
    primary: "bg-sumi text-washi hover:bg-sumi/85",
    secondary: "border border-sumi/15 bg-white/70 text-sumi hover:border-sumi/30 hover:bg-white",
    ghost: "text-nezumi hover:bg-sumi/[0.05] hover:text-sumi",
    danger: "text-shu hover:bg-shu/[0.06]"
  }.freeze

  def ui_input_class(extra = nil)
    [ INPUT, extra ].compact.join(" ")
  end

  def ui_label_class
    LABEL
  end

  def ui_button_class(variant = :secondary, extra = nil)
    [ BUTTON_BASE, BUTTONS.fetch(variant), extra ].compact.join(" ")
  end
end
