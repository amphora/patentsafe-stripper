require File.dirname(__FILE__) + '/../test_helper'

class TestStripIdentity < Test::Unit::TestCase

  def setup
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    @file = read_file("/data/2009/01/02/TEST0100000001/docinfo.xml")
    @stripped = @repo.strip_content(@file)
  end


  def test_user_id_is_replaced
    assert_no_match /holmes/i, @stripped
    assert_match /#{@repo.users['homles']}/i, @stripped
  end

  def test_user_name_is_replaced
    assert_no_match /sherlock/i, @stripped
    assert_match /#{@repo.users['Sherlock Holmes']}/i, @stripped
  end

end