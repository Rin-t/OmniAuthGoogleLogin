class OauthPendingState < ApplicationRecord
  belongs_to :user, optional: true

  validates :state, presence: true, uniqueness: true
  validates :redirect_uri, presence: true
  validates :expires_at, presence: true

  scope :unexpired, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end
end
