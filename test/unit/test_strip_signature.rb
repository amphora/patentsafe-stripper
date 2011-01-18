require File.dirname(__FILE__) + '/../test_helper'

class TestStripSignature < Test::Unit::TestCase

  def setup
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    file = read_file("/data/2009/01/02/TEST0100000002/signature-001.xml")
    # extract rule and subs for sig
    @stripped = @repo.strip_content(@repo.rules.find{|k,r,t,s|k == "signature\-\d\d\d\.xml$"}[3], file)
  end


  def test_user_id_is_replaced
    assert_no_match /holmes/i, @stripped
    assert_match /#{@repo.user_map.find{|k,v| k == 'holmes' }[1]}/i, @stripped
  end

  def test_user_name_is_replaced
    assert_no_match /sherlock/i, @stripped
    assert_match /#{@repo.user_map.find{|k,v| k == 'Sherlock Holmes'}[1]}/i, @stripped
  end

end