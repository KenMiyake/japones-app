module KanjiStudy
  class ComponentsController < ApplicationController
    before_action :set_component, only: %i[edit update destroy]

    def index
      @components = Component.includes(:kanjis).ordered
    end

    def new
      @component = Component.new
    end

    def create
      @component = Component.new(component_params)

      if @component.save
        redirect_to components_path, notice: "Pieza #{@component.label} creada."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @component.update(component_params)
        redirect_to components_path, notice: "Pieza #{@component.label} actualizada."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @component.destroy!
      redirect_to components_path, notice: "Pieza #{@component.label} eliminada.", status: :see_other
    end

    private

    def set_component
      @component = Component.find(params[:id])
    end

    def component_params
      params.expect(component: %i[character name meaning_es])
    end
  end
end
