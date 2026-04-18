Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    User.find_by(id: session[:user_id]) || begin
      session[:oauth_return_to] = request.fullpath
      redirect_to root_url, alert: "ログインしてください"
    end
  end

  admin_authenticator do
    # TODO: 本番ではUser#admin?などの権限チェックを追加する
    redirect_to root_url, alert: "権限がありません" if session[:user_id].blank?
  end

  grant_flows %w[authorization_code]
  use_refresh_token

  default_scopes  :read
  optional_scopes :write
  enforce_configured_scopes

  access_token_expires_in       2.hours
  authorization_code_expires_in 10.minutes

  base_controller "ApplicationController"
end
