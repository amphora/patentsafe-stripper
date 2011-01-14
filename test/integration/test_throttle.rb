require File.dirname(__FILE__) + '/../test_helper'

class TestThrottle < Test::Unit::TestCase

  def setup
    @outdir = Pathname.new("tmp/throttle-test")
  end

  def teardown
    @outdir.rmtree rescue nil
  end

  def test_throttling
    tzero = get_throttled_run_time(0)
    ttwo = get_throttled_run_time(2)
    assert ttwo > tzero
  end

  def get_throttled_run_time(throttle)
    @outdir.rmtree rescue nil
    start = Time.now
    cmd = "#{@@script} -V -t #{throttle} \"#{@@psdir}\" \"#{@outdir.to_s}\""
    `#{cmd}`
    stop = Time.now
    stop.to_f - start.to_f
  end
end