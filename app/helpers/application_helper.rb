module ApplicationHelper
  BADGE_TONES = {
    neutral: "bg-stone-100 text-stone-700 ring-stone-300",
    info: "bg-sky-50 text-sky-800 ring-sky-300",
    warning: "bg-amber-50 text-amber-800 ring-amber-300",
    success: "bg-emerald-50 text-emerald-800 ring-emerald-300"
  }.freeze

  # Insignia pequeña: <%= badge "provisional", tone: :warning %>
  # Las clases viven aquí para no repetirlas en cada vista (ver README, Aprendizajes).
  def badge(text, tone: :neutral)
    tag.span(text, class: [
      "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset",
      BADGE_TONES.fetch(tone)
    ])
  end

  # "16–22 nov" o "30 nov – 6 dic" (o con año si cambia: "28 dic 2026 – 3 ene 2027").
  def date_range(from, to)
    if from.year != to.year
      "#{l(from, format: '%-d %b %Y')} – #{l(to, format: '%-d %b %Y')}"
    elsif from.month != to.month
      "#{l(from, format: '%-d %b')} – #{l(to, format: '%-d %b')}"
    else
      "#{from.day}–#{l(to, format: '%-d %b')}"
    end
  end
end
