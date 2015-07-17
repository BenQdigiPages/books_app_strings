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

Prefix        | Usage
--------------|--------
**title_**    | Title for activity (view controller), dialog, etc
**msg_**      | Message displayed in dialog or in content
**btn_**      | Title for button, including clickable link
**hint_**     | Hint for search bar, text field, or other short message to prompt user
**category_** | book category name, used in bookshelf
**drawer_**   | Title for panel drawer item
**menu_**     | Title for popup menu item
**err_**      | System error message
...           | If there are other strings should be grouped, you can add common prefix to it

Export to iOS strings
---------------------

A ruby script `localize.rb` is available to export Android string resources to iOS, it supports
the following resource types:

Android xml tag  | iOS file
-----------------|-----------
**string**       | Merge into Localizable.strings
**string-array** | Merge into LocalizableArray.strings
**plurals**      | Merge into Localizable.stringsdict

For every language, Android side may have multiple .xml files, all will be merged into
single file on iOS. The iOS file will be put into proper language directory, such as Base.lproj
or zh-Hant.lproj.

To run the tool:

````
ruby localize.rb --in res --out ios-strings
````

It is recommended to use the following helper to access the resource in iOS,
so you can access resource as `L("msg_waiting")`, `L("msg_items_found", quantity: n)`
and `L(array: "menu_items")`


````swift
public func L(key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

public func L(key: String, quantity: Int) -> String {
    return String.localizedStringWithFormat(key, quantity)
}

private var _arrays: NSDictionary? = {
    if let path = NSBundle.mainBundle().pathForResource("LocalizableArray", ofType: "strings") {
        return NSDictionary(contentsOfFile: path)
    }
    return nil
}()

public func L(array key: String) -> [String] {
    return _arrays?[key] as? [String] ?? []
}
````

Export to CSV report
--------------------

The `localize.rb` can also export resources to one CSV file, for review or other purpose, please try:

````
ruby localize.rb --in res --report strings.csv
````


