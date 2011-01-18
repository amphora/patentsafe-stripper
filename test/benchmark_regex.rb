require 'tempfile'
require 'benchmark'
require File.dirname(__FILE__) + '/test_helper'

class TestBenchmarkRegex < Test::Unit::TestCase

  def setup
    @tests = 100000
    @repo = PatentSafe::Repository.new(:path => @@psdir)
    @file = read_file("/data/2009/01/02/TEST0100000002/docinfo.xml")
    @rules = @repo.rules.find{|k,rest|k == "docinfo\.xml$"}[3].length
    @docinfo_subs = @repo.rules.find{|k,r,t,s| k == "docinfo\.xml$" }[3]
  end

  def teardown
  end

  def test_regex
    puts
    puts "Run #{@tests} times with #{@rules} for #{@tests*@rules} substitutions:"
    puts Benchmark.measure {
      @tests.times do
        @repo.strip_content(@docinfo_subs, @file)
      end
    }

    puts
    puts " - with FileIO"
    puts Benchmark.measure {
      @tests.times do
        Tempfile.open("psstrip"){ |t| t.puts @repo.strip_content(@docinfo_subs, @file)}
      end
    }

  end


  def test_full_copy
    outdir = Pathname.new("tmp/throttle-test")
    puts
    puts "Full repo copy"
    puts Benchmark.measure {
      @repo.copy_to outdir.to_s
    }
    outdir.rmtree rescue nil
  end
end

# Run 1000000 times with 19 for 19000000 substitutions:
#  50.956000   0.000000  50.956000 ( 50.956000)
#.
#Finished in 51.476 seconds.
