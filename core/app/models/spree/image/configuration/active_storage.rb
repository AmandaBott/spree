module Spree
  class Image < Asset
    module Configuration
      module ActiveStorage
        extend ActiveSupport::Concern

        included do
          has_one_attached :attachment

          def self.styles
            @styles ||= {
              mini:    '48x48>',
              small:   '100x100>',
              product: '240x240>',
              large:   '600x600>'
            }
          end

          def default_style
            :product
          end
        end
      end
    end
  end
end
