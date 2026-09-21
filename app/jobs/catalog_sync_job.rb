class CatalogSyncJob < ApplicationJob
  queue_as :default

  retry_on CatalogSync::Error, wait: :polynomially_longer, attempts: 5

  def perform(product)
    CatalogSync.push(product)
  end
end
