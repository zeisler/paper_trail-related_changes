class Customer < ApplicationRecord
  belongs_to :buying_group
  has_many :orders

  has_many :notes, dependent: :destroy, foreign_key: :notable_id, as: :notable
end
