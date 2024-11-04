class FakeStdErr
  attr_accessor :messages

  def initialize
    @messages = []
  end

  def write(msg)
    @messages << msg
  end

  # Rails 5.0 + Ruby 2.6 require puts to be a public method
  def puts(thing)
  end
end
