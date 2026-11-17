module KanjiStudy
  class ConfusableMember < ApplicationRecord
    self.table_name = "confusable_members"

    belongs_to :confusable_group, class_name: "KanjiStudy::ConfusableGroup", inverse_of: :members
    belongs_to :kanji, class_name: "KanjiStudy::Kanji", inverse_of: :confusable_members
  end
end
