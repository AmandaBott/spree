module Spree
  class TaxonIcon < Asset
    include ENV['USE_PAPERCLIP'] ? Configuration::Paperclip : Configuration::ActiveStorage
  end
end
