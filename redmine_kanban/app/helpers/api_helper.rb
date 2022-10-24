module ApiHelper

  # errors should be array of string
  def api_error(errors=[])
    render json: {"errors" => errors }, status: 403
  end

  # errors should be array of string
  def api_one_error(error)
    render json: {"error" => error }, status: 403
  end

  def api_403(error = "")
    render json: {"error" => error }, status: 403
  end

  def api_validation_errors(objects)
    messages = Array.wrap(objects).map {|object| object.errors.full_messages}.flatten
    # pp messages.flatten
    api_error(messages.flatten)
  end

  def api_404(text = "Not found")
    render json: {"error" => text }, status: 404
  end

  def api_updated_at(updated_at)
    render json: { :updated_at => updated_at }, status: 200
  end

  def api_answer(array)
    render json: array, status: 200
  end

  def api_exception(e)
    render json: {"error" => e.message, 'trace'=> e.backtrace }, status: 500
  end



end