require 'active_support/core_ext/module/delegation'
require 'hashr'

module SimpleStates
  class Event
    attr_reader :name, :options

    def initialize(name, options = {})
      @name    = name
      @options = Hashr.new(options) do
        def except
          self[:except]
        end
      end
    end

    def call(object, *args)
      return if skip?(object, args)

      assert_transition(object)
      run_callback(:before, object, args)

      yield.tap do
        set_state(object)
        run_callback(:after, object, args)
      end
    end

    protected

      def skip?(object, args)
        result = false
        result ||= !send_method(options.if, object, args) if options.if?
        result ||= send_method(options.except, object, args) if options.except?
        result
      end

      def run_callback(type, object, args)
        send_method(options.send(type), object, args) if options.send(type)
      end

      def assert_transition(object)
        # assert transition is allowed
      end

      def set_state(object)
        if options.to
          object.past_states << object.state
          object.state = options.to
        end
      end

      def send_method(method, object, args)
        object.send method, *case arity = object.class.instance_method(method).arity
          when 0;  []
          when -1; [self].concat(args)
          else;    [self].concat(args).slice(0..arity - 1)
        end
      end
  end
end
