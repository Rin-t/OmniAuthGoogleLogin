class SessionsController < ApplicationController
  skip_forgery_protection only: :create

  def create
    user = User.from_omniauth(request.env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to(session.delete(:oauth_return_to) || root_path, notice: "ログインしました")
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  def failure
    redirect_to root_path, alert: "ログインに失敗しました: #{params[:message]}"
  end
end
