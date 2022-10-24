# frozen_string_literal: true

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html


get '/projects/:project_id/kanban/board', to: 'kanban#index', as: 'project_kanban_board'

scope 'kanban' do
  get '/board', to: 'kanban#index', as: 'common_kanban_board'
  post '/set_issue_status/', to: 'kanban#set_issue_status'
  post '/:project_id/set_issue_status/', to: 'kanban#set_issue_status'
  post '/issues/', to: 'kanban#get_issues'
  # get '/:project_id/issues/', to: 'kanban#get_issues'
  post '/:project_id/issues/', to: 'kanban#get_issues'
  get '/issue/:id', to: 'kanban#get_issue'
  post '/:project_id/order/', to: 'kanban#set_sort_order'
  post '/order/', to: 'kanban#set_sort_order'
end

scope 'questionlist' do
  get '/:issue_id', to: 'questionlist#index'
  post '/:issue_id', to: 'questionlist#create'
  put '/assign/:id', to: 'questionlist#assign'
  patch '/:id', to: 'questionlist#patch'
  get '/templates/:issue_id/:type', to: 'questionlist#templates', as: 'kanban_api_checklist_tpl_index'
  post '/template/:id', to: 'questionlist#add_from_template', as: 'kanban_api_checklist_tpl_create_from_tpl'
  post '/to-template/save', to: 'questionlist#template_from_checklist', as: 'kanban_api_admin_checklist_tpl_create_from_checklist'
end

scope 'question' do
  get '/:questionlist_id', to: 'question#index'
  get '/assignees/:issue_id', to: 'question#assignees'
  post '/:questionlist_id', to: 'question#create'
  patch '/:id', to: 'question#patch'
  post '/upload/:id', to: 'question#upload'
  patch '/attachments/:id', to: 'question#update_attachment'
  delete '/attachments/:id', to: 'question#destroy_attachment'
end

get '/question/get_issue_users/:issue_id', to: 'question#get_issue_users'

post '/kanban/:issue_id/checklist', to: 'checklist#index'

scope 'kanban_query' do
  get '/new', to: 'kanban_query#new', as: 'kanban_query_new'
  get '/edit/:id', to: 'kanban_query#edit', as: 'kanban_query_edit'
  post '/create', to: 'kanban_query#create', as: 'kanban_query_create'
  patch '/:id', to: 'kanban_query#update', as: 'kanban_query_update'
  put '/:id', to: 'kanban_query#update', as: 'kanban_query_put'
end

resources :kanban_query, :except => [:show]

get '/projects/:project_id/kanban_query/new', to: 'kanban_query#new', as:'kanban_project_query_new'
get '/projects/:project_id/kanban_query/edit/:id', to: 'kanban_query#edit', as:'kanban_project_query_edit'
post '/projects/:project_id/kanban_query/new', to: 'kanban_query#create'
patch '/projects/:project_id/kanban_query/:id', to: 'kanban_query#update', as:'kanban_project_query_update'
put '/projects/:project_id/kanban_query/:id', to: 'kanban_query#update', as:'kanban_project_query_put'
