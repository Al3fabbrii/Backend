class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :customer, presence: true
  validates :address, presence: true

  accepts_nested_attributes_for :order_items

  def as_json(options = {})
    # Precarica i prodotti se non già caricati per evitare N+1
    items_with_products = order_items.includes(:product) unless order_items.loaded?
    items_with_products ||= order_items
    
    {
      id: id,
      userId: user_id,
      customer: customer,
      address: address,
      total: total.to_f,
      createdAt: created_at.iso8601,
      items: items_with_products.map do |item|
        {
          id: item.id,
          orderId: item.order_id,
          productId: item.product_id,
          quantity: item.quantity,
          unitPrice: item.unit_price.to_f,
          product: item.product.as_json
        }
      end
    }
  end
end
