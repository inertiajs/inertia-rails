require 'rails_helper'

<% module_namespacing do -%>
RSpec.describe "/<%= name.underscore.pluralize %>", <%= type_metatag(:request) %> do
  <% if mountable_engine? -%>
    include Engine.routes.url_helpers
  <% end -%>

  # This should return the minimal set of attributes required to create a valid
  # <%= class_name %>. As you add validations to <%= class_name %>, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

<% unless options[:singleton] -%>
  describe "GET /index" do
    it "renders a successful response" do
      <%= class_name %>.create! valid_attributes
      get <%= index_helper %>_url
      expect(response).to be_successful
    end
  end
<% end -%>

  describe "GET /show" do
    it "renders a successful response" do
      <%= file_name %> = <%= class_name %>.create! valid_attributes
      get <%= show_helper %>
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get <%= new_helper %>
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      <%= file_name %> = <%= class_name %>.create! valid_attributes
      get <%= edit_helper %>
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new <%= class_name %>" do
        expect {
          post <%= index_helper %>_url, params: valid_attributes
        }.to change(<%= class_name %>, :count).by(1)
      end

      it "redirects to the created <%= singular_table_name %>" do
        post <%= index_helper %>_url, params: valid_attributes
        expect(response).to redirect_to(<%= show_helper(class_name+".last") %>)
      end
    end

    context "with invalid parameters" do
      it "does not create a new <%= class_name %>" do
        expect {
          post <%= index_helper %>_url, params: invalid_attributes
        }.to change(<%= class_name %>, :count).by(0)
      end

      it "redirects to the new form" do
        post <%= index_helper %>_url, params: invalid_attributes
        expect(response).to redirect_to(<%= new_helper %>)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested <%= singular_table_name %>" do
        <%= file_name %> = <%= class_name %>.create! valid_attributes
        patch <%= show_helper %>, params: new_attributes
        <%= file_name %>.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the <%= singular_table_name %>" do
        <%= file_name %> = <%= class_name %>.create! valid_attributes
        patch <%= show_helper %>, params: new_attributes
        <%= file_name %>.reload
        expect(response).to redirect_to(<%= singular_table_name %>_url(<%= file_name %>))
      end
    end

    context "with invalid parameters" do
      it "redirects to the edit form" do
        <%= file_name %> = <%= class_name %>.create! valid_attributes
        patch <%= show_helper %>, params: invalid_attributes
        expect(response).to redirect_to(<%= edit_helper %>)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested <%= singular_table_name %>" do
      <%= file_name %> = <%= class_name %>.create! valid_attributes
      expect {
        delete <%= show_helper %>
      }.to change(<%= class_name %>, :count).by(-1)
    end

    it "redirects to the <%= table_name %> list" do
      <%= file_name %> = <%= class_name %>.create! valid_attributes
      delete <%= show_helper %>
      expect(response).to redirect_to(<%= index_helper %>_url)
    end
  end
end
<% end -%>
