require File.dirname(__FILE__) + '/../test_helper'

class TestUsers < Test::Unit::TestCase

  def setup
    @outdir = Pathname.new("tmp/user-test")
    @outdir.rmtree rescue nil
    @userdir = @outdir.join('data','users','us','er')
    @out = `#{@@script} "#{@@psdir}" "#{@outdir.to_s}"`
  end

  def teardown
    @outdir.rmtree
  end

  def test_users_are_copied_to_new_dir
    repo = PatentSafe::Repository.new(:path => @@psdir)
    repo.users.each do |id, name|
      anon_id = repo.user_map[id]
      assert @userdir.join(anon_id, "#{anon_id}.xml").exist?
    end
  end

end