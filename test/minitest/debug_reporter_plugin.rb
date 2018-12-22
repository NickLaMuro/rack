require "minitest"

module Minitest
  def self.plugin_debug_reporter_options opts, options
    opts.on "--with-debugging", "Print out spec doc (for debugging)" do
      options[:verbose] = true
      DebugReporter.enable!
    end
  end

  def self.plugin_debug_reporter_init options
    if DebugReporter.enabled? && !AbstractReporter.new.respond_to?(:prerecord)
      summary_reporter   = reporter.reporters.detect { |r| r.is_a? SummaryReporter }
      summary_reporter ||= SummaryReporter.new(options[:io], options)

      reporter.reporters = [
        summary_reporter,
        DebugReporter.new(options[:io], options)
      ]

      Runnable.patch_run_one_method_for_debug_reporter
    end
  end

  class DebugReporter < Minitest::ProgressReporter
    def self.enable!
      @enabled = true
    end

    def self.enabled?
      @enabled ||= false
    end

    def initialize io = $stdout, options = {}
      super

      @verbose = options[:verbose]
    end

    def record_starting klass_name, method_name
      io.print "%s#%s running...\r" % [klass_name, method_name] if @verbose
    end
  end

  class Runnable
    def self.patch_run_one_method_for_debug_reporter
      # self.send :alias_method, :__old_run_one_method, :run_one_method

      # def self.run_one_method klass, method_name, reporter
      #   reporter.record_starting klass.name, method_name
      #   __old_run_one_method klass, method_name, reporter
      # end

      # Don't know why the above doesn't work, but whatever...
      def self.run_one_method klass, method_name, reporter
        reporter.record_starting klass.name, method_name
        reporter.record Minitest.run_one_method(klass, method_name)
      end
    end
  end

  class CompositeReporter < AbstractReporter
    def record_starting klass_name, method_name
      self.reporters.each do |reporter|
        if reporter.respond_to? :record_starting
          reporter.record_starting klass_name, method_name
        end
      end
    end
  end
end
