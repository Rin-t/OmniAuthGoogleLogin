class SessionsController < ApplicationController
  skip_forgery_protection only: :create

  def create
    omniauth_params = request.env["omniauth.params"]
    callback_state  = params[:state]

    Rails.logger.info "[OMNIAUTH] omniauth.params = #{omniauth_params.inspect}"
    Rails.logger.info "[OMNIAUTH] callback params[:state] = #{callback_state.inspect}"

    user = User.from_omniauth(request.env["omniauth.auth"])
    session[:user_id] = user.id

    flash[:debug] = {
      "omniauth.params" => omniauth_params,
      "callback state"  => callback_state
    }.to_json

    return_to = session.delete(:oauth_return_to)

    # return_toにstateがあれば OauthPendingState と照合
    if return_to.present?
      oauth_state = extract_state(return_to)
      if oauth_state.present?
        pending = OauthPendingState.find_by(state: oauth_state)

        if pending.nil?
          redirect_to(root_path, alert: "OAuth stateが見つかりません") and return
        elsif pending.expired?
          pending.destroy
          redirect_to(root_path, alert: "OAuth stateの有効期限が切れています") and return
        else
          pending.destroy
        end
      end
    end

    redirect_to(return_to || root_path, notice: "ログインしました")
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  def failure
    redirect_to root_path, alert: "ログインに失敗しました: #{params[:message]}"
  end

  def start_google
    # 自動送信フォームを描画して POST /auth/google を発火する
  end

  private

  def extract_state(url)
    uri = URI.parse(url)
    URI.decode_www_form(uri.query || "").to_h["state"]
  rescue URI::InvalidURIError
    nil
  end
end
