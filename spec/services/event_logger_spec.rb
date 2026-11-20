require 'rails_helper'

RSpec.describe EventLogger do
  let(:recipe) { create(:recipe) }
  let(:user) { create(:user) }

  describe '.log!' do
    context 'with valid attributes' do
      it 'creates an EventLog' do
        expect {
          described_class.log!(event_type: 'recipe_view', recipe: recipe, actor: user)
        }.to change(EventLog, :count).by(1)

        log = EventLog.last
        expect(log.event_type).to eq('recipe_view')
        expect(log.recipe).to eq(recipe)
        expect(log.actor).to eq(user)
      end

      it 'allows nil actor' do
        expect {
          described_class.log!(event_type: 'recipe_view', recipe: recipe, actor: nil)
        }.to change(EventLog, :count).by(1)
        expect(EventLog.last.actor).to be_nil
      end

      it 'saves metadata' do
        metadata = { 'foo' => 'bar' }
        described_class.log!(event_type: 'recipe_view', recipe: recipe, metadata: metadata)
        expect(EventLog.last.metadata).to eq(metadata)
      end
    end

    context 'with invalid attributes' do
      it 'raises error for invalid event_type' do
        expect {
          described_class.log!(event_type: 'invalid_type', recipe: recipe)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'raises error for missing recipe' do
        expect {
          described_class.log!(event_type: 'recipe_view', recipe: nil)
        }.to raise_error(ActiveRecord::RecordInvalid) # or StandardError depending on implementation
      end
    end
  end
end
