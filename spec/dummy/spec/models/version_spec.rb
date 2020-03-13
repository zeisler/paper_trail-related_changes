require 'rails_helper'

RSpec.describe PaperTrail::Version do
  describe "#name", versioning: true do
    let!(:user) { User.create!(name: "Fred") }
    let(:user_versions) { described_class.where(item_type: "User", item_id: user.id) }

    it "describes the record" do
      expect(user_versions.count).to eq(1)

      # Create event
      original_name = user_versions.first.name
      expect(original_name).to eq(user.reload.name)

      user.update(name: "Steve")
      expect(user_versions.count).to eq(2)

      # Update event
      expect(user_versions.last.name).to eq("Steve")

      # come back and check create event
      expect(user_versions.first.name).to eq(original_name)
    end

    it "rescues a failed reify" do
      subject.update(item_type: "User", item_id: user.id)
      expect(subject).to receive(:next).and_return(subject)
      expect(subject).to receive(:reify).and_raise(StandardError)

      expect(subject.name).to eq(user.name)
    end
  end

  describe "#model_class" do
    it "returns the versioned active record class" do
      version = described_class.create!(item_type: "User", item_id: 1, event: "create")
      expect(version.model_class).to eq(User)
    end
  end

  describe "#extract" do
    it "from object" do
      subject = described_class.new(object: { "product_id" => 12 })
      expect(subject.extract(:product_id)).to eq(12)
    end

    it "from object_changes" do
      subject = described_class.new(object_changes: { "product_id" => [nil, 12] })
      expect(subject.extract(:product_id)).to eq(12)
    end
  end
end
