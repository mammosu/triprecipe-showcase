require 'rails_helper'

RSpec.describe ApplicationPolicy do
  let(:user) { User.create!(email: "u#{SecureRandom.hex}@example.com", password: "password") }
  let(:record) { Object.new }
  subject { described_class.new(user, record) }

  it 'defaults to false for index/show/create/update/destroy' do
    expect(subject.index?).to be false
    expect(subject.show?).to be false
    expect(subject.create?).to be false
    expect(subject.update?).to be false
    expect(subject.destroy?).to be false
  end

  it 'maps new? to create? and edit? to update?' do
    expect(subject.new?).to eq(subject.create?)
    expect(subject.edit?).to eq(subject.update?)
  end
end
