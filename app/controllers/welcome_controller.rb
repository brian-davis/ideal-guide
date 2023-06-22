class WelcomeController < ApplicationController
  include Recaptchable

  def index
  end

  def new
  end

  def create
    if params[:name].present? && recaptcha_valid?
      # important business logic goes here
      flash[:notice] = "Success."
      redirect_to(root_path)
    else
      flash.now[:alert] = "There was a problem."
      render 'new', status: :unprocessable_entity
    end
  end
end
