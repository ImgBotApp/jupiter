class UriValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    raise ArgumentError, "#{attr} must specify a vocabulary to validate against!" unless options[:in_vocabulary].present?
    return unless value.present?
    value = [value] unless value.is_a?(Array) || value.is_a?(ActiveTriples::Relation)
    value.each do |v|
      unless ::CONTROLLED_VOCABULARIES[options[:in_vocabulary]].from_uri(v).present?
        record.errors.add(attr, :not_recognized)
      end
    end
  end
end
