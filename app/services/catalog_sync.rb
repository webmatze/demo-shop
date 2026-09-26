# Pushes a product to the external catalog. The real API is slow; we simulate
# that with a sleep and write a line to tmp/catalog.log so we can see it happen.
class CatalogSync
  class Error < StandardError; end

  def self.push(product)
    sleep 3
    File.open(Rails.root.join("tmp/catalog.log"), "a") do |f|
      f.puts "synced #{product.name} at #{Time.current.strftime('%H:%M:%S')}"
    end
    product.update!(synced_at: Time.current)
    true
  end
end
