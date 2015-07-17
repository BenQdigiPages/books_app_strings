#!/usr/bin/env ruby
#
# Written by Steve Chiu <steve.k.chiu@gmail.com>
#
# This script can be called from an Xcode 'Run Script' build phase at the
# beginning of the build process, like this:
#
# ${PROJECT_DIR}/tool/localize.rb --in ${PROJECT_DIR}/tool/i18n --out ${PROJECT_DIR}/res
#
# What it does is to read Andrord resources and translate it into iOS resources:
#
# + string, string-array and plurals are supported
# + values-zh-rTW (or values-zh-rHK) will be translated into zh-Hant.lproj
# + values-zh-rCN will be translated into zh-Hans.lproj
# + string format %s will be translated into %@
# + storyboard with @key in document label, will have its title or content
#   substituned with real localized string (lookup by key);
#   you need have at least one storyboard .strings for this to work
#

require 'fileutils'
require 'pathname'
require 'rexml/document'
require 'optparse'

ARGV << '--help' if ARGV.empty?

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: localize.rb options"

  opts.on("--in DIRECTORY", "Andrord resources directory") do |v|
    options[:in] = v
  end

  opts.on("--out DIRECTORY", "iOS resources directory") do |v|
    options[:out] = v
  end

  opts.on("--report FILE", "CSV report file") do |v|
    options[:csv] = v
  end

  opts.on_tail("--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

src_path = Pathname.new(File.expand_path(options[:in])) if options[:in]
dest_path = Pathname.new(File.expand_path(options[:out])) if options[:out]
csv_path = Pathname.new(File.expand_path(options[:csv])) if options[:csv]

unless src_path
  puts "Error! source directory not specified"
  exit
end

unless dest_path or csv_path
  puts "Error! either --out or --report must be specified"
  exit
end

unless src_path.exist?
  puts "Error! source directory not found: #{src_path}"
  exit
end

$locales = {}
strings_keys = {}
arrays_keys = {}
plurals_keys = {}

src_path.each_entry { |values_dir|
  next unless values_dir.fnmatch? 'values*'

  in_path = src_path + values_dir

  if values_dir.fnmatch? 'values'
    locale = "Base"
  else
    locale = values_dir.to_s.gsub(/^values-(.+)$/, '\1').gsub(/-r/, '-')
    if locale == 'zh-TW'
      locale = 'zh-Hant'
    elsif locale == 'zh-HK'
      locale = 'zh-Hant'
      next if $locales.key?(locale)
    elsif locale == 'zh-CN'
      locale = 'zh-Hans'
    end
  end

  values = {
    :strings => {},
    :arrays => {},
    :plurals => {},
  }

  in_path.each_entry { |xml_file|
    next unless xml_file.fnmatch? '*.xml'

    xml_path = in_path + xml_file
    next unless xml_path.exist?

    puts "xml: #{xml_path.to_s}"

    xml = File.read xml_path.to_s
    doc = REXML::Document.new(xml)

    doc.elements.each('resources/string') { |str|
      next if str.attributes['translatable'] == 'false'

      key = str.attributes['name']
      puts "string: #{key}"

      until not str.has_elements?
        str.each_element { |astr|
          str = astr
        }
      end

      next if not str.text
      strings_keys[key] = true
      values[:strings][key] = str.text
    }

    doc.elements.each('resources/string-array') { |arr|
      next if arr.attributes['translatable'] == 'false'

      key = arr.attributes['name']
      puts "string-array: #{key}"

      arr_items = []
      arr.elements.each { |e|
        if e.name == 'item'
          arr_items << e.text
        end
      }

      if not arr_items.empty?
        arrays_keys[key] = true
        values[:arrays][key] = arr_items
      end
    }

    doc.elements.each('resources/plurals') { |plu|
      next if plu.attributes['translatable'] == 'false'

      key = plu.attributes['name']
      puts "plurals: #{key}"

      plu_items = []
      plu.elements.each { |e|
        if e.name == 'item'
          plu_items << { :qty => e.attributes['quantity'], :value => e.text }
        end
      }

      if not plu_items.empty?
        plurals_keys[key] = true
        values[:plurals][key] = plu_items
      end
    }

    if not values[:strings].empty? or not values[:arrays].empty? or not values[:plurals].empty?
      $locales[locale] = values
    end
  }
}

def locales_lookup(locale, type, key)
    while true
      values = $locales[locale]
      if values
        value = values[type][key]
        return value if value
      end

      break if locale == 'Base'

      r = locale.match(/^(.*)-[^-]+$/)
      locale = r ? r[1] : "Base"
    end
    return nil
end

def normalize_value(locale, str)
  while str
    r = str.match(/^@string\/(.*)$/)
    break if not r
    str = locales_lookup(locale, :string, r[1])
  end
  return str
end

def normalize_string(locale, str)
  str = normalize_value(locale, str)
  str = str.gsub(/(%(\d\$)?)s/, '\1@')
  str = str.gsub(/(%(\d\$)?),d/, '\1d')
  return str.gsub(/"/, '\\"')
end

def normalize_csv(locale, str)
  str = normalize_value(locale, str)
  return '"' + str.gsub(/"/, '""') + '"'
end

def ensure_order(array, order)
    out = []
    order.each { |e|
      out << e if array.include?(e)
    }
    out += array.sort - order
    return out
end

def output_resource(dest_path, locale, strings_keys, arrays_keys, plurals_keys)
  locale_path = dest_path + "#{locale}.lproj"
  FileUtils.mkdir_p(locale_path) unless File.directory?(locale_path)

  if not strings_keys.empty?
    strings_path = locale_path + 'Localizable.strings'
    strings_path.delete if strings_path.exist?

    File.open(strings_path, 'wb') { |f|
      f.write "\xef\xbb\xbf"

      strings_keys.keys.sort.each { |key|
        value = locales_lookup(locale, :strings, key)
        next if not value

        value = normalize_string(locale, value)
        f.write "\"#{key}\" = \"#{value}\";\n"
      }
    }
  end

  if not arrays_keys.empty?
    arrays_path = locale_path + 'LocalizableArray.strings'
    arrays_path.delete if arrays_path.exist?

    File.open(arrays_path, 'wb') { |f|
      f.write "\xef\xbb\xbf"

      arrays_keys.keys.sort.each { |key|
        arr = locales_lookup(locale, :arrays, key)
        next if not arr

        f.write "\"#{key}\" = (\n"
        arr.each { |value|
          value = normalize_string(locale, value)
          f.write "    \"#{value}\",\n"
        }
        f.write ");\n\n"
      }
    }
  end

  if not plurals_keys.empty?
    plurals_path = locale_path + 'Localizable.stringsdict'
    plurals_path.delete if plurals_path.exist?

    File.open(plurals_path, 'wb') { |f|
      f.write "\xef\xbb\xbf"
      f.write "<plist version=\"1.0\">\n"
      f.write "<dict>\n\n"

      plurals_keys.keys.sort.each { |key|
        plu = locales_lookup(locale, :plurals, key)
        next if not plu

        f.write "<key>#{key}</key>\n"
        f.write "<dict>\n"
        f.write "    <key>NSStringLocalizedFormatKey</key>\n"
        f.write "    <string>%\#@x@</string>\n"
        f.write "    <key>x</key>\n"
        f.write "    <dict>\n"
        f.write "        <key>NSStringFormatSpecTypeKey</key>\n"
        f.write "        <string>NSStringPluralRuleType</string>\n"
        f.write "        <key>NSStringFormatValueTypeKey</key>\n"
        f.write "        <string>d</string>\n"

        plu.each { |e|
          qty = e[:qty]
          value = normalize_string(locale, e[:value])
          value = value.gsub(/%\d\$,?d/, '%d')
          f.write "        <key>#{qty}</key>\n"
          f.write "        <string>#{value}</string>\n"
        }

        f.write "    </dict>\n"
        f.write "</dict>\n\n"
      }

      f.write "</dict>\n"
      f.write "</plist>\n"
    }
  end
end

def output_csv(csv_path, strings_keys, arrays_keys, plurals_keys)
    csv_path.delete if csv_path.exist?

    locale_keys = ensure_order($locales.keys, ['Base', 'en'])

    File.open(csv_path, 'wb') { |f|
      f.write "\xef\xbb\xbf"

      f.write "ID,"
      locale_keys.each { |locale|
        f.write "#{locale},"
      }
      f.write "\n"

      strings_keys.keys.sort.each { |key|
        f.write "#{key},"
        locale_keys.each { |locale|
          value = locales_lookup(locale, :strings, key)
          value = "" if not value
          value = normalize_csv(locale, value)
          f.write "#{value},"
        }
        f.write "\n"
      }

      arrays_keys.keys.sort.each { |key|
        max_size = 0
        locale_keys.each { |locale|
          arr = locales_lookup(locale, :arrays, key)
          max_size = arr.size if arr and arr.size > max_size
        }

        for idx in 1..max_size
          f.write "#{key}.#{idx},"
          locale_keys.each { |locale|
            arr = locales_lookup(locale, :arrays, key)
            value = (arr and idx <= arr.size) ? arr[idx-1] : ""
            value = normalize_csv(locale, value)
            f.write "#{value},"
          }
          f.write "\n"
        end
      }

      plurals_keys.keys.sort.each { |key|
        qtys = {}
        locale_keys.each { |locale|
          plu = locales_lookup(locale, :plurals, key)
          next if not plu
          plu.each { |e|
            qtys[e[:qty]] = true
          }
        }

        qtys = ensure_order(qtys.keys, ['zero', 'one', 'two', 'few', 'many', 'other'])

        qtys.each { |qty|
          f.write "#{key}.#{qty},"
          locale_keys.each { |locale|
            plu = locales_lookup(locale, :plurals, key)
            plu = {} if not plu
            found = false

            plu.each { |e|
              if qty == e[:qty]
                found = true
                value = normalize_csv(locale, e[:value])
                f.write "#{value},"
                break
              end
            }

            if not found
              f.write ","
            end
          }
          f.write "\n"
        }
      }
    }
end

if dest_path
  $locales.keys.each { |locale|
    output_resource(dest_path, locale, strings_keys, arrays_keys, plurals_keys)
  }
end

if csv_path
  output_csv(csv_path, strings_keys, arrays_keys, plurals_keys)
end
