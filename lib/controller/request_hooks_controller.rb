# frozen_string_literal: true

module Controller
  class RequestHooksController < BaseController
    before do
      Helper::CurrentAuth.reset
    end

    after do
      Helper::CurrentAuth.reset
    end
  end
end
