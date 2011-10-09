require File.dirname(__FILE__) + '/../test_helper'

class TestStripEvents < Test::Unit::TestCase

  def setup
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    file = read_file("/data/2009/01/02/events.txt")
    # extract rule and subs for events
    @stripped = @repo.strip_content(@repo.rules.find{|k,r,t,s|k == "events\.(txt|log)$"}[3], file)
  end


  def test_holmes_user_id_is_replaced
    assert_no_match /holmes/i, @stripped
    assert_match /#{@repo.user_id_mapping('holmes')}/i, @stripped
  end

  def test_installer_user_id_is_not_replaced
    assert_match /installer/i, @stripped
  end

end