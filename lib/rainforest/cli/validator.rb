# frozen_string_literal: true
class RainforestCli::Validator
  API_TOKEN_ERROR = 'Please supply API token and try again'
  VALIDATIONS_PASSED = '[VALID]'
  VALIDATIONS_FAILED = '[INVALID] - Please see log to correct errors.'

  attr_reader :local_tests, :remote_tests

  def initialize(options, local_tests = nil, remote_tests = nil)
    @local_tests = local_tests || RainforestCli::TestFiles.new(options.test_folder)
    @remote_tests = remote_tests || RainforestCli::RemoteTests.new(options.token)
  end

  def validate
    check_test_directory_for_tests!

    # Avoid using || in order to make sure both methods are called
    parsing_validation = has_parsing_errors?
    dependency_validation = has_test_dependency_errors?
    is_invalid = parsing_validation || dependency_validation

    logger.info ''
    logger.info(is_invalid ? VALIDATIONS_FAILED : VALIDATIONS_PASSED)
  end

  def validate_with_errors!
    check_test_directory_for_tests!

    unless remote_tests.api_token_set?
      logger.error API_TOKEN_ERROR
      exit 2
    end

    exit 1 if has_parsing_errors? || has_test_dependency_errors?
  end

  private

  def check_test_directory_for_tests!
    unless local_tests.count > 0
      logger.error "No tests found in directory: #{local_tests.test_folder}"
      exit 3
    end
  end

  def has_parsing_errors?
    logger.info 'Validating parsing errors...'
    has_parsing_errors = rfml_tests.select { |t| t.errors.any? }

    return false unless has_parsing_errors.any?

    parsing_error_notification(has_parsing_errors)
    true
  end

  def has_test_dependency_errors?
    logger.info 'Validating embedded test IDs...'
    has_nonexisting_tests? || has_circular_dependencies?
  end

  def has_nonexisting_tests?
    contains_nonexistent_ids = rfml_tests.select { |t| (t.embedded_ids - all_rfml_ids).any? }

    return false unless contains_nonexistent_ids.any?

    nonexisting_embedded_id_notification(contains_nonexistent_ids)
    true
  end

  def has_circular_dependencies?
    # TODO: Add validation for circular dependencies in server tests as well
    has_circular_dependencies = false
    rfml_tests.each do |rfml_test|
      has_circular_dependencies ||= check_for_nested_embed(rfml_test, rfml_test.rfml_id, rfml_test.file_name)
    end
    has_circular_dependencies
  end

  def check_for_nested_embed(rfml_test, root_id, root_file)
    rfml_test.embedded_ids.each do |embed_id|
      descendant = test_dictionary[embed_id]

      if descendant.embedded_ids.include?(root_id)
        circular_dependencies_notification(root_file, descendant.file_name) if descendant.embedded_ids.include?(root_id)
        return true
      end

      check_for_nested_embed(descendant, root_id, root_file)
    end
    false
  end

  def rfml_tests
    @rfml_tests ||= local_tests.test_data
  end

  def all_rfml_ids
    local_rfml_ids + remote_rfml_ids
  end

  def local_rfml_ids
    @local_rfml_ids ||= local_tests.rfml_ids
  end

  def remote_rfml_ids
    @remote_rfml_ids ||= remote_tests.rfml_ids
  end

  def test_dictionary
    @test_dictionary ||= local_tests.test_dictionary
  end

  def parsing_error_notification(rfml_tests)
    logger.error 'Parsing errors:'
    logger.error ''
    rfml_tests.each do |rfml_test|
      logger.error "\t#{rfml_test.file_name}"
      rfml_test.errors.each do |_line, error|
        logger.error "\t#{error}"
      end
    end
    logger.error ''
  end

  def nonexisting_embedded_id_notification(rfml_tests)
    logger.error 'The following files contain unknown embedded test IDs:'
    logger.error ''
    rfml_tests.each do |rfml_test|
      logger.error "\t#{rfml_test.file_name}"
    end
    logger.error ''
  end

  def circular_dependencies_notification(file_a, file_b)
    logger.error 'The following files are embedding one another:'
    logger.error ''
    logger.error "\t#{file_a}"
    logger.error "\t#{file_b}"
    logger.error ''
  end

  def logger
    RainforestCli.logger
  end
end
