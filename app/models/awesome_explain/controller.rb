class AwesomeExplain::Controller < ActiveRecord::Base
  establish_connection AE_DB_CONFIG
  self.table_name = 'controllers'

  has_many :logs
  has_many :explains

  def total_duration
    logs.sum(:duration).round(3)
  end

  def gql?
    path =~ /graphql/ || name =~ /GraphqlController/
  end

  def formatted_params
    h_params = JSON.parse(params)
    gql? ? h_params.dig('graphql') : h_params
  end
end
