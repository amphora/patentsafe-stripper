require File.dirname(__FILE__) + '/../test_helper'

class TestStripDocument < Test::Unit::TestCase

  def setup
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    @file = read_file("data/2009/01/02/TEST0100000002/docinfo.xml")
    @stripped = @repo.strip_content(@file)
  end


  def test_user_id_is_replaced
    assert_no_match /holmes/i, @stripped
    assert_match /#{@repo.user_map['homles']}/i, @stripped
  end

  def test_user_name_is_replaced
    assert_no_match /sherlock/i, @stripped
    assert_match /#{@repo.user_map['Sherlock Holmes']}/i, @stripped
  end

  def test_workgroup_is_replaced
    assert_no_match /irregulars/i, @stripped
  end

  def test_summary_is_replaced
    assert_match /~summary stripped by psstrip~/i, @stripped
  end

  def test_signer_is_replaced
    assert_no_match /watson/i, @stripped
    assert_match /#{@repo.user_map['watson']}/i, @stripped
  end

  def test_metadata_is_repaced
    file = Pathname.new("test/fixtures/metadata-test.xml").read
    stripped = @repo.strip_content(file)
    assert_no_match /enerfaxweb@egroups.com/i, stripped
    assert_no_match /enerfax1@bellsouth.net/i, stripped
    assert_match /~metadata stripped by psstrip~/i, stripped
  end
end