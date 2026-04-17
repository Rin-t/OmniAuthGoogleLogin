class User < ApplicationRecord
  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  def self.from_omniauth(auth)
    find_or_initialize_by(provider: auth.provider, uid: auth.uid).tap do |user|
      user.email = auth.info.email
      user.name  = auth.info.name
      user.image = auth.info.image
      user.save!
    end
  end
end
