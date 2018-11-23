require 'test_helper'

class BigbluebuttonApiControllerTest < ActionDispatch::IntegrationTest
  # getRecordings
  test 'getRecordings with no parameters returns checksum error' do
    get bigbluebutton_api_get_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'FAILURE'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'getRecordings with invalid checksum returns checksum error' do
    get bigbluebutton_api_get_recordings_url, params: "checksum=#{'x' * 40}"
    assert_response :success
    assert_select 'response>returncode', 'FAILURE'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'getRecordings with only checksum returns all recordings' do
    params = encode_bbb_params('getRecordings', '')
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', Recording.count
  end

  test 'getRecordings fetches recording by meeting id' do
    r = recordings(:fred_room)
    params = encode_bbb_params('getRecordings', { meetingID: r.meeting_id }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    url_prefix = "#{@request.protocol}#{@request.host}"
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 1
    assert_select 'response>recordings>recording' do |rec_el|
      assert_select rec_el, 'recordID', r.record_id
      assert_select rec_el, 'meetingID', r.meeting_id
      assert_select rec_el, 'internalMeetingID', r.record_id
      assert_select rec_el, 'name', r.name
      assert_select rec_el, 'published', r.published
      assert_select rec_el, 'state', r.state
      assert_select rec_el, 'startTime', (r.starttime.to_r * 1000).to_i.to_s
      assert_select rec_el, 'endTime', (r.endtime.to_r * 1000).to_i.to_s
      assert_select rec_el, 'participants', r.participants.to_s

      assert_select rec_el, 'playback>format', r.playback_formats.count
      assert_select rec_el, 'playback>format' do |format_els|
        format_els.each do |format_el|
          format_type = css_select format_el, 'type'
          pf = nil
          case format_type.first.content
          when 'podcast' then pf = playback_formats(:fred_room_podcast)
          when 'presentation' then pf = playback_formats(:fred_room_presentation)
          else flunk("Unexpected playback format: #{format_type.first.content}")
          end

          assert_select format_el, 'type', pf.format
          assert_select format_el, 'url', "#{url_prefix}#{pf.url}"
          assert_select format_el, 'length', pf.length.to_s
          assert_select format_el, 'processingTime', pf.processing_time.to_s

          imgs = css_select format_el, 'preview>images>image'
          assert_equal imgs.length, pf.thumbnails.count
          imgs.each_with_index do |img, i|
            t = thumbnails("fred_room_#{pf.format}_thumb#{i+1}")
            img = imgs[i]
            assert_equal img['alt'], t.alt
            assert_equal img['height'], t.height.to_s
            assert_equal img['width'], t.width.to_s
            assert_equal img.content, "#{url_prefix}#{t.url}"
          end
        end
      end
    end
  end

  test 'getRecordings allows multiple comma-separated meeting IDs' do
    r1 = recordings(:fred_room)
    r2 = recordings(:published_false)

    params = encode_bbb_params('getRecordings', {
      meetingID: [r1.meeting_id, r2.meeting_id].join(',')
    }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 2
  end

  test 'getRecordings does case-sensitive match on recording id' do
    r = recordings(:fred_room)
    params = encode_bbb_params('getRecordings', { recordID: r.record_id.upcase }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>messageKey', 'noRecordings'
    assert_select 'response>recordings>recording', 0
  end

  test 'getRecordings does prefix match on recording id' do
    r = recordings(:bulk_room1)
    params = encode_bbb_params('getRecordings', { recordID: r.record_id[0, 40] }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 20
    assert_select 'recording>meetingID', r.meeting_id
  end

  test 'getRecordings allows multiple comma-separated recording IDs' do
    r1 = recordings(:fred_room)
    r2 = recordings(:published_false)

    params = encode_bbb_params('getRecordings', {
      recordID: [r1.record_id, r2.record_id].join(',')
    }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 2
  end

  # publishRecordings
  test 'publishRecordings with no parameters returns checksum error' do
    get bigbluebutton_api_publish_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'FAILURE'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'publishRecordings with invalid checksum returns checksum error' do
    get bigbluebutton_api_publish_recordings_url, params: "checksum=#{'x' * 40}"
    assert_response :success
    assert_select 'response>returncode', 'FAILURE'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'publishRecordings requires recordID parameter' do
    params = encode_bbb_params('publishRecordings', { publish: 'true' }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILURE'
    assert_select 'response>messageKey', 'missingParamRecordID'
  end

  test 'publishRecordings requires publish parameter' do
    params = encode_bbb_params('publishRecordings', { recordID: recordings(:fred_room).record_id }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILURE'
    assert_select 'response>messageKey', 'missingParamPublish'
  end

  test 'publishRecordings updates published property to false' do
    r = recordings(:fred_room)
    assert_equal r.published, true

    params = encode_bbb_params('publishRecordings', { recordID: r.record_id, publish: 'false' }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>published', 'false'

    r.reload
    assert_equal r.published, false
  end

  test 'publishRecordings updates published property to true' do
    r = recordings(:published_false)
    assert_equal r.published, false

    params = encode_bbb_params('publishRecordings', { recordID: r.record_id, publish: 'true' }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>published', 'true'

    r.reload
    assert_equal r.published, true
  end
end
