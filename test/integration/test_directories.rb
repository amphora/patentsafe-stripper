require File.dirname(__FILE__) + '/../test_helper'

class TestDirectories < Test::Unit::TestCase

  def setup
    @outdir = "tmp/dir-test"
    Pathname.new(@outdir).rmtree
    @out = `#{@@script} "#{@@dirs}" "#{@outdir}"`
  end

  def test_directories_are_not_copied
    assert !Pathname.new("#{@outdir}/configlets").exist?
    assert !Pathname.new("#{@outdir}/index").exist?
    assert !Pathname.new("#{@outdir}/printers").exist?
    assert !Pathname.new("#{@outdir}/scripts").exist?
    assert !Pathname.new("#{@outdir}/data/printjobs").exist?
    assert !Pathname.new("#{@outdir}/data/queues").exist?
    assert !Pathname.new("#{@outdir}/data/scanning").exist?
    assert !Pathname.new("#{@outdir}/data/spool").exist?
  end

end