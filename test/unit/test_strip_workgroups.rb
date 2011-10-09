require File.dirname(__FILE__) + '/../test_helper'

class TestStripWorkgroups < Test::Unit::TestCase

  def setup
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    @file = read_file("data/config/workgroups.xml")
    workgroups = @repo.workgroup_map.map{ |group, groupsub| [/(#{group})/im, groupsub] }
    @stripped = @repo.strip_content(workgroups, @file)
  end


  def test_workgroups_are_stripped
    assert_no_match /irregulars/i, @stripped
    assert_no_match /baker\sstreet/i, @stripped
    assert_match /admin/i, @stripped
    assert_no_match /group\s1/i, @stripped # admin
    assert_match /group\s2/i, @stripped
    assert_match /group\s3/i, @stripped
  end


end