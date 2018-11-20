xml.response do
  xml.returncode 'SUCCESS'
  xml.recordings do
    @recordings.each do |recording|
      xml.recording do
        xml.recordID recording.recording_id
        xml.meetingID recording.meeting_id
        xml.name recording.name
        xml.published recording.published_v2.to_s
        xml.protected recording.protected.to_s
        xml.startTime (recording.start_time.to_f * 1000).to_i
        xml.endTime (recording.end_time.to_f * 1000).to_i
        xml.participants recording.participants unless recording.participants.nil?
        xml.metadata do
          recording.metadata.each do |k, v|
            if v.blank?
              xml.tag! k do
                # For legacy reasons - some integrations require *a* node of
                # some sort inside empty meta tags
                xml.cdata! ''
              end
            else
              xml.tag! k, v
            end
          end
        end
        xml.playback do
          recording.playback_formats.each do |format|
            xml.format do
              xml.type format.format
              xml.url format.url
              xml.length format.length
            end
          end
        end
      end
    end
  end
  if @recordings.empty?
    xml.messageKey 'noRecordings'
    xml.message 'There are not recordings for the meetings'
  end
end
