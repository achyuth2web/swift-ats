class GoogleAuthorizationService
  def initialize(integration)
    @integration = integration
  end

  def authorization
    credentials = Signet::OAuth2::Client.new(
      client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
      token_credential_uri: "https://oauth2.googleapis.com/token",
      access_token: @integration.access_token,
      refresh_token: @integration.refresh_token,
      expires_at: @integration.token_expires_at&.to_i
    )

    if credentials.expired?
      credentials.fetch_access_token!

      @integration.update!(
        access_token: credentials.access_token,
        token_expires_at: credentials.expires_at
      )
    end

    credentials
  end
end