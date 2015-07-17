books_app_common_resource
=========================

This project is common resource for Android and iOS app, app project should add this project
as submodule, for example:

````
git submodule add https://github.com/BenQdigiPages/books_app_common_resource.git common
````

String ID naming convention
---------------------------

Prefix        | Usage
--------------|--------
**title_**    | Title for activity (view controller), dialog, etc
**msg_**      | Message displayed in dialog or in content
**btn_**      | Title for button, including clickable link
**hint_**     | Hint for seachbox, text field, or other short message to prompt user
**category_** | book category name, used in bookshelf
**drawer_**   | Title for panel drawer item
**menu_**     | Title for popup menu item
**err_**      | System error message
...           | If there are other strings should be grouped, you can add common prefix to it

Export to iOS strings
---------------------

A ruby script `localize.rb` is available to export Android string resources to iOS, it supports
the following resource types:

Android type       | iOS type
-------------------|-----------
**<string>**       | Merge into Localizable.strings
**<string-array>** | Merge into LocalizableArray.strings
**<plurals>**      | Merge into Localizable.stringsdict

For every language, Android side may have multiple .xml files, all will be merged into
single file on iOS. The iOS file will be put into proper language directory, such as Base.lproj
or zh-Hant.lproj.

To run the tool:

````
ruby localize.rb --in res --out ios-strings
````

It is recommended to use the following helper to access the resource in iOS,
soo you can access resouce as `L("msg_waiting")`, `L("msg_items_found", quantity: n)`
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

The `localize.rb` can also export resources to CSV file, for review or other purpose, please try:

````
ruby localize.rb --in res --report strings.csv
````

Troubleshooting
---------------

If the submodule directory is empty after you clone your project, please try:

````
git submodule init
git submodule update
````

Or you can avoid this problem by add `--recursive` option when you clone the project:

````
git clone --recursive https://....
````

