require 'test_helper'

class BigbluebuttonApiControllerTest < ActionDispatch::IntegrationTest
  test 'should get all recordings' do
    get bigbluebutton_api_get_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', Recording.count
  end
end
