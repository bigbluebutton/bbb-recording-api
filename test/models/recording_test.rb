require 'test_helper'
require 'recordings_helper'


class RecordingTest < ActiveSupport::TestCase

  setup do
    @record_id = 'a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284'
  end

  context '#sync_from_redis' do
    setup do
      @all_event_names = %w[
        archive_started
        archive_ended
        sanity_started
        sanity_ended
        process_started
        process_ended
        publish_started
        publish_ended
      ]
    end

    context 'with any recording event' do
      should 'create a recording if not existant' do
        @all_event_names.each_with_index do |event_name, index|
          event = redis_event(event_name, record_id: "#{@record_id}#{index}")

          assert_difference 'Recording.count' do
            Recording.sync_from_redis(event)
          end
        end
      end

      should 'return the created recording' do
        @all_event_names.each_with_index do |event_name, index|
          event = redis_event(event_name, record_id: "#{@record_id}#{index}")
          recording = Recording.sync_from_redis(event)
          assert_instance_of Recording, recording
        end
      end

      should 'set the recording as published when "published" included in the payload' do
        @all_event_names.each_with_index do |event_name, index|
          event = redis_event(event_name, record_id: "#{@record_id}#{index}")
          event['payload']['published'] = 'true'
          recording = Recording.sync_from_redis(event)
          assert_equal true, recording.published
        end
      end

      should 'sync metadata when metadata is included in the payload' do
        @all_event_names.each_with_index do |event_name, index|
          event = redis_event(event_name, record_id: "#{@record_id}#{index}")
          event['payload']['metadata'] = {}
          mock = MiniTest::Mock.new
          mock.expect(:call, nil, [String, Hash])
          Metadatum.stub :upsert_by_record_id, mock do
            Recording.sync_from_redis(event.deep_stringify_keys)
          end
          assert mock.verify
        end
      end

      should 'save the recording name when meetingName included in metadata' do
        @all_event_names.each_with_index do |event_name, index|
          event = redis_event(event_name, record_id: "#{@record_id}#{index}")
          meeting_name = 'This is a meeting name'
          event['payload']['metadata'] = { 'meetingName': meeting_name }
          recording = Recording.sync_from_redis(event.deep_stringify_keys)
          assert_equal meeting_name, recording.name
        end
      end

    end

    context 'with events from unpublished recording' do
      setup do
        # All events but 'publish_ended' are from unpublished recordings.
        @unpublished_recording_event_names = @all_event_names - ['publish_ended']
      end

      should 'save the recording basic information' do
        @unpublished_recording_event_names.each_with_index do |event_name, index|
          event = redis_event(event_name, record_id: "#{@record_id}#{index}")
          recording = Recording.sync_from_redis(event)

          assert_equal "Not Fred's Room", recording.meeting_id
          assert_nil recording.name
          assert_nil recording.starttime
          assert_nil recording.endtime
          assert_nil recording.participants
        end
      end

      should 'not save the recording as published' do
        @unpublished_recording_event_names.each_with_index do |event_name, index|
          event = redis_event(event_name, record_id: "#{@record_id}#{index}")
          recording = Recording.sync_from_redis(event)

          assert_not recording.published
        end
      end

      context 'with events from a processing recording but not yet processed' do
        setup do
          @event_names = %w[
            archive_started
            archive_ended
            sanity_started
            sanity_ended
            process_started
          ]
        end

        should 'set the recording state as "processing"' do
          @event_names.each_with_index do |event_name, index|
            event = redis_event(event_name, record_id: "#{@record_id}#{index}")
            recording = Recording.sync_from_redis(event)
            assert_equal 'processing', recording.state
          end
        end

        should 'not set the recording as published' do
          @event_names.each_with_index do |event_name, index|
            event = redis_event(event_name, record_id: "#{@record_id}#{index}")
            recording = Recording.sync_from_redis(event)
            assert_not recording.published
          end
        end
      end

      context 'with events from a processed recording but not yet published' do
        setup do
          @event_names = ['process_ended', 'publish_started']
        end

        should 'set the recording state as "processed"' do
          @event_names.each_with_index do |event_name, index|
            event = redis_event(event_name, record_id: "#{@record_id}#{index}")
            recording = Recording.sync_from_redis(event)
            assert_equal 'processed', recording.state
          end
        end

        should 'not set the recording as published' do
          @event_names.each_with_index do |event_name, index|
            event = redis_event(event_name, record_id: "#{@record_id}#{index}")
            recording = Recording.sync_from_redis(event)
            assert_not recording.published
          end
        end
      end

    end

    context 'with events from published recording' do
      setup do
        # The only event from a published recording is 'publish_ended'
        @event = redis_event('publish_ended')
      end

      should 'set the recording as published' do
        recording = Recording.sync_from_redis(@event)
        assert recording.published
        assert 'published', recording.published
      end

      should 'save the start and the end time of the recording' do
        expected_start_time = Time.at(Rational(@event['payload']['start_time'], 1000)).utc
        expected_end_time = Time.at(Rational(@event['payload']['end_time'], 1000)).utc
        recording = Recording.sync_from_redis(@event)
        assert_equal expected_start_time, recording.starttime
        assert_equal expected_end_time, recording.endtime
      end

      should 'save the recording number of participants' do
        @event['payload']['participants'] = 4
        recording = Recording.sync_from_redis(@event.deep_stringify_keys)
        assert_equal 4, recording.participants
      end
    end
  end

  #
  # Updates a recording because of an event
  #
  test '.sync_from_redis updates an existent recording on archive_started' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: 'archive_started',
        current_time: 1542719593,
        version: '0.0.1'
      }, payload: {
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference 'Recording.count', 0 do
      Recording.sync_from_redis(event)
    end
    target = Recording.find_by(record_id: r.record_id)
    assert_not_nil target
    assert_equal target.meeting_id, r.meeting_id
    assert_equal target.state, 'processing'
    assert_equal target.starttime, r.starttime
    assert_equal target.endtime, r.endtime
    assert_equal target.name, r.name
    assert_equal target.participants, r.participants
    assert_not target.published
  end

  test '.sync_from_redis updates an existent recording on archive_ended' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: 'archive_ended',
        current_time: 1542719593,
        version: '0.0.1'
      }, payload: {
        success: true,
        step_time: 1336,
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference 'Recording.count', 0 do
      Recording.sync_from_redis(event)
    end
    target = Recording.find_by(record_id: r.record_id)
    assert_not_nil target
    assert_equal target.meeting_id, "Not Fred's Room"
    assert_equal target.state, 'processing'
    assert_equal target.starttime, r.starttime
    assert_equal target.endtime, r.endtime
    assert_equal target.name, r.name
    assert_equal target.participants, r.participants
    assert_not target.published
  end

  test '.sync_from_redis updates an existent recording on sanity_started' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: 'sanity_started',
        current_time: 1542719593,
        version: '0.0.1'
      }, payload: {
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference 'Recording.count', 0 do
      Recording.sync_from_redis(event)
    end
    target = Recording.find_by(record_id: r.record_id)
    assert_not_nil target
    assert_equal target.meeting_id, "Not Fred's Room"
    assert_equal target.state, 'processing'
    assert_equal target.starttime, r.starttime
    assert_equal target.endtime, r.endtime
    assert_equal target.name, r.name
    assert_equal target.participants, r.participants
    assert_not target.published
  end

  test '.sync_from_redis updates an existent recording on sanity_ended' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: 'sanity_ended',
        current_time: 1542719593,
        version: '0.0.1'
      }, payload: {
        success: true,
        step_time: 557,
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference 'Recording.count', 0 do
      Recording.sync_from_redis(event)
    end
    target = Recording.find_by(record_id: r.record_id)
    assert_not_nil target
    assert_equal target.meeting_id, "Not Fred's Room"
    assert_equal target.state, 'processing'
    assert_equal target.starttime, r.starttime
    assert_equal target.endtime, r.endtime
    assert_equal target.name, r.name
    assert_equal target.participants, r.participants
    assert_not target.published
  end

  test '.sync_from_redis updates an existent recording on process_started' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: 'process_started',
        current_time: 1542719593,
        version: '0.0.1'
      }, payload: {
        workflow: 'presentation',
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference 'Recording.count', 0 do
      Recording.sync_from_redis(event)
    end
    target = Recording.find_by(record_id: r.record_id)
    assert_not_nil target
    assert_equal target.meeting_id, "Not Fred's Room"
    assert_equal target.state, 'processing'
    assert_equal target.starttime, r.starttime
    assert_equal target.endtime, r.endtime
    assert_equal target.name, r.name
    assert_equal target.participants, r.participants
    assert_not target.published
  end

  test '.sync_from_redis updates an existent recording on process_ended' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: 'process_ended',
        current_time: 1542719593,
        version: '0.0.1'
      }, payload: {
        workflow: 'presentation',
        success: true,
        step_time: 557,
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference 'Recording.count', 0 do
      Recording.sync_from_redis(event)
    end
    target = Recording.find_by(record_id: r.record_id)
    assert_not_nil target
    assert_equal target.meeting_id, "Not Fred's Room"
    assert_equal target.state, 'processed'
    assert_equal target.starttime, r.starttime
    assert_equal target.endtime, r.endtime
    assert_equal target.name, r.name
    assert_equal target.participants, r.participants
    assert_not target.published
  end

  test '.sync_from_redis updates an existent recording on publish_started' do
    r = recordings(:fred_room)
    event = {
      header: {
        timestamp: 5161997873,
        name: 'publish_started',
        current_time: 1542719593,
        version: '0.0.1'
      }, payload: {
        success: true,
        step_time: 557,
        workflow: 'presentation',
        external_meeting_id: "Not Fred's Room",
        record_id: r.record_id,
        meeting_id: r.record_id
      }
    }.deep_stringify_keys

    assert_difference 'Recording.count', 0 do
      Recording.sync_from_redis(event)
    end
    target = Recording.find_by(record_id: r.record_id)
    assert_not_nil target
    assert_equal target.meeting_id, "Not Fred's Room"
    assert_equal target.state, 'processed'
    assert_equal target.starttime, r.starttime
    assert_equal target.endtime, r.endtime
    assert_equal target.name, r.name
    assert_equal target.participants, r.participants
    assert_not target.published
  end

  test '.sync_from_redis creates a recording on publish_ended' do
    event = redis_publish_ended_event

    assert_difference 'Recording.count' do
      assert_difference 'Metadatum.count', 3 do
        assert_difference 'PlaybackFormat.count', 2 do
          assert_difference 'Thumbnail.count', 3 do
            Recording.sync_from_redis(event)
          end
        end
      end
    end

    target = Recording.find_by(record_id: 'a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284')
    assert_not_nil target
    assert_equal event['payload']['external_meeting_id'], target.meeting_id
    assert_equal target.state, 'published'
    assert_equal target.starttime, Time.at(Rational(event['payload']['start_time'], 1000)).utc
    assert_equal target.endtime, Time.at(Rational(event['payload']['end_time'], 1000)).utc
    assert_equal event['payload']['metadata']['meetingName'], target.name
    assert_nil target.participants
    assert target.published

    meta = target.metadata.find_by(key: 'meetingName')
    assert_not_nil meta
    assert_equal meta.value, "Certainly not Fred's Room"
    meta = target.metadata.find_by(key: 'isBreakout')
    assert_not_nil meta
    assert_equal meta.value, 'false'
    meta = target.metadata.find_by(key: 'meetingId')
    assert_not_nil meta
    assert_equal meta.value, "Not Fred's Room"

    pf = target.playback_formats.find_by(format: 'presentation')
    assert_not_nil pf
    assert_equal pf.url, '/playback/presentation/2.0/playback.html?meetingId=a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284'
    assert_equal pf.length, 29185
    assert_equal pf.processing_time, 5999
    assert_equal pf.thumbnails.count, 2

    thumbnail_url = '/presentation/a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284'\
                    '/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1542719370905'\
                    '/thumbnails/thumb-1.png'
    assert_not_nil pf.thumbnails.find_by(url: thumbnail_url)

    thumbnail_url = '/presentation/a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284'\
                    '/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1542719370905'\
                    '/thumbnails/thumb-2.png'
    assert_not_nil pf.thumbnails.find_by(url: thumbnail_url)

    pf = target.playback_formats.find_by(format: 'podcast')
    assert_not_nil pf
    assert_equal pf.url, '/playback/podcast/2.0/playback.html?meetingId=a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284'
    assert_equal pf.length, 22999
    assert_equal pf.processing_time, 9919
    assert_equal pf.thumbnails.count, 1

    thumbnail_url = '/podcast/a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284'\
                    '/podcast/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1542719370905'\
                    '/thumbnails/thumb-1.png'
    assert_not_nil pf.thumbnails.find_by(url: thumbnail_url)
  end

  # test '.sync_from_redis updates an existent recording and all associated models on publish_ended'
end
