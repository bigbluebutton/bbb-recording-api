xml.response do
  xml.returncode 'SUCCESS'
  xml.recordings do
    @recordings.each do |recording|
      xml.recording do
        xml.recordID recording.record_id
        xml.meetingID recording.meeting_id
        xml.name recording.name
        xml.published recording.published
        xml.state recording.state unless recording.state.nil?
        xml.startTime((recording.starttime.to_r * 1000).to_i)
        xml.endTime((recording.endtime.to_r * 1000).to_i)
        xml.participants recording.participants unless recording.participants.nil?
        xml.metadata do
          recording.metadata.each do |metadatum|
            if metadatum.value.blank?
              xml.tag! k do
                # For legacy reasons - some integrations require *a* node of
                # some sort inside empty meta tags
                xml.cdata! ''
              end
            else
              xml.tag! metadatum.key, metadatum.value
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