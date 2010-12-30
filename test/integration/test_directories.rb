require File.dirname(__FILE__) + '/../test_helper'

class TestDirectories < Test::Unit::TestCase

  def setup
    @outdir = Pathname.new("tmp/dir-test")
    @outdir.rmtree rescue nil
    @out = `#{@@script} "#{@@dirs}" "#{@outdir.to_s}"`
  end

  def teardown
    @outdir.rmtree
  end

  def test_directories_are_not_copied
    assert !@outdir.join("configlets").exist?
    assert !@outdir.join("index").exist?
    assert !@outdir.join("printers").exist?
    assert !@outdir.join("scripts").exist?
    assert !@outdir.join("data", "printjobs").exist?
    assert !@outdir.join("data" ,"queues").exist?
    assert !@outdir.join("data", "scanning").exist?
    assert !@outdir.join("data", "spool").exist?
  end

end