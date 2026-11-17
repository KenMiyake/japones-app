module ApplicationHelper
  BADGE_TONES = {
    neutral: "bg-sumi/[0.04] text-nezumi ring-sumi/15",
    accent: "bg-shu/[0.07] text-shu ring-shu/30",
    warning: "bg-kincha/[0.07] text-kincha ring-kincha/30",
    success: "bg-matcha/[0.08] text-matcha ring-matcha/30"
  }.freeze

  # Insignia pequeña: <%= badge "provisional", tone: :warning %>
  # Las clases viven aquí para no repetirlas en cada vista (ver README, Aprendizajes).
  def badge(text, tone: :neutral)
    tag.span(text, class: [
      "inline-flex items-center rounded-sm px-2 py-0.5 text-[11px] font-medium tracking-wide ring-1 ring-inset",
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
