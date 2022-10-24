class QuestionController < ApplicationController

  PATCH_ACTION_DELETE = 'question.delete'
  PATCH_ACTION_COMPLETE = 'question.complete'
  PATCH_ACTION_SET_TITLE = 'question.set_title'
  PATCH_ACTION_SET_ANSWER = 'question.set_answer'
  PATCH_ACTION_DELETE_ANSWER = 'question.delete_answer'
  PATCH_ACTION_SET_ASSIGNED_TO = 'question.set_assigned_to'
  PATCH_ACTION_SET_SORT_ORDER = 'question.set_order'
  unloadable

  include QuestionHelper


  before_action :find_questionlist_by_id, :only => [:index, :create]
  before_action :find_question_by_id, :only => [:patch]
  before_action :check_updated_at, :only => [:patch]
  before_action :find_issue_by_id, :only => [:assignees]

  include ApiHelper


  #after_action :update_issue, :only => [:create, :patch]

  helper

  def index
    data = []
    @questionlist.items.each do |r|
      data.push(transform_question(r))
    end

    render json: data
  rescue  StandardError => e
    api_exception e
  end

  def assignees
    data = []
    @issue.assignable_users.each do |r|
      data.push(transform_user(r))
    end

    render json: data
  rescue  StandardError => e
    api_exception e
  end

  def create
    record = Question.new
    record.title = params[:title]
    record.questionlist = @questionlist
    record.created_by = User.current
    record.sort_order = Question.where(questionlist: @questionlist).length
    record.set_assigned_to(params[:assigned_to_id]) if params[:assigned_to_id]
    unless record.save
      api_validation_errors(record)
      return false
    end
    render json: transform_question(record)
  rescue  StandardError => e
    api_exception e
  end

  def patch
    case params[:data][:action]
    when PATCH_ACTION_DELETE
      @question.set_deleted true
    when PATCH_ACTION_COMPLETE
      @question.set_completed params[:data][:value]
    when PATCH_ACTION_SET_TITLE
      @question.set_title params[:data][:value]
    when PATCH_ACTION_SET_ANSWER
      @question.set_answer params[:data][:value]
    when PATCH_ACTION_DELETE_ANSWER
      @question.delete_answer
    when PATCH_ACTION_SET_ASSIGNED_TO
      @question.set_assigned_to params[:data][:value]
    when PATCH_ACTION_SET_SORT_ORDER
      @question.set_order params[:data][:value]
    else
      api_one_error(l(:invalid_action_attribute))
      return
    end

    unless @question.save
      api_validation_errors(@question)
      return
    end

    api_updated_at @question.updated_at
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  rescue  StandardError => e
    api_exception e
  end

  private

  def find_questionlist_by_id
    @questionlist = Questionlist.find(params[:questionlist_id])
    @issue = @questionlist.issue
    raise Unauthorized unless @issue.visible?
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  rescue  StandardError => e
    api_exception e
    return
  end

  def find_question_by_id
    pp "he1"
    @question = Question.find(params[:id])
    @issue = @question.questionlist.issue
    api_403 unless @issue.visible?
    @project = @issue.project

  rescue ActiveRecord::RecordNotFound
    pp "he"
    api_404
    return
  end

  def check_updated_at
    if params[:data][:updated_at].nil?
      api_one_error "updated_at required"
      return
    end
    if (DateTime.parse(params[:data][:updated_at]).to_i-@question.updated_at.to_i).abs >0
      api_one_error(l(:record_already_updated))
      return
    end
  rescue TypeError => e
    api_one_error "updated_at wrong format"
    return
  rescue StandardError => e
    api_exception e
    return
  end

  def find_issue_by_id
    @issue = Issue.find(params[:issue_id])
    raise Unauthorized unless @issue.visible?
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404("issue not found")
    return
  end



end
