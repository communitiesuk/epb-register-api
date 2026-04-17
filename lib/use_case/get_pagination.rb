module UseCase
  class GetPagination
    def initialize(gateway:)
      @gateway = gateway
    end

    def execute(start_date:, end_date:, current_page:, records_per_page: 5000, url: nil, count_method: :count, event_types: [])
      total_records = if count_method == :count_scottish_events
                        @gateway.method(count_method).call(event_types:, start_date:, end_date:)
                      elsif %i[count count_scottish_assessor_events].include?(count_method)
                        @gateway.method(count_method).call(start_date:, end_date:)
                      else
                        raise NoMethodError
                      end

      raise Boundary::NoData, "#{start_date} to #{end_date}" if total_records.zero?

      total_pages = (total_records / records_per_page.to_f).ceil

      raise Errors::OutOfPaginationRangeError, "The requested page number #{current_page} is out of range. There are #{total_pages} pages." if current_page > total_pages || current_page < 1

      next_page = current_page + 1 unless current_page >= total_pages
      prev_page = current_page > 1 ? current_page - 1 : nil

      if url
        replace_page_numbers_with_urls(url, next_page, prev_page)
      else
        {
          current_page: current_page,
          next_page: next_page,
          previous_page: prev_page,
        }
      end
    end

    def replace_page_numbers_with_urls(url, next_page, prev_page)
      next_page = if next_page.nil?
                    nil
                  elsif url.match?(/page=(\d*)/)
                    url.gsub(/page=(\d*)/, "page=#{next_page}")
                  else
                    url + "&page=#{next_page}"
                  end

      {
        self: url,
        next: next_page,
        prev: prev_page.nil? ? nil : url.gsub(/page=(\d*)/, "page=#{prev_page}"),
      }
    end
  end
end
