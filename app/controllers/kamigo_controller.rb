require 'uri'

class KamigoController < ApplicationController
  def kamiform(http_method, path, resource)
    error_message = "please generate model Kamiform by the following command:\n\nrails g model kamiform platform_type source_group_id http_method path params:jsonb field\nrails db:migrate\n\n"
    begin
      Kamiform
    rescue StandardError
      raise error_message
    end

    return nil if resource.errors.empty?

    error = resource.errors.first
    resource_name = resource.class.to_s.downcase
    Kamiform.create(
      platform_type: params[:platform_type],
      source_group_id: params[:source_group_id],
      http_method: http_method,
      path: path,
      params: params,
      field: "#{resource_name}.#{error[0]}"
    )

    begin
      render "#{resource_name.pluralize}/kamiform/#{error[0]}"
    rescue StandardError
      render json: {
        type: 'text',
        text: error[1]
      }
    end
  end
end
