require File.dirname(__FILE__) + '/../test_helper'

class TestStripDocument < Test::Unit::TestCase

  def setup
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    file = read_file("/data/2009/01/02/TEST0100000002/docinfo.xml")
    # extract rule and subs for doc
    @docinfo_subs = @repo.rules.find{|k,r,t,s| k == "docinfo\.xml$" }[3]
    @stripped = @repo.strip_content(@docinfo_subs, file)
  end


  def test_user_id_is_replaced
    assert_no_match /holmes/i, @stripped
    assert_match /#{@repo.user_id_mapping('holmes')}/i, @stripped
  end

  def test_user_name_is_replaced
    assert_no_match /sherlock/i, @stripped
    assert_match /#{@repo.user_name_mapping('Sherlock Holmes')}/i, @stripped
  end

  def test_workgroup_is_replaced
    assert_no_match /irregulars/i, @stripped
  end

  def test_summary_is_replaced
    assert_match /~summary stripped by psstrip~/i, @stripped
  end

  def test_signer_is_replaced
    assert_no_match /watson/i, @stripped
    assert_match /#{@repo.user_id_mapping('watson')}/i, @stripped
  end

  def test_metadata_is_repaced
    file = Pathname.new("test/fixtures/metadata-test.xml").read
    stripped = @repo.strip_content(@docinfo_subs, file)
    assert_no_match /enerfaxweb@egroups.com/i, stripped
    assert_no_match /enerfax1@bellsouth.net/i, stripped
    assert_match /~metadata stripped by psstrip~/i, stripped
  end
end