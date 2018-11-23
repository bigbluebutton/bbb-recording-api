require 'test_helper'

class PlaybackFormatTest < ActiveSupport::TestCase
  test 'Playback formats are returned in sorted order' do
    pfs = PlaybackFormat.where(recording: recordings(:out_of_order))

    assert_equal pfs[0].format, 'a'
    assert_equal pfs[1].format, 'b'
  end
end
