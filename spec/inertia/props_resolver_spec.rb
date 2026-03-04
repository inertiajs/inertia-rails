# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::PropsResolver do
  let(:evaluator) { InertiaRails::PropEvaluator.new(Object.new) }
  let(:component) { 'TestComponent' }

  def resolve(props, visit: {})
    resolver = described_class.new(props, evaluator: evaluator, visit: visit)
    resolved_props, metadata = resolver.resolve
    { props: resolved_props }.merge(metadata)
  end

  def resolve_partial(props, *only, **visit_opts)
    resolve(props, visit: { component: true, only: only.map(&:to_s), **visit_opts })
  end

  describe 'closure resolution' do
    it 'resolves a top-level closure' do
      page = resolve({ auth: -> { { user: 'Jonathan' } } })

      expect(page[:props][:auth]).to eq({ user: 'Jonathan' })
    end

    it 'resolves a closure inside a hash' do
      page = resolve({ auth: { user: -> { 'Jonathan' } } })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
    end
  end

  describe 'AlwaysProp' do
    it 'resolves nested always prop' do
      page = resolve({ auth: { user: InertiaRails.always { 'Jonathan' } } })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
    end

    it 'includes top-level always prop even when not requested in partial' do
      page = resolve_partial(
        { other: 'value', errors: InertiaRails.always { { name: 'required' } } },
        'other'
      )

      expect(page[:props][:other]).to eq('value')
      expect(page[:props][:errors]).to eq({ name: 'required' })
    end

    it 'includes nested always prop on partial request for sibling' do
      page = resolve_partial(
        { auth: { user: 'Jonathan', errors: InertiaRails.always { { name: 'required' } } } },
        'auth.user'
      )

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth][:errors]).to eq({ name: 'required' })
    end
  end

  describe 'MergeProp' do
    it 'resolves top-level merge prop with metadata' do
      page = resolve({ posts: InertiaRails.merge { [{ id: 1 }] } })

      expect(page[:props][:posts]).to eq([{ id: 1 }])
      expect(page[:mergeProps]).to include('posts')
    end

    it 'includes nested merge prop on partial request with metadata' do
      page = resolve_partial(
        { feed: { posts: InertiaRails.merge { [{ id: 1 }] } } },
        'feed.posts'
      )

      expect(page[:props][:feed][:posts]).to eq([{ id: 1 }])
      expect(page[:mergeProps]).to include('feed.posts')
    end

    it 'resolves nested merge prop with dot-path metadata' do
      page = resolve({ feed: { posts: InertiaRails.merge { [{ id: 1 }] } } })

      expect(page[:props][:feed][:posts]).to eq([{ id: 1 }])
      expect(page[:mergeProps]).to include('feed.posts')
    end

    it 'collects prepend metadata' do
      page = resolve({ posts: InertiaRails.merge(prepend: true) { %w[a b] } })

      expect(page[:prependProps]).to include('posts')
    end

    it 'collects nested prepend metadata with dot-path' do
      page = resolve({ feed: { posts: InertiaRails.merge(prepend: true) { %w[a b] } } })

      expect(page[:prependProps]).to include('feed.posts')
    end

    it 'collects nested deep merge metadata with dot-path' do
      page = resolve({ settings: { preferences: InertiaRails.deep_merge { { theme: 'dark' } } } })

      expect(page[:deepMergeProps]).to include('settings.preferences')
    end

    it 'collects nested merge prop with nested append path' do
      page = resolve({ feed: { posts: InertiaRails.merge(append: 'data') { { data: [{ id: 1 }] } } } })

      expect(page[:mergeProps]).to include('feed.posts.data')
    end

    it 'collects nested merge prop with match_on metadata' do
      page = resolve({ feed: { posts: InertiaRails.deep_merge(match_on: 'id') { [{ id: 1 }] } } })

      expect(page[:deepMergeProps]).to include('feed.posts')
      expect(page[:matchPropsOn]).to include('feed.posts.id')
    end

    it 'suppresses nested merge metadata on reset' do
      page = resolve(
        { feed: { posts: InertiaRails.merge { [{ id: 1 }] } } },
        visit: { component: true, only: ['feed.posts'], reset: ['feed.posts'] }
      )

      expect(page[:props][:feed][:posts]).to eq([{ id: 1 }])
      expect(page).not_to have_key(:mergeProps)
    end

    it 'collects nested merge metadata on exact partial request' do
      page = resolve_partial(
        { feed: { posts: InertiaRails.merge { [{ id: 1 }] } } },
        'feed.posts'
      )

      expect(page[:props][:feed][:posts]).to eq([{ id: 1 }])
      expect(page[:mergeProps]).to include('feed.posts')
    end

    it 'collects nested merge metadata when parent is requested' do
      page = resolve_partial(
        { feed: { posts: InertiaRails.merge { [{ id: 1 }] } } },
        'feed'
      )

      expect(page[:props][:feed][:posts]).to eq([{ id: 1 }])
      expect(page[:mergeProps]).to include('feed.posts')
    end
  end

  describe 'OptionalProp' do
    it 'excludes optional prop from initial load' do
      resolved = false
      page = resolve({
                       user: 'Jonathan',
                       permissions: InertiaRails.optional do
                         resolved = true
                         ['admin']
                       end,
                     })

      expect(page[:props][:user]).to eq('Jonathan')
      expect(page[:props]).not_to have_key(:permissions)
      expect(resolved).to be false
    end

    it 'includes optional prop on partial request' do
      page = resolve_partial(
        { user: 'Jonathan', permissions: InertiaRails.optional { ['admin'] } },
        'permissions'
      )

      expect(page[:props][:permissions]).to eq(['admin'])
    end

    it 'excludes nested optional prop from initial load without resolving' do
      resolved = false
      page = resolve({
                       auth: {
                         user: 'Jonathan',
                         permissions: InertiaRails.optional do
                           resolved = true
                           ['admin']
                         end,
                       },
                     })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:permissions)
      expect(resolved).to be false
    end

    it 'includes nested optional prop on partial request' do
      page = resolve_partial(
        { auth: { user: 'Jonathan', permissions: InertiaRails.optional { ['admin'] } } },
        'auth.permissions'
      )

      expect(page[:props][:auth][:permissions]).to eq(['admin'])
    end

    it 'deeply nested optional prop is included on partial request' do
      page = resolve_partial(
        { app: { auth: { permissions: InertiaRails.optional { ['admin'] } } } },
        'app.auth.permissions'
      )

      expect(page[:props][:app][:auth][:permissions]).to eq(['admin'])
    end

    it 'dot-notation optional prop is excluded from initial load' do
      page = resolve({
                       'auth.user.permissions' => InertiaRails.optional { ['edit-posts'] },
                       'auth.user.name' => 'Jonathan',
                     })

      # Dot-notation keys should be expanded into nested hash
      expect(page[:props][:auth][:user][:name]).to eq('Jonathan')
      expect(page[:props][:auth][:user]).not_to have_key(:permissions)
    end

    it 'dot-notation optional prop is included on partial request' do
      page = resolve_partial(
        {
          'auth.user.permissions' => InertiaRails.optional { %w[edit-posts delete-posts] },
          'auth.user.name' => 'Jonathan',
        },
        'auth.user.permissions'
      )

      expect(page[:props][:auth][:user][:permissions]).to eq(%w[edit-posts delete-posts])
    end

    it 'optional props inside indexed arrays are excluded from initial load' do
      resolved = false
      page = resolve({
                       foos: [
                         { foo: 'bar-1', bar: InertiaRails.optional do
                           resolved = true
                           'expensive-data-1'
                         end, },
                         { foo: 'bar-2', bar: InertiaRails.optional { 'expensive-data-2' } }
                       ],
                     })

      expect(page[:props][:foos][0][:foo]).to eq('bar-1')
      expect(page[:props][:foos][0]).not_to have_key(:bar)
      expect(resolved).to be false
    end

    it 'optional props inside indexed arrays are resolved on partial request' do
      page = resolve_partial(
        {
          foos: [
            { foo: 'bar-1', bar: InertiaRails.optional { 'expensive-data-1' } },
            { foo: 'bar-2', bar: InertiaRails.optional { 'expensive-data-2' } }
          ],
        },
        'foos'
      )

      expect(page[:props][:foos][0][:bar]).to eq('expensive-data-1')
      expect(page[:props][:foos][1][:bar]).to eq('expensive-data-2')
    end

    it 'deferred prop inside indexed array uses indexed path in metadata' do
      page = resolve({
                       foos: [
                         { name: 'First', notifications: InertiaRails.defer { ['msg'] } }
                       ],
                     })

      expect(page[:props][:foos][0][:name]).to eq('First')
      expect(page[:props][:foos][0]).not_to have_key(:notifications)
      expect(page[:deferredProps]).to eq({ 'default' => ['foos.0.notifications'] })
    end

    it 'merge prop inside indexed array uses indexed path in metadata' do
      page = resolve({
                       foos: [
                         { name: 'First', posts: InertiaRails.merge { [{ id: 1 }] } }
                       ],
                     })

      expect(page[:props][:foos][0][:posts]).to eq([{ id: 1 }])
      expect(page[:mergeProps]).to eq(['foos.0.posts'])
    end

    it 'deferred prop inside indexed array is resolved on partial request for parent' do
      page = resolve_partial(
        {
          foos: [
            { name: 'First', notifications: InertiaRails.defer { ['msg'] } }
          ],
        },
        'foos'
      )

      expect(page[:props][:foos][0][:name]).to eq('First')
      expect(page[:props][:foos][0][:notifications]).to eq(['msg'])
    end

    it 'optional prop inside indexed array is resolved by indexed path' do
      page = resolve_partial(
        {
          foos: [
            { name: 'First', bar: InertiaRails.optional { 'expensive-1' } },
            { name: 'Second', bar: InertiaRails.optional { 'expensive-2' } }
          ],
        },
        'foos.0.bar'
      )

      expect(page[:props][:foos].length).to eq(1)
      expect(page[:props][:foos][0][:bar]).to eq('expensive-1')
      expect(page[:props][:foos][0]).not_to have_key(:name)
    end

    it 'non-indexed field path does not match inside indexed array' do
      page = resolve_partial(
        {
          foos: [
            { name: 'First', bar: InertiaRails.optional { 'expensive-1' } }
          ],
        },
        'foos.bar'
      )

      expect(page[:props][:foos]).to eq([])
    end

    it 'closure returning array with optional prop excludes it on initial load' do
      resolved = false
      page = resolve({
                       foos: lambda {
                         [
                           { name: 'First', bar: InertiaRails.optional do
                             resolved = true
                             'expensive'
                           end, }
                         ]
                       },
                     })

      expect(page[:props][:foos][0][:name]).to eq('First')
      expect(page[:props][:foos][0]).not_to have_key(:bar)
      expect(resolved).to be false
    end

    it 'closure returning array with optional prop resolves on partial request' do
      page = resolve_partial(
        {
          foos: -> { [{ name: 'First', bar: InertiaRails.optional { 'expensive' } }] },
        },
        'foos'
      )

      expect(page[:props][:foos][0][:name]).to eq('First')
      expect(page[:props][:foos][0][:bar]).to eq('expensive')
    end

    it 'closure returning array with deferred prop collects indexed metadata' do
      page = resolve({
                       foos: lambda {
                         [{ name: 'First', notifications: InertiaRails.defer { ['msg'] } }]
                       },
                     })

      expect(page[:props][:foos][0][:name]).to eq('First')
      expect(page[:props][:foos][0]).not_to have_key(:notifications)
      expect(page[:deferredProps]).to eq({ 'default' => ['foos.0.notifications'] })
    end

    it 'dot-notation with indexed array excludes optional on initial load' do
      page = resolve({
                       'foos.items' => [
                         { name: 'First', bar: InertiaRails.optional { 'expensive' } }
                       ],
                     })

      expect(page[:props][:foos][:items][0][:name]).to eq('First')
      expect(page[:props][:foos][:items][0]).not_to have_key(:bar)
    end

    it 'dot-notation with indexed array resolves optional on partial request' do
      page = resolve_partial(
        {
          'foos.items' => [
            { name: 'First', bar: InertiaRails.optional { 'expensive' } }
          ],
        },
        'foos.items'
      )

      expect(page[:props][:foos][:items][0][:name]).to eq('First')
      expect(page[:props][:foos][:items][0][:bar]).to eq('expensive')
    end
  end

  describe 'DeferProp' do
    it 'excludes deferred prop from initial load without resolving' do
      resolved = false
      page = resolve({
                       name: 'Jonathan',
                       notifications: InertiaRails.defer do
                         resolved = true
                         []
                       end,
                     })

      expect(page[:props][:name]).to eq('Jonathan')
      expect(page[:props]).not_to have_key(:notifications)
      expect(page[:deferredProps]).to eq({ 'default' => ['notifications'] })
      expect(resolved).to be false
    end

    it 'includes deferred prop on partial request' do
      page = resolve_partial(
        { name: 'Jonathan', notifications: InertiaRails.defer { ['msg'] } },
        'notifications'
      )

      expect(page[:props][:notifications]).to eq(['msg'])
    end

    it 'preserves deferred group' do
      page = resolve({
                       sport: InertiaRails.defer(group: 'sidebar') { 'hockey' },
                       level: InertiaRails.defer { 'pro' },
                     })

      expect(page[:deferredProps]).to eq({
                                           'sidebar' => ['sport'],
                                           'default' => ['level'],
                                         })
    end

    it 'excludes nested deferred prop from initial load with dot-path metadata' do
      resolved = false
      page = resolve({
                       auth: {
                         user: 'Jonathan',
                         notifications: InertiaRails.defer do
                           resolved = true
                           []
                         end,
                       },
                     })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:notifications)
      expect(page[:deferredProps]).to eq({ 'default' => ['auth.notifications'] })
      expect(resolved).to be false
    end

    it 'nested deferred prop preserves group' do
      page = resolve({
                       auth: {
                         notifications: InertiaRails.defer(group: 'sidebar') { [] },
                         messages: InertiaRails.defer(group: 'sidebar') { [] },
                       },
                     })

      expect(page[:deferredProps]).to eq({ 'sidebar' => ['auth.notifications', 'auth.messages'] })
    end

    it 'includes nested deferred prop on partial request' do
      page = resolve_partial(
        { auth: { user: 'Jonathan', notifications: InertiaRails.defer { ['msg'] } } },
        'auth.notifications'
      )

      expect(page[:props][:auth][:notifications]).to eq(['msg'])
    end

    it 'deeply nested deferred prop is excluded with dot-path metadata' do
      page = resolve({
                       app: { auth: { notifications: InertiaRails.defer(group: 'alerts') { [] } } },
                     })

      # Parent hashes become empty when all children are deferred, so they're excluded too
      expect(page[:props]).not_to have_key(:app)
      expect(page[:deferredProps]).to eq({ 'alerts' => ['app.auth.notifications'] })
    end

    it 'deferred props at mixed depths collect correct metadata' do
      page = resolve({
                       foo: InertiaRails.defer { 'bar' },
                       nested: { a: 'b', c: InertiaRails.defer { 'd' } },
                     })

      expect(page[:props]).not_to have_key(:foo)
      expect(page[:props][:nested][:a]).to eq('b')
      expect(page[:props][:nested]).not_to have_key(:c)
      expect(page[:deferredProps]).to eq({ 'default' => ['foo', 'nested.c'] })
    end

    it 'deferred props at mixed depths resolve on partial request' do
      page = resolve_partial(
        { foo: InertiaRails.defer { 'bar' }, nested: { a: 'b', c: InertiaRails.defer { 'd' } } },
        'foo', 'nested.c'
      )

      expect(page[:props][:foo]).to eq('bar')
      expect(page[:props][:nested][:c]).to eq('d')
      expect(page[:props][:nested]).not_to have_key(:a)
      expect(page).not_to have_key(:deferredProps)
    end

    it 'collects deferred + merge metadata together' do
      page = resolve({ posts: InertiaRails.defer(merge: true) { [{ id: 1 }] } })

      expect(page[:props]).not_to have_key(:posts)
      expect(page[:deferredProps]).to eq({ 'default' => ['posts'] })
      expect(page[:mergeProps]).to include('posts')
    end

    it 'collects nested deferred + merge metadata together' do
      page = resolve({ feed: { posts: InertiaRails.defer(merge: true) { [{ id: 1 }] } } })

      # Parent hash becomes empty when all children are deferred
      expect(page[:props]).not_to have_key(:feed)
      expect(page[:deferredProps]).to eq({ 'default' => ['feed.posts'] })
      expect(page[:mergeProps]).to include('feed.posts')
    end

    it 'multiple deferred props inside closure are excluded from initial load' do
      notifications_resolved = false
      roles_resolved = false
      page = resolve({
                       auth: lambda {
                         {
                           user: 'Jonathan',
                           notifications: InertiaRails.defer do
                             notifications_resolved = true
                             ['msg']
                           end,
                           roles: InertiaRails.defer do
                             roles_resolved = true
                             ['admin']
                           end,
                         }
                       },
                     })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:notifications)
      expect(page[:props][:auth]).not_to have_key(:roles)
      expect(notifications_resolved).to be false
      expect(roles_resolved).to be false
    end

    it 'multiple deferred props inside closure are resolved on partial request' do
      page = resolve_partial(
        {
          auth: lambda {
            {
              user: 'Jonathan',
              notifications: InertiaRails.defer { ['msg'] },
              roles: InertiaRails.defer { ['admin'] },
            }
          },
        },
        'auth.notifications', 'auth.roles'
      )

      expect(page[:props][:auth][:notifications]).to eq(['msg'])
      expect(page[:props][:auth][:roles]).to eq(['admin'])
    end
  end

  describe 'OnceProp' do
    it 'resolves once prop on initial load' do
      page = resolve({ locale: InertiaRails.once { 'en' } })

      expect(page[:props][:locale]).to eq('en')
      expect(page[:onceProps]).to eq({ 'locale' => { prop: 'locale' } })
    end

    it 'once prop with custom key' do
      page = resolve({ locale: InertiaRails.once(key: 'app-locale') { 'en' } })

      expect(page[:onceProps]).to eq({ 'app-locale' => { prop: 'locale' } })
    end

    it 'excludes once prop when already loaded by client' do
      page = resolve({ locale: InertiaRails.once { 'en' }, timezone: 'UTC' }, visit: { except_once: ['locale'] })

      expect(page[:props][:timezone]).to eq('UTC')
      expect(page[:props]).not_to have_key(:locale)
      # Metadata is still collected
      expect(page[:onceProps]).to eq({ 'locale' => { prop: 'locale' } })
    end

    it 'resolves nested once prop on initial load with dot-path metadata' do
      page = resolve({ config: { locale: InertiaRails.once { 'en' } } })

      expect(page[:props][:config][:locale]).to eq('en')
      expect(page[:onceProps]).to eq({ 'config.locale' => { prop: 'config.locale' } })
    end

    it 'nested once prop with custom key and dot-path prop reference' do
      page = resolve({ config: { locale: InertiaRails.once(key: 'app-locale') { 'en' } } })

      expect(page[:onceProps]).to eq({ 'app-locale' => { prop: 'config.locale' } })
    end

    it 'excludes nested once prop when already loaded' do
      page = resolve(
        { config: { locale: InertiaRails.once { 'en' }, timezone: 'UTC' } },
        visit: { except_once: ['config.locale'] }
      )

      expect(page[:props][:config][:timezone]).to eq('UTC')
      expect(page[:props][:config]).not_to have_key(:locale)
      expect(page[:onceProps]).to eq({ 'config.locale' => { prop: 'config.locale' } })
    end

    it 'nested once metadata collected on exact partial request' do
      page = resolve_partial(
        { config: { locale: InertiaRails.once { 'en' } } },
        'config.locale'
      )

      expect(page[:props][:config][:locale]).to eq('en')
      expect(page[:onceProps]).to eq({ 'config.locale' => { prop: 'config.locale' } })
    end

    it 'nested once metadata collected when parent is requested' do
      page = resolve_partial(
        { config: { locale: InertiaRails.once { 'en' } } },
        'config'
      )

      expect(page[:props][:config][:locale]).to eq('en')
      expect(page[:onceProps]).to eq({ 'config.locale' => { prop: 'config.locale' } })
    end
  end

  describe 'DeferProp + once' do
    it 'suppresses deferred metadata when once-prop already loaded (non-partial)' do
      page = resolve({ posts: InertiaRails.defer(once: true) { [] } }, visit: { except_once: ['posts'] })

      expect(page).not_to have_key(:deferredProps)
    end

    it 'includes deferred + once metadata on first load' do
      page = resolve({ posts: InertiaRails.defer(once: true) { [] } })

      expect(page[:deferredProps]).to eq({ 'default' => ['posts'] })
      expect(page[:onceProps]).to eq({ 'posts' => { prop: 'posts' } })
    end

    it 'nested: suppresses deferred metadata when already loaded' do
      page = resolve(
        { feed: { posts: InertiaRails.defer(once: true) { [] } } },
        visit: { except_once: ['feed.posts'] }
      )

      expect(page).not_to have_key(:deferredProps)
    end

    it 'nested: includes deferred + once metadata on first load' do
      page = resolve({ feed: { posts: InertiaRails.defer(once: true) { [] } } })

      expect(page[:deferredProps]).to eq({ 'default' => ['feed.posts'] })
      expect(page[:onceProps]).to eq({ 'feed.posts' => { prop: 'feed.posts' } })
    end
  end

  describe 'closure returning prop type' do
    it 'closure returning defer prop is excluded from initial load' do
      resolved = false
      page = resolve({ notifications: lambda {
        InertiaRails.defer do
          resolved = true
          []
        end
      } })

      expect(page[:props]).not_to have_key(:notifications)
      expect(page[:deferredProps]).to eq({ 'default' => ['notifications'] })
      expect(resolved).to be false
    end

    it 'closure returning defer prop metadata is collected' do
      page = resolve({ notifications: -> { InertiaRails.defer(group: 'alerts') { [] } } })

      expect(page[:deferredProps]).to eq({ 'alerts' => ['notifications'] })
    end

    it 'closure returning merge prop resolves with metadata' do
      page = resolve({ posts: -> { InertiaRails.merge { [{ id: 1 }] } } })

      expect(page[:props][:posts]).to eq([{ id: 1 }])
      expect(page[:mergeProps]).to include('posts')
    end

    it 'closure returning once prop resolves with metadata' do
      page = resolve({ locale: -> { InertiaRails.once { 'en' } } })

      expect(page[:props][:locale]).to eq('en')
      expect(page[:onceProps]).to eq({ 'locale' => { prop: 'locale' } })
    end

    it 'closure returning defer + merge prop is excluded with metadata' do
      page = resolve({ posts: -> { InertiaRails.defer(merge: true) { [{ id: 1 }] } } })

      expect(page[:props]).not_to have_key(:posts)
      expect(page[:deferredProps]).to eq({ 'default' => ['posts'] })
      expect(page[:mergeProps]).to include('posts')
    end

    it 'closure returning hash with optional prop excluded from initial load' do
      resolved = false
      page = resolve({
                       auth: lambda {
                         {
                           user: 'Jonathan',
                           permissions: InertiaRails.optional do
                             resolved = true
                             ['admin']
                           end,
                         }
                       },
                     })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:permissions)
      expect(resolved).to be false
    end

    it 'closure returning hash with deferred prop excluded from initial load' do
      resolved = false
      page = resolve({
                       auth: lambda {
                         {
                           user: 'Jonathan',
                           notifications: InertiaRails.defer do
                             resolved = true
                             []
                           end,
                         }
                       },
                     })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:notifications)
      expect(page[:deferredProps]).to eq({ 'default' => ['auth.notifications'] })
      expect(resolved).to be false
    end

    it 'closure inside nested hash returning defer prop collects metadata' do
      page = resolve({
                       auth: lambda {
                         {
                           user: { name: 'Jonathan', email: 'jonathan@example.com' },
                           notifications: InertiaRails.defer(group: 'alerts') { [] },
                         }
                       },
                     })

      expect(page[:deferredProps]).to eq({ 'alerts' => ['auth.notifications'] })
    end
  end

  describe 'excluded props are not resolved on initial load' do
    it 'both optional and deferred closures skip execution on initial load' do
      optional_resolved = false
      deferred_resolved = false
      page = resolve({
                       auth: {
                         user: 'Jonathan',
                         permissions: InertiaRails.optional do
                           optional_resolved = true
                           ['admin']
                         end,
                         notifications: InertiaRails.defer do
                           deferred_resolved = true
                           []
                         end,
                       },
                     })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:permissions)
      expect(page[:props][:auth]).not_to have_key(:notifications)
      expect(optional_resolved).to be false
      expect(deferred_resolved).to be false
    end
  end

  describe 'ScrollProp' do
    let(:scroll_metadata) { { page_name: 'page', previous_page: nil, next_page: 2, current_page: 1 } }
    let(:scroll_controller) do
      headers = instance_double(ActionDispatch::Http::Headers)
      allow(headers).to receive(:[]).and_return(nil)
      request = instance_double(ActionDispatch::Request, headers: headers)
      instance_double(ActionController::Base, request: request)
    end
    let(:scroll_evaluator) { InertiaRails::PropEvaluator.new(scroll_controller) }

    it 'nested deferred scroll prop is excluded from initial load with metadata' do
      props = { feed: { posts: InertiaRails::ScrollProp.new(defer: true, metadata: scroll_metadata) { [{ id: 1 }] } } }
      resolver = described_class.new(props, evaluator: scroll_evaluator)
      resolved_props, metadata = resolver.resolve
      page = { props: resolved_props }.merge(metadata)

      expect(page[:props]).not_to have_key(:feed)
      expect(page[:deferredProps]).to eq('default' => ['feed.posts'])
    end

    it 'nested scroll prop is included on partial request with metadata' do
      props = { feed: { posts: InertiaRails::ScrollProp.new(metadata: scroll_metadata) { [{ id: 1 }] } } }
      resolver = described_class.new(props, evaluator: scroll_evaluator,
                                            visit: { component: true, only: ['feed.posts'] })
      resolved_props, metadata = resolver.resolve
      page = { props: resolved_props }.merge(metadata)

      expect(page[:props][:feed][:posts]).to eq([{ id: 1 }])
      expect(page[:scrollProps]).to eq('feed.posts' => { pageName: 'page', previousPage: nil, nextPage: 2,
                                                         currentPage: 1, reset: false, })
    end
  end

  describe 'to_inertia protocol' do
    pending 'resolves object responding to to_inertia' do
      serializer = Object.new
      def serializer.to_inertia = { name: 'Jonathan', email: 'jon@example.com' }

      page = resolve({ user: serializer })

      expect(page[:props][:user]).to eq({ name: 'Jonathan', email: 'jon@example.com' })
    end

    pending 'resolves nested object responding to to_inertia' do
      serializer = Object.new
      def serializer.to_inertia = { name: 'Jonathan' }

      page = resolve({ auth: { user: serializer } })

      expect(page[:props][:auth][:user]).to eq({ name: 'Jonathan' })
    end

    pending 'resolves to_inertia object with prop types inside' do
      serializer = Object.new
      def serializer.to_inertia
        {
          user: 'Jonathan',
          permissions: InertiaRails.optional { ['admin'] },
        }
      end

      page = resolve({ auth: serializer })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:permissions)
    end
  end

  describe 'partial request filtering' do
    it 'excludes props not in partial-data header' do
      page = resolve_partial(
        { name: 'Jonathan', email: 'jon@example.com' },
        'name'
      )

      expect(page[:props][:name]).to eq('Jonathan')
      expect(page[:props]).not_to have_key(:email)
    end

    it 'excludes props via except header' do
      page = resolve(
        { auth: { user: 'Jonathan', token: 'secret' } },
        visit: { component: true, only: ['auth'], except: ['auth.token'] }
      )

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:token)
    end

    it 'except header for parent suppresses all nested props' do
      page = resolve(
        { feed: { posts: InertiaRails.merge { [{ id: 1 }] } }, other: 'value' },
        visit: { component: true, only: %w[feed other], except: ['feed'] }
      )

      expect(page[:props]).not_to have_key(:feed)
      expect(page[:props][:other]).to eq('value')
      expect(page).not_to have_key(:mergeProps)
    end

    it 'partial request for parent resolves all nested prop types with dot-path metadata' do
      page = resolve_partial(
        {
          dashboard: {
            stats: 'visible',
            feed: InertiaRails.merge { [{ id: 1 }] },
            notifications: InertiaRails.defer { ['msg'] },
            settings: InertiaRails.optional { { theme: 'dark' } },
            locale: InertiaRails.once { 'en' },
          },
        },
        'dashboard'
      )

      expect(page[:props][:dashboard][:stats]).to eq('visible')
      expect(page[:props][:dashboard][:feed]).to eq([{ id: 1 }])
      expect(page[:props][:dashboard][:notifications]).to eq(['msg'])
      expect(page[:props][:dashboard][:settings]).to eq({ theme: 'dark' })
      expect(page[:props][:dashboard][:locale]).to eq('en')
      expect(page[:mergeProps]).to include('dashboard.feed')
      expect(page[:onceProps]).to eq({ 'dashboard.locale' => { prop: 'dashboard.locale' } })
      expect(page).not_to have_key(:deferredProps)
    end

    it 'except header suppresses nested merge metadata' do
      page = resolve(
        { feed: { posts: InertiaRails.merge { [{ id: 1 }] }, comments: InertiaRails.merge { [{ id: 2 }] } } },
        visit: { component: true, only: ['feed.posts', 'feed.comments'], except: ['feed.posts'] }
      )

      expect(page[:props][:feed]).not_to have_key(:posts)
      expect(page[:props][:feed][:comments]).to eq([{ id: 2 }])
      expect(page[:mergeProps]).to eq(['feed.comments'])
    end
  end

  describe 'non-partial Inertia request' do
    it 'behaves like initial load for nested prop types with dot-path metadata' do
      page = resolve({
                       dashboard: {
                         stats: 'visible',
                         feed: InertiaRails.merge { [{ id: 1 }] },
                         notifications: InertiaRails.defer { [] },
                         settings: InertiaRails.optional { [] },
                       },
                     })

      expect(page[:props][:dashboard][:stats]).to eq('visible')
      expect(page[:props][:dashboard][:feed]).to eq([{ id: 1 }])
      expect(page[:props][:dashboard]).not_to have_key(:notifications)
      expect(page[:props][:dashboard]).not_to have_key(:settings)
      expect(page[:mergeProps]).to include('dashboard.feed')
      expect(page[:deferredProps]).to eq({ 'default' => ['dashboard.notifications'] })
    end
  end

  describe 'multiple nested prop types' do
    it 'handles all types together with dot-path metadata' do
      page = resolve({
                       dashboard: {
                         stats: 'visible',
                         feed: InertiaRails.merge { [{ id: 1 }] },
                         notifications: InertiaRails.defer { [] },
                         settings: InertiaRails.optional { [] },
                         locale: InertiaRails.once { 'en' },
                       },
                     })

      expect(page[:props][:dashboard][:stats]).to eq('visible')
      expect(page[:props][:dashboard][:feed]).to eq([{ id: 1 }])
      expect(page[:props][:dashboard][:locale]).to eq('en')
      expect(page[:props][:dashboard]).not_to have_key(:notifications)
      expect(page[:props][:dashboard]).not_to have_key(:settings)
      expect(page[:mergeProps]).to include('dashboard.feed')
      expect(page[:deferredProps]).to eq({ 'default' => ['dashboard.notifications'] })
      expect(page[:onceProps]).to eq({ 'dashboard.locale' => { prop: 'dashboard.locale' } })
    end

    it 'deeply nested merge prop uses full dot-path' do
      page = resolve({
                       app: { feed: { posts: InertiaRails.merge { [{ id: 1 }] } } },
                     })

      expect(page[:mergeProps]).to include('app.feed.posts')
    end
  end

  describe 'dot-notation key expansion' do
    it 'expands dot-notation key into nested hash' do
      page = resolve({ 'auth.user' => 'Jonathan' })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
    end

    it 'merges dot-notation key with existing nested hash' do
      page = resolve({
                       auth: { user: 'Jonathan' },
                       'auth.admin' => true,
                     })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth][:admin]).to be true
    end

    it 'deeply nested dot-notation key' do
      page = resolve({ 'app.auth.user.name' => 'Jonathan' })

      expect(page[:props][:app][:auth][:user][:name]).to eq('Jonathan')
    end

    it 'dot-notation key with prop type' do
      page = resolve({
                       'auth.notifications' => InertiaRails.defer { ['msg'] },
                       'auth.user' => 'Jonathan',
                     })

      # Dot-notation keys should be expanded into nested hash
      expect(page[:props][:auth][:user]).to eq('Jonathan')
      expect(page[:props][:auth]).not_to have_key(:notifications)
      expect(page[:deferredProps]).to be_present
    end

    it 'dot-notation key with closure' do
      page = resolve({ 'auth.user' => -> { 'Jonathan' } })

      expect(page[:props][:auth][:user]).to eq('Jonathan')
    end
  end

  describe 'AlwaysProp errors' do
    it 'resolves AlwaysProp errors' do
      page = resolve({ name: 'Jon', errors: InertiaRails.always { { email: 'required' } } })

      expect(page[:props][:errors]).to eq({ email: 'required' })
    end

    it 'includes AlwaysProp errors on partial request even when not requested' do
      page = resolve_partial(
        { name: 'Jon', errors: InertiaRails.always { { email: 'required' } } },
        'name'
      )

      expect(page[:props][:name]).to eq('Jon')
      expect(page[:props][:errors]).to eq({ email: 'required' })
    end
  end
end
