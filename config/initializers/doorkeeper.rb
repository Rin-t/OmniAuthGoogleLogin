Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    if params[:prompt] == "login"
      # prompt=loginを外したURLに戻るようにしてから session をクリア（ループ防止）
      uri = URI.parse(request.fullpath)
      query = URI.decode_www_form(uri.query || "").reject { |k, _| k == "prompt" }
      uri.query = query.empty? ? nil : URI.encode_www_form(query)
      return_to = uri.to_s

      # state / redirect_uri をDB保存（callback時にSessionsControllerで検証）
      if params[:state].present? && params[:redirect_uri].present?
        OauthPendingState.create!(
          state: params[:state],
          redirect_uri: params[:redirect_uri],
          expires_at: 5.minutes.from_now
        )
      end

      reset_session
      session[:oauth_return_to] = return_to
      redirect_to "/auth/google/start"
      nil
    else
      User.find_by(id: session[:user_id]) || begin
        session[:oauth_return_to] = request.fullpath
        redirect_to root_url, alert: "ログインしてください"
        nil
      end
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

  # ファーストパーティのconfidentialクライアントは認可画面をスキップ
  skip_authorization do |_resource_owner, client|
    client.application.confidential?
  end

  base_controller "ApplicationController"
end
