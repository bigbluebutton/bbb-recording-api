require 'test_helper'

class BigbluebuttonApiControllerTest < ActionDispatch::IntegrationTest
  test 'with no parameters should return checksum error' do
    get bigbluebutton_api_get_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'FAILURE'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'with only checksum returns all recordings' do
    params = encode_bbb_params('getRecordings', '')
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', Recording.count
  end
end
