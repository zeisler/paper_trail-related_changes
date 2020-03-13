class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_many :notes, dependent: :destroy, foreign_key: :notable_id, as: :notable
end
