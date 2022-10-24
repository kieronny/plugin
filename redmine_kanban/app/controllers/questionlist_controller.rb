class QuestionlistController < ApplicationController
  PATCH_ACTION_DELETE = 'questionlist.delete'.freeze
  PATCH_ACTION_SET_TITLE = 'questionlist.set_title'.freeze

  unloadable

  include QuestionlistHelper
  include KanbanHelper
  include ApiHelper

  before_action :find_issue_by_id, :only => [:index, :create, :templates, :add_from_template]
  before_action :find_questionlist_by_id, :only =>[:patch, :assign, :template_from_checklist]
  before_action :check_updated_at, :only => [:patch, :assign]
  #after_action :update_issue, :only => [:create, :patch]

  helper

  def index

    data = []
    Questionlist.where(issue: @issue, deleted: false).order(id: :asc).each do |r|
      data.push(transform_questionlist(r))
    end
    render json: data
  rescue  StandardError => e
    api_exception e
  end

  def create

    if Questionlist.where(issue: @issue, deleted: false, list_type: ChecklistBase::TYPE_USUAL).length > 0
      render json: {"errors" => l(:message_disabled_create_more_one) }, status: 403
      return false
    end

    @issue.can_add_checklist?(User.current)|| (raise Unauthorized)


    record = Questionlist.new
    record.title = params[:title]
    record.issue = @issue
    record.created_by = User.current
    record.list_type = ChecklistBase::TYPE_USUAL

    unless record.save
      render_validation_errors(record)
      return false
    end

    render json: transform_questionlist(record)
  end

  def patch
    @questionlist.editable? || (raise Unauthorized)
    case params[:data][:action]
    when PATCH_ACTION_DELETE
      @questionlist.set_deleted true
    when PATCH_ACTION_SET_TITLE
      @questionlist.set_title params[:data][:value]
    else
      api_one_error(l(:invalid_action_attribute))
      return
    end

    unless @questionlist.save
      api_validation_errors(@questionlist)
      return false
    end

    render json: { updatedAt: @questionlist.updated_at }
  end

  def assign
    Question.where(questionlist: @questionlist, deleted: false, done: false ).each do |r|
      if r.editable?
        r.set_assigned_to params[:data][:value]
        r.save || render_validation_errors(r)
      end
    end

    @questionlist.reload
    render json: transform_questionlist(@questionlist)

  rescue ActiveRecord::RecordNotFound => e
    api_404 e.message
  rescue  StandardError => e
    api_exception e
  end

  private

  def find_issue_by_id
    @issue = Issue.find(params[:issue_id])
    raise Unauthorized unless @issue.visible?
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  end

  def find_questionlist_by_id
    @questionlist = Questionlist.find(params[:id])
    @issue = @questionlist.issue
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  end

  def check_updated_at
    if params[:data][:updated_at].nil?
      api_one_error "updated_at required"
      return
    end

    if DateTime.parse(params[:data][:updated_at]).to_i != @questionlist.updated_at.to_i
      api_one_error(l(:record_already_updated))
      return
    end
  rescue TypeError => e
    api_one_error "updated_at required"
    return
  rescue StandardError => e
    api_exception e
    return
  end

end
