class Project < ApplicationRecord
  belongs_to :user, presence: true
  validates :title, presence: true
end
