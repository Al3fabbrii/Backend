module Api
  class ProductsController < ApplicationController
    # GET /api/products
    def index
      @products = Product.all.order(created_at: :desc)
      render json: @products
    end

    # GET /api/products/:id
    def show
      @product = Product.find(params[:id])
      render json: @product
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Product not found' }, status: :not_found
    end
  end
end
