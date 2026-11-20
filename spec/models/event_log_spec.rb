require 'rails_helper'

RSpec.describe EventLog, type: :model do
  describe 'associations' do
    it { should belong_to(:recipe) }
    it { should belong_to(:actor).class_name('User').optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:event_type) }
    it { should validate_inclusion_of(:event_type).in_array(EventLog::EVENT_TYPES) }
  end

  describe 'creation' do
    let(:recipe) { create(:recipe) }
    let(:user) { create(:user) }

    it 'is valid with valid attributes' do
      event_log = build(:event_log, recipe: recipe, actor: user, event_type: 'recipe_view')
      expect(event_log).to be_valid
    end

    it 'is valid without actor' do
      event_log = build(:event_log, recipe: recipe, actor: nil, event_type: 'recipe_view')
      expect(event_log).to be_valid
    end
  end
end
