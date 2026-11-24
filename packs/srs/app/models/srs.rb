# Pack srs: repetición espaciada (ver docs/decisions/0004).
module Srs
  # Nombres relativos: params[:card], card_path, dom_id → "card_1".
  def self.use_relative_model_naming?
    true
  end
end
