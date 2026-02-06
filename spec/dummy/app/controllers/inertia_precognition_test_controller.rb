# frozen_string_literal: true

class InertiaPrecognitionTestController < ApplicationController
  class TestValidator
    include ::ActiveModel::Model
    include ::ActiveModel::Attributes

    attribute :name, :string
    attribute :email, :string

    validates :name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  end

  class CustomValidator
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def errors
      result = {}
      result[:name] = ['is required'] if data[:name].blank?
      result[:email] = ['is invalid'] if data[:email].present? && !data[:email].include?('@')
      result
    end
  end

  before_action :build_validator, only: [:with_before_action]

  def basic
    validator = TestValidator.new(validator_params)
    precognition!(validator)

    render json: { success: true }
  end

  def non_bang
    validator = TestValidator.new(validator_params)
    return if precognition(validator)

    render json: { success: true }
  end

  def with_before_action
    precognition!(@validator)

    render json: { success: true }
  end

  def without_precognition
    render json: { message: 'hello' }
  end

  def with_custom_validator
    validator = CustomValidator.new(validator_params.to_h.symbolize_keys)
    precognition!(validator.errors)

    render json: { success: true }
  end

  def with_string_keyed_errors
    errors = {}
    errors['name'] = ['is required'] if validator_params[:name].blank?
    errors['email'] = ['is invalid'] if validator_params[:email].present? && !validator_params[:email].include?('@')
    precognition!(errors)

    render json: { success: true }
  end

  def with_module_level
    validator = TestValidator.new(validator_params)
    InertiaRails.precognition!(validator)

    render json: { success: true }
  end

  private

  def validator_params
    params.fetch(:user, {}).permit(:name, :email)
  end

  def build_validator
    @validator = TestValidator.new(validator_params)
  end
end
