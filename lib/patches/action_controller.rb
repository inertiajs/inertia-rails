module ActionController
  module RequestForgeryProtection
    private
    def request_authenticity_tokens
      [form_authenticity_param, request.x_csrf_token, request.headers['X-XSRF-TOKEN']]
    end
  end
end