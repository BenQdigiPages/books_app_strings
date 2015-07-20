books_app_strings
=================

This project is common strings for Android and iOS app, app project should add this project
as submodule, for example:

````
git submodule add https://github.com/BenQdigiPages/books_app_strings.git i18n
````

Update strings to latest version
--------------------------------

The git submodule is actually bind to a particular commit, so it will not
be updated automatically. If the strings has been modified in books_app_strings,
you need to update strings for your project, you can do that with:

````
git submodule update --remote --merge i18n
````

Clone your project with submodules
----------------------------------

You need to add `--recursive` option when you clone the app project for Android or iOS:

````
git clone --recursive https://github.com/BenQdigiPages/books_app_ios.git
````

Or you can force update submodule directory when you find it is empty:

````
git submodule init
git submodule update
````

String ID naming convention
---------------------------

Prefix    | Usage
----------|--------
title_    | Title for activity (view controller), dialog, etc
msg_      | Message displayed in dialog or in content
btn_      | Title for button, including clickable link
hint_     | Hint for search bar, text field, or other short message to prompt user
category_ | book category name, used in bookshelf
drawer_   | Title for panel drawer item
menu_     | Title for popup menu item
err_      | System error message
...       | If there are other strings should be grouped, you can add common prefix to it

Generate iOS strings
--------------------

A ruby script `ios-strings.rb` is available to generate iOS strings from Android string resources,
it supports the following resource types:

Android xml tag | iOS file
----------------|-----------
string          | Generate to Localizable.strings
string-array    | Generate to LocalizableArray.strings
plurals         | Generate to Localizable.stringsdict

For example, to run the tool for books_app_ios:

````
cd books_app_strings
ruby ios-strings.rb --import=res --res=../books_app_ios/res
````

The tool also generate a `R.swift` that mimic Android R.java, it is type-safe and IDE friendly:

swift expression        | swift type | Usage
------------------------|------------|-------
R.string.btn_ok         | R.string   | enum case, you can get the key string by .rawValue
R.string.btn_ok^        | String     | To get the localized string
R.array.menu_list       | R.array    | enum case, you can get the key string by .rawValue
R.array.menu_list^      | [String]   | To get the localized string array
R.array.menu_list[3]    | String     | To get 3rd item of the localized string array
R.plurals.item_count    | R.plurals  | enum case, you can get the key string by .rawValue
R.plurals.item_count[5] | String     | To get the localized string with quantity 5

The ^ and [] opeartor for R.swift are overloaded to provide access to resource.

Generate CSV report
-------------------

The `ios-strings.rb` can also export resources to one CSV file, for review or other purpose, please try:

````
cd books_app_strings
ruby ios-strings.rb --import=res --export-csv=report.csv
````
