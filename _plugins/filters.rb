# -*- coding: utf-8 -*-
module Jekyll
  module Filters
    def date_to_ja_string(date)
      date.strftime("%Y年%m月%d日")
    end
  end
end
