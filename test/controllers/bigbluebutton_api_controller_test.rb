require 'test_helper'

class BigbluebuttonApiControllerTest < ActionDispatch::IntegrationTest
  # getRecordings
  test 'with no parameters returns checksum error' do
    get bigbluebutton_api_get_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'FAILURE'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'with invalid checksum returns checksum error' do
    get bigbluebutton_api_get_recordings_url, params: "checksum=#{'x' * 40}"
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

  test 'fetches recording by meeting id' do
    r = recordings(:fred_room)
    params = encode_bbb_params('getRecordings', {meetingID: r.meeting_id}.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 1
    assert_select 'response>recordings>recording' do
      assert_select 'recordID', r.record_id
      assert_select 'meetingID', r.meeting_id
      assert_select 'name', r.name
      assert_select 'published', r.published
      assert_select 'state', r.state
      assert_select 'startTime', (r.starttime.to_r * 1000).to_i.to_s
      assert_select 'endTime', (r.endtime.to_r * 1000).to_i.to_s
      assert_select 'participants', r.participants.to_s
    end
    assert_select 'playback>format', r.playback_formats.count
  end

  test 'does case-sensitive match on recording id' do
    r = recordings(:fred_room)
    params = encode_bbb_params('getRecordings', {recordID: r.record_id.upcase}.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>messageKey', 'noRecordings'
    assert_select 'response>recordings>recording', 0
  end

  test 'does prefix match on recording id' do
    r = recordings(:fred_room)
    params = encode_bbb_params('getRecordings', {recordID: r.record_id[0, 40]}.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 1
    assert_select 'recording>recordID', r.record_id
    assert_select 'recording>meetingID', r.meeting_id
  end
end
