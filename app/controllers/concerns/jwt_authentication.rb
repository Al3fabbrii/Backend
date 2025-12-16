module JwtAuthentication
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = extract_token_from_header

    if token.nil?
      render json: { error: 'Missing authentication token' }, status: :unauthorized
      return
    end

    begin
      decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
      user_id = decoded_token[0]['user_id']
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      render json: { error: 'Invalid or expired token' }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'User not found' }, status: :unauthorized
    end
  end

  def extract_token_from_header
    authorization_header = request.headers['Authorization']
    return nil unless authorization_header

    # Format: "Bearer <token>"
    authorization_header.split(' ').last if authorization_header.start_with?('Bearer ')
  end
end
