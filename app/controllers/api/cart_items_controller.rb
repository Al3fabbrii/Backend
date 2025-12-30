module Api
  class CartItemsController < ApplicationController
    before_action :set_cart
    before_action :set_cart_item, only: [:update, :destroy]

    # POST /api/cart/items
    def create
      product = Product.find(params[:product_id])
      requested_quantity = (params[:quantity] || 1).to_i

      # Cerca se il prodotto è già nel carrello
      cart_item = @cart.cart_items.find_by(item_id: product.id)

      # Calcola la quantità totale che verrebbe aggiunta
      total_quantity = cart_item ? cart_item.quantity + requested_quantity : requested_quantity

      # Verifica che ci sia stock sufficiente
      if product.stock < total_quantity
        render json: { error: "Stock insufficiente. Disponibili: #{product.stock}, richiesti: #{total_quantity}" }, status: :unprocessable_entity
        return
      end

      if cart_item
        # Incrementa quantità
        cart_item.quantity += requested_quantity
        cart_item.save!
      else
        # Crea nuovo item
        cart_item = @cart.cart_items.create!(
          item_id: product.id,
          quantity: requested_quantity,
          unit_price: product.price
        )
      end

      render json: @cart.as_json, status: :created
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Product not found' }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    # PATCH /api/cart/items/:id
    def update
      new_quantity = params[:quantity].to_i
      product = Product.find(@cart_item.item_id)

      # Verifica che ci sia stock sufficiente
      if product.stock < new_quantity
        render json: { error: "Stock insufficiente. Disponibili: #{product.stock}, richiesti: #{new_quantity}" }, status: :unprocessable_entity
        return
      end

      @cart_item.update!(quantity: new_quantity)
      render json: @cart.as_json
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    # DELETE /api/cart/items/:id
    def destroy
      @cart_item.destroy!
      render json: @cart.as_json
    end

    private

    def set_cart
      @cart = current_user.current_cart
    end

    def set_cart_item
      @cart_item = @cart.cart_items.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Cart item not found' }, status: :not_found
    end
  end
end
