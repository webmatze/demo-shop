Product.find_or_create_by!(name: "Ruby Mug") { |p| p.price = 12.50; p.description = "A mug for Rubyists." }
Product.find_or_create_by!(name: "Rails T-Shirt") { |p| p.price = 24.00; p.description = "Red, of course." }
Product.find_or_create_by!(name: "Screencast Sticker Pack") { |p| p.price = 4.90; p.description = "Ten stickers." }
