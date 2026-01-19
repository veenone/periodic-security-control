# frozen_string_literal: true

module PeriodicSecurityControl
  module ProjectPatch
    extend ActiveSupport::Concern

    included do
      has_many :psc_control_categories, class_name: 'PscControlCategory', dependent: :destroy
      has_many :psc_control_points, through: :psc_control_categories, source: :control_points
    end
  end
end
