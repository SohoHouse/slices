require 'spec_helper'

describe "Renaming an asset", type: :model do
  context "with a simple name" do
    let :asset do
      Asset.make file: file_fixture
    end

    before do
      asset.name = "Cute Ladybird"
      asset.save!
    end

    it "ensures the extension is maintained" do
      expect(asset.name).to eq("Cute_Ladybird.jpg")
    end

    it "alters the file name accordingly" do
      expect(asset.file_file_name).to eq("Cute_Ladybird.jpg")
    end

    it "moves the file on storage" do
      expect(asset.file).to be_exists
    end

    context "with a filename that is too long" do
      let(:trimmed_filename_length) { reasonable_length - extension_length - uuid.length }
      let(:uuid) { "2a89b871-1bdb-4dce-9006-ad5e083c66da" }
      let(:extension_length) { 4 }
      let(:reasonable_length) { 100 }
      let(:really_long) { 5000 }

      before do
        allow_any_instance_of(Asset::FilenameSanitizer).to receive(:uuid).and_return uuid
      end

      it "correctly renames the file" do
        asset.name = "a" * really_long
        expect(-> { asset.save! }).not_to raise_error

        asset.reload

        expect(asset.file_file_name.length).to eq reasonable_length
        expect(asset.file_file_name).to match /a{#{trimmed_filename_length}}#{uuid}.jpg/
      end
    end
  end

  context "with a dangerous name" do
    let :asset do
      Asset.make file: file_fixture, name: '../../../Ladybird/ladybug_1'
    end

    it "sanitizes the problem characters" do
      expect(asset.file_file_name).to eq(".._.._.._Ladybird_ladybug_1.jpg")
    end

    it "manages to store the file" do
      expect(asset.file).to be_exists
    end
  end

  context "when changing case only" do
    let :asset do
      Asset.make file: file_fixture
    end

    before do
      asset.name = 'Ladybird.jpg'
      asset.save!
    end

    it "obeys the new case" do
      expect(asset.file_file_name).to eq("Ladybird.jpg")
    end

    it "actually moves the file" do
      expect(asset.file.path).to match /Ladybird.jpg$/
      expect(asset.file).to be_exists
    end
  end
end
