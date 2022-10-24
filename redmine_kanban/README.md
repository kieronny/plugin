# Redmine Kanban and checklists plugin

Plugin for Redmine. Add checklists and Kanban board.

##Features

### Checklists features:
* ajax checklists
* checklist item can be assigned to different user
* answer to checklist item

### Kanban board features:
* full issue view in modal window
* edit checklists in modal
* new field “external block”
* quick filters



## Install

1. Download plugin and copy plugin folder redmine_kanban to Redmine's plugins folder

2. Run migrations in redmine root folder.

`bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_kanban`

3. Restart server f.i.

`sudo /etc/init.d/apache2 restart`

## Configure
1. Go to Administration -> Kanban

2. Configure user's roles  
   Plugin add permissions in 2 blocks: "Kanban" and "Checklists". Activate checkboxes for necessarily roles.

3. Enable modules "Kanban" and "Checklists" for projects.

## Uninstall

1. go to redmine root folder

`bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_kanban VERSION=0`

2. go to plugins folder, delete plugin folder redmine_kanban

`rm -r redmine_kanban`

3. restart server f.i.

`sudo /etc/init.d/apache2 restart`


## Requirements
Redmine 4.1, 4.2, 5.0
Database: sqlite, mysql, postgresql 