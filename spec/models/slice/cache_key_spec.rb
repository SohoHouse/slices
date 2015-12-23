require 'spec_helper'

describe Slice, type: :model do
  describe "#cache_key" do
    let :timestamp do
      Time.new(2013, 12, 11, 10, 9, 8)
    end

    let :slice do
      Slice.new
    end

    context "when the slice is embeded in a page" do
      before do
        page = double(updated_at: timestamp)
        allow(slice).to receive_messages(
          id: 'bson',
          model_key: 'slice',
          normal_or_set_page: page,
        )
      end

      it "should have the slice id and page's updated at key name" do
        expect(slice.cache_key).to eq "slice/bson-20131211100908"
      end
    end

    context "when the slice is not embeded in a page" do
      it "should only have the slice id as the key name" do
        expect(slice.cache_key).to eq "slices/new"
      end
    end
  end
end
