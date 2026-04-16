module Helper
  class PaginationHelper
    def self.calculate_offset(current_page, limit)
      current_page = 1 if current_page <= 0
      (current_page - 1) * limit
    end
  end
end
