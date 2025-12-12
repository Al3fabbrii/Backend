class User < ApplicationRecord
  has_many: projects
  has_many: tasks

  validates :name, presence: true
  validates :email, presence:true, uniqueness: true
end
