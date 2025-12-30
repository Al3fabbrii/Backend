# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'json'

puts "🌱 Seeding database..."

# Pulisci dati esistenti
puts "Cleaning existing products..."
Product.destroy_all

# Leggi i dati dal mock API
mock_data_path = Rails.root.join('..', 'frontend', 'shop-mock-api', 'db.json')

unless File.exist?(mock_data_path)
  puts "❌ Error: Mock data file not found at #{mock_data_path}"
  exit 1
end

mock_data = JSON.parse(File.read(mock_data_path))

# Importa i prodotti
puts "Importing products from mock API..."
mock_data['products'].each do |product|
  Product.create!(
    id: product['id'],
    title: product['title'],
    description: product['description'],
    price: product['price'],
    original_price: product['originalPrice'],
    sale: product['sale'],
    thumbnail: product['thumbnail'],
    tags: product['tags'],
    stock: rand(10..100), # Stock casuale tra 10 e 100
    created_at: product['createdAt'],
    updated_at: product['createdAt']
  )
end

puts "✅ Successfully imported #{Product.count} products"
puts "🎉 Seeding completed!"
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Crea utenti di test
puts "\nCreating test users..."


puts "✅ Created #{User.count} users"
puts "   - User: user@example.com / password123"
puts "   - Admin: admin@example.com / admin123"

puts "\n🎉 Seeding completed!"
