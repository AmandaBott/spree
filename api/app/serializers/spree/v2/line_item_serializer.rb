module Spree
  module V2
    class LineItemSerializer < BaseSerializer
      set_type :line_item
      attributes :id, :quantity, :price, :variant_id
      belongs_to :variant
    end
  end
end
