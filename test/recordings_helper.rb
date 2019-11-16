#
# Creates a Redis event by the given name.
#
# If finished is `true`, sets the attributes `success` and `step_time` in the payload.
#
# @param [String] name Event name
# @param [Boolean] finished Indicates if the event finished or not
# @param [String] workflow Workflow name
# @param [String] record_id Record identifier
#
# @return [Hash] Redis event
#
def redis_event(name, finished: false, workflow: nil, record_id: nil)
  return redis_publish_ended_event if name == 'publish_ended'

  event = redis_event_base(name, record_id)
  if finished
    event[:payload][:success] = true
    event[:payload][:step_time] = 1336
  end
  event[:payload][:workflow] = workflow if workflow
  event.deep_stringify_keys
end

def redis_event_base(name, record_id)
  {
    header: {
      timestamp: 5161997873,
      name: name,
      current_time: 1542719593,
      version: '0.0.1'
    },
    payload:
    {
      external_meeting_id: "Not Fred's Room",
      record_id: record_id,
      meeting_id: record_id
    }
  }
end

# rubocop:disable Metrics/MethodLength
def redis_publish_ended_event
  {
    header: {
      timestamp: 5161997873,
      name: 'publish_ended',
      current_time: 1542719593,
      version: '0.0.1'
    }, payload: {
      success: true,
      step_time: 1793,
      playback: [
        {
          format: 'presentation',
          link: 'https://dev90.bigbluebutton.org/playback/presentation/2.0/playback.html?meetingId=a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284',
          processing_time: 5999,
          duration: 29185,
          extensions: {
            preview: {
              images: {
                image: [
                  'https://dev90.bigbluebutton.org/presentation/a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1542719370905/thumbnails/thumb-1.png',
                  'https://dev90.bigbluebutton.org/presentation/a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284/presentation/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1542719370905/thumbnails/thumb-2.png'
                ]
              }
            }
          },
          size: 321302
        }, {
          format: 'podcast',
          link: 'https://dev90.bigbluebutton.org/playback/podcast/2.0/playback.html?meetingId=a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284',
          processing_time: 9919,
          duration: 22999,
          extensions: {
            preview: {
              images: {
                image: 'https://dev90.bigbluebutton.org/podcast/a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284/podcast/d2d9a672040fbde2a47a10bf6c37b6a4b5ae187f-1542719370905/thumbnails/thumb-1.png'
              }
            }
          },
          size: 28892
        }
      ], metadata: {
        meetingName: "Certainly not Fred's Room",
        isBreakout: 'false',
        meetingId: "Not Fred's Room"
      },
      raw_size: 8166022,
      start_time: 1542719370284,
      end_time: 1542719443220,
      workflow: 'presentation',
      external_meeting_id: "Not Fred's Room",
      record_id: 'a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284',
      meeting_id: 'a0fcb226a234fccc45a9417f8d7c871792e25e1d-1542719370284'
    }
  }.deep_stringify_keys
end
# rubocop:enable Metrics/MethodLength
