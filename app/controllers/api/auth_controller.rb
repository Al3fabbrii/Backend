module Api
  class AuthController < ApplicationController
    skip_before_action :authenticate_user!, only: [:login, :register, :logout]

    # POST /api/auth/login
    def login
      user = User.find_by(email_address: params[:email])

      if user&.authenticate(params[:password])
        token = generate_jwt_token(user)
        render json: {
          token: token,
          user: user.as_json
        }, status: :ok
      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    end

    # POST /api/auth/logout
    def logout
      # Con JWT stateless, il logout è gestito lato client (rimuovere il token)
      head :no_content
    end

    # GET /api/auth/me
    def me
      render json: current_user.as_json
    end
    # POST /api/auth/register
    def register
      user = User.new(email_address: params[:email], password: params[:password]) 
      if user.save
        token = generate_jwt_token(user)
        render json: {
          token: token,
          user: user.as_json
        }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def generate_jwt_token(user)
      payload = {
        user_id: user.id,
        exp: 24.hours.from_now.to_i
      }
      JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
    end
  end
end
