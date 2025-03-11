class ApplicationMutation < Mutations::Command
  private

  def add_model_errors(obj)
    obj.errors.each do |err|
      add_error(err.attribute.to_sym, err.type.to_sym, "#{err.message}.")
    end
  end
end
