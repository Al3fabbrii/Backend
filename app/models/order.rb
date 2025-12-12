class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :customer, presence: true
  validates :address, presence: true

  accepts_nested_attributes_for :order_items

  def as_json(options = {})
    {
      id: id,
      customer: customer,
      address: address,
      total: total.to_f,
      createdAt: created_at.iso8601,
      order_items: order_items.map(&:as_json)
    }
  end
end
