# frozen_string_literal: true

module EffectiveLogging
  module ActiveStorageLogger

    def track_active_storage_download
      @blob || set_download_blob()
      track_active_storage_blob(@blob)
    end

    def track_active_storage_redirect
      @blob || set_blob()
      track_active_storage_blob(@blob)
    end

    private

    def track_active_storage_blob(blob)
      return if EffectiveLogging.supressed?
      return unless blob.present?

      onlies = EffectiveLogging.active_storage_onlies
      excepts = EffectiveLogging.active_storage_excepts

      blob.attachments.each do |attachment|
        next if attachment.name == 'embeds'
        next if attachment.record_type.blank?

        # Process except and only
        next if excepts.present? && excepts.any? { |type| attachment.record_type.start_with?(type) || attachment.record_type.end_with?(type) }
        next if onlies.present? && !onlies.any? { |type| attachment.record_type.start_with?(type) || attachment.record_type.end_with?(type) }

        associated = attachment.record
        filename = blob.filename.to_s
        message = [associated.to_s, filename.to_s].uniq.join(' ')
        user = current_user

        EffectiveLogger.download(message, associated: associated, associated_to_s: filename, filename: filename, user: user)
      end
    end

    def set_download_blob
      @blob ||= ActiveStorage::Blob.where(key: decode_verified_key().try(:dig, :key)).first
    end

    def current_user
      (defined?(Tenant) ? send("current_#{Tenant.current}_user") : super)
    end

  end
end
