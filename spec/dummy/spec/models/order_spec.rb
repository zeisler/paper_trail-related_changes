require 'rails_helper'

RSpec.describe Order do
  it "builds hierarchy" do
    expect(
      PaperTrail::RelatedChanges::Hierarchy.build(Order).to_simple
    ).to eq(
           {
             :type     => "Order", :name => "Order",
             :children => [
               {
                 :type     => "OrderItem", :name => :items,
                 :children => [
                   { :type => "Note", :name => :note }
                 ]
               },
               { :type => "Note", :name => :note }
             ]
           }
         )
  end
end
