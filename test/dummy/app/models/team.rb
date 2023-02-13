class Team < ApplicationRecord
  include Billing::Usage::HasTrackers

  validates :name, presence: true

  def team
    self
  end
end
