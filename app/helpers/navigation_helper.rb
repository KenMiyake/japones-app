module NavigationHelper
  NavItem = Data.define(:kanji, :label, :path)

  # Secciones del sidebar. path: nil = todavía no implementada (se muestra como "pronto").
  def nav_items
    [
      NavItem.new("計画", "Plan", plan_weeks_path),
      NavItem.new("漢字", "Kanji", kanjis_path),
      NavItem.new("言葉", "Palabras", words_path),
      NavItem.new("部品", "Piezas", components_path),
      NavItem.new("区別", "Distinguir", confusable_groups_path),
      NavItem.new("既知", "Sabidos", known_kanjis_path)
    ]
  end

  # Opciones del menú de usuario. Todas "pronto" hasta que exista la autenticación.
  def user_menu_items
    [
      NavItem.new("人", "Perfil", nil),
      NavItem.new("設", "Preferencias", nil),
      :divider,
      NavItem.new("出", "Cerrar sesión", nil)
    ]
  end

  # Ruta de navegación de la barra superior:
  #   <% content_for :breadcrumbs, breadcrumbs([ "Plan de estudio", plan_weeks_path ], [ "S5" ]) %>
  # Cada elemento es [texto, path]; el último (sin path) es la página actual.
  def breadcrumbs(*items)
    safe_join(items.each_with_index.map do |(label, path), index|
      separator = index.zero? ? "".html_safe : tag.li("/", class: "text-sumi/25", "aria-hidden": "true")
      crumb = if path
        tag.li(link_to(label, path, class: "transition-colors hover:text-sumi"))
      else
        tag.li(label, class: "truncate font-medium text-sumi", "aria-current": "page")
      end
      separator + crumb
    end)
  end

  def sidebar_collapsed?
    cookies[:sidebar_collapsed] == "1"
  end

  def nav_item_active?(item)
    return false if item.path.nil?

    current_page?(item.path) || request.path.start_with?("#{item.path}/")
  end
end
