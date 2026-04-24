module Helper
  class PaginationHelper
    def self.calculate_offset(current_page, data_per_page)
      current_page = 1 if current_page <= 0
      (current_page - 1) * data_per_page
    end
  end
end
