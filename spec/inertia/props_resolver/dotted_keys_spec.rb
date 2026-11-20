# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::PropsResolver::DottedKeys do
  def expand(props)
    described_class.new(props).expand
  end

  # Runs a closure or prop type the way the resolver does: as the controller.
  def evaluate(value, controller = Object.new)
    InertiaRails::PropEvaluator.new(controller).call(value)
  end

  describe 'props without dotted keys' do
    it 'turns top-level keys into Symbols and leaves nested keys as they are' do
      expect(expand({ 'user' => { 'name' => 'Jonathan' }, id: 1 })).to eq({ user: { 'name' => 'Jonathan' }, id: 1 })
    end

    it 'keeps the later of a key given as a Symbol and as a String' do
      expect(expand({ auth: { id: 1 }, 'auth' => { role: 'admin' } })).to eq({ auth: { role: 'admin' } })
    end
  end

  describe 'a dotted key' do
    it 'becomes nested hashes' do
      expect(expand({ 'auth.user.name' => 'Jonathan' })).to eq({ auth: { user: { name: 'Jonathan' } } })
    end

    it 'is written next to the dotted keys that start the same way' do
      props = { 'auth.user.name' => 'Jonathan', 'auth.user.id' => 1, 'auth.role' => 'admin' }

      expect(expand(props)).to eq({ auth: { user: { name: 'Jonathan', id: 1 }, role: 'admin' } })
    end

    it 'is written into copies of the hashes it extends' do
      user = { id: 1 }.freeze
      auth = { user: user }.freeze

      expect(expand({ auth: auth, 'auth.user.name' => 'Jonathan' }))
        .to eq({ auth: { user: { id: 1, name: 'Jonathan' } } })
      expect(auth).to eq({ user: { id: 1 } })
    end

    it 'replaces what the hash it extends holds at the same key' do
      expect(expand({ auth: { name: 'old' }, 'auth.name' => 'new' })).to eq({ auth: { name: 'new' } })
    end

    it 'replaces a key the hash holds as a String' do
      expect(expand({ auth: { 'name' => 'old' }, 'auth.name' => 'new' })).to eq({ auth: { 'name' => 'new' } })
    end

    it 'replaces what an earlier, longer dotted key set under it' do
      expect(expand({ 'a.b.c' => 1, 'a.b' => { d: 2 } })).to eq({ a: { b: { d: 2 } } })
    end

    it 'is set in the hash an earlier, shorter dotted key set' do
      expect(expand({ 'a.b' => { d: 2 }, 'a.b.c' => 1 })).to eq({ a: { b: { d: 2, c: 1 } } })
    end
  end

  describe 'a dotted key given after a value that is not a hash' do
    it 'replaces it' do
      expect(expand({ auth: 'guest', 'auth.name' => 'Jonathan' })).to eq({ auth: { name: 'Jonathan' } })
      expect(expand({ auth: nil, 'auth.name' => 'Jonathan' })).to eq({ auth: { name: 'Jonathan' } })
      expect(expand({ auth: { user: 1 }, 'auth.user.name' => 'Jonathan' }))
        .to eq({ auth: { user: { name: 'Jonathan' } } })
    end

    it 'replaces a prop type' do
      props = { auth: InertiaRails.optional { 1 }, 'auth.name' => 'Jonathan' }

      expect(expand(props)).to eq({ auth: { name: 'Jonathan' } })
    end
  end

  describe 'a dotted key given before the key it extends' do
    it 'adds what that key does not set, after the keys it does set' do
      auth = expand({ 'auth.name' => 'Jonathan', auth: { id: 1 } })[:auth]

      expect(auth).to eq({ id: 1, name: 'Jonathan' })
      expect(auth.keys).to eq(%i[id name])
    end

    it 'adds a hash that key does not hold' do
      props = { 'auth.user.name' => 'Jonathan', auth: { id: 1 } }

      expect(expand(props)).to eq({ auth: { id: 1, user: { name: 'Jonathan' } } })
    end

    it 'does not overwrite what that key sets itself' do
      expect(expand({ 'auth.name' => 'shared', auth: { name: 'page' } })).to eq({ auth: { name: 'page' } })
      expect(expand({ 'auth.name' => 'shared', auth: { name: nil } })).to eq({ auth: { name: nil } })
    end

    it 'does not replace a value that is not a hash' do
      expect(expand({ 'auth.name' => 'Jonathan', auth: 'guest' })).to eq({ auth: 'guest' })
      expect(expand({ 'auth.name' => 'Jonathan', auth: nil })).to eq({ auth: nil })
      expect(expand({ 'auth.user.name' => 'Jonathan', auth: { user: nil } })).to eq({ auth: { user: nil } })
    end

    it 'counts the last time the key it extends is given' do
      props = { auth: { name: 'first' }, 'auth.name' => 'dotted', 'auth' => { name: 'last' } }

      expect(expand(props)).to eq({ auth: { name: 'last' } })
    end
  end

  describe 'a dotted key that extends a closure' do
    it 'does not call the closure' do
      called = false
      expand({ auth: -> { called = true }, 'auth.name' => 'Jonathan' })

      expect(called).to be false
    end

    it 'is written into a copy of what the closure returns, once that is asked for' do
      returned = { id: 1 }.freeze
      props = expand({ auth: -> { returned }, 'auth.name' => 'Jonathan' })

      expect(evaluate(props[:auth])).to eq({ id: 1, name: 'Jonathan' })
    end

    it 'runs the closure as the controller' do
      controller = Struct.new(:current_user).new('Jonathan')
      props = expand({ auth: -> { { user: current_user } }, 'auth.role' => 'admin' })

      expect(evaluate(props[:auth], controller)).to eq({ user: 'Jonathan', role: 'admin' })
    end

    it 'calls the closure once for several dotted keys' do
      calls = 0
      props = expand({ auth: -> { { id: (calls += 1) } }, 'auth.name' => 'Jonathan', 'auth.role' => 'admin' })

      expect(evaluate(props[:auth])).to eq({ id: 1, name: 'Jonathan', role: 'admin' })
      expect(calls).to eq(1)
    end

    it 'is written into what a closure returned by the closure returns' do
      props = expand({ auth: -> { -> { { id: 1 } } }, 'auth.name' => 'Jonathan' })

      expect(evaluate(evaluate(props[:auth]))).to eq({ id: 1, name: 'Jonathan' })
    end

    it 'reaches a closure that a hash holds' do
      props = expand({ auth: { user: -> { { id: 1 } } }, 'auth.user.name' => 'Jonathan' })

      expect(evaluate(props[:auth][:user])).to eq({ id: 1, name: 'Jonathan' })
    end

    it 'replaces what the closure returns when that is not a hash' do
      props = expand({ auth: -> { 'guest' }, 'auth.name' => 'Jonathan' })

      expect(evaluate(props[:auth])).to eq({ name: 'Jonathan' })
    end

    it 'does not overwrite what the closure returns when it was given before the closure' do
      props = expand({ 'auth.name' => 'shared', 'auth.role' => 'admin', auth: -> { { name: 'page' } } })

      expect(evaluate(props[:auth])).to eq({ name: 'page', role: 'admin' })
      expect(evaluate(expand({ 'auth.name' => 'shared', auth: -> { 'guest' } })[:auth])).to eq('guest')
    end
  end

  describe 'a dotted key that extends an object with `to_inertia`' do
    let(:serializer) do
      Class.new do
        attr_reader :calls

        def to_inertia
          @calls = calls.to_i + 1
          { id: 1 }
        end
      end.new
    end

    it 'does not ask the object for its props' do
      expand({ auth: serializer, 'auth.name' => 'Jonathan' })

      expect(serializer.calls).to be_nil
    end

    it 'is written into what the object returns, once that is asked for' do
      props = expand({ auth: serializer, 'auth.name' => 'Jonathan' })

      expect(evaluate(props[:auth])).to eq({ id: 1, name: 'Jonathan' })
    end

    it 'treats a hash with `to_inertia` as such an object' do
      hash = Class.new(Hash) { def to_inertia = { id: 1 } }.new
      props = expand({ auth: hash, 'auth.name' => 'Jonathan' })

      expect(evaluate(props[:auth])).to eq({ id: 1, name: 'Jonathan' })
    end
  end
end
