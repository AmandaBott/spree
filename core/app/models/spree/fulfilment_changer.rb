module Spree
  class FulfilmentChanger
    include ActiveModel::Validations

    validates :quantity, numericality: { greater_than: 0 }
    validates :desired_stock_location, presence: true
    validate  :current_shipment_not_already_shipped
    validate  :desired_shipment_different_from_current
    validate  :enough_stock_at_desired_location, if: :handle_stock_counts?

    def initialize(params = {})
      @current_stock_location = params[:current_stock_location]
      @desired_stock_location = params[:desired_stock_location]
      @current_shipment       = params[:current_shipment]
      @desired_shipment       = params[:desired_shipment]
      @variant                = params[:variant]
      @quantity               = params[:quantity]
    end

    def run!
      return false if invalid?

      desired_shipment.save! if desired_shipment.new_record?

      available_quantity   = [desired_shipment.stock_location.count_on_hand(variant), 0].max
      new_on_hand_quantity = [available_quantity, quantity].min
      unstock_quantity     = desired_shipment.stock_location.backorderable?(variant) ? quantity : new_on_hand_quantity

      ActiveRecord::Base.transaction do
        if handle_stock_counts?
          current_on_hand_quantity = [current_shipment.inventory_units.on_hand_or_backordered.size, quantity].min

          current_stock_location.restock(variant, current_on_hand_quantity, current_shipment)
          desired_stock_location.unstock(variant, unstock_quantity, desired_shipment)
        end

        update_current_shipment_inventory_units(new_on_hand_quantity, :on_hand)
        update_current_shipment_inventory_units(quantity - new_on_hand_quantity, :backordered)
      end

      reload_shipment_inventory_units

      if current_shipment.inventory_units.length.zero?
        current_shipment.destroy!
      else
        current_shipment.refresh_rates
      end

      desired_shipment.refresh_rates

      desired_shipment.order.reload
      desired_shipment.order.update_with_updater!

      true
    end

    private

    attr_reader :variant, :quantity, :current_stock_location, :desired_stock_location,
      :current_shipment, :desired_shipment

    def update_current_shipment_inventory_units(quantity, state)
      current_shipment.
        inventory_units.
        where(variant: variant).
        order(state: :asc).
        limit(quantity).
        update_all(shipment_id: desired_shipment.id, state: state)
    end

    def reload_shipment_inventory_units
      [current_shipment, desired_shipment].each { |shipment| shipment.inventory_units.reload }
    end

    def handle_stock_counts?
      current_shipment.order.completed? && current_stock_location != desired_stock_location
    end

    def current_shipment_not_already_shipped
      return unless current_shipment.shipped?

      errors.add(:current_shipment, :has_already_been_shipped)
    end

    def enough_stock_at_desired_location
      return if Spree::Stock::Quantifier.new(variant, desired_stock_location).can_supply?(quantity)

      errors.add(:desired_shipment, :not_enough_stock_at_desired_location)
    end

    def desired_shipment_different_from_current
      return unless desired_shipment.id == current_shipment.id

      errors.add(:desired_shipment, :can_not_transfer_within_same_shipment)
    end
  end
end
