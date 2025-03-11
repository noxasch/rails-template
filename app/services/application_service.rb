#
# Any service class that inherit this base class can be call as in the example
# and return the same outcome format
#
# ideally we want to return result containing the processed object
#   in case of error, we want to return result/outcome object containing the error and success: false
#   and should not catch expected error outside of service class
#   - similar approach to mutation gem which act as service class in a controller
#
# @example:
#   `MyService.call(args)`
#
# @note: see existing class that inherit `ApplicationService` for example
#
class ApplicationService
  def self.call(*, &)
    new(*, &).call
  end

  def call
    raise NotImplementedError
  end

  def logger
    @logger ||= ServiceLog
  end
end
