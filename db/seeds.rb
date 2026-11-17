# Datos iniciales: bin/rails db:seed
# Cada seeder es idempotente y no sobrescribe lo que ya existe (se puede volver a correr).

plan = PlanSeeder.call
puts "Lecciones creadas: #{plan.lessons_created}"
puts "Semanas del plan creadas: #{plan.weeks_created}"

kanji = KanjiStudy::PlanKanjiSeeder.call
puts "Kanji creados: #{kanji.created} (ya existían: #{kanji.skipped})"

groups = KanjiStudy::ConfusableGroupSeeder.call
puts "Grupos para distinguir creados: #{groups.created} (ya existían: #{groups.skipped})"
puts "Kanji de referencia creados: #{groups.reference_kanji.join(' ')}" if groups.reference_kanji.any?
