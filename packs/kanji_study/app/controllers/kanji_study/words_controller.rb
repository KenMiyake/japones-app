module KanjiStudy
  class WordsController < ApplicationController
    before_action :set_word, only: %i[edit update destroy]

    def index
      @query = params[:q].to_s.strip
      @words = Word.includes(:kanjis, :lesson).ordered
      @words = @words.search(@query) if @query.present?
    end

    def new
      @word = Word.new(text: params[:text])
    end

    def create
      @word = Word.new(word_params)

      if @word.save
        redirect_to return_path, notice: saved_notice("creada")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @word.update(word_params)
        redirect_to words_path, notice: saved_notice("actualizada")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @word.destroy!
      redirect_to words_path, notice: "Palabra #{@word.text} eliminada.", status: :see_other
    end

    private

    def set_word
      @word = Word.find(params[:id])
    end

    def word_params
      params.expect(word: %i[text reading meaning_es lesson_id])
    end

    # Si se creó desde la ficha de un kanji, vuelve a esa ficha.
    def return_path
      kanji = Kanji.find_by(character: params[:return_to_kanji]) if params[:return_to_kanji].present?
      kanji ? kanji_path(kanji) : words_path
    end

    def saved_notice(verb)
      notice = "Palabra #{@word.text} #{verb}."
      missing = @word.unregistered_kanji
      missing.any? ? "#{notice} Kanji sin registrar (no enlazados): #{missing.join(' ')}." : notice
    end
  end
end
