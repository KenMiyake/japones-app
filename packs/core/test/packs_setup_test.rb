require "test_helper"

# Verifica la configuración de packs (docs/decisions/0001). Que este archivo corra con
# `bin/rails test` confirma además que el runner encuentra los tests dentro de packs/.
class PacksSetupTest < ActiveSupport::TestCase
  test "Rails autocarga las carpetas app/ de cada pack" do
    autoload_paths = ActiveSupport::Dependencies.autoload_paths.map(&:to_s)

    %w[core kanji_study].each do |pack|
      assert_includes autoload_paths, Rails.root.join("packs/#{pack}/app/models").to_s
      assert_includes autoload_paths, Rails.root.join("packs/#{pack}/app/controllers").to_s
    end
  end

  test "las vistas de los packs están en el view path" do
    view_paths = ActionController::Base.view_paths.map { |path| path.to_path.to_s }

    assert_includes view_paths, Rails.root.join("packs/kanji_study/app/views").to_s
  end
end
