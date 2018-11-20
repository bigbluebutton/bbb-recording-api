require 'test_helper'

class BigbluebuttonApiControllerTest < ActionDispatch::IntegrationTest
  test "should get get_recordings" do
    get bigbluebutton_api_get_recordings_url
    assert_response :success
  end
end
