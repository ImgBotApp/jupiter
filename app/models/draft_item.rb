class DraftItem < ApplicationRecord

  enum status: { inactive: 0, active: 1, archived: 2 }

  enum wizard_step: { describe_item: 0, choose_license_and_visibility: 1, upload_files: 2, review_and_deposit_item: 3 }

  enum license: { attribution_non_commercial: 0,
                  attribution: 1,
                  attribution_non_commercial_no_derivatives: 2,
                  attribution_non_commercial_share_alike: 3,
                  attribution_no_derivatives: 4,
                  attribution_share_alike: 5,
                  cco_universal: 6,
                  public_domain_mark: 7,
                  license_text: 8 }

  # Can't use public as this is a ActiveRecord method
  enum visibility: { open_access: 0,
                     embargo: 1,
                     authenticated: 2 }

  # Can't reuse same keys as visibility, need to differentiate a bit
  enum visibility_after_embargo: { opened: 0,
                                   ccid_protected: 1 }

  has_many_attached :files

  has_many :draft_items_languages, dependent: :destroy

  has_many :languages, through: :draft_items_languages

  # Rails 5 turns presence check on by default for belongs_to relationships
  belongs_to :type, optional: true
  belongs_to :user

  validates :title, :type, :languages,
            :creators, :subjects, :date_created,
            :description, :member_of_paths,
            presence: true, if: :validate_describe_item?

  validates :license, :visibility, presence: true, if: :validate_choose_license_and_visibility?
  validates :license_text_area, presence: true, if: :validate_if_license_is_text?
  validates :embargo_end_date, presence: true, if: :validate_if_visibility_is_embargo?

  validates :files, presence: true, if: :validate_upload_files?


  def thumbnail
    if self.thumbnail_id.present?
      file = self.files.find(self.thumbnail_id)
      return file if file.present?
    end

    self.files.first
  end

  private

  # TODO: turn on all validations on when reviewing (archived status)
  def validate_describe_item?
    active? && describe_item?
  end

  def validate_choose_license_and_visibility?
    active? && choose_license_and_visibility?
  end

  def validate_upload_files?
    active? && upload_files?
  end

  def validate_if_license_is_text?
    validate_choose_license_and_visibility? && license_text?
  end

  def validate_if_visibility_is_embargo?
    validate_choose_license_and_visibility? && embargo?
  end

end