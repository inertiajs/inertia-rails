# frozen_string_literal: true

RSpec.describe InertiaRails::ValidationErrors do
  describe '.flatten' do
    it 'converts indexed association keys to dot notation' do
      errors = { 'addresses[0].street': ["can't be blank"], user: { 'phones[1].number': ['is invalid'] } }

      expect(described_class.flatten(errors)).to eq(
        'addresses.0.street' => ["can't be blank"],
        'user.phones.1.number' => ['is invalid']
      )
    end

    it 'merges a dotted symbol key with the same nested key instead of duplicating it' do
      errors = { 'profile.bio': ['too long'], profile: { bio: ["can't be blank"] } }

      expect(described_class.flatten(errors)).to eq('profile.bio' => ["can't be blank"])
    end
  end
end
