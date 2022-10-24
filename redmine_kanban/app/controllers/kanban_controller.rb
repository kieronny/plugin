class KanbanController < ApplicationController
  menu_item :kanban
  require 'json'

  include ProjectsHelper
  include QueriesHelper
  include KanbanHelper
  include ApiHelper

  before_action :find_optional_project, :build_query, only: [
    :index, :get_issues, :set_sort_order, :set_issue_status
  ]

  before_action :find_project_by_issue, only: [
    :set_issue_status, :get_issue
  ]

  before_action :check_updated_at, only: [
    :set_issue_status
  ]

  def index
    @settings = get_board_settings
    @current_user = get_current_user
    @checklist_settings = get_checklist_settings

    @kanban_query_id = nil
  end

  def get_issues
    items = @query.issues(limit: 500)
    data = format_issues items

    render json: data
  end

  def get_issue
    data = format_issue Issue.find(params[:id])
    render json: data
  end

  def set_issue_status
    status_id = params[:status_id].to_i

    if User.current.allowed_to?(:edit_issues, @project) && @issue.new_statuses_allowed_to.select { |item| item.id == status_id }.any?
      @issue.init_journal(User.current)
      @issue.status_id = status_id
      if @issue.save
        # head :ok
        render json: format_issues(@query.issues(limit: 500))
      else
        render json: {"errors" => @issue.errors.full_messages }, status: 403
      end
    else
      render json: {"errors" =>  l(:kanban_rejected_status) }, status: 403
    end
  rescue  StandardError => e
    api_exception e
  end


  private

  def get_board_settings
    {
      'query' => request.GET.empty? ? to_arr(@query) : request.GET ,
      'id' => @project ? @project.identifier : nil,
      'statuses' => format_statuses(@query.get_statuses, []),
      'swimlanes' => {:name => nil},
      'show_card_properties' => @query.columns.map do |column|
        # @TODO in free version should be column.name
        column.respond_to?(:custom_field) ? column.custom_field.name : column.name
      end
    }
  end

  def find_project_by_issue
    @issue = Issue.find(params[:id])
    @project = @issue.project
  end

  def build_query
      @query = KanbanQuery.new(:name => "_")
      @query.user = User.current
      @query.project = @project
      @query.build_from_params(params)
  end

  def check_updated_at
    if DateTime.parse(params[:updated_on]).to_i != @issue.updated_on.to_i
      render json: { :errors => l(:record_already_updated) }, :status =>  400
    end
  end
end
