# frozen_string_literal: true

module EffectiveLogging
  module ActiveStorageLogger

    def track_downloads
      return if EffectiveLogging.supressed?

      user = current_user if respond_to?(:current_user)

      key = decode_verified_key()
      return unless key.present?
      return if (key[:content_type] || '').starts_with?('image')

      blob = ActiveStorage::Blob.where(key: key[:key]).first
      return unless blob.present?

      blob.attachments.each do |attachment|
        next if attachment.name == 'embeds'
        next if attachment.record_type == 'ActionText::RichText'

        associated = attachment.record
        filename = blob.filename.to_s
        message = [associated.to_s, filename.to_s].uniq.join(' ')

        EffectiveLogger.download(message, associated: associated, associated_to_s: filename, filename: filename, user: user)
      end
    end

  end
end
