books_app_common_resource
=========================

This project is common resource for Android and iOS app, app project should add this project
as submodule, for example:

````
git submodule add https://github.com/BenQdigiPages/books_app_common_resource.git common
````

String ID naming convention
---------------------------

Prefix      | Usage
------------|--------
`title_`    | Title for activity (view controller), dialog, etc
`msg_`      | Message displayed in dialog or in content
`btn_`      | Title for button, including clickable link
`hint_`     | Hint for seachbox, text field, or other short message to prompt user
`category_` | book category name, used in bookshelf
`drawer_`   | Title for panel drawer item
`menu_`     | Title for popup menu item
...         | If there are other strings should be grouped, you can add common prefix to it

Trouble shotting
----------------

If the submodule directory is empty after you clone your project, please try:

````
git submodule init
git submodule update
````

Or you can avoid this problem by add `--recursive` option when you clone

````
git clone --recursive https://....
````

