# frozen_string_literal: true

RSpec.describe 'Inertia meta tag sharing', type: :request do
  let(:inertia_headers) {
    {
      'X-Inertia' => true,
    }
  }

  let(:non_conditional_meta_tags) {
    [
      {
        'tagName' => 'title',
        'content' => 'The Inertia Title',
        'head-key' => '1',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'non-conditional plain data',
        'head-key' => '2',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'non-conditional callable data',
        'head-key' => '3',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'second non-conditional callable data',
        'head-key' => '4',
      }
    ]
  }

  let(:index_renderer_meta_tags) {
    [
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'index renderer',
        'head-key' => 'index',
      }
    ]
  }

  let(:shared_edit_meta_tags) {
    [
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional plain data, only edit',
        'head-key' => '5',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional plain data, if edit, with multiple conditions',
        'head-key' => '6',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional plain data, unless not_edit with a method reference',
        'head-key' => '7',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional plain data, with only edit and an if option',
        'head-key' => '8',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional plain data, except index and show, with an if option',
        'head-key' => '9',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional callable data, only edit',
        'head-key' => '10',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional callable data, except show and index',
        'head-key' => '11',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional callable data, if is_edit?',
        'head-key' => '12',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'conditional callable data, unless !is_edit?',
        'head-key' => '13',
      },
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'instance_exec lets you conditionally add data as well',
        'head-key' => '14',
      }
    ]
  }

  describe 'data shared on every request' do
    %i[
      shared_meta_path
      shared_metas_path
      edit_shared_meta_path
    ].each do |path|
      it "renders non-conditional meta tag data for #{path}" do
        get send(path), headers: inertia_headers

        expect(response.parsed_body['meta']).to include(*non_conditional_meta_tags)
      end
    end
  end

  describe 'renderer specified meta tag data' do
    it 'renders the meta tag data for the index action' do
      get shared_metas_path, headers: inertia_headers

      expect(response.parsed_body['meta']).to include(*index_renderer_meta_tags)
    end
  end

  describe 'conditional meta tag data' do
    describe 'the edit action' do
      it 'renders the correct meta tag data' do
        # Call twice to ensure meta tags are not appended multiple times across requests
        get edit_shared_meta_path, headers: inertia_headers
        get edit_shared_meta_path, headers: inertia_headers

        expect(response.parsed_body['meta']).to match_array([
          *shared_edit_meta_tags,
          *non_conditional_meta_tags,
        ])
      end
    end

    describe 'the index action' do
      it 'does not render the conditional meta tag data' do
        get edit_shared_meta_path, headers: inertia_headers
        get shared_metas_path, headers: inertia_headers

        expect(response.parsed_body['meta']).not_to include(*shared_edit_meta_tags)
      end
    end

    describe 'the show action' do
      it 'does not render the conditional meta tag data' do
      end
    end
  end

  context "when there is conditional data shared via before_action" do
    it "raises an error because it is frozen" do
      # Data isn't frozen until after the first time it's accessed.
      InertiaSharedMetaController.send(:_inertia_meta)

      expect {
        get shared_meta_with_a_problem_path, headers: {'X-Inertia' => true}
      }.to raise_error(FrozenError)
    end
  end
end
