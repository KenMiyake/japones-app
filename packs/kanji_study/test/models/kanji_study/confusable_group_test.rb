require "test_helper"

module KanjiStudy
  class ConfusableGroupTest < ActiveSupport::TestCase
    test "acepta los kanji separados por / o seguidos, en ese orden" do
      group = ConfusableGroup.create!(characters: "間/食")
      assert_equal "間/食", group.label

      other = ConfusableGroup.create!(characters: "食人")
      assert_equal %w[食 人], other.kanjis.map(&:character)
    end

    test "exige al menos dos kanji distintos" do
      [ "人", "人/人", "あ/い", "" ].each do |characters|
        group = ConfusableGroup.new(characters:)

        assert_not group.valid?, "#{characters.inspect} no debería ser válido"
        assert_includes group.errors.full_messages, "Kanji del grupo debe tener al menos 2 kanji distintos (ej.: 人/入)"
      end
    end

    test "crea como kanji de referencia los que no existen y los informa" do
      group = nil
      assert_difference -> { Kanji.count }, 2 do
        group = ConfusableGroup.create!(characters: "待/持/食")
      end

      assert_equal %w[待 持], group.created_kanjis.map(&:character)
      assert_nil Kanji.find_by!(character: "待").plan_week
    end

    test "al editar, reemplaza y reordena los miembros" do
      group = confusable_groups(:hito_taberu)

      group.update!(characters: "食/間")

      assert_equal %w[食 間], group.reload.kanjis.map(&:character)
      assert_equal [ 0, 1 ], group.members.map(&:position)
      assert_equal 2, group.members.count
    end

    test "practice_mode es por confirmar por defecto y solo admite los tres valores" do
      assert ConfusableGroup.new.practice_pending?
      assert_not ConfusableGroup.new(characters: "人/食", practice_mode: "quizás").valid?
    end

    test "el kanji conoce sus grupos" do
      assert_equal 2, kanjis(:hito).confusable_groups.count
    end

    test "al eliminar el grupo no se eliminan los kanji" do
      assert_no_difference -> { Kanji.count } do
        confusable_groups(:hito_taberu).destroy
      end
      assert_equal 0, ConfusableMember.where(confusable_group_id: confusable_groups(:hito_taberu).id).count
    end
  end
end
