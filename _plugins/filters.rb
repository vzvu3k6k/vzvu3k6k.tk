# -*- coding: utf-8 -*-
module Jekyll
  module Filters
    def date_to_ja_string(date)
      date.strftime("%Y年%m月%d日")
    end

    # Format a date to html5 valid date string
    # http://www.w3.org/TR/html5/common-microsyntaxes.html#valid-date-string
    def date_to_valid_date_string(date)
      date.strftime("%Y-%m-%d")
    end
  end
end
