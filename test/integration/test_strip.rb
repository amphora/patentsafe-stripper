require File.dirname(__FILE__) + '/../test_helper'

class TestStrip < Test::Unit::TestCase

  def setup
    @outdir = Pathname.new("tmp/strip-test")
    @outdir.rmtree rescue nil
    @out = `#{@@script} "#{@@psdir}" "#{@outdir.to_s}"`
  end

  def teardown
    @outdir.rmtree
  end

  def test_files_in_stripped_repo
    # events log
    assert !@outdir.join("data", "events.log.migrated").exist?
    # settings
    assert @outdir.join("data", "config", "settings.xml").exist?
    assert !@outdir.join("data", "config", "settings.xml.backup-2.0").exist?
    # docinfo
    docdir = @outdir.join("data", "2009", "01", "02", "TEST0100000002")
    assert docdir.join("docinfo.xml").exist?
    assert !docdir.join("docinfo.update-to-3.3.xml").exist?
    assert !docdir.join("docinfo.update-to-3.6.xml").exist?
    assert !docdir.join("submitted.pdf").exist?
    assert !docdir.join("thumbnail.png").exist?
    assert !docdir.join("page-01.png").exist?
    # log
    daydir = docdir.parent
    assert daydir.join("events.txt").exist?
    assert !daydir.join("log.xml.migrated").exist?
  end

end