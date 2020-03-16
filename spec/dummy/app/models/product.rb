class Product < ApplicationRecord
  has_many :items, class_name: 'OrderItem'
  has_many :notes, as: :notable
end
