require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/identity/v2/public/list_tenants' do

    def create_request(session_data = get_session_data, &block)
      klass.new(session_data, &block)
    end


    def get_session_data
      session.send :auth_info
    end


    def helper
      Aviator::Test::RequestHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'identity', 'v2', 'public', 'list_tenants.rb')
    end


    def session
      unless @session
        @session = Aviator::Session.new(
          config_file: Environment.path,
          environment: 'openstack_admin'
        )
        @session.authenticate
      end

      @session
    end


    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v2
    end


    validate_attr :body do
      klass.body?.must_equal false
      create_request.body?.must_equal false
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :public
    end


    validate_attr :headers do
      session_data = get_session_data

      headers = { 'X-Auth-Token' => session_data[:access][:token][:id] }

      request = create_request(session_data)

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :get
    end


    validate_attr :url do
      session_data = get_session_data
      service_spec = session_data[:access][:serviceCatalog].find{|s| s[:type] == 'identity' }
      url          = "#{ service_spec[:endpoints][0][:publicURL] }/tenants"
      request      = klass.new(session_data)

      request.url.must_equal url
    end


    validate_response 'no parameters are provided' do
      service = session.identity_service

      response = service.request :list_tenants

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:tenants].length.wont_equal 0
      response.headers.wont_be_nil
    end


    validate_response 'session is using a default token' do
      s = Aviator::Session.new(
          config_file: Environment.path,
          environment: 'openstack_admin'
        )

      s.authenticate do |creds|
        creds.username = Environment.openstack_member[:auth_credentials][:username]
        creds.password = Environment.openstack_member[:auth_credentials][:password]
      end

      response = s.identity_service.request :list_tenants
      
      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:tenants].length.wont_equal 0
      response.headers.wont_be_nil
    end


  end

end
