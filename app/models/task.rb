class Task < ApplicationRecord
  belongs_to :user, presence: true
  belongs_to :project, presence: true

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: [ "In corso", "Completato", "In attesa" ] }
  validates :deadline, optional: true
  validates :user, uniqueness: { scope: [ :project_id, :title ] }
end
