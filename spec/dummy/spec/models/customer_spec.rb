require 'rails_helper'

RSpec.describe Customer do
  it "builds hierarchy" do
    expect(
      PaperTrail::RelatedChanges::Hierarchy.build(Customer).to_simple
    ).to eq(
           :children => [
             { :children => [
               { :children => [
                 { :name => :note, :type => "Note" }
               ],
                 :name     => :items, :type => "OrderItem"
               },
               { :name => :note, :type => "Note" }
             ],
               :name     => :orders, :type => "Order"
             },
             { :name => :note, :type => "Note" }
           ],
           :name     => "Customer",
           :type     => "Customer",
         )
  end
end
