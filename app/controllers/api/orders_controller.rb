module Api
  class OrdersController < ApplicationController
  # GET /api/orders
  def index
    @orders = Order.all.order(created_at: :desc)
    render json: @orders, include: :order_items
  end

  # POST /api/orders
  def create
    # Il frontend invia un oggetto con customer, address, items (array di prodotti), total
    @order = Order.new(
      customer: order_params[:customer],
      address: order_params[:address],
      total: order_params[:total]
    )

    # Creare order items dall'array di prodotti
    if order_params[:items].present?
      order_params[:items].each do |item|
        product_id = item[:id]
        # Verifica che il prodotto esista
        unless Product.exists?(product_id)
          render json: { error: "Product #{product_id} not found" }, status: :unprocessable_entity
          return
        end

        @order.order_items.build(
          product_id: product_id,
          quantity: 1, # Il frontend invia prodotti separati per ogni quantità
          unit_price: item[:price]
        )
      end
    end

    if @order.save
      render json: @order, status: :created, include: :order_items
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(
      :total,
      customer: [:firstName, :lastName, :email],
      address: [:street, :city, :zip],
      items: [:id, :title, :price, :originalPrice, :sale, :thumbnail, :createdAt, :description, tags: []]
    )
  end
  end
end
