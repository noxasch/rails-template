# frozen_string_literal: true

require "active_support/concern"

#
# Make flash messages available as shared data
#
module InertiaFlash
  extend ActiveSupport::Concern

  included do
    inertia_share flash: -> { flash.to_hash }
    inertia_share do
      {
        referrer: request.referer
      }
    end
  end
end
