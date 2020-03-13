require "rails_helper"

RSpec.describe "Request", type: :request do
  describe "#GET" do
    it "shows related versions", versioning: true do
      User.create!(name: "Dustin")
      buying_group = BuyingGroup.create!
      customer     = Customer.create!(buying_group: buying_group)
      get "/related_changes", params: { type: "Customer", id: customer.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).keys).to eq(["data", "meta"])
      expect(
        JSON.parse(response.body)["data"].map { |d| d.except("timestamp", "version_id") }
      ).to eq([{ "diffs"          =>
                   [{
                      "attribute" => "buying_group",
                      "new"       => "Record no longer exists",
                      "old"       => nil,
                    }],
                 "children"       => [],
                 "description"    => { "name" => "Customer", "value" => nil },
                 "event"          => "create",
                 "requested_root" => true,
                 "resource"       => "Customer",
                 "resource_id"    => customer.id.to_s,
                 "user"           => "system" }])
    end
  end
end
