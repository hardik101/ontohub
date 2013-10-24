# A users SSH Key
class Key < ActiveRecord::Base
  
  include Key::Fingerprint
  include Key::Filesystem

  after_create :add_to_authorized_keys_file
  after_destroy :remove_from_authorized_key_file

  belongs_to :user

  attr_accessible :key, :name

  strip_attributes :only => [:key, :name]

  validates :name, presence: true, length: { within: 0..50 }
  validates :key, presence: true, length: { within: 0..5000 }, format: { with: /\A(ssh|ecdsa)-.*\Z/ }, uniqueness: true

  def shell_id
    "key-#{id}"
  end


  private
  def add_to_authorized_keys_file
    AuthorizedKeysManager.add(self.id, self.key)
  end

  def remove_from_authorized_keys_file
    AuthorizedKeysManager.remove(self.id)
  end

end
