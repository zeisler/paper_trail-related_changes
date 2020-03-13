require 'rails_helper'

RSpec.describe OrderItem do
  it "builds hierarchy" do
    expect(
      PaperTrail::RelatedChanges::Hierarchy.build(OrderItem).to_simple
    ).to eq(
           {
             :type     => "OrderItem", :name => "OrderItem",
             :children => [
               { :type => "Note", :name => :notes }
             ]
           }
         )
  end

  it "builds hierarchy with a parent" do
    expect(
      PaperTrail::RelatedChanges::Hierarchy.build(OrderItem, include_parent_as_child: [:product]).to_simple
    ).to eq(
           {
             :type     => "OrderItem", :name => "OrderItem",
             :children => [
               { :type     => "Product", :name => :product,
                 :children => [
                   { :type => "Note", :name => :notes }
                 ]
               },
               { :type => "Note", :name => :notes }
             ]
           }
         )
  end
end
