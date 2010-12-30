require File.dirname(__FILE__) + '/../test_helper'

class TestStripEvents < Test::Unit::TestCase

  def setup
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    @file = read_file("/data/2009/01/02/events.txt")
    @stripped = @repo.strip_content(@file)
  end


  def test_holmes_user_id_is_replaced
    assert_no_match /holmes/i, @stripped
    assert_match /#{@repo.user_map['homles']}/i, @stripped
  end

  def test_installer_user_id_is_replaced
    assert_no_match /installer/i, @stripped
    assert_match /#{@repo.user_map['installer']}/i, @stripped
  end

end