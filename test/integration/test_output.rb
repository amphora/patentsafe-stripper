require File.dirname(__FILE__) + '/../test_helper'

class TestOutput < Test::Unit::TestCase

  def setup
  end

  def test_quiet_has_no_output
    out = `#{@@script} -q "#{@@psdir}" "#{@@outdir}"`
    assert_equal "", out
  end

  def test_default_has_limited_output
    out = `#{@@script} "#{@@psdir}" "#{@@outdir}"`
    assert_match /PatentSafe repository copied to/i, out
  end

  def test_verbose_has_output
    out = `#{@@script} -V "#{@@psdir}" "#{@@outdir}"`
    assert_match /patentsafe stripper/i, out
    assert_match /loading users/i, out
    assert_match /copying patentsafe/i, out
    assert_match /skipped/i, out
    assert_match /stripped/i, out
    assert_match /copied/i, out
    assert_match /patentsafe repository copied to/i, out
    assert_match /ended at/i, out
  end
end