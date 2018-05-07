module Spree
  if ENV['USE_PAPERCLIP']
    Paperclip.interpolates :viewable_id do |attachment, _style|
      attachment.instance.viewable_id
    end
  end

  class Asset < Spree::Base
    include Support::ActiveStorage unless ENV['USE_PAPERCLIP']

    belongs_to :viewable, polymorphic: true, touch: true
    acts_as_list scope: [:viewable_id, :viewable_type]
  end
end
