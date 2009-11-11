require 'gherkin/states'
require 'gherkin/lexer'
require 'forwardable'

module Gherkin
  class ParseError < ::SyntaxError
    attr_reader :event, :line, :expected

    def initialize(event, line, expected)
      @event, @line, @expected = event, line, expected
      super "Parse error on line #{@line}. Found #{@event} when expecting one of: #{@expected.join(', ')}."
    end
  end
  
  class Parser
    extend Forwardable
    include States
    
    def_delegators :@lexer, :scan
    
    def initialize(i18n_lang, listener, raise_on_error=true)
      @raise_on_error = raise_on_error
      @listener       = listener
      @lexer          = Lexer[i18n_lang].new(self)
      @current        = State.new
    end

    def error(args)
      @raise_on_error ? raise(ParseError.new(args.first, args.last, @current.expected)) : @listener.syntax_error(*args)
    end
    
    def method_missing(meth, *args)
      @current.respond_to?(meth) ? dispatch(meth, *args) : super
    end
    
    private 
    
    def change_state(state)
      (@current = @states[state]) if event_allowed?(state)
    end
    
    def dispatch(event, *args)
      event_allowed?(event) ? @listener.send(event, *args) : error([event] + args)
    end
    
    def event_allowed?(event)
      @current.send(event)
    end
  end  
end