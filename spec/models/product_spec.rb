require 'rails_helper'

RSpec.describe Product, type: :model do
  # Test delle associazioni
  describe 'associations' do
    it 'has many order_items' do
      expect(Product.reflect_on_association(:order_items).macro).to eq(:has_many)
    end

    it 'has many orders through order_items' do
      expect(Product.reflect_on_association(:orders).macro).to eq(:has_many)
      expect(Product.reflect_on_association(:orders).options[:through]).to eq(:order_items)
    end

    it 'destroys dependent order_items when destroyed' do
      expect(Product.reflect_on_association(:order_items).options[:dependent]).to eq(:destroy)
    end
  end

  # Test delle validazioni
  describe 'validations' do
    context 'title validation' do
      it 'is valid with a title' do
        product = Product.new(
          title: 'Test Product',
          price: 10.0,
          original_price: 15.0,
          stock: 5
        )
        expect(product).to be_valid
      end

      it 'is invalid without a title' do
        product = Product.new(
          title: nil,
          price: 10.0,
          original_price: 15.0,
          stock: 5
        )
        expect(product).not_to be_valid
        expect(product.errors[:title]).to include("can't be blank")
      end
    end

    context 'price validation' do
      it 'is valid with a positive price' do
        product = Product.new(
          title: 'Test Product',
          price: 10.0,
          original_price: 15.0,
          stock: 5
        )
        expect(product).to be_valid
      end

      it 'is invalid without a price' do
        product = Product.new(
          title: 'Test Product',
          price: nil,
          original_price: 15.0,
          stock: 5
        )
        expect(product).not_to be_valid
        expect(product.errors[:price]).to include("can't be blank")
      end

      it 'is invalid with a zero or negative price' do
        product = Product.new(
          title: 'Test Product',
          price: 0,
          original_price: 15.0,
          stock: 5
        )
        expect(product).not_to be_valid
        expect(product.errors[:price]).to include('must be greater than 0')
      end
    end

    context 'original_price validation' do
      it 'is valid with a positive original_price' do
        product = Product.new(
          title: 'Test Product',
          price: 10.0,
          original_price: 15.0,
          stock: 5
        )
        expect(product).to be_valid
      end

      it 'is invalid without an original_price' do
        product = Product.new(
          title: 'Test Product',
          price: 10.0,
          original_price: nil,
          stock: 5
        )
        expect(product).not_to be_valid
        expect(product.errors[:original_price]).to include("can't be blank")
      end

      it 'is invalid with a zero or negative original_price' do
        product = Product.new(
          title: 'Test Product',
          price: 10.0,
          original_price: -5.0,
          stock: 5
        )
        expect(product).not_to be_valid
        expect(product.errors[:original_price]).to include('must be greater than 0')
      end
    end

    context 'stock validation' do
      it 'is valid with zero stock' do
        product = Product.new(
          title: 'Test Product',
          price: 10.0,
          original_price: 15.0,
          stock: 0
        )
        expect(product).to be_valid
      end

      it 'is invalid without stock' do
        product = Product.new(
          title: 'Test Product',
          price: 10.0,
          original_price: 15.0,
          stock: nil
        )
        expect(product).not_to be_valid
        expect(product.errors[:stock]).to include("can't be blank")
      end

      it 'is invalid with negative stock' do
        product = Product.new(
          title: 'Test Product',
          price: 10.0,
          original_price: 15.0,
          stock: -1
        )
        expect(product).not_to be_valid
        expect(product.errors[:stock]).to include('must be greater than or equal to 0')
      end
    end
  end

  # Test del metodo as_json
  describe '#as_json' do
    let(:product) do
      Product.create!(
        id: 'test-product-1',
        title: 'Test Product',
        description: 'A test product',
        price: 10.99,
        original_price: 15.99,
        sale: true,
        thumbnail: 'http://example.com/image.jpg',
        tags: ['electronics', 'sale'],
        stock: 10
      )
    end

    it 'returns a hash with camelCase keys' do
      json = product.as_json
      expect(json).to include(
        :id,
        :title,
        :description,
        :price,
        :originalPrice,
        :sale,
        :thumbnail,
        :tags,
        :stock,
        :createdAt
      )
    end

    it 'converts prices to floats' do
      json = product.as_json
      expect(json[:price]).to eq(10.99)
      expect(json[:originalPrice]).to eq(15.99)
      expect(json[:price]).to be_a(Float)
      expect(json[:originalPrice]).to be_a(Float)
    end

    it 'formats created_at as ISO8601' do
      json = product.as_json
      expect(json[:createdAt]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it 'includes all product attributes' do
      json = product.as_json
      expect(json[:title]).to eq('Test Product')
      expect(json[:description]).to eq('A test product')
      expect(json[:sale]).to be true
      expect(json[:thumbnail]).to eq('http://example.com/image.jpg')
      expect(json[:tags]).to eq(['electronics', 'sale'])
      expect(json[:stock]).to eq(10)
    end
  end

  # Test delle relazioni con order_items
  describe 'order_items relationship' do
    it 'destroys associated order_items when product is destroyed' do
      product = Product.create!(
        id: 'test-product-2',
        title: 'Test Product',
        price: 10.0,
        original_price: 15.0,
        stock: 5
      )
      
      user = User.create!(email_address: 'test@example.com', password: 'password123')
      order = Order.create!(
        user: user,
        total: 10.0,
        customer: { name: 'Test User', email: 'test@example.com' },
        address: { street: '123 Test St', city: 'Test City' }
      )
      order_item = OrderItem.create!(order: order, product: product, quantity: 1, unit_price: 10.0)
      
      expect { product.destroy }.to change { OrderItem.count }.by(-1)
    end
  end
end
