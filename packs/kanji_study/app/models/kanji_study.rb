# Pack kanji_study (ver docs/decisions/0001).
module KanjiStudy
  # Los modelos usan nombres relativos: params[:kanji], kanji_path, dom_id → "kanji_1",
  # en vez de kanji_study_kanji. Las traducciones siguen bajo kanji_study/kanji.
  def self.use_relative_model_naming?
    true
  end
end
