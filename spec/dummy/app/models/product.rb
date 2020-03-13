class Product < ApplicationRecord
  has_many :items, class_name: 'OrderItem'
  has_many :notes, dependent: :destroy, foreign_key: :notable_id, as: :notable
end
