require File.dirname(__FILE__) + '/../test_helper'

class TestOptions < Test::Unit::TestCase

  def setup
  end

  def test_no_options_displays_usage
    out = `#{@@script}`
    assert_match /psstrip.rb \[options\]/, out
  end

  def test_help_option_displays_extended_usage
    out = `#{@@script} -h`
    assert_match /Displays help message/, out
  end

end