require File.dirname(__FILE__) + '/../test_helper'

class TestStripWorkgroups < Test::Unit::TestCase

  def setup
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    @file = read_file("data/config/workgroups.xml")
    @stripped = @repo.strip_content(@file)
  end


  def test_workgroups_are_stripped
    assert_no_match /irregulars/i, @stripped
    assert_no_match /baker street/i, @stripped
    assert_match /admin/i, @stripped
    assert_no_match /group 1/i, @stripped # admin
    assert_match /group 2/i, @stripped
    assert_match /group 3/i, @stripped
  end


end