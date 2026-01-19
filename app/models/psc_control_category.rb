# frozen_string_literal: true

class PscControlCategory < (defined?(ApplicationRecord) == 'constant' ? ApplicationRecord : ActiveRecord::Base)
  include Redmine::SafeAttributes

  belongs_to :project
  has_many :control_points, class_name: 'PscControlPoint',
           foreign_key: 'category_id', dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :code, presence: true, uniqueness: { scope: :project_id, case_sensitive: false },
            length: { minimum: 2, maximum: 5 },
            format: { with: /\A[A-Z]+\z/, message: :invalid_code_format }
  validates :project, presence: true

  before_validation :upcase_code

  acts_as_positioned scope: [:project_id]

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position) }
  scope :for_project, ->(project) { where(project_id: project.is_a?(Project) ? project.id : project) }

  safe_attributes 'name', 'code', 'description', 'position', 'active', 'project_id'

  def to_s
    name
  end

  def control_points_count
    control_points.active.count
  end

  def completed_schedules_count(year = Date.current.year)
    PscSchedule.joins(:control_point)
               .where(psc_control_points: { category_id: id })
               .for_year(year)
               .where(status: 'completed')
               .count
  end

  def total_schedules_count(year = Date.current.year)
    PscSchedule.joins(:control_point)
               .where(psc_control_points: { category_id: id })
               .for_year(year)
               .count
  end

  def completion_rate(year = Date.current.year)
    total = total_schedules_count(year)
    return 0 if total.zero?

    (completed_schedules_count(year).to_f / total * 100).round(1)
  end

  private

  def upcase_code
    self.code = code.upcase if code.present?
  end
end
