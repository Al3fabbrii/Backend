module Api
  class OrdersController < ApplicationController
    # GET /api/orders
    # Restituisce solo gli ordini dell'utente corrente
    # Query params:
    #   - date_from: data minima (ISO 8601)
    #   - date_to: data massima (ISO 8601)
    #   - total_min: totale minimo
    #   - total_max: totale massimo
    #   - sort: 'date_asc', 'date_desc', 'total_asc', 'total_desc' (default: 'date_desc')
    def index
      @orders = current_user.orders.includes(order_items: :product)

      # Filtro per data minima
      if params[:date_from].present?
        begin
          date_from = DateTime.parse(params[:date_from])
          @orders = @orders.where('created_at >= ?', date_from)
        rescue ArgumentError
          # Ignora se la data non è valida
        end
      end

      # Filtro per data massima
      if params[:date_to].present?
        begin
          date_to = DateTime.parse(params[:date_to])
          @orders = @orders.where('created_at <= ?', date_to)
        rescue ArgumentError
          # Ignora se la data non è valida
        end
      end

      # Filtro per totale minimo
      if params[:total_min].present?
        @orders = @orders.where('total >= ?', params[:total_min].to_f)
      end

      # Filtro per totale massimo
      if params[:total_max].present?
        @orders = @orders.where('total <= ?', params[:total_max].to_f)
      end

      # Ordinamento
      @orders = case params[:sort]
                when 'date_asc'
                  @orders.order(created_at: :asc)
                when 'total_asc'
                  @orders.order(total: :asc)
                when 'total_desc'
                  @orders.order(total: :desc)
                else # 'date_desc' o default
                  @orders.order(created_at: :desc)
                end

      render json: @orders.as_json
    end

    # POST /api/orders
    def create
      # Il frontend invia un oggetto con customer, address, items (array di prodotti), total
      @order = current_user.orders.build(
        customer: order_params[:customer],
        address: order_params[:address],
        total: order_params[:total]
      )

      # Hash per contare le quantità di ogni prodotto nell'ordine
      product_quantities = Hash.new(0)
      
      # Creare order items dall'array di prodotti
      if order_params[:items].present?
        order_params[:items].each do |item|
          product_id = item[:id]
          product_quantities[product_id] += 1
        end

        # Verifica stock disponibile per ogni prodotto prima di creare l'ordine
        product_quantities.each do |product_id, quantity|
          product = Product.find_by(id: product_id)
          
          unless product
            render json: { error: "Prodotto #{product_id} non trovato" }, status: :unprocessable_entity
            return
          end

          if product.stock < quantity
            render json: { 
              error: "Stock insufficiente per il prodotto '#{product.title}'. Disponibili: #{product.stock}, richiesti: #{quantity}" 
            }, status: :unprocessable_entity
            return
          end
        end

        # Se tutti i controlli sono passati, crea gli order items
        product_quantities.each do |product_id, quantity|
          product = Product.find(product_id)
          
          @order.order_items.build(
            product_id: product_id,
            quantity: quantity,
            unit_price: product.price
          )
        end
      end

      # Usa una transazione per garantire che tutto venga eseguito o nulla
      ActiveRecord::Base.transaction do
        if @order.save
          # Decrementa lo stock per ogni prodotto ordinato
          product_quantities.each do |product_id, quantity|
            product = Product.find(product_id)
            product.update!(stock: product.stock - quantity)
          end

          # Svuota il carrello dopo aver creato l'ordine
          cart = current_user.current_cart
          cart.cart_items.destroy_all if cart

          render json: @order.as_json, status: :created
        else
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
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
