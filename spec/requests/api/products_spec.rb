require 'rails_helper'

RSpec.describe 'Api::Products', type: :request do
  # Setup: creiamo alcuni prodotti di test
  let!(:product1) do
    Product.create!(
      id: 'laptop-1',
      title: 'Laptop',
      description: 'High-performance laptop',
      price: 999.99,
      original_price: 1299.99,
      sale: true,
      stock: 10,
      tags: ['electronics', 'computers']
    )
  end

  let!(:product2) do
    Product.create!(
      id: 'mouse-1',
      title: 'Mouse',
      description: 'Wireless mouse',
      price: 29.99,
      original_price: 39.99,
      sale: false,
      stock: 50,
      tags: ['electronics', 'accessories']
    )
  end

  let!(:product3) do
    Product.create!(
      id: 'keyboard-1',
      title: 'Keyboard',
      description: 'Mechanical keyboard',
      price: 149.99,
      original_price: 179.99,
      sale: true,
      stock: 0,
      tags: ['electronics', 'accessories']
    )
  end

  describe 'GET /api/products' do
    context 'without filters' do
      it 'returns all products' do
        get '/api/products'
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end

      it 'returns products in descending order by creation date (default)' do
        get '/api/products'
        
        json_response = JSON.parse(response.body)
        # L'ultimo creato dovrebbe essere primo
        expect(json_response.first['title']).to eq('Keyboard')
        expect(json_response.last['title']).to eq('Laptop')
      end
    end

    context 'with search filter' do
      it 'filters products by title (case-insensitive)' do
        get '/api/products', params: { search: 'laptop' }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq('Laptop')
      end

      it 'returns multiple matches' do
        get '/api/products', params: { search: 'o' } # matches Mouse and Keyboard
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to be >= 2
        titles = json_response.map { |p| p['title'] }
        expect(titles).to include('Mouse', 'Keyboard')
      end

      it 'returns empty array when no matches' do
        get '/api/products', params: { search: 'NonexistentProduct' }
        
        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end
    end

    context 'with price filters' do
      it 'filters by minimum price' do
        get '/api/products', params: { price_min: 100 }
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(2)
        json_response.each do |product|
          expect(product['price']).to be >= 100
        end
      end

      it 'filters by maximum price' do
        get '/api/products', params: { price_max: 100 }
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq('Mouse')
      end

      it 'filters by price range' do
        get '/api/products', params: { price_min: 50, price_max: 500 }
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq('Keyboard')
        expect(json_response.first['price']).to be_between(50, 500)
      end
    end

    context 'with sorting' do
      it 'sorts by price ascending' do
        get '/api/products', params: { sort: 'price_asc' }
        
        json_response = JSON.parse(response.body)
        expect(json_response.first['title']).to eq('Mouse')
        expect(json_response.last['title']).to eq('Laptop')
        
        # Verifica che i prezzi siano in ordine crescente
        prices = json_response.map { |p| p['price'] }
        expect(prices).to eq(prices.sort)
      end

      it 'sorts by price descending' do
        get '/api/products', params: { sort: 'price_desc' }
        
        json_response = JSON.parse(response.body)
        expect(json_response.first['title']).to eq('Laptop')
        expect(json_response.last['title']).to eq('Mouse')
        
        # Verifica che i prezzi siano in ordine decrescente
        prices = json_response.map { |p| p['price'] }
        expect(prices).to eq(prices.sort.reverse)
      end

      it 'sorts by date ascending' do
        get '/api/products', params: { sort: 'date_asc' }
        
        json_response = JSON.parse(response.body)
        expect(json_response.first['title']).to eq('Laptop')
        expect(json_response.last['title']).to eq('Keyboard')
      end

      it 'sorts by date descending (explicit)' do
        get '/api/products', params: { sort: 'date_desc' }
        
        json_response = JSON.parse(response.body)
        expect(json_response.first['title']).to eq('Keyboard')
        expect(json_response.last['title']).to eq('Laptop')
      end
    end

    context 'with combined filters' do
      it 'combines search and price filters' do
        get '/api/products', params: { search: 'e', price_min: 100 }
        
        json_response = JSON.parse(response.body)
        json_response.each do |product|
          expect(product['title'].downcase).to include('e')
          expect(product['price']).to be >= 100
        end
      end

      it 'combines all filters and sorting' do
        get '/api/products', params: { 
          search: 'o',
          price_max: 200,
          sort: 'price_asc'
        }
        
        json_response = JSON.parse(response.body)
        expect(json_response).not_to be_empty
        
        # Verifica che tutti i prodotti soddisfino i criteri
        json_response.each do |product|
          expect(product['title'].downcase).to include('o')
          expect(product['price']).to be <= 200
        end
        
        # Verifica l'ordinamento
        prices = json_response.map { |p| p['price'] }
        expect(prices).to eq(prices.sort)
      end
    end
  end

  describe 'GET /api/products/:id' do
    context 'when the product exists' do
      it 'returns the product' do
        get "/api/products/#{product1.id}"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(product1.id)
        expect(json_response['title']).to eq('Laptop')
      end

      it 'returns product with camelCase attributes' do
        get "/api/products/#{product1.id}"
        
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('originalPrice')
        expect(json_response).to have_key('createdAt')
        expect(json_response['originalPrice']).to eq(1299.99)
      end
    end

    context 'when the product does not exist' do
      it 'returns a not found error' do
        get '/api/products/99999'
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Product not found')
      end
    end
  end

  describe 'JSON response format' do
    it 'returns products with correct camelCase format' do
      get '/api/products'
      
      json_response = JSON.parse(response.body)
      product = json_response.first
      
      expect(product).to have_key('id')
      expect(product).to have_key('title')
      expect(product).to have_key('description')
      expect(product).to have_key('price')
      expect(product).to have_key('originalPrice')
      expect(product).to have_key('sale')
      expect(product).to have_key('thumbnail')
      expect(product).to have_key('tags')
      expect(product).to have_key('stock')
      expect(product).to have_key('createdAt')
    end

    it 'does not require authentication' do
      # Questo test verifica che il controller salta l'autenticazione
      get '/api/products'
      
      expect(response).to have_http_status(:success)
      # Non dovrebbe richiedere autenticazione
    end
  end
end
