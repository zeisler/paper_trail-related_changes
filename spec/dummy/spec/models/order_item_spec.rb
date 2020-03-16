require 'rails_helper'

RSpec.describe OrderItem do
  it "builds hierarchy" do
    expect(
      PaperTrail::RelatedChanges::Hierarchy.build(OrderItem).to_simple
    ).to eq(
           {
             :type     => "OrderItem", :name => "OrderItem",
             :children => [
               { :type => "Note", :name => :note }
             ]
           }
         )
  end
end
