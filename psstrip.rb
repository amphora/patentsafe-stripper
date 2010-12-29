#!/usr/bin/env ruby
#
# == Synopsis
#   Script to create a copy of a PatentSafe repository stripped of
#   sensitive data.
#
# == Examples
#
#     ruby psstrip.rb /path/to/repository /path/to/copy
#
#     * A directory named 'patentsafe-stripped' is created under the copy
#       directory. In the above example the copy would be created at
#       /path/to/copy/patentsafe-stripped
#
#   Other examples:
#     ruby psstrip.rb -q /path/to/repository /path/to/copy
#     ruby psstrip.rb --verbose /path/to/repository /path/to/copy
#     ruby psstrip.rb -V /path/to/repository /path/to/copy
#
# == Usage
#   psstrip.rb [options] "/path/to/repository" "/path/to/copy"
#
#   For help use: ruby psstrip.rb -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#
# == Copyright
#   Copyright (c) 2010 Amphora Research Systems Ltd.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#


# ===========================================================================
# psstrip.rb
# ===========================================================================

require 'date'
require 'fileutils'
require 'find'
require 'logger'
require 'optparse'
require 'ostruct'
require 'pathname'
require 'rdoc/usage'
require 'rexml/document'


# Setup global logger if file is being run as a script (not included)
if __FILE__ == $PROGRAM_NAME
  LOG = Logger.new(STDOUT)
end


# Script
#   sets up arguments, logging level, and options. Also handles help output.
class Script
  VERSION = '5.1.0'

  # Simple log formatter
  class Formatter < Logger::Formatter
    def call(severity, time, program_name, message)
      "#{message}\n"
    end
  end

  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
  end

  def run
    LOG.formatter = Formatter.new

    if parsed_options? && arguments_valid?

      LOG.level = if @options.verbose
        Logger::INFO
      elsif @options.quiet
        Logger::ERROR
      else # default
        Logger::WARN
      end

      process_arguments
      process_command
    else
      output_usage
    end

  end

  protected

  def parsed_options?
    opts = OptionParser.new
    opts.on('-v', '--version')      { output_version ; exit 0 }
    opts.on('-h', '--help')         { output_help }
    opts.on('-V', '--verbose')      { @options.verbose = true }
    opts.on('-q', '--quiet')        { @options.quiet = true }
    opts.parse!(@arguments) rescue return false
    process_options
    true
  end

  # Performs post-parse processing on options
  def process_options
    @options.verbose = false if @options.quiet
  end

  # True if required arguments were provided
  def arguments_valid?
    true if @arguments.length == 2
  end

  # Setup the arguments
  def process_arguments
    @patentsafe_dir = ARGV[0] if ARGV[0]
    @target_dir = ARGV[1] if ARGV[1]
  end

  def process_command
    repo = PatentSafe::Repository.new(:path => @patentsafe_dir)
    repo.copy_to(@target_dir)
  end

  def version_text
    "#{File.basename(__FILE__)} version #{VERSION}"
  end

  def output_help
    LOG.info version_text
    RDoc::usage() #exits app
  end

  def output_usage
    RDoc::usage('usage') # gets usage from comments above
  end

  def output_version
    LOG.info version_text
    RDoc::usage('copyright')
  end

  def output_options
    LOG.info "Options:\n"
    @options.marshal_dump.each do |name, val|
      LOG.info "  #{name} = #{val}"
    end
  end

end # class Script


# PatentSafe
#  wrapper around PatentSafe data and objects
module PatentSafe

  class Repository
    attr_accessor :path
    attr_reader :results, :users

    CLEAN_DIR = 'patentsafe-stripped'

    # File patterns used to match against repo file paths

    # COPY: files that are copied with no changes
    COPY = [
      "id-values\.xml.*",
      "settings\.xml.*",
      "workgroups\.xml.*"
    ]

    # SKIP: files we not copied
    SKIP = [
      "database\.xml",
      "content\.txt",
      ".*\.(png|ps|pdf)$" # images + pdf
    ]

    # STRIP: files that are cleaned before copy
    STRIP = [
      "docinfo\.xml.*",
      "signature\-.*\.xml.*",
      "events\.txt.*", # 5.0 merge of events.log + log.xml
      "events\.log.*", # 4.8 event log
      "log\.xml.*" # 4.8 read log
    ]

    # SUBSTITUTIONS: substitutions made of document content
    SUBSTITUTIONS = {
      "<summary>.*<\/summary>" => "<summary>~summary stripped by psstrip~</summary>",
      "<text>.*<\/text>" => "<text>~text stripped by psstrip~</text>",
      "<metadataValues>.*<metadataValues\/>" => "<metadataValues>~metadata stripped by psstrip~</metadataValues>"
    }

    def initialize(options={})
      @path = options[:path]
      @users = Hash.new
      @rules = Hash.new
      @subs = Hash.new

      LOG.info "-----------------------------------------------------------------------"
      LOG.info " PatentSafe Stripper "
      LOG.info "-----------------------------------------------------------------------"
      LOG.info " Started at: #{Time.now}"
      LOG.info ""

      load_rules
      load_substitutions # loads users also
    end

    def data_path
      File.expand_path(File.join(@path, 'data'))
    end

    def users_path
      File.expand_path(File.join(data_path, 'users'))
    end

    # Loads users from the xml in the repo
    def load_users
      LOG.info "** loading users from #{users_path}"

      Dir["#{users_path}/**/*.xml"].each_with_index do |path,i|
        user = User.new(:path => path)
        # lookup with user id and name to "User#{i}" alias
        @users[user.user_id] = "user#{i}"
        @users[user.name] = "User #{i}"
      end

      LOG.info "** #{@users.length} users loaded"
    end

    def load_rules
      COPY.each{|p| @rules[p] = :copy}
      SKIP.each{|p| @rules[p] = :skip}
      STRIP.each{|p| @rules[p] = :strip}
    end

    def load_substitutions
      load_users
      @subs.merge!(SUBSTITUTIONS)
      @subs.merge!(@users)
    end

    # Applies substitutions to the content
    def strip_content(file)
      @subs.each{|pattern, sub| file.gsub!(/#{pattern}/m, sub)}
      file
    end

    def copy_to(dest)
      unless File.exists?(dest)
        LOG.error "Repository can not be stripped since target directory '#{dest}' doesn't exist."
        exit 0
      end

      orig = Pathname.new(@path)
      clean = Pathname.new(File.join(dest, CLEAN_DIR))
      clean.rmtree if clean.exist? # reset destination

      LOG.info ""
      LOG.info "** copying patentsafe repository from #{File.expand_path(orig.to_s)}"

      # Descend through the PatentSafe repository
      Find.find(orig.to_s) do |path|
        src = Pathname.new(path) # pathname to slice and dice
        rel = src.relative_path_from(orig) # just the part below the top dir
        target = Pathname.new(File.join(clean.to_s, rel))

        if src.directory?
          target.mkpath unless target.exist?
        else
          basename = src.basename.to_s

          @rules.each do |pattern, rule|
            if /#{pattern}/i =~ basename

              case rule
              when :strip
                target.open("w+"){|t| t.puts strip_content(src.read)}
                LOG.info " - stripped #{basename}"

              when :skip
                LOG.info " - skipped #{basename}"

              else # :copy
                FileUtils.cp(src.to_s, target.to_s)
                LOG.info " - copied #{basename}"

              end # case

              # short circuit @rules.each
              break

            end
          end # rules.each

        end # if src.directory?
      end # Find

      LOG.info ""
      LOG.warn " PatentSafe repository copied to: #{File.expand_path(clean.to_s)}"
      LOG.info ""
      LOG.info " Ended at: #{Time.now}"
      LOG.info "-----------------------------------------------------------------------"

    end # def copy_to

  end # class Repository

  class User
    attr_reader :user_id, :name

    def initialize(options={})
      @path = options[:path]
      return unless @path

      @xml = REXML::Document.new(File.read(@path))
      @user_id = @xml.root.attribute("userId").to_s
      @name = @xml.root.get_text("name").value().to_s
      LOG.info " - loaded #{@name} [#{@user_id}]"
    end

  end # class User

end # module PatentSafe


# Only run script if called from command line and not included as a lib
if __FILE__ == $PROGRAM_NAME
  # Create and run the application
  script = Script.new(ARGV, STDIN)
  script.run
end


