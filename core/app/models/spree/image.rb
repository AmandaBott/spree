module Spree
  class Image < Asset
    include ENV['USE_PAPERCLIP'] ? Configuration::Paperclip : Configuration::ActiveStorage
  end
end
