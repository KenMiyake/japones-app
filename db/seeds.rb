# Datos iniciales: bin/rails db:seed
# Cada seeder es idempotente y no sobrescribe lo que ya existe (se puede volver a correr).

plan = PlanSeeder.call
puts "Lecciones creadas: #{plan.lessons_created}"
puts "Semanas del plan creadas: #{plan.weeks_created}"
