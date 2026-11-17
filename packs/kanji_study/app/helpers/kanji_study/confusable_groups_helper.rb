module KanjiStudy
  module ConfusableGroupsHelper
    PRACTICE_MODE_TONES = { card: :accent, paper: :neutral, pending: :warning }.freeze

    def practice_mode_label(mode)
      t("kanji_study.practice_modes.#{mode}")
    end

    def practice_mode_badge(group)
      badge practice_mode_label(group.practice_mode), tone: PRACTICE_MODE_TONES.fetch(group.practice_mode.to_sym)
    end

    def practice_mode_options
      ConfusableGroup.practice_modes.keys.map { |mode| [ practice_mode_label(mode), mode ] }
    end

    # { "card" => 6, "paper" => 2, "pending" => 14 }
    def practice_mode_counts
      ConfusableGroup.group(:practice_mode).count
    end
  end
end
