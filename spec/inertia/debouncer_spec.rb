# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::Debouncer do
  describe '#debounce' do
    it 'executes the block after the delay' do
      executed = false
      debouncer = described_class.new(delay: 0.1)

      debouncer.debounce { executed = true }
      expect(executed).to be false

      debouncer.wait
      expect(executed).to be true
    end

    it 'cancels the previous task when called again within delay' do
      call_count = 0
      debouncer = described_class.new(delay: 0.1)

      debouncer.debounce { call_count += 1 }
      debouncer.debounce { call_count += 1 }
      debouncer.debounce { call_count += 1 }

      debouncer.wait
      expect(call_count).to eq(1)
    end
  end
end

RSpec.describe InertiaRails::ThreadDebouncer do
  around do |example|
    previous = InertiaRails::ThreadDebouncer.debouncer_class
    InertiaRails::ThreadDebouncer.debouncer_class = InertiaRails::Debouncer
    example.run
  ensure
    InertiaRails::ThreadDebouncer.debouncer_class = previous
  end

  describe '.for' do
    it 'returns a debouncer for the given key' do
      debouncer = described_class.for('test:key', delay: 0.1)
      expect(debouncer).to be_a(described_class)
    end

    it 'returns the same instance for the same key' do
      d1 = described_class.for('test:same', delay: 0.1)
      d2 = described_class.for('test:same', delay: 0.1)
      expect(d1).to equal(d2)
    end

    it 'returns different instances for different keys' do
      d1 = described_class.for('test:one', delay: 0.1)
      d2 = described_class.for('test:two', delay: 0.1)
      expect(d1).not_to equal(d2)
    end
  end

  describe '#debounce' do
    it 'coalesces rapid calls into one execution' do
      call_count = 0
      debouncer = described_class.for('test:coalesce', delay: 0.1)

      3.times { debouncer.debounce { call_count += 1 } }

      debouncer.wait
      expect(call_count).to eq(1)
    end

    it 'clears thread-local after execution' do
      key = 'test:clear'
      debouncer = described_class.for(key, delay: 0.1)

      debouncer.debounce { 'done' }
      debouncer.wait

      # Thread-local should be cleared
      expect(Thread.current[key]).to be_nil
    end
  end
end
