class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_one :note, as: :notable
end
