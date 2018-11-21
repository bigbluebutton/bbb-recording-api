require 'test_helper'

class RecordingTest < ActiveSupport::TestCase
  test '.sync_from_redis creates a recording on archive_started' do
    event = {
      header: {
        timestamp: 5161997873,
        name: "archive_started",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        record_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284",
        meeting_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
      }
    }.deep_stringify_keys

    assert_difference "Recording.count" do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_nil Recording.last.meeting_id
    assert_equal Recording.last.state, "processing"
    assert_nil Recording.last.starttime
    assert_nil Recording.last.endtime
    assert_nil Recording.last.name
    assert_nil Recording.last.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis updates an existent recording on archive_started' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: "archive_started",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference "Recording.count", 0 do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, r.record_id
    assert_equal Recording.last.meeting_id, r.meeting_id
    assert_equal Recording.last.state, "processing"
    assert_equal Recording.last.starttime, r.starttime
    assert_equal Recording.last.endtime, r.endtime
    assert_equal Recording.last.name, r.name
    assert_equal Recording.last.participants, r.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis creates a recording on archive_ended' do
    event = {
      header: {
        timestamp: 5161997873,
        name: "archive_ended",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        success: true,
        step_time: 1336,
        external_meeting_id: "Not Fred's Room",
        record_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284",
        meeting_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
      }
    }.deep_stringify_keys

    assert_difference "Recording.count" do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processing"
    assert_nil Recording.last.starttime
    assert_nil Recording.last.endtime
    assert_nil Recording.last.name
    assert_nil Recording.last.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis updates an existent recording on archive_ended' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: "archive_ended",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        success: true,
        step_time: 1336,
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference "Recording.count", 0 do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, r.record_id
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processing"
    assert_equal Recording.last.starttime, r.starttime
    assert_equal Recording.last.endtime, r.endtime
    assert_equal Recording.last.name, r.name
    assert_equal Recording.last.participants, r.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis creates a recording on sanity_started' do
    event = {
      header: {
        timestamp: 5161997873,
        name: "sanity_started",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        external_meeting_id: "Not Fred's Room",
        record_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284",
        meeting_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
      }
    }.deep_stringify_keys

    assert_difference "Recording.count" do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processing"
    assert_nil Recording.last.starttime
    assert_nil Recording.last.endtime
    assert_nil Recording.last.name
    assert_nil Recording.last.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis updates an existent recording on sanity_started' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: "sanity_started",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference "Recording.count", 0 do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, r.record_id
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processing"
    assert_equal Recording.last.starttime, r.starttime
    assert_equal Recording.last.endtime, r.endtime
    assert_equal Recording.last.name, r.name
    assert_equal Recording.last.participants, r.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis creates a recording on sanity_ended' do
    event = {
      header: {
        timestamp: 5161997873,
        name: "sanity_ended",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        success: true,
        step_time: 557,
        external_meeting_id: "Not Fred's Room",
        record_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284",
        meeting_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
      }
    }.deep_stringify_keys

    assert_difference "Recording.count" do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processing"
    assert_nil Recording.last.starttime
    assert_nil Recording.last.endtime
    assert_nil Recording.last.name
    assert_nil Recording.last.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis updates an existent recording on sanity_ended' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: "sanity_ended",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        success: true,
        step_time: 557,
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference "Recording.count", 0 do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, r.record_id
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processing"
    assert_equal Recording.last.starttime, r.starttime
    assert_equal Recording.last.endtime, r.endtime
    assert_equal Recording.last.name, r.name
    assert_equal Recording.last.participants, r.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis creates a recording on process_started' do
    event = {
      header: {
        timestamp: 5161997873,
        name: "process_started",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        workflow: "presentation",
        external_meeting_id: "Not Fred's Room",
        record_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284",
        meeting_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
      }
    }.deep_stringify_keys

    assert_difference "Recording.count" do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processing"
    assert_nil Recording.last.starttime
    assert_nil Recording.last.endtime
    assert_nil Recording.last.name
    assert_nil Recording.last.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis updates an existent recording on process_started' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: "process_started",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        workflow: "presentation",
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference "Recording.count", 0 do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, r.record_id
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processing"
    assert_equal Recording.last.starttime, r.starttime
    assert_equal Recording.last.endtime, r.endtime
    assert_equal Recording.last.name, r.name
    assert_equal Recording.last.participants, r.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis creates a recording on process_ended' do
    event = {
      header: {
        timestamp: 5161997873,
        name: "process_ended",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        workflow: "presentation",
        success: true,
        step_time: 557,
        external_meeting_id: "Not Fred's Room",
        record_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284",
        meeting_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
      }
    }.deep_stringify_keys

    assert_difference "Recording.count" do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processed"
    assert_nil Recording.last.starttime
    assert_nil Recording.last.endtime
    assert_nil Recording.last.name
    assert_nil Recording.last.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis updates an existent recording on process_ended' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: "process_ended",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        workflow: "presentation",
        success: true,
        step_time: 557,
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference "Recording.count", 0 do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, r.record_id
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processed"
    assert_equal Recording.last.starttime, r.starttime
    assert_equal Recording.last.endtime, r.endtime
    assert_equal Recording.last.name, r.name
    assert_equal Recording.last.participants, r.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis creates a recording on publish_started' do
    event = {
      header: {
        timestamp: 5161997873,
        name: "publish_started",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        workflow: "presentation",
        external_meeting_id: "Not Fred's Room",
        record_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284",
        meeting_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
      }
    }.deep_stringify_keys

    assert_difference "Recording.count" do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processed"
    assert_nil Recording.last.starttime
    assert_nil Recording.last.endtime
    assert_nil Recording.last.name
    assert_nil Recording.last.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis updates an existent recording on publish_started' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: "publish_started",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        success: true,
        step_time: 557,
        workflow: "presentation",
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference "Recording.count", 0 do
      Recording.sync_from_redis(event)
    end
    assert_equal Recording.last.record_id, r.record_id
    assert_equal Recording.last.meeting_id, "Not Fred's Room"
    assert_equal Recording.last.state, "processed"
    assert_equal Recording.last.starttime, r.starttime
    assert_equal Recording.last.endtime, r.endtime
    assert_equal Recording.last.name, r.name
    assert_equal Recording.last.participants, r.participants
    assert_not Recording.last.published
  end

  test '.sync_from_redis creates a recording on publish_ended' do
    event = {
      header: {
        timestamp: 5161997873,
        name: "publish_ended",
        current_time: 1542719593,
        version: "0.0.1"
      }, payload: {
        success: true,
        step_time: 1793,
        playback: {
          format: 'presentation',
          link: 'https://dev90.bigbluebutton.org/playback/presentation/2.0/playback.html?meetingId=a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284',
          processing_time: 5999,
          duration: 29185,
          extensions: {
            preview: {
              images: {
                image: 'https://dev90.bigbluebutton.org/presentation/a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1542719370905/thumbnails/thumb-1.png'
              }
            }
          },
          size: 321302
        }, metadata: {
          meetingName: "Certainly not Fred's Room",
          isBreakout: "false",
          meetingId: "Not Fred's Room"
        },
        raw_size: 8166022,
        start_time: 1542719370284,
        end_time: 1542719443220,
        workflow: "presentation",
        external_meeting_id: "Not Fred's Room",
        record_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284",
        meeting_id: "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
      }
    }.deep_stringify_keys

    assert_difference "Recording.count" do
      assert_difference "Metadatum.count", 3 do
        assert_difference "PlaybackFormat.count" do
          assert_difference "Thumbnail.count" do
            Recording.sync_from_redis(event)
          end
        end
      end
    end

    r = Recording.last
    assert_equal r.record_id, "a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_equal r.meeting_id, event["payload"]["external_meeting_id"]
    assert_equal r.state, "published"
    assert_equal r.starttime, Time.at(event["payload"]["start_time"]/1000)
    assert_equal r.endtime, Time.at(event["payload"]["end_time"]/1000)
    assert_equal r.name, event["payload"]["metadata"]["meetingName"]
    assert_nil r.participants
    assert r.published

    assert_equal r.metadata[0].recording, r
    assert_equal r.metadata[0].key, "meetingName"
    assert_equal r.metadata[0].value, "Certainly not Fred's Room"
    assert_equal r.metadata[1].recording, r
    assert_equal r.metadata[1].key, "isBreakout"
    assert_equal r.metadata[1].value, "false"
    assert_equal r.metadata[2].recording, r
    assert_equal r.metadata[2].key, "meetingId"
    assert_equal r.metadata[2].value, "Not Fred's Room"

    assert_equal r.playback_formats[0].recording, r
    assert_equal r.playback_formats[0].format, "presentation"
    assert_equal r.playback_formats[0].url, "/playback/presentation/2.0/playback.html?meetingId=a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284"
    assert_equal r.playback_formats[0].length, 29185
    assert_equal r.playback_formats[0].processing_time, 5999

    assert_equal r.playback_formats[0].thumbnails[0].url, "/presentation/a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1542719370905/thumbnails/thumb-1.png"
  end

  # test '.sync_from_redis updates an existent recording and all associated models on publish_ended'
end
